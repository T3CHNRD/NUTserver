#!/bin/bash
set -u

TARGET="${1:-}"
LOG_FILE="/var/log/nut-db-shutdown.log"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

if [ -z "$TARGET" ]; then
  log "ERROR no target provided"
  exit 1
fi

case "$TARGET" in
  DB01)
    HOST="192.168.1.9"
    ;;
  DB02)
    HOST="192.168.1.11"
    ;;
  *)
    log "ERROR unknown target '$TARGET'"
    exit 1
    ;;
esac

CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 root@${HOST} \"/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'\""

log "Starting Solaris shutdown for $TARGET at $HOST"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no DB shutdown command sent for $TARGET"
  exit 0
fi

ssh -o BatchMode=yes -o ConnectTimeout=10 root@"$HOST" "/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR shutdown command failed for $TARGET rc=$RC"
  exit "$RC"
fi

log "SUCCESS shutdown command sent to $TARGET"
exit 0
