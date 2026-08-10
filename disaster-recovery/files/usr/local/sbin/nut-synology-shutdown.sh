#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

LOG_FILE="/var/log/nut-synology-shutdown.log"
CONFIG_FILE="/etc/nut/synology-api.conf"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

power_classification() {
  local result="$1"
  local reason="$2"
  local extra="${3:-}"

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    if [ -n "$extra" ]; then
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"Synology\" reason=\"${reason}\" ${extra}"
    else
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"Synology\" reason=\"${reason}\""
    fi
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
}

require_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR Synology DSM API config missing: $CONFIG_FILE"
    power_classification "FAIL" "dsm_api_config_missing"
    exit 1
  fi

  # shellcheck disable=SC1090
  . "$CONFIG_FILE"

  if [ -z "${SYNOLOGY_BASE_URL:-}" ] || [ -z "${SYNOLOGY_USERNAME:-}" ] || [ -z "${SYNOLOGY_PASSWORD:-}" ]; then
    log "ERROR Synology DSM API config incomplete"
    power_classification "FAIL" "dsm_api_config_incomplete"
    exit 1
  fi
}

dsm_login() {
  curl -k -sS --max-time 15 \
    --get "${SYNOLOGY_BASE_URL}/webapi/auth.cgi" \
    --data-urlencode "api=SYNO.API.Auth" \
    --data-urlencode "version=6" \
    --data-urlencode "method=login" \
    --data-urlencode "account=${SYNOLOGY_USERNAME}" \
    --data-urlencode "passwd=${SYNOLOGY_PASSWORD}" \
    --data-urlencode "session=Core" \
    --data-urlencode "format=sid"
}

extract_sid() {
  python3 -c 'import sys,json; data=json.load(sys.stdin); print(data.get("data",{}).get("sid",""))' 2>/dev/null
}

dsm_logout() {
  local sid="$1"

  if [ -z "$sid" ]; then
    return 0
  fi

  curl -k -sS --max-time 15 \
    --get "${SYNOLOGY_BASE_URL}/webapi/auth.cgi" \
    --data-urlencode "api=SYNO.API.Auth" \
    --data-urlencode "version=6" \
    --data-urlencode "method=logout" \
    --data-urlencode "session=Core" \
    --data-urlencode "_sid=${sid}" \
    >/dev/null 2>&1 || true
}

dsm_shutdown() {
  local sid="$1"

  curl -k -sS --max-time 20 \
    --get "${SYNOLOGY_BASE_URL}/webapi/entry.cgi" \
    --data-urlencode "api=SYNO.Core.System" \
    --data-urlencode "version=1" \
    --data-urlencode "method=shutdown" \
    --data-urlencode "_sid=${sid}"
}

log "Starting Synology shutdown wrapper using DSM API"
log "SIMULATE=$SIMULATE"

require_config

log "DSM API base_url=${SYNOLOGY_BASE_URL}"
log "DSM API username=${SYNOLOGY_USERNAME}"
log "DSM API password=[REDACTED]"

LOGIN_JSON="$(dsm_login)"
SID="$(printf '%s' "$LOGIN_JSON" | extract_sid)"

if [ -z "$SID" ]; then
  log "ERROR Synology DSM API login failed or no SID returned"
  power_classification "FAIL" "dsm_api_login_failed"
  exit 1
fi

log "DSM API login success sid=[REDACTED]"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: would call SYNO.Core.System shutdown through DSM API"
  dsm_logout "$SID"
  log "DSM API logout complete"
  power_classification "WARN" "simulation_only_command_not_sent" "method=\"dsm_api\""
  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: SYNOLOGY_LIVE_APPROVED=${SYNOLOGY_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR Synology live shutdown blocked: ALLOW_REAL_TEST is not 1"
  dsm_logout "$SID"
  power_classification "FAIL" "blocked_allow_real_test_not_set"
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "phase3-full" ] && [ "${REAL_TEST_PHASE:-}" != "phase-synology" ]; then
  log "ERROR Synology live shutdown blocked: REAL_TEST_PHASE is not approved for Synology"
  dsm_logout "$SID"
  power_classification "FAIL" "blocked_wrong_real_test_phase" "phase=\"${REAL_TEST_PHASE:-unset}\""
  exit 2
fi

if [ "${SYNOLOGY_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR Synology live shutdown blocked: SYNOLOGY_LIVE_APPROVED is not 1"
  dsm_logout "$SID"
  power_classification "FAIL" "blocked_synology_live_not_approved"
  exit 2
fi

log "APPROVED: sending Synology DSM API shutdown request"
SHUTDOWN_JSON="$(dsm_shutdown "$SID")"
RC=$?

dsm_logout "$SID"
log "DSM API logout attempted after shutdown request"

if [ "$RC" -ne 0 ]; then
  log "ERROR Synology DSM API shutdown curl failed rc=$RC"
  power_classification "FAIL" "dsm_api_shutdown_curl_failed" "command_rc=${RC}"
  exit "$RC"
fi

SUCCESS="$(printf '%s' "$SHUTDOWN_JSON" | python3 -c 'import sys,json; data=json.load(sys.stdin); print(str(data.get("success", False)).lower())' 2>/dev/null || echo false)"

if [ "$SUCCESS" != "true" ]; then
  log "ERROR Synology DSM API shutdown returned unsuccessful response"
  power_classification "FAIL" "dsm_api_shutdown_unsuccessful"
  exit 1
fi

log "SUCCESS Synology DSM API shutdown command sent"

if [ -x /usr/local/sbin/nut-classify-target-shutdown ]; then
  /usr/local/sbin/nut-classify-target-shutdown Synology 0 >> "$LOG_FILE" 2>&1
  CLASSIFY_RC="$?"
  exit "$CLASSIFY_RC"
fi

power_classification "WARN" "command_sent_but_not_verified" "verify_rc=99 method=\"dsm_api\""
exit 3
