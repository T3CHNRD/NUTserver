#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -Eeuo pipefail

STATE_DIR="/var/lib/nut-apc-idf-monitor"
LOG="/var/log/nut-orchestrator-ui/power-events.log"
PUBLISHER="/usr/local/sbin/nut-publish-power-events-json"
CRED_FILE="/etc/nut/apc-idf-web.conf"
LOCK_FILE="/run/nut-apc-idf-event-monitor.lock"

FAIL_WARN_AT=3
FAIL_REPEAT_EVERY=6

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_event() {
  local msg="$1"
  mkdir -p "$STATE_DIR"
  touch "$LOG"
  printf '[%s] %s\n' "$(timestamp)" "$msg" >> "$LOG"
}

publish_events() {
  if [ -x "$PUBLISHER" ]; then
    "$PUBLISHER" >/dev/null 2>&1 || true
  fi
}

safe_name() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//'
}

sanitize_log_field() {
  printf '%s' "$1" | tr -d '\r\n' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

init_paths() {
  mkdir -p "$STATE_DIR"
  chmod 0755 "$STATE_DIR" 2>/dev/null || true
  touch "$LOG"
}

load_credentials() {
  if [ ! -r "$CRED_FILE" ]; then
    log_event "APC_IDF_STATUS source=\"monitor\" status=\"credential_file_missing\" path=\"$CRED_FILE\""
    return 1
  fi

  # shellcheck disable=SC1090
  . "$CRED_FILE"

  if [ -z "${APC_IDF_USERNAME:-}" ] || [ -z "${APC_IDF_PASSWORD:-}" ]; then
    log_event "APC_IDF_STATUS source=\"monitor\" status=\"credential_file_incomplete\" path=\"$CRED_FILE\""
    return 1
  fi

  return 0
}

read_count() {
  local file="$1"
  if [ -s "$file" ]; then
    tr -dc '0-9' < "$file"
  else
    printf '0'
  fi
}

write_count() {
  local file="$1"
  local value="$2"
  printf '%s\n' "$value" > "$file"
  chmod 0644 "$file" 2>/dev/null || true
}

record_failure() {
  local name="$1"
  local ip="$2"
  local dns="$3"
  local reason="$4"
  local fail_file="$5"

  local count
  count="$(read_count "$fail_file")"
  count=$((count + 1))
  write_count "$fail_file" "$count"

  if [ "$count" -eq "$FAIL_WARN_AT" ] || { [ "$count" -gt "$FAIL_WARN_AT" ] && [ $((count % FAIL_REPEAT_EVERY)) -eq 0 ]; }; then
    log_event "APC_IDF_STATUS source=\"$name\" status=\"event_txt_unavailable\" consecutive_failures=\"$count\" reason=\"$reason\" ip=\"$ip\" dns=\"$dns\""
    publish_events
  fi
}

record_success() {
  local name="$1"
  local ip="$2"
  local dns="$3"
  local fail_file="$4"
  local matching_events="$5"
  local status="$6"

  local previous_count
  previous_count="$(read_count "$fail_file")"

  if [ "$previous_count" -gt 0 ]; then
    log_event "APC_IDF_STATUS source=\"$name\" status=\"event_txt_recovered\" previous_consecutive_failures=\"$previous_count\" matching_events=\"$matching_events\" ip=\"$ip\" dns=\"$dns\""
    publish_events
  elif [ "$status" = "baseline_created" ]; then
    log_event "APC_IDF_STATUS source=\"$name\" status=\"baseline_created\" event_source=\"authenticated_event_txt_v2\" matching_events=\"$matching_events\" ip=\"$ip\" dns=\"$dns\""
    publish_events
  fi

  write_count "$fail_file" 0
}

try_logout() {
  local base_url="$1"
  local cookie="$2"

  [ -n "$base_url" ] || return 0

  curl -k -sS --max-time 8 -b "$cookie" "${base_url%/}/logout.htm" -o /dev/null >/dev/null 2>&1 || true
  curl -k -sS --max-time 8 -b "$cookie" "${base_url%/}/logoff.htm" -o /dev/null >/dev/null 2>&1 || true
  curl -k -sS --max-time 8 -b "$cookie" "${base_url%/}/Forms/logout1" -o /dev/null >/dev/null 2>&1 || true

  return 0
}

fetch_apc_event_txt() {
  local name="$1"
  local primary_url="$2"
  local fallback_url="$3"
  local tmp_dir="$4"
  local event_txt="$5"

  local url login_html login_headers cookie post_headers post_body event_headers
  local login_action post_url base_url event_url curl_rc

  login_html="$tmp_dir/${name}.login.html"
  login_headers="$tmp_dir/${name}.login.headers.txt"
  cookie="$tmp_dir/${name}.cookies.txt"
  post_headers="$tmp_dir/${name}.post.headers.txt"
  post_body="$tmp_dir/${name}.post.html"
  event_headers="$tmp_dir/${name}.event.headers.txt"

  for url in "$primary_url" "$fallback_url"; do
    [ -n "$url" ] || continue

    : > "$cookie"
    : > "$login_html"
    : > "$login_headers"
    : > "$post_headers"
    : > "$post_body"
    : > "$event_headers"
    : > "$event_txt"

    if ! curl -k -L --max-time 20 -sS -c "$cookie" -b "$cookie" -D "$login_headers" "$url" -o "$login_html" >/dev/null 2>&1; then
      continue
    fi

    login_action="$(grep -Eio 'action="[^"]+"' "$login_html" | head -1 | sed -E 's/action="([^"]+)"/\1/I')"

    if [ -z "$login_action" ]; then
      continue
    fi

    case "$login_action" in
      http://*|https://*)
        post_url="$login_action"
        ;;
      /*)
        post_url="${url%/}$login_action"
        ;;
      *)
        post_url="${url%/}/$login_action"
        ;;
    esac

    curl -k --max-time 20 -sS -c "$cookie" -b "$cookie" -D "$post_headers" \
      -X POST "$post_url" \
      --data-urlencode "login_username=$APC_IDF_USERNAME" \
      --data-urlencode "login_password=$APC_IDF_PASSWORD" \
      --data-urlencode "submit=Log On" \
      -o "$post_body" >/dev/null 2>&1 || true

    if grep -qi 'Maximum Connections Reached' "$post_body"; then
      return 20
    fi

    if grep -qi 'The maximum number of web connections has been reached' "$post_body"; then
      return 20
    fi

    base_url="$(grep -i '^Location:' "$post_headers" | tail -1 | awk '{print $2}' | tr -d '\r')"

    if [ -z "$base_url" ]; then
      continue
    fi

    case "$base_url" in
      http://*|https://*)
        ;;
      /*)
        base_url="${url%/}$base_url"
        ;;
      *)
        base_url="${url%/}/$base_url"
        ;;
    esac

    event_url="${base_url%/}/event.txt"

    curl_rc=0
    curl -k -L --max-time 60 -sS -c "$cookie" -b "$cookie" -D "$event_headers" "$event_url" -o "$event_txt" >/dev/null 2>&1 || curl_rc=$?

    try_logout "$base_url" "$cookie"

    if [ -s "$event_txt" ] && grep -qi 'Content-Disposition: attachment; filename=event.txt' "$event_headers"; then
      return 0
    fi

    if [ -s "$event_txt" ] && grep -q 'Network Management Card' "$event_txt"; then
      return 0
    fi

    if [ "$curl_rc" -ne 0 ] && [ -s "$event_txt" ] && grep -q 'UPS:' "$event_txt"; then
      return 0
    fi
  done

  return 1
}

extract_relevant_events() {
  local event_txt="$1"
  local detected_file="$2"

  awk '
    BEGIN {
      OFS="\t"
    }

    /^[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9][[:space:]]+[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ {
      date=$1
      time=$2
      user=$3
      code=$NF

      msg=""
      for (i=4; i<NF; i++) {
        msg = msg (msg == "" ? "" : " ") $i
      }

      if (msg ~ /UPS: On battery power/ ||
          msg ~ /UPS: No longer on battery power/ ||
          msg ~ /UPS: Self-Test started/ ||
          msg ~ /UPS: Self-Test passed/ ||
          msg ~ /UPS: Self-Test failed/ ||
          msg ~ /UPS: Compensating for a low input voltage/ ||
          msg ~ /UPS: No longer compensating for a low input voltage/) {
        print date, time, user, msg, code
      }
    }
  ' "$event_txt" | sort -u > "$detected_file"
}

event_severity_for_message() {
  local msg="$1"

  case "$msg" in
    *"UPS: On battery power"*) printf 'Warning' ;;
    *"UPS: No longer on battery power"*) printf 'Informational' ;;
    *"UPS: Self-Test failed"*) printf 'Warning' ;;
    *"UPS: Self-Test started"*) printf 'Informational' ;;
    *"UPS: Self-Test passed"*) printf 'Informational' ;;
    *"Compensating for a low input voltage"*) printf 'Warning' ;;
    *"No longer compensating for a low input voltage"*) printf 'Informational' ;;
    *) printf 'Informational' ;;
  esac
}

monitor_target() {
  local name="$1"
  local primary_url="$2"
  local fallback_url="$3"
  local ip="$4"
  local dns="$5"

  local state_name state_file fail_file tmp_dir event_txt detected_file new_file
  local event_date event_time event_user event_msg event_code event_severity event_time_combined
  local matching_events status fetch_rc

  state_name="$(safe_name "$name")"
  state_file="$STATE_DIR/${state_name}.target-events.state"
  fail_file="$STATE_DIR/${state_name}.eventtxt.failures"

  tmp_dir="$(mktemp -d "/tmp/nut-apc-idf-${state_name}.XXXXXX")"
  # Do not use a RETURN trap here. With set -u, the trap can fire after
  # local variables are out of scope and cause an unbound variable failure.

  event_txt="$tmp_dir/event.txt"
  detected_file="$tmp_dir/detected-events.txt"
  new_file="$tmp_dir/new-events.txt"

  touch "$state_file" "$fail_file"

  fetch_rc=0
  fetch_apc_event_txt "$name" "$primary_url" "$fallback_url" "$tmp_dir" "$event_txt" || fetch_rc=$?

  if [ "$fetch_rc" -eq 20 ]; then
    # APC NMC web session table is full. Do not spam the dashboard.
    # Leave a quiet state marker only; retry later when sessions expire.
    printf '%s\n' "$(timestamp) max_connections_reached" > "$STATE_DIR/${state_name}.maxconn.last"
    chmod 0644 "$STATE_DIR/${state_name}.maxconn.last" 2>/dev/null || true
    return 0
  fi

  if [ "$fetch_rc" -ne 0 ]; then
    record_failure "$name" "$ip" "$dns" "fetch_or_auth_failed" "$fail_file"
    return 0
  fi

  extract_relevant_events "$event_txt" "$detected_file"

  matching_events="$(wc -l < "$detected_file" | tr -d ' ')"

  if [ ! -s "$detected_file" ]; then
    record_failure "$name" "$ip" "$dns" "event_txt_no_matching_events" "$fail_file"
    return 0
  fi

  if [ ! -s "$state_file" ]; then
    cp "$detected_file" "$state_file"
    chmod 0644 "$state_file" 2>/dev/null || true
    record_success "$name" "$ip" "$dns" "$fail_file" "$matching_events" "baseline_created"
    return 0
  fi

  comm -13 <(sort -u "$state_file") <(sort -u "$detected_file") > "$new_file"

  if [ -s "$new_file" ]; then
    while IFS=$'\t' read -r event_date event_time event_user event_msg event_code; do
      [ -n "$event_msg" ] || continue

      event_date="$(sanitize_log_field "$event_date")"
      event_time="$(sanitize_log_field "$event_time")"
      event_user="$(sanitize_log_field "$event_user")"
      event_msg="$(sanitize_log_field "$event_msg")"
      event_code="$(sanitize_log_field "$event_code")"

      event_severity="$(event_severity_for_message "$event_msg")"
      event_time_combined="$event_date $event_time"

      log_event "APC_IDF_EVENT source=\"$name\" device=\"$name\" ip=\"$ip\" dns=\"$dns\" severity=\"$event_severity\" code=\"$event_code\" event_time=\"$event_time_combined\" status=\"$event_msg\" message=\"$event_msg\" source_path=\"authenticated_event_txt_v2\""
    done < "$new_file"

    cp "$detected_file" "$state_file"
    chmod 0644 "$state_file" 2>/dev/null || true
    write_count "$fail_file" 0
    publish_events
    return 0
  fi

  cp "$detected_file" "$state_file"
  chmod 0644 "$state_file" 2>/dev/null || true
  record_success "$name" "$ip" "$dns" "$fail_file" "$matching_events" "ok"
  return 0
}

main() {
  init_paths

  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    exit 0
  fi

  if ! load_credentials; then
    publish_events
    exit 0
  fi

  monitor_target "IDF2" "http://APC-IDF2.albl.com" "http://192.168.9.251" "192.168.9.251" "APC-IDF2.albl.com"
  monitor_target "IDF3" "http://apc-idf3.albl.com/" "http://192.168.9.252" "192.168.9.252" "apc-idf3.albl.com"
}

main "$@"
