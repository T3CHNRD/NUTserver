#!/bin/bash
set -u

LOG_FILE="/var/log/nut-blueiris-shutdown.log"
TARGET_NAME="BlueIris"
TARGET_IP="192.168.1.25"
CREDS_FILE="/etc/nut/lansweeper.creds"
SIMULATE="${SIMULATE:-1}"

CLASSIFY_TARGET_HELPER="/usr/local/sbin/nut-classify-target-shutdown"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

classify_target() {
  local command_rc="$1"

  if [ -x "$CLASSIFY_TARGET_HELPER" ]; then
    "$CLASSIFY_TARGET_HELPER" "$TARGET_NAME" "$command_rc"
    return "$?"
  fi

  log "WARN classification helper missing: $CLASSIFY_TARGET_HELPER"
  return 3
}

if [ -f "$CREDS_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CREDS_FILE"
fi

RPC_DOMAIN="${LANSWEEPER_DOMAIN:-ALBL}"
RPC_USERNAME="${LANSWEEPER_USERNAME:-administrator}"
RPC_PASSWORD=[REDACTED]

RPC_USER="${RPC_DOMAIN}\\${RPC_USERNAME}%${RPC_PASSWORD}"
CMD_PREVIEW="/usr/bin/net rpc shutdown -S ${TARGET_IP} -U '${RPC_DOMAIN}\\${RPC_USERNAME}%********' -f -t 0 -C \"UPS shutdown\""

log "Starting Blue Iris shutdown for $TARGET_IP"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no Blue Iris shutdown command sent"
  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log 'SHUTDOWN_CLASSIFICATION WARN target="BlueIris" reason="simulation_only_command_not_sent"'
  fi
  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: BLUEIRIS_LIVE_APPROVED=${BLUEIRIS_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR live Blue Iris shutdown blocked: ALLOW_REAL_TEST is not 1"
  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log 'SHUTDOWN_CLASSIFICATION FAIL target="BlueIris" reason="blocked_allow_real_test_not_set"'
  fi
  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "phase3-full" ]; then
  log "ERROR live Blue Iris shutdown blocked: REAL_TEST_PHASE is not phase3-full"
  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION FAIL target=\"BlueIris\" reason=\"blocked_wrong_real_test_phase\" phase=\"${REAL_TEST_PHASE:-unset}\""
  fi
  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
  exit 2
fi

if [ "${BLUEIRIS_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR live Blue Iris shutdown blocked: BLUEIRIS_LIVE_APPROVED is not 1"
  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log 'SHUTDOWN_CLASSIFICATION FAIL target="BlueIris" reason="blocked_blueiris_live_not_approved"'
  fi
  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
  exit 2
fi

if [ ! -f "$CREDS_FILE" ]; then
  log "ERROR credentials file not found: $CREDS_FILE"
  classify_target 1
  exit 1
fi

if [ -z "${RPC_PASSWORD:[REDACTED]
  log "ERROR RPC password missing from $CREDS_FILE"
  classify_target 1
  exit 1
fi

log "APPROVED: executing Blue Iris RPC shutdown"
log "COMMAND PREVIEW: ${CMD_PREVIEW}"

/usr/bin/net rpc shutdown -S "$TARGET_IP" -U "$RPC_USER" -f -t 0 -C "UPS shutdown" >> "$LOG_FILE" 2>&1
COMMAND_RC="$?"

if [ "$COMMAND_RC" -ne 0 ]; then
  log "ERROR Blue Iris shutdown command failed rc=$COMMAND_RC"
else
  log "SUCCESS Blue Iris shutdown command sent"
fi

classify_target "$COMMAND_RC"
CLASSIFY_RC="$?"

exit "$CLASSIFY_RC"
