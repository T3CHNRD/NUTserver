#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/var/lib/nut-apc-idf-monitor"
LOGGER="/usr/local/sbin/nut-power-event-log"
PUBLISHER="/usr/local/sbin/nut-publish-power-events-json"

mkdir -p "$STATE_DIR"

log_event() {
  local msg="$1"

  if [ -x "$LOGGER" ]; then
    "$LOGGER" "$msg"
  else
    echo "LOGGER_MISSING $msg" >&2
  fi
}

publish_events() {
  if [ -x "$PUBLISHER" ]; then
    "$PUBLISHER" >/dev/null 2>&1 || true
  fi
}

safe_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_' '_'
}

check_target() {
  local name="$1"
  local dns_url="$2"
  local ip_url="$3"

  local state_name
  state_name="$(safe_name "$name")"

  local body_file
  body_file="$(mktemp)"

  local selected_url=""
  local http_code=""
  local curl_rc=0
  local status=""

  # Try DNS URL first.
  http_code="$(curl -k -L --max-time 10 --connect-timeout 5 -sS -o "$body_file" -w '%{http_code}' "$dns_url" 2>/dev/null)" || curl_rc="$?"

  if [ "${curl_rc:-0}" -eq 0 ] && [ "$http_code" != "000" ]; then
    selected_url="$dns_url"
    status="reachable"
  else
    # Try IP URL fallback.
    curl_rc=0
    http_code="$(curl -k -L --max-time 10 --connect-timeout 5 -sS -o "$body_file" -w '%{http_code}' "$ip_url" 2>/dev/null)" || curl_rc="$?"

    if [ "${curl_rc:-0}" -eq 0 ] && [ "$http_code" != "000" ]; then
      selected_url="$ip_url"
      status="reachable"
    else
      selected_url="$ip_url"
      status="unreachable"
      http_code="000"
      : > "$body_file"
    fi
  fi

  local hash
  hash="$(sha256sum "$body_file" | awk '{print $1}')"

  local state_file="${STATE_DIR}/${state_name}.state"
  local previous=""
  local current="status=${status}|http_code=${http_code}|hash=${hash}|url=${selected_url}"

  if [ -f "$state_file" ]; then
    previous="$(cat "$state_file")"
  fi

  if [ "$current" != "$previous" ]; then
    if [ -z "$previous" ]; then
      log_event "APC_IDF_EVENT source=\"${name}\" status=\"${status}\" http_code=\"${http_code}\" url=\"${selected_url}\" change=\"initial_state\""
    else
      log_event "APC_IDF_EVENT source=\"${name}\" status=\"${status}\" http_code=\"${http_code}\" url=\"${selected_url}\" change=\"state_changed\" previous=\"${previous}\" current=\"${current}\""
    fi

    printf '%s\n' "$current" > "$state_file"
  fi

  rm -f "$body_file"
}

check_target "IDF2" "http://APC-IDF2.albl.com" "http://192.168.9.251"
check_target "IDF3" "http://apc-idf3.albl.com/" "http://192.168.9.252"

publish_events
