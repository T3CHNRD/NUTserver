#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u
set -o pipefail

UPS_NAME="${1:-}"
PULSE_COUNT="${2:-3}"
PULSE_ON_SECONDS="${3:-5}"
PULSE_OFF_SECONDS="${4:-1}"

case "$UPS_NAME" in
  ups2|ups3|ups6|ups7|ups8|ups9) ;;
  ups1|ups4|ups5)
    echo "===== SAFE UPS FIND / AUDIBLE BEEP ATTEMPT ====="
    echo "UPS: $UPS_NAME"
    echo
    echo "This UPS does not report safe beeper control commands through NUT."
    echo "No UPS control command was sent."
    exit 2
    ;;
  *)
    echo "ERROR: UPS must be one of: ups1 ups2 ups3 ups4 ups5 ups6 ups7 ups8 ups9"
    exit 2
    ;;
esac

case "$PULSE_COUNT" in ''|*[!0-9]*) PULSE_COUNT=3 ;; esac
case "$PULSE_ON_SECONDS" in ''|*[!0-9]*) PULSE_ON_SECONDS=5 ;; esac
case "$PULSE_OFF_SECONDS" in ''|*[!0-9]*) PULSE_OFF_SECONDS=1 ;; esac

if [ "$PULSE_COUNT" -lt 1 ]; then PULSE_COUNT=1; fi
if [ "$PULSE_COUNT" -gt 5 ]; then PULSE_COUNT=5; fi
if [ "$PULSE_ON_SECONDS" -lt 2 ]; then PULSE_ON_SECONDS=2; fi
if [ "$PULSE_ON_SECONDS" -gt 15 ]; then PULSE_ON_SECONDS=15; fi
if [ "$PULSE_OFF_SECONDS" -lt 1 ]; then PULSE_OFF_SECONDS=1; fi
if [ "$PULSE_OFF_SECONDS" -gt 5 ]; then PULSE_OFF_SECONDS=5; fi

TARGET="${UPS_NAME}@localhost"

echo "===== SAFE UPS FIND / AUDIBLE BEEP ATTEMPT ====="
echo "UPS: $UPS_NAME"
echo
echo "This action attempts an audible locator beep using only NUT beeper-enable commands."
echo "It will not intentionally disable or mute the UPS beeper unless restoring a previously disabled state."
echo "No load-control, shutdown, killpower, battery-test, panel-test, outlet, reboot, or poweroff command will be sent."
echo

echo "===== UPS IDENTITY / STATUS BEFORE ATTEMPT ====="
upsc "$TARGET" 2>/dev/null \
  | grep -E '^(device.location|device.mfr|device.model|device.serial|driver.name|ups.id|ups.mfr|ups.model|ups.serial|ups.status|ups.beeper.status):' \
  || true

echo
echo "===== SUPPORTED BEEPER COMMANDS ====="
COMMANDS="$(upscmd -l "$TARGET" 2>/dev/null || true)"
printf '%s\n' "$COMMANDS" | grep -Ei '^beeper\.' || true

ORIGINAL_STATUS="$(upsc "$TARGET" ups.beeper.status 2>/dev/null || true)"
echo
echo "Original beeper status: ${ORIGINAL_STATUS:-unknown}"

if printf '%s\n' "$COMMANDS" | grep -q '^beeper.enable '; then
  ON_CMD="beeper.enable"
elif printf '%s\n' "$COMMANDS" | grep -q '^beeper.on '; then
  ON_CMD="beeper.on"
else
  echo "ERROR: No supported safe beeper enable command found for $UPS_NAME."
  echo "No UPS beeper command was sent."
  exit 3
fi

run_upscmd() {
  local cmd="$1"

  if [ -r /etc/nut/upsd.users ]; then
    local pass
    pass="$(awk '
      /^\[[^]]+\]/ { section=$0; gsub(/[][]/,"",section) }
      section=="admin" && /^[[:space:]]*password[[:space:]]*=/ {
        sub(/^[[:space:]]*password[[:space:]]*=[[:space:]]*/,"")
        print
        exit
      }
    ' /etc/nut/upsd.users 2>/dev/null || true)"
    if [ -n "$pass" ]; then
      upscmd -u admin -p "$pass" "$TARGET" "$cmd"
      return $?
    fi
  fi

  upscmd "$TARGET" "$cmd"
}

echo
echo "===== AUDIBLE ENABLE ATTEMPT ====="
echo "Using command: $ON_CMD"
echo "Pulse count: $PULSE_COUNT"
echo "Hold seconds per pulse: $PULSE_ON_SECONDS"
echo
echo "NOTE: If the UPS firmware treats this only as an alarm-enable setting, it may return OK without making sound."

i=1
while [ "$i" -le "$PULSE_COUNT" ]; do
  echo
  echo "Pulse $i of $PULSE_COUNT: sending $ON_CMD"
  run_upscmd "$ON_CMD"
  rc_on=$?
  if [ "$rc_on" -ne 0 ]; then
    echo "ERROR: $ON_CMD failed with rc=$rc_on"
    exit "$rc_on"
  fi

  echo "Waiting ${PULSE_ON_SECONDS}s for audible response..."
  sleep "$PULSE_ON_SECONDS"

  echo "Current beeper status:"
  upsc "$TARGET" ups.beeper.status 2>/dev/null || true

  sleep "$PULSE_OFF_SECONDS"
  i=$((i + 1))
done

echo
echo "===== RESTORE ORIGINAL DISABLED STATE ONLY IF NEEDED ====="
if [ "$ORIGINAL_STATUS" = "disabled" ]; then
  if printf '%s\n' "$COMMANDS" | grep -q '^beeper.disable '; then
    echo "Original state was disabled; restoring disabled state."
    run_upscmd "beeper.disable" || true
  else
    echo "Original state was disabled, but no beeper.disable command is available."
  fi
else
  echo "Original state was not disabled; leaving beeper enabled."
fi

echo
echo "===== UPS STATUS AFTER ATTEMPT ====="
upsc "$TARGET" 2>/dev/null \
  | grep -E '^(ups.status|ups.beeper.status|device.location|ups.id|ups.model|ups.serial):' \
  || true

echo
echo "===== SAFE COMMAND POLICY ====="
echo "PASS: Only safe beeper enable commands were attempted, except optional restore-disable if original state was disabled."
echo "PASS: No load-control, shutdown, killpower, battery-test, panel-test, outlet, reboot, or poweroff command was sent."
echo
echo "===== COMPLETE ====="
echo "Find UPS audible enable attempt completed for $UPS_NAME."
