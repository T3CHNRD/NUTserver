#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR="/var/lib/nut-apc-idf-monitor"
LOG="/var/log/nut-orchestrator-ui/power-events.log"
PUBLISHER="/usr/local/sbin/nut-publish-power-events-json"
CRED_FILE="/etc/nut/apc-idf-web.conf"

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

load_credentials() {
  if [ ! -r "$CRED_FILE" ]; then
    log_event "APC_IDF_EVENT source=\"monitor\" status=\"credential_file_missing\" path=\"$CRED_FILE\""
    return 1
  fi

  # shellcheck disable=SC1090
  . "$CRED_FILE"

  if [ -z "${APC_IDF_USERNAME:-}" ] || [ -z "${APC_IDF_PASSWORD:-}" ]; then
    log_event "APC_IDF_EVENT source=\"monitor\" status=\"credential_file_incomplete\" path=\"$CRED_FILE\""
    return 1
  fi

  return 0
}

is_relevant_event_message() {
  local msg="$1"

  case "$msg" in
    *"UPS: On battery power"*|\
    *"UPS: No longer on battery power"*|\
    *"UPS: Self-Test started"*|\
    *"UPS: Self-Test passed"*|\
    *"UPS: Self-Test failed"*|\
    *"UPS: Compensating for a low input voltage"*|\
    *"UPS: No longer compensating for a low input voltage"*)
      return 0
      ;;
  esac

  return 1
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

    if ! curl -k -L --max-time 20 -sS -c "$cookie" -b "$cookie" -D "$login_headers" "$url" -o "$login_html" 2>/dev/null; then
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

    curl -k -L --max-time 20 -sS -c "$cookie" -b "$cookie" -D "$post_headers" \
      -X POST "$post_url" \
      --data-urlencode "login_username=$APC_IDF_USERNAME" \
      --data-urlencode "login_password=$APC_IDF_PASSWORD" \
      --data-urlencode "submit=Log On" \
      -o "$post_body" >/dev/null 2>&1 || true

    base_url="$(grep -i '^Location:' "$post_headers" | tail -1 | awk '{print $2}' | tr -d '\r')"

    if [ -z "$base_url" ]; then
      continue
    fi

    event_url="${base_url%/}/event.txt"

    curl_rc=0
    curl -k -L --max-time 45 -sS -c "$cookie" -b "$cookie" -D "$event_headers" "$event_url" -o "$event_txt" >/dev/null 2>&1 || curl_rc=$?

    if [ -s "$event_txt" ] && grep -qi 'Content-Disposition: attachment; filename=event.txt' "$event_headers"; then
      return 0
    fi

    if [ -s "$event_txt" ] && grep -q 'Network Management Card' "$event_txt"; then
      return 0
    fi

    if [ "$curl_rc" -ne 0 ]; then
      log_event "APC_IDF_EVENT source=\"$name\" status=\"event_txt_fetch_warning\" curl_rc=\"$curl_rc\""
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
      code=$NF
      user=$3

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

monitor_target() {
  local name="$1"
  local primary_url="$2"
  local fallback_url="$3"
  local ip="$4"
  local dns="$5"

  local state_name state_file tmp_dir event_txt detected_file new_file line
  local event_date event_time event_user event_msg event_code event_severity event_time_combined

  state_name="$(safe_name "$name")"
  state_file="$STATE_DIR/${state_name}.target-events.state"

  tmp_dir="$(mktemp -d "/tmp/nut-apc-idf-${state_name}.XXXXXX")"
  event_txt="$tmp_dir/event.txt"
  detected_file="$tmp_dir/detected-events.txt"
  new_file="$tmp_dir/new-events.txt"

  mkdir -p "$STATE_DIR"
  touch "$state_file"

  if ! fetch_apc_event_txt "$name" "$primary_url" "$fallback_url" "$tmp_dir" "$event_txt"; then
    log_event "APC_IDF_EVENT source=\"$name\" status=\"event_txt_unavailable\" ip=\"$ip\" dns=\"$dns\""
    publish_events
    return 0
  fi

  extract_relevant_events "$event_txt" "$detected_file"

  if [ ! -s "$detected_file" ]; then
    log_event "APC_IDF_EVENT source=\"$name\" status=\"event_txt_reachable_no_matching_events\" ip=\"$ip\" dns=\"$dns\""
    publish_events
    return 0
  fi

  if [ ! -s "$state_file" ]; then
    cp "$detected_file" "$state_file"
    chmod 0664 "$state_file" 2>/dev/null || true
    log_event "APC_IDF_EVENT source=\"$name\" status=\"baseline_created\" event_source=\"authenticated_event_txt\" matching_events=\"$(wc -l < "$detected_file" | tr -d ' ')\" ip=\"$ip\" dns=\"$dns\""
    publish_events
    return 0
  fi

  comm -13 <(sort -u "$state_file") <(sort -u "$detected_file") > "$new_file"

  if [ -s "$new_file" ]; then
    while IFS=$'\t' read -r event_date event_time event_user event_msg event_code; do
      [ -n "$event_msg" ] || continue

      if ! is_relevant_event_message "$event_msg"; then
        continue
      fi

      event_severity="$(event_severity_for_message "$event_msg")"
      event_time_combined="$event_date $event_time"

      log_event "APC_IDF_EVENT source=\"$name\" device=\"$name\" ip=\"$ip\" dns=\"$dns\" severity=\"$event_severity\" code=\"$event_code\" event_time=\"$event_time_combined\" status=\"$event_msg\" message=\"$event_msg\" source_path=\"authenticated_event_txt\""
    done < "$new_file"

    cp "$detected_file" "$state_file"
    chmod 0664 "$state_file" 2>/dev/null || true
    publish_events
    return 0
  fi

  cp "$detected_file" "$state_file"
  chmod 0664 "$state_file" 2>/dev/null || true
  log_event "APC_IDF_EVENT source=\"$name\" status=\"no_new_matching_events\" event_source=\"authenticated_event_txt\" matching_events=\"$(wc -l < "$detected_file" | tr -d ' ')\" ip=\"$ip\" dns=\"$dns\""
  publish_events
  return 0
}

main() {
  mkdir -p "$STATE_DIR"

  if ! load_credentials; then
    publish_events
    exit 0
  fi

  monitor_target "IDF2" "http://APC-IDF2.albl.com" "http://192.168.9.251" "192.168.9.251" "APC-IDF2.albl.com"
  monitor_target "IDF3" "http://apc-idf3.albl.com/" "http://192.168.9.252" "192.168.9.252" "apc-idf3.albl.com"
}

main "$@"
