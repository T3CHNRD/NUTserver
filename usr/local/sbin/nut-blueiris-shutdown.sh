#!/bin/bash
set -u

LOG_FILE="/var/log/nut-blueiris-shutdown.log"
TARGET_IP="192.168.1.25"
CREDS="/etc/nut/blueiris.creds"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

CMD_PREVIEW="/usr/bin/net rpc shutdown -S ${TARGET_IP} -A ${CREDS} -f -t 0 -C \"UPS shutdown\""

log "Starting Blue Iris shutdown for $TARGET_IP"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no Blue Iris shutdown command sent"
  exit 0
fi

if [ ! -f "$CREDS" ]; then
  log "ERROR credentials file not found: $CREDS"
  exit 1
fi

/usr/bin/net rpc shutdown -S "$TARGET_IP" -A "$CREDS" -f -t 0 -C "UPS shutdown" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR Blue Iris shutdown command failed rc=$RC"
  exit "$RC"
fi

log "SUCCESS Blue Iris shutdown command sent"
exit 0
