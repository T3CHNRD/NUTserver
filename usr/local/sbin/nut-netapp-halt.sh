#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

LOG_FILE="/var/log/nut-netapp-halt.log"
CONFIG_FILE="/etc/nut/nut-orchestrator.conf"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

classify_name() {
  case "${TARGET:-}" in
    Alblnetapp01)
      echo "NetApp01"
      ;;
    Alblnetapp02)
      echo "NetApp02"
      ;;
    *)
      echo "${TARGET:-NetApp}"
      ;;
  esac
}

power_classification() {
  local result="$1"
  local reason="$2"
  local extra="${3:-}"
  local cname
  cname="$(classify_name)"

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    if [ -n "$extra" ]; then
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"${cname}\" reason=\"${reason}\" ${extra}"
    else
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"${cname}\" reason=\"${reason}\""
    fi
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
}

if [ ! -f "$CONFIG_FILE" ]; then
  log "ERROR config file missing: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

TARGET="${1:-}"

if [ -z "$TARGET" ]; then
  log "ERROR no target provided"
  exit 1
fi

case "$TARGET" in
  Alblnetapp01)
    HOST="${NETAPP01_HOST:-}"
    ARRAY_NAME="${NETAPP01_NODE:-}"
    NODE_A="${NETAPP01_NODE_A:-}"
    NODE_B="${NETAPP01_NODE_B:-}"
    ;;
  Alblnetapp02)
    HOST="${NETAPP02_HOST:-}"
    ARRAY_NAME="${NETAPP02_NODE:-}"
    NODE_A="${NETAPP02_NODE_A:-}"
    NODE_B="${NETAPP02_NODE_B:-}"
    ;;
  *)
    log "ERROR unknown target '$TARGET'"
    exit 1
    ;;
esac

if [ -z "${NETAPP_USERNAME:-}" ] || [ -z "${NETAPP_PASSWORD:-}" ]; then
  log "ERROR NetApp username/password not set in $CONFIG_FILE"
  exit 1
fi

if [ -z "$HOST" ] || [ -z "$ARRAY_NAME" ]; then
  log "ERROR Host or array name missing for $TARGET"
  exit 1
fi

log "Starting NetApp halt wrapper"
log "Target=$TARGET Host=$HOST Array=$ARRAY_NAME NodeA=${NODE_A:-n/a} NodeB=${NODE_B:-n/a}"

CMD_PREVIEW="ssh ${NETAPP_USERNAME}@${HOST} \"system node halt -node ${ARRAY_NAME} -reason 'UPS power event'\""
log "SIMULATION ONLY: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION RESULT: wrapper validated, no NetApp halt command sent"

  case "$TARGET" in
    Alblnetapp01)
      CLASSIFY_NAME="NetApp01"
      ;;
    Alblnetapp02)
      CLASSIFY_NAME="NetApp02"
      ;;
    *)
      CLASSIFY_NAME="$TARGET"
      ;;
  esac

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION WARN target=\"${CLASSIFY_NAME}\" reason=\"simulation_only_command_not_sent\""
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi

  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: NETAPP_LIVE_APPROVED=${NETAPP_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR NetApp live halt blocked: ALLOW_REAL_TEST is not 1"
  power_classification "FAIL" "blocked_allow_real_test_not_set"
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "full-production" ] && [ "${REAL_TEST_PHASE:-}" != "phase-netapp" ]; then
  log "ERROR NetApp live halt blocked: REAL_TEST_PHASE is not approved for NetApp"
  power_classification "FAIL" "blocked_wrong_real_test_phase" "phase=\"${REAL_TEST_PHASE:-unset}\""
  exit 2
fi

if [ "${NETAPP_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR NetApp live halt blocked: NETAPP_LIVE_APPROVED is not 1"
  power_classification "FAIL" "blocked_netapp_live_not_approved"
  exit 2
fi

log "APPROVED: executing NetApp halt command"
ssh -o BatchMode=yes -o ConnectTimeout=10 "${NETAPP_USERNAME}@${HOST}" "system node halt -node ${ARRAY_NAME} -reason 'UPS power event'" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR NetApp halt command failed for $TARGET rc=$RC"
  power_classification "FAIL" "command_failed" "command_rc=${RC}"
  exit "$RC"
fi

log "SUCCESS NetApp halt command sent to $TARGET"

if [ -x /usr/local/sbin/nut-classify-target-shutdown ]; then
  CLASSIFY_NAME="$(classify_name)"
  /usr/local/sbin/nut-classify-target-shutdown "$CLASSIFY_NAME" "$RC" >> "$LOG_FILE" 2>&1
  CLASSIFY_RC="$?"
  exit "$CLASSIFY_RC"
fi

power_classification "WARN" "command_sent_but_not_verified" "verify_rc=99"
exit 3
