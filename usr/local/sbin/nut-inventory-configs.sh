#!/usr/bin/env bash
set -euo pipefail

REGISTRY="/opt/nut-orchestrator-ui/lib/config_registry.json"
OUT="/var/log/nut-orchestrator-ui/config-inventory-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "NUT CONFIG INVENTORY REPORT"
  echo "Generated: $(date -Is)"
  echo

  echo "== Approved editable configs =="
  jq -r '.editable_configs[] | "\(.name) | \(.path) | validator=\(.validator)"' "$REGISTRY"
  echo

  echo "== Blocked filename patterns =="
  jq -r '.blocked_patterns[]' "$REGISTRY"
  echo

  echo "== /etc/nut files =="
  find /etc/nut -maxdepth 2 -type f -printf '%M %u %g %p\n' | sort
  echo

  echo "== UI-managed source-of-truth assessment =="
  echo "/etc/nut/config.d/* = UI-managed source-of-truth where applicable"
  echo "/etc/nut/upsmon.conf = approved live file"
  echo "/etc/nut/upssched.conf = approved live file"
  echo "/etc/nut/nut.conf = approved live file"
  echo "/etc/nut/upsd.users = excluded from UI and Git-backed editing"
  echo

  echo "== Recommended secret exclusions =="
  echo "*.env"
  echo "*.key"
  echo "*.pem"
  echo "id_rsa"
  echo "id_ed25519"
  echo "upsd.users"
} | tee "$OUT"

echo
echo "Inventory written to: $OUT"
