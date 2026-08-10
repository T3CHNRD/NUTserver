#!/bin/bash
set -u

LOG_FILE="/var/log/nut-synology-shutdown.log"
HOST="192.168.1.250"
USER_NAME="Admin"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 ${USER_NAME}@${HOST} \"sudo shutdown -P now\""

log "Starting Synology shutdown for $HOST"
log "SIMULATE=$SIMULATE"
log "SIMULATION PREVIEW: would run ${CMD_PREVIEW}"

if [ "$SIMULATE" = "1" ]; then
  log "SIMULATION ONLY: no Synology shutdown command sent"
  exit 0
fi

ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER_NAME}@${HOST}" "sudo shutdown -P now" >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "ERROR Synology shutdown command failed rc=$RC"
  exit "$RC"
fi

log "SUCCESS Synology shutdown command sent"
exit 0
