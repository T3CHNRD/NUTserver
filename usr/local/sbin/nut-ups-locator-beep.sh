#!/usr/bin/env bash
set -euo pipefail

UPS_NAME="${1:-}"
PULSE_COUNT="${2:-3}"
PULSE_ON_SECONDS="${3:-1}"
PULSE_OFF_SECONDS="${4:-1}"

NUT_CMD_USER="admin"
NUT_UPSD_USERS="/etc/nut/upsd.users"

read_nut_command_password() {
  awk '
    BEGIN { in_admin = 0 }
    /^\[admin\][[:space:]]*$/ { in_admin = 1; next }
    /^\[/ { in_admin = 0 }
    in_admin && $1 == "password" {
      for (i = 3; i <= NF; i++) {
        if (i > 3) printf " ";
        printf "%s", $i;
      }
      printf "\n";
      exit
    }
  ' "$NUT_UPSD_USERS"
}

NUT_CMD_PASS="$(read_nut_command_password)"

run_upscmd_auth() {
  local target="$1"
  local command="$2"

  if [[ -z "$NUT_CMD_PASS" ]]; then
    echo "FAIL: NUT command password for admin was not found in $NUT_UPSD_USERS."
    return 1
  fi

  # Use -u for the NUT command user and feed only the password through stdin.
  # Do not use -p here because that can briefly expose the password in the process list.
  printf '%s\n' "$NUT_CMD_PASS" | upscmd -u "$NUT_CMD_USER" "$target" "$command"
}

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

LOCATOR_ON_CMD=""
LOCATOR_OFF_CMD=""

# APC USB units may expose beeper.on/off aliases.
# Tripp Lite SNMP units generally expose beeper.enable/disable only.
# Both paths are beeper-only and do not use any UPS output, power-control, or hardware-test commands.
if echo "$COMMAND_LIST" | grep -q '^beeper.on ' && echo "$COMMAND_LIST" | grep -q '^beeper.off '; then
  LOCATOR_ON_CMD="beeper.on"
  LOCATOR_OFF_CMD="beeper.off"
elif echo "$COMMAND_LIST" | grep -q '^beeper.enable ' && echo "$COMMAND_LIST" | grep -q '^beeper.disable '; then
  LOCATOR_ON_CMD="beeper.enable"
  LOCATOR_OFF_CMD="beeper.disable"
else
  echo "FAIL: $UPS_NAME does not expose a supported beeper-only command pair."
  echo "No command was sent."
  exit 1
fi

RESTORE_ENABLE_CMD="beeper.enable"
RESTORE_DISABLE_CMD="beeper.disable"

if ! echo "$COMMAND_LIST" | grep -q '^beeper.enable '; then
  RESTORE_ENABLE_CMD="$LOCATOR_ON_CMD"
fi

if ! echo "$COMMAND_LIST" | grep -q '^beeper.disable '; then
  RESTORE_DISABLE_CMD="$LOCATOR_OFF_CMD"
fi

echo "PASS: $UPS_NAME exposes supported beeper-only locator commands."
echo "Selected locator command pair: $LOCATOR_ON_CMD / $LOCATOR_OFF_CMD"
echo

INITIAL_BEEPER_STATUS="$(upsc "${UPS_NAME}@localhost" 2>/dev/null | awk -F': ' 'tolower($1) ~ /beeper/ {print $2; exit}' || true)"
echo "Initial beeper status: ${INITIAL_BEEPER_STATUS:-unknown}"

restore_beeper_state() {
  case "${INITIAL_BEEPER_STATUS,,}" in
    enabled|on)
      echo "Restoring beeper to enabled..."
      run_upscmd_auth "${UPS_NAME}@localhost" "$RESTORE_ENABLE_CMD" >/dev/null 2>&1 || true
      ;;
    disabled|off)
      echo "Restoring beeper to disabled..."
      run_upscmd_auth "${UPS_NAME}@localhost" "$RESTORE_DISABLE_CMD" >/dev/null 2>&1 || true
      ;;
    *)
      echo "Initial beeper state unknown. Leaving beeper disabled as final safe quiet state."
      run_upscmd_auth "${UPS_NAME}@localhost" "$RESTORE_DISABLE_CMD" >/dev/null 2>&1 || true
      ;;
  esac
}

trap restore_beeper_state EXIT

echo "===== START 3-PULSE FIND ATTEMPT ====="
echo "Only $LOCATOR_ON_CMD and $LOCATOR_OFF_CMD will be sent."

for i in $(seq 1 "$PULSE_COUNT")
do
  echo "Pulse $i of $PULSE_COUNT: $LOCATOR_ON_CMD"
  run_upscmd_auth "${UPS_NAME}@localhost" "$LOCATOR_ON_CMD"
  sleep "$PULSE_ON_SECONDS"

  echo "Pulse $i of $PULSE_COUNT: $LOCATOR_OFF_CMD"
  run_upscmd_auth "${UPS_NAME}@localhost" "$LOCATOR_OFF_CMD"
  sleep "$PULSE_OFF_SECONDS"
done

echo
echo "===== COMPLETE ====="
echo "Find attempt completed for $UPS_NAME."
