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
    validate_nut_email_alerts_conf) validate_nut_email_alerts_conf "$file" ;;
    *)
      echo "Unknown validator: $validator" >&2
      return 1
      ;;
  esac
}

validate_nut_email_alerts_conf() {
  local file="$1"

  grep -qE '^NUT_EMAIL_ENABLED="' "$file" || { echo "Missing NUT_EMAIL_ENABLED"; return 1; }
  grep -qE '^SMTP_SERVER="' "$file" || { echo "Missing SMTP_SERVER"; return 1; }
  grep -qE '^SERVER_PORT="' "$file" || { echo "Missing SERVER_PORT"; return 1; }
  grep -qE '^AUTHENTICATION_REQUIRED="' "$file" || { echo "Missing AUTHENTICATION_REQUIRED"; return 1; }
  grep -qE '^USER_NAME="' "$file" || { echo "Missing USER_NAME"; return 1; }
  grep -qE '^SMTP_PASSWORD="' "$file" || { echo "Missing SMTP_PASSWORD"; return 1; }
  grep -qE '^SSL_STATE="' "$file" || { echo "Missing SSL_STATE"; return 1; }
  grep -qE '^EMAIL_RECIPIENTS="' "$file" || { echo "Missing EMAIL_RECIPIENTS"; return 1; }
  grep -qE '^EMAIL_FROM="' "$file" || { echo "Missing EMAIL_FROM"; return 1; }
  grep -qE '^EMAIL_SUBJECT_PREFIX="' "$file" || { echo "Missing EMAIL_SUBJECT_PREFIX"; return 1; }

  local port
  port="$(grep -E '^SERVER_PORT="' "$file" | head -n 1 | sed -E 's/^SERVER_PORT="([^"]*)".*/\1/')"
  [[ "$port" =~ ^[0-9]+$ ]] || { echo "SERVER_PORT must be numeric"; return 1; }

  local auth
  auth="$(grep -E '^AUTHENTICATION_REQUIRED="' "$file" | head -n 1 | sed -E 's/^AUTHENTICATION_REQUIRED="([^"]*)".*/\1/')"
  case "$auth" in
    Yes|No|yes|no|1|0|true|false|on|off) ;;
    *) echo "AUTHENTICATION_REQUIRED must be Yes or No"; return 1 ;;
  esac

  local ssl
  ssl="$(grep -E '^SSL_STATE="' "$file" | head -n 1 | sed -E 's/^SSL_STATE="([^"]*)".*/\1/')"
  case "$ssl" in
    STARTTLS|TLS|SSL|Disable|Disabled|Off|ON|On|off|on) ;;
    *) echo "SSL_STATE must be STARTTLS, TLS, SSL, or Disable"; return 1 ;;
  esac

  local recipients
  recipients="$(grep -E '^EMAIL_RECIPIENTS="' "$file" | head -n 1 | sed -E 's/^EMAIL_RECIPIENTS="([^"]*)".*/\1/')"
  [ -n "$recipients" ] || { echo "EMAIL_RECIPIENTS cannot be blank"; return 1; }

  echo "Email alert config validation passed"
}

