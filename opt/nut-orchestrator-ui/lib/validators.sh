#!/usr/bin/env bash
set -euo pipefail

validate_json() {
  local file="$1"
  jq empty "$file"
}

validate_yaml() {
  local file="$1"
  python3 - <<'PY' "$file"
import sys
import yaml

p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    yaml.safe_load(f)

print("YAML OK")
PY
}

validate_text_generic() {
  local file="$1"
  test -s "$file"
}

validate_upsmon_conf() {
  local file="$1"
  test -s "$file"
  grep -Eq '^[[:space:]]*MONITOR[[:space:]]+' "$file"
}

validate_upssched_conf() {
  local file="$1"
  test -s "$file"
  grep -Eq '^[[:space:]]*(CMDSCRIPT|PIPEFN|LOCKFN)[[:space:]]+' "$file"
}

validate_nut_conf() {
  local file="$1"
  test -s "$file"
  grep -Eq '^[[:space:]]*MODE[[:space:]]*=' "$file"
}

run_validator() {
  local validator="$1"
  local file="$2"

  case "$validator" in
    validate_json) validate_json "$file" ;;
    validate_yaml) validate_yaml "$file" ;;
    validate_text_generic) validate_text_generic "$file" ;;
    validate_upsmon_conf) validate_upsmon_conf "$file" ;;
    validate_upssched_conf) validate_upssched_conf "$file" ;;
    validate_nut_conf) validate_nut_conf "$file" ;;
    *)
      echo "Unknown validator: $validator" >&2
      return 1
      ;;
  esac
}
