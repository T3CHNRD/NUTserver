#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/var/lib/nut-apc-idf-monitor"
LOG="/var/log/nut-orchestrator-ui/power-events.log"
PUBLISHER="/usr/local/sbin/nut-publish-power-events-json"

mkdir -p "$STATE_DIR"
mkdir -p "$(dirname "$LOG")"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

log_event() {
  printf '[%s] %s\n' "$(timestamp)" "$*" >> "$LOG"
}

publish_events() {
  if [ -x "$PUBLISHER" ]; then
    "$PUBLISHER" >/dev/null 2>&1 || true
  fi
}

safe_name() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_'
}

strip_html_to_lines() {
  # Converts simple APC HTML/text into readable lines.
  # This is intentionally conservative and read-only.
  sed -E '
    s/<[Bb][Rr][[:space:]]*\/?>/\n/g;
    s/<\/[Tt][Rr]>/\n/g;
    s/<\/[Dd][Ii][Vv]>/\n/g;
    s/<\/[Tt][Dd]>/ /g;
    s/<[^>]*>/ /g;
    s/&nbsp;/ /g;
    s/&amp;/\&/g;
    s/&lt;/</g;
    s/&gt;/>/g;
    s/[[:space:]]+/ /g;
    s/^ //;
    s/ $//;
  ' | sed '/^$/d'
}

is_noise_line() {
  local line_lc="$1"

  case "$line_lc" in
    *"ntp update successful"*|\
    *"cli user"*|\
    *"web user"*|\
    *"logged in"*|\
    *"logged out"*|\
    *"unauthorized user attempting to access the snmp interface"*|\
    *"login"*|\
    *"password"*|\
    *"user name"*|\
    *"username"*|\
    *"maximum connections"*|\
    *"maximum number of web connections"*|\
    *"session"*|\
    *"hashform"*|\
    *"log on"*|\
    *"reset"*)
      return 0
      ;;
  esac

  return 1
}

classify_target_line() {
  local line="$1"
  local line_lc
  line_lc="$(printf '%s\n' "$line" | tr '[:upper:]' '[:lower:]')"

  if is_noise_line "$line_lc"; then
    return 1
  fi

  case "$line_lc" in
    *"on battery"*|\
    *"on-battery"*|\
    *"ups on battery"*|\
    *"operating on battery"*|\
    *"input power failed"*|\
    *"utility power failure"*|\
    *"utility power lost"*|\
    *"power failure"*|\
    *"transfer to battery"*)
      printf 'POWER_SOURCE_ON_BATTERY|%s\n' "$line"
      return 0
      ;;

    *"no longer on battery"*|\
    *"not on battery"*|\
    *"returned from battery"*|\
    *"utility power restored"*|\
    *"input power restored"*|\
    *"power restored"*|\
    *"transfer from battery"*|\
    *"online operation"*|\
    *"on line"*|\
    *"online"*)
      printf 'POWER_SOURCE_ONLINE|%s\n' "$line"
      return 0
      ;;

    *"self-test started"*|\
    *"self test started"*|\
    *"self-test running"*|\
    *"self test running"*|\
    *"self-test in progress"*|\
    *"self test in progress"*)
      printf 'SELF_TEST_RUNNING|%s\n' "$line"
      return 0
      ;;

    *"self-test passed"*|\
    *"self test passed"*|\
    *"self-test completed"*|\
    *"self test completed"*|\
    *"self-test ok"*|\
    *"self test ok"*)
      printf 'SELF_TEST_PASSED|%s\n' "$line"
      return 0
      ;;

    *"self-test failed"*|\
    *"self test failed"*|\
    *"self-test fault"*|\
    *"self test fault"*)
      printf 'SELF_TEST_FAILED|%s\n' "$line"
      return 0
      ;;
  esac

  return 1
}

fetch_target_text() {
  local body_file="$1"
  shift

  : > "$body_file"

  local url
  for url in "$@"; do
    # Read-only GET. Follows APC redirects. Does not submit credentials or forms.
    if curl -k -L -sS --max-time 12 "$url" >> "$body_file" 2>/dev/null; then
      printf '\n' >> "$body_file"
    fi
  done
}

monitor_target() {
  local name="$1"
  shift

  local state_name
  state_name="$(safe_name "$name")"

  local body_file
  body_file="$(mktemp "/tmp/${state_name}.apc-idf.XXXXXX")"

  fetch_target_text "$body_file" "$@"

  local detected_file
  detected_file="$(mktemp "/tmp/${state_name}.apc-idf-detected.XXXXXX")"

  strip_html_to_lines < "$body_file" | while IFS= read -r line; do
    classified="$(classify_target_line "$line" || true)"
    if [ -n "${classified:-}" ]; then
      printf '%s\n' "$classified"
    fi
  done | sort -u > "$detected_file"

  local state_file="${STATE_DIR}/${state_name}.target-events.state"

  # Baseline behavior:
  # First run records what is already visible but does not publish old/stale APC event-log rows.
  if [ ! -f "$state_file" ]; then
    cp "$detected_file" "$state_file"
    rm -f "$body_file" "$detected_file"
    exit_code=0
    return "$exit_code"
  fi

  local new_file
  new_file="$(mktemp "/tmp/${state_name}.apc-idf-new.XXXXXX")"

  comm -13 "$state_file" "$detected_file" > "$new_file" || true

  if [ -s "$new_file" ]; then
    while IFS='|' read -r event_type message; do
      [ -n "${event_type:-}" ] || continue
      [ -n "${message:-}" ] || message="APC target event detected"

      log_event "APC_IDF_TARGET_EVENT source=\"${name}\" event_type=\"${event_type}\" message=\"${message}\""
    done < "$new_file"

    cp "$detected_file" "$state_file"
  fi

  rm -f "$body_file" "$detected_file" "$new_file"
}

# Read-only target checks.
# Do not hard-code APC /NMC/<session-token>/ URLs here.
# These root URLs are intentionally stable; the monitor no longer logs page hashes.
monitor_target "IDF2" \
  "http://APC-IDF2.albl.com" \
  "http://192.168.9.251"

monitor_target "IDF3" \
  "http://apc-idf3.albl.com/" \
  "http://192.168.9.252"

publish_events
