#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/nut-local-final-shutdown.log"
POWER_EVENT_LOG="/usr/local/sbin/nut-power-event-log"
PUBLISHER="/usr/local/sbin/nut-publish-power-events-json"

SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $*" | tee -a "$LOG_FILE"
}

power_event() {
  if [ -x "$POWER_EVENT_LOG" ]; then
    "$POWER_EVENT_LOG" "$*"
  fi

  if [ -x "$PUBLISHER" ]; then
    "$PUBLISHER" >/dev/null 2>&1 || true
  fi
}

log "Starting NUT server final shutdown wrapper"
log "SIMULATE=${SIMULATE}"
log "PURPOSE: local NUT server should be the final shutdown target after orchestration completes"

power_event "NUTSERVER_FINAL_SHUTDOWN status=\"started\" simulate=\"${SIMULATE}\" note=\"NUT server final shutdown wrapper entered\""

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: would flush logs, publish power events, and run /sbin/shutdown -h now as final local step"
  power_event "NUTSERVER_FINAL_SHUTDOWN status=\"simulation_only\" result=\"not_shutdown\" note=\"would shut down NUT server last\""
  exit 0
fi

log "MODE: REAL / LIVE LOCAL NUT SERVER SHUTDOWN"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: NUTSERVER_LIVE_APPROVED=${NUTSERVER_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR local NUT server shutdown blocked: ALLOW_REAL_TEST is not 1"
  power_event "NUTSERVER_FINAL_SHUTDOWN status=\"blocked\" reason=\"ALLOW_REAL_TEST_not_1\""
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "full-production" ]; then
  log "ERROR local NUT server shutdown blocked: REAL_TEST_PHASE is not full-production"
  power_event "NUTSERVER_FINAL_SHUTDOWN status=\"blocked\" reason=\"REAL_TEST_PHASE_not_full_production\""
  exit 2
fi

if [ "${NUTSERVER_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR local NUT server shutdown blocked: NUTSERVER_LIVE_APPROVED is not 1"
  power_event "NUTSERVER_FINAL_SHUTDOWN status=\"blocked\" reason=\"NUTSERVER_LIVE_APPROVED_not_1\""
  exit 2
fi

log "APPROVED: publishing final power event before local shutdown"
power_event "NUTSERVER_FINAL_SHUTDOWN status=\"approved\" result=\"shutdown_command_will_run\" note=\"NUT server shutting down last\""

sync

log "EXECUTING: /sbin/shutdown -h now"
/sbin/shutdown -h now
