#!/bin/bash
set -euo pipefail

LOG_JSON="/var/www/html/nut-outage-log.json"
TMP_FILE="$(mktemp)"

BOOT_TIME="$(uptime -s 2>/dev/null || true)"
PREV_LAST_LOG="$(journalctl -b -1 -n 1 --no-pager -o short-iso 2>/dev/null | sed 's/\\/\\\\/g; s/"/\\"/g' || true)"
PREV_CLEAN="unknown"

if journalctl -b -1 --no-pager 2>/dev/null | grep -qiE 'Reached target (System )?Shutdown|Finished Power-Off|systemd-shutdown'; then
    PREV_CLEAN="yes"
elif journalctl -b -1 -n 1 --no-pager >/dev/null 2>&1; then
    PREV_CLEAN="no"
fi

python3 - "$LOG_JSON" "$TMP_FILE" "$BOOT_TIME" "$PREV_LAST_LOG" "$PREV_CLEAN" <<'PY'
import json
import os
import sys
from datetime import datetime

log_json = sys.argv[1]
tmp_file = sys.argv[2]
boot_time = sys.argv[3]
prev_last_log = sys.argv[4]
prev_clean = sys.argv[5]

event = {
    "logged_at": datetime.now().astimezone().isoformat(timespec="seconds"),
    "boot_time": boot_time,
    "previous_shutdown_clean": prev_clean,
    "previous_boot_last_log": prev_last_log
}

try:
    with open(log_json, "r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        data = []
except Exception:
    data = []

data.insert(0, event)
data = data[:50]

with open(tmp_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

install -o root -g www-data -m 0644 "$TMP_FILE" "$LOG_JSON"
rm -f "$TMP_FILE"
