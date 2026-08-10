#!/bin/bash
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

CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 ${USER_NAME}@${HOST} \"sudo /usr/bin/systemctl poweroff\""

log "Starting VOIP shutdown for $HOST"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no VOIP shutdown command sent"
  exit 0
fi

ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER_NAME}@${HOST}" "sudo /usr/bin/systemctl poweroff" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR VOIP shutdown command failed rc=$RC"
  exit "$RC"
fi

log "SUCCESS VOIP shutdown command sent"
exit 0
