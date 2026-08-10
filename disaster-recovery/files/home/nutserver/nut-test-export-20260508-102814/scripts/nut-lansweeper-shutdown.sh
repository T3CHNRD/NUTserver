#!/usr/bin/env bash
set -uo pipefail

LOG_FILE="/var/log/nut-lansweeper-shutdown.log"
CREDS_FILE="/etc/nut/lansweeper.creds"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

if [ ! -f "$CREDS_FILE" ]; then
  log "ERROR creds file missing: $CREDS_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$CREDS_FILE"

if [ -z "${LANSWEEPER_IP:-}" ] || [ -z "${LANSWEEPER_DOMAIN:-}" ] || [ -z "${LANSWEEPER_USERNAME:-}" ] || [ -z "${LANSWEEPER_PASSWORD:-}" ]; then
  log "ERROR required Lansweeper RPC values missing in $CREDS_FILE"
  exit 1
fi

if [ "${LANSWEEPER_METHOD:-}" != "rpc" ]; then
  log "ERROR unsupported method '${LANSWEEPER_METHOD:-}' for this wrapper"
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
  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: LANSWEEPER_LIVE_APPROVED=${LANSWEEPER_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR live Lansweeper shutdown blocked: ALLOW_REAL_TEST is not 1"
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "phase1-lansweeper" ]; then
  log "ERROR live Lansweeper shutdown blocked: REAL_TEST_PHASE is not phase1-lansweeper"
  exit 2
fi

if [ "${LANSWEEPER_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR live Lansweeper shutdown blocked: LANSWEEPER_LIVE_APPROVED is not 1"
  exit 2
fi

log "APPROVED: executing Lansweeper RPC shutdown"
log "COMMAND PREVIEW: ${CMD_PREVIEW}"

if net rpc shutdown -S "${LANSWEEPER_IP}" -U "${RPC_USER}" -f -t 0; then
  log "SUCCESS Lansweeper shutdown command sent"
  exit 0
else
  rc=$?
  log "ERROR Lansweeper shutdown command failed rc=${rc}"
  exit "$rc"
fi
