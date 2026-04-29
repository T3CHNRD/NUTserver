#!/bin/bash
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
  exit 0
fi

log "MODE: REAL / LIVE"
log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
log "SAFETY CHECK: NETAPP_LIVE_APPROVED=${NETAPP_LIVE_APPROVED:-0}"

if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
  log "ERROR NetApp live halt blocked: ALLOW_REAL_TEST is not 1"
  exit 2
fi

if [ "${REAL_TEST_PHASE:-}" != "full-production" ] && [ "${REAL_TEST_PHASE:-}" != "phase-netapp" ]; then
  log "ERROR NetApp live halt blocked: REAL_TEST_PHASE is not approved for NetApp"
  exit 2
fi

if [ "${NETAPP_LIVE_APPROVED:-0}" != "1" ]; then
  log "ERROR NetApp live halt blocked: NETAPP_LIVE_APPROVED is not 1"
  exit 2
fi

log "APPROVED: executing NetApp halt command"
ssh -o BatchMode=yes -o ConnectTimeout=10 "${NETAPP_USERNAME}@${HOST}" "system node halt -node ${ARRAY_NAME} -reason 'UPS power event'" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR NetApp halt command failed for $TARGET rc=$RC"
  exit "$RC"
fi

log "SUCCESS NetApp halt command sent to $TARGET"
exit 0
