#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

LOG_FILE="/var/log/nut-voip-shutdown.log"
HOST="192.168.1.14"
USER_NAME="root"
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
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"VOIP\" reason=\"${reason}\" ${extra}"
    else
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"VOIP\" reason=\"${reason}\""
    fi
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
}

CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 ${USER_NAME}@${HOST} \"sudo /usr/bin/systemctl poweroff\""

log "Starting VOIP shutdown for $HOST"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no VOIP shutdown command sent"

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log 'SHUTDOWN_CLASSIFICATION WARN target="VOIP" reason="simulation_only_command_not_sent"'
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi

  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: VOIP_LIVE_APPROVED=${VOIP_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR VOIP live shutdown blocked: ALLOW_REAL_TEST is not 1"
  power_classification "FAIL" "blocked_allow_real_test_not_set"
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "phase3-full" ] && [ "${REAL_TEST_PHASE:-}" != "phase-voip" ]; then
  log "ERROR VOIP live shutdown blocked: REAL_TEST_PHASE is not approved for VOIP"
  power_classification "FAIL" "blocked_wrong_real_test_phase" "phase=\"${REAL_TEST_PHASE:-unset}\""
  exit 2
fi

if [ "${VOIP_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR VOIP live shutdown blocked: VOIP_LIVE_APPROVED is not 1"
  power_classification "FAIL" "blocked_voip_live_not_approved"
  exit 2
fi

ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER_NAME}@${HOST}" "sudo /usr/bin/systemctl poweroff" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR VOIP shutdown command failed rc=$RC"
  power_classification "FAIL" "command_failed" "command_rc=${RC}"
  exit "$RC"
fi

log "SUCCESS VOIP shutdown command sent"

if [ -x /usr/local/sbin/nut-classify-target-shutdown ]; then
  /usr/local/sbin/nut-classify-target-shutdown VOIP "$RC" >> "$LOG_FILE" 2>&1
  CLASSIFY_RC="$?"
  exit "$CLASSIFY_RC"
fi

power_classification "WARN" "command_sent_but_not_verified" "verify_rc=99"
exit 3
