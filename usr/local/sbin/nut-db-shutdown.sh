#!/bin/bash
set -u

TARGET="${1:-}"
LOG_FILE="/var/log/nut-db-shutdown.log"
SIMULATE="${SIMULATE:-1}"
ALLOW_REAL_TEST="${ALLOW_REAL_TEST:-0}"
REAL_TEST_PHASE="${REAL_TEST_PHASE:-}"
DB_LIVE_APPROVED="${DB_LIVE_APPROVED:-0}"
PRODUCTION_ENV="/etc/nut/production-mode.conf"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

get_live_actions_allowed() {
  if [ -f "$PRODUCTION_ENV" ]; then
    # shellcheck disable=SC1090
    . "$PRODUCTION_ENV"
  fi

  echo "${NUT_ALLOW_LIVE_ACTIONS:-0}"
}

if [ -z "$TARGET" ]; then
  log "ERROR no target provided"
  exit 1
fi

case "$TARGET" in
  DB01)
    HOST="REPLACE_WITH_DB01_IP"
    ;;
  DB02)
    HOST="REPLACE_WITH_DB02_IP"
    ;;
  *)
    log "ERROR unknown target '$TARGET'"
    exit 1
    ;;
esac

CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 root@${HOST} \"/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'\""

log "Starting Solaris shutdown for $TARGET at $HOST"
log "SIMULATE=$SIMULATE"
log "ALLOW_REAL_TEST=$ALLOW_REAL_TEST"
log "REAL_TEST_PHASE=$REAL_TEST_PHASE"
log "DB_LIVE_APPROVED=$DB_LIVE_APPROVED"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" != "0" ]; then
  log "SIMULATION ONLY: no DB shutdown command sent for $TARGET"
  exit 0
fi

if [ "$ALLOW_REAL_TEST" != "1" ]; then
  log "BLOCKED: ALLOW_REAL_TEST is not 1"
  exit 20
fi

if [ "$REAL_TEST_PHASE" != "phase3-full" ] && [ "$REAL_TEST_PHASE" != "ups-event" ]; then
  log "BLOCKED: REAL_TEST_PHASE must be phase3-full or ups-event"
  exit 21
fi

if [ "$DB_LIVE_APPROVED" != "1" ]; then
  log "BLOCKED: DB_LIVE_APPROVED is not 1"
  exit 22
fi

LIVE_ALLOWED="$(get_live_actions_allowed)"
log "NUT_ALLOW_LIVE_ACTIONS=$LIVE_ALLOWED"

if [ "$LIVE_ALLOWED" != "1" ]; then
  log "BLOCKED: production mode does not allow live actions"
  exit 23
fi

log "LIVE APPROVED: sending DB shutdown command for $TARGET"
ssh -o BatchMode=yes -o ConnectTimeout=10 root@"$HOST" "/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR shutdown command failed for $TARGET rc=$RC"
  exit "$RC"
fi

log "SUCCESS shutdown command sent to $TARGET"
exit 0
