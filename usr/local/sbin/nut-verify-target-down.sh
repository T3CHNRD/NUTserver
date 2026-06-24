#!/bin/bash
set -u

TARGET_NAME="${1:-}"
TARGET_IP="${2:-}"
TIMEOUT_SECONDS="${3:-}"
NETWORK_DEPENDENCY="${4:-}"

LOG_FILE="/var/log/nut-orchestrator.log"
POLL_SECONDS=5

usage() {
  echo "Usage: nut-verify-target-down.sh <target_name> <ip> <timeout_seconds> [network_dependency_ip]"
}

log_line() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFY_TARGET_DOWN $*" >> "$LOG_FILE"
}

if [ -z "$TARGET_NAME" ] || [ -z "$TARGET_IP" ] || [ -z "$TIMEOUT_SECONDS" ]; then
  usage
  exit 64
fi

case "$TIMEOUT_SECONDS" in
  ''|*[!0-9]*)
    usage
    exit 64
    ;;
esac

if [ -n "$NETWORK_DEPENDENCY" ]; then
  if ! ping -c 1 -W 2 "$NETWORK_DEPENDENCY" >/dev/null 2>&1; then
    log_line "target=\"$TARGET_NAME\" ip=\"$TARGET_IP\" result=UNKNOWN reason=\"network dependency unavailable\" dependency=\"$NETWORK_DEPENDENCY\""
    exit 2
  fi
fi

elapsed=0

while [ "$elapsed" -lt "$TIMEOUT_SECONDS" ]; do
  if ping -c 1 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
    log_line "target=\"$TARGET_NAME\" ip=\"$TARGET_IP\" status=online elapsed=${elapsed}s"
    sleep "$POLL_SECONDS"
    elapsed=$((elapsed + POLL_SECONDS))
  else
    log_line "target=\"$TARGET_NAME\" ip=\"$TARGET_IP\" result=PASS reason=\"target no longer responds to ping\" elapsed=${elapsed}s"
    exit 0
  fi
done

if [ -n "$NETWORK_DEPENDENCY" ]; then
  if ! ping -c 1 -W 2 "$NETWORK_DEPENDENCY" >/dev/null 2>&1; then
    log_line "target=\"$TARGET_NAME\" ip=\"$TARGET_IP\" result=UNKNOWN reason=\"network dependency lost during verification\" dependency=\"$NETWORK_DEPENDENCY\""
    exit 2
  fi
fi

log_line "target=\"$TARGET_NAME\" ip=\"$TARGET_IP\" result=FAIL reason=\"target still online after timeout\" timeout=${TIMEOUT_SECONDS}s"
exit 1
