#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -euo pipefail

UPS_NAME="${1:-}"

case "$UPS_NAME" in
  ups1|ups2|ups3|ups4|ups5|ups6|ups7|ups8|ups9)
    ;;
  *)
    echo "FAIL: UPS name must be one of: ups1 ups2 ups3 ups4 ups5 ups6 ups7 ups8 ups9"
    echo "No UPS command was sent."
    exit 2
    ;;
esac

echo "===== SAFE UPS IDENTIFY / FIND UPS ====="
echo "UPS: $UPS_NAME"
echo
echo "No UPS control command will be sent."
echo "This action is read-only and does not beep, test, shut down, or change UPS output."
echo

if ! upsc "${UPS_NAME}@localhost" >/dev/null 2>&1; then
  echo "FAIL: $UPS_NAME is not reachable through NUT."
  exit 1
fi

echo "===== UPS IDENTITY / STATUS ====="
upsc "${UPS_NAME}@localhost" 2>&1 \
  | grep -Ei '^(device\.mfr|device\.model|device\.serial|device\.location|driver\.name|ups\.mfr|ups\.model|ups\.serial|ups\.id|ups\.status|ups\.beeper\.status|battery\.charge|battery\.runtime|ups\.load|input\.voltage|output\.voltage):' \
  || true

echo
echo "===== BEEPER / LOCATOR CAPABILITY ====="
COMMAND_LIST="$(upscmd -l "${UPS_NAME}@localhost" 2>&1 || true)"

if echo "$COMMAND_LIST" | grep -Eq '^beeper\.(enable|disable|mute|on|off)[[:space:]]'; then
  echo "NUT reports beeper control commands for $UPS_NAME."
  echo "However, prior live checks found that these commands did not produce an audible locator beep."
  echo "Treat this UPS as status-identify only unless vendor tools prove otherwise."
else
  echo "NUT does not report safe beeper control commands for $UPS_NAME."
  echo "This UPS cannot be audibly located through the current NUT command set."
fi

echo
echo "===== SAFE COMMAND POLICY ====="
echo "PASS: No beeper, battery-test, shutdown, load-control, killpower, or FSD command was sent."

echo
echo "===== COMPLETE ====="
echo "Identify action completed for $UPS_NAME."
