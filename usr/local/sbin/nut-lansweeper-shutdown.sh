#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -uo pipefail

LOG_FILE="/var/log/nut-lansweeper-shutdown.log"
CREDS_FILE="/etc/nut/lansweeper.creds"
SIMULATE="${SIMULATE:-1}"

POWER_EVENT_LOGGER="/usr/local/sbin/nut-power-event-log"
PUBLISH_POWER_EVENTS="/usr/local/sbin/nut-publish-power-events-json"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

power_event() {
  if [ -x "$POWER_EVENT_LOGGER" ]; then
    "$POWER_EVENT_LOGGER" "$*" || true
  fi
}

publish_power_events() {
  if [ -x "$PUBLISH_POWER_EVENTS" ]; then
    "$PUBLISH_POWER_EVENTS" >/dev/null 2>&1 || true
  fi
}

if [ ! -f "$CREDS_FILE" ]; then
  log "ERROR creds file missing: $CREDS_FILE"
  power_event 'SHUTDOWN_CLASSIFICATION FAIL target="Lansweeper" reason="missing_creds_file"'
  publish_power_events
  exit 1
fi

# shellcheck disable=SC1090
. "$CREDS_FILE"

if [ -z "${LANSWEEPER_IP:-}" ] || [ -z "${LANSWEEPER_DOMAIN:-}" ] || [ -z "${LANSWEEPER_USERNAME:-}" ] || [ -z "${LANSWEEPER_PASSWORD:-}" ]; then
  log "ERROR required Lansweeper RPC values missing in $CREDS_FILE"
  power_event 'SHUTDOWN_CLASSIFICATION FAIL target="Lansweeper" reason="missing_required_rpc_values"'
  publish_power_events
  exit 1
fi

if [ "${LANSWEEPER_METHOD:-}" != "rpc" ]; then
  log "ERROR unsupported method '${LANSWEEPER_METHOD:-}' for this wrapper"
  power_event "SHUTDOWN_CLASSIFICATION FAIL target=\"Lansweeper\" reason=\"unsupported_method\" method=\"${LANSWEEPER_METHOD:-}\""
  publish_power_events
  exit 1
fi

RPC_USER="${LANSWEEPER_DOMAIN}\\${LANSWEEPER_USERNAME}%${LANSWEEPER_PASSWORD}"
CMD_PREVIEW="net rpc shutdown -S ${LANSWEEPER_IP} -U '${LANSWEEPER_DOMAIN}\\${LANSWEEPER_USERNAME}%********' -f -t 0"

log "Starting Lansweeper shutdown wrapper"
log "Method=${LANSWEEPER_METHOD:-unknown} Host=${LANSWEEPER_IP}"

if [ "$SIMULATE" = "1" ]; then
  log "MODE: SIMULATED / DRY-RUN"
  log "SIMULATION ONLY: would run ${CMD_PREVIEW}"
  log "SIMULATION RESULT: wrapper validated, no shutdown command sent"
  power_event 'SHUTDOWN_CLASSIFICATION WARN target="Lansweeper" reason="simulation_only_command_not_sent"'
  publish_power_events
  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: LANSWEEPER_LIVE_APPROVED=${LANSWEEPER_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR live Lansweeper shutdown blocked: ALLOW_REAL_TEST is not 1"
  power_event 'SHUTDOWN_CLASSIFICATION FAIL target="Lansweeper" reason="blocked_allow_real_test_not_set"'
  publish_power_events
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "phase1-lansweeper" ]; then
  log "ERROR live Lansweeper shutdown blocked: REAL_TEST_PHASE is not phase1-lansweeper"
  power_event "SHUTDOWN_CLASSIFICATION FAIL target=\"Lansweeper\" reason=\"blocked_wrong_real_test_phase\" phase=\"${REAL_TEST_PHASE:-unset}\""
  publish_power_events
  exit 2
fi

if [ "${LANSWEEPER_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR live Lansweeper shutdown blocked: LANSWEEPER_LIVE_APPROVED is not 1"
  power_event 'SHUTDOWN_CLASSIFICATION FAIL target="Lansweeper" reason="blocked_lansweeper_live_not_approved"'
  publish_power_events
  exit 2
fi

log "APPROVED: executing Lansweeper RPC shutdown"
log "COMMAND PREVIEW: ${CMD_PREVIEW}"

net rpc shutdown -S "${LANSWEEPER_IP}" -U "${RPC_USER}" -f -t 0
COMMAND_RC="$?"

if [ "$COMMAND_RC" -eq 0 ]; then
  log "SUCCESS Lansweeper shutdown command sent"
else
  log "ERROR Lansweeper shutdown command failed rc=${COMMAND_RC}"
fi

if [ "$COMMAND_RC" -eq 0 ]; then
  CLASSIFICATION=COMMAND_ACCEPTED
else
  CLASSIFICATION=COMMAND_FAILED
fi
CLASSIFY_RC="$COMMAND_RC"
log "Lansweeper ${CLASSIFICATION}; command_rc=${COMMAND_RC}; power-off not independently verified"
power_event "SHUTDOWN_CLASSIFICATION ${CLASSIFICATION}"
publish_power_events
exit "$COMMAND_RC"
