#!/usr/bin/env bash
set -euo pipefail

UPS_NAME="${1:-}"
PULSE_COUNT="${2:-3}"
PULSE_ON_SECONDS="${3:-1}"
PULSE_OFF_SECONDS="${4:-1}"

case "$UPS_NAME" in
  ups2|ups3|ups6|ups7|ups8|ups9)
    ;;
  ups1|ups4|ups5)
    echo "FAIL: $UPS_NAME does not expose safe beeper commands in NUT."
    echo "No command was sent."
    exit 1
    ;;
  *)
    echo "FAIL: UPS name must be one of: ups2 ups3 ups6 ups7 ups8 ups9"
    echo "No command was sent."
    exit 2
    ;;
esac

if ! [[ "$PULSE_COUNT" =~ ^[0-9]+$ ]] || (( PULSE_COUNT < 1 || PULSE_COUNT > 5 )); then
  echo "FAIL: pulse count must be 1 through 5."
  exit 2
fi

if ! [[ "$PULSE_ON_SECONDS" =~ ^[0-9]+$ ]] || (( PULSE_ON_SECONDS < 1 || PULSE_ON_SECONDS > 3 )); then
  echo "FAIL: pulse on seconds must be 1 through 3."
  exit 2
fi

if ! [[ "$PULSE_OFF_SECONDS" =~ ^[0-9]+$ ]] || (( PULSE_OFF_SECONDS < 1 || PULSE_OFF_SECONDS > 3 )); then
  echo "FAIL: pulse off seconds must be 1 through 3."
  exit 2
fi

echo "===== SAFE UPS FIND / LOCATOR BEEP ====="
echo "UPS: $UPS_NAME"
echo "Pulses: $PULSE_COUNT"
echo "Pulse on seconds: $PULSE_ON_SECONDS"
echo "Pulse off seconds: $PULSE_OFF_SECONDS"
echo

echo "===== CURRENT UPS STATUS ====="
upsc "${UPS_NAME}@localhost" 2>&1 \
  | grep -Ei 'device.mfr|device.model|device.serial|ups.serial|ups.id|ups.status|battery.charge|ups.load|input.voltage|output.voltage|beeper' \
  || true
echo

echo "===== SAFETY CHECK: REQUIRED BEEPER COMMANDS ONLY ====="
COMMAND_LIST="$(upscmd -l "${UPS_NAME}@localhost" 2>&1 || true)"

if ! echo "$COMMAND_LIST" | grep -q '^beeper.enable '; then
  echo "FAIL: $UPS_NAME does not expose beeper.enable."
  echo "No command was sent."
  exit 1
fi

if ! echo "$COMMAND_LIST" | grep -q '^beeper.disable '; then
  echo "FAIL: $UPS_NAME does not expose beeper.disable."
  echo "No command was sent."
  exit 1
fi

echo "PASS: $UPS_NAME exposes beeper.enable and beeper.disable."
echo

INITIAL_BEEPER_STATUS="$(upsc "${UPS_NAME}@localhost" 2>/dev/null | awk -F': ' 'tolower($1) ~ /beeper/ {print $2; exit}' || true)"
echo "Initial beeper status: ${INITIAL_BEEPER_STATUS:-unknown}"

restore_beeper_state() {
  case "${INITIAL_BEEPER_STATUS,,}" in
    enabled|on)
      echo "Restoring beeper to enabled..."
      upscmd "${UPS_NAME}@localhost" beeper.enable >/dev/null 2>&1 || true
      ;;
    disabled|off)
      echo "Restoring beeper to disabled..."
      upscmd "${UPS_NAME}@localhost" beeper.disable >/dev/null 2>&1 || true
      ;;
    *)
      echo "Initial beeper state unknown. Leaving beeper disabled as final safe quiet state."
      upscmd "${UPS_NAME}@localhost" beeper.disable >/dev/null 2>&1 || true
      ;;
  esac
}

trap restore_beeper_state EXIT

echo "===== START 3-PULSE FIND ATTEMPT ====="
echo "Only beeper.enable and beeper.disable will be sent."

for i in $(seq 1 "$PULSE_COUNT")
do
  echo "Pulse $i of $PULSE_COUNT: beeper.enable"
  upscmd "${UPS_NAME}@localhost" beeper.enable
  sleep "$PULSE_ON_SECONDS"

  echo "Pulse $i of $PULSE_COUNT: beeper.disable"
  upscmd "${UPS_NAME}@localhost" beeper.disable
  sleep "$PULSE_OFF_SECONDS"
done

echo
echo "===== COMPLETE ====="
echo "Find attempt completed for $UPS_NAME."
