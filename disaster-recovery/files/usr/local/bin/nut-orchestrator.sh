#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

LOG_FILE="/var/log/nut-orchestrator.log"
STATE_DIR="/var/www/html/nut-state"
EVENT_LOG="/var/www/html/nut-state/events.log"
UI_POWER_LOG="/var/log/nut-orchestrator-ui/power-events.log"

mkdir -p "$STATE_DIR"
touch "$LOG_FILE" "$EVENT_LOG"
chmod 2775 "$STATE_DIR" 2>/dev/null || true
chmod 0664 "$EVENT_LOG" 2>/dev/null || true

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_line() {
  local line="[$(ts)] $1"

  echo "$line" | tee -a "$LOG_FILE"
  echo "$line" >> "$EVENT_LOG"

  mkdir -p "$(dirname "$UI_POWER_LOG")"
  touch "$UI_POWER_LOG"
  chmod 0664 "$UI_POWER_LOG" 2>/dev/null || true
  echo "$line" >> "$UI_POWER_LOG"
}

write_state() {
  local ups_name="$1"
  local display_name="$2"
  local state="$3"
  local scope="$4"
  local countdown_seconds="$5"
  local commit_seconds="$6"
  local note="$7"

  local state_file="${STATE_DIR}/${ups_name}.json"
  local now_epoch
  now_epoch="$(date +%s)"

  cat > "$state_file" <<JSON
{
  "ups_name": "${ups_name}",
  "display_name": "${display_name}",
  "state": "${state}",
  "scope": "${scope}",
  "countdown_seconds": ${countdown_seconds},
  "commit_seconds": ${commit_seconds},
  "updated_epoch": ${now_epoch},
  "updated_at": "$(ts)",
  "note": "${note}"
}
JSON

  chmod 0664 "$state_file" 2>/dev/null || true
}


production_mode_allows_commit() {
  local ups_name="${1:-unknown}"
  local mode_file="/etc/nut/production-mode.conf"
  local mode="disarmed"
  local allow_live="0"
  local allow_esxi="0"

  if [ -f "$mode_file" ]; then
    # shellcheck disable=SC1090
    . "$mode_file" 2>/dev/null || true
    mode="${NUT_PRODUCTION_MODE:-disarmed}"
    allow_live="${NUT_ALLOW_LIVE_ACTIONS:-0}"
    allow_esxi="${NUT_ALLOW_ESXI_SSH_FALLBACK:-0}"
  fi

  # Current enforcement rule:
  #   armed/protecting + allow_live=1 may execute the verified/current approved commit paths.
  #   legacy storm_guard is accepted as an alias only.
  #   disarmed/off block live commit actions.
  #   ESXi SSH fallback remains separately disabled unless explicitly approved.
  if { [ "$mode" = "armed" ] || [ "$mode" = "storm_guard" ]; } && [ "$allow_live" = "1" ]; then
    log_line "PRODUCTION_MODE_GATE_ALLOW ups=${ups_name} mode=${mode} allow_live=${allow_live} allow_esxi=${allow_esxi}"
    return 0
  fi

  log_line "PRODUCTION_MODE_GATE_BLOCK ups=${ups_name} mode=${mode} allow_live=${allow_live} allow_esxi=${allow_esxi} reason='live commit actions blocked by production mode'"
  write_state "$ups_name" "$ups_name" "shutdown_blocked_by_production_mode" "production mode gate" 0 0 "Blocked by production mode: ${mode}"
  return 1
}

run_phase2_power_restore_abort() {
  local ups_name="$1"
  local rc=0

  log_line "PHASE2_POWER_RESTORE_ABORT_REQUESTED ${ups_name}"
  log_line "PHASE2_POWER_RESTORE_ABORT_TARGET ${ups_name}"

  if [ -x /usr/local/sbin/phase2-power-restore-abort ]; then
    /usr/local/sbin/phase2-power-restore-abort --ups "$ups_name" >> "$LOG_FILE" 2>&1
    rc=$?
    log_line "PHASE2_POWER_RESTORE_ABORT_RESULT ${ups_name} rc=${rc}"
    return "$rc"
  fi

  if [ -x /usr/local/bin/phase2-power-restore-abort ]; then
    /usr/local/bin/phase2-power-restore-abort --ups "$ups_name" >> "$LOG_FILE" 2>&1
    rc=$?
    log_line "PHASE2_POWER_RESTORE_ABORT_RESULT ${ups_name} rc=${rc}"
    return "$rc"
  fi

  log_line "PHASE2_POWER_RESTORE_ABORT_FAILED ${ups_name} reason='script not found or not executable'"
  log_line "PHASE2_POWER_RESTORE_ABORT_CHECKED /usr/local/sbin/phase2-power-restore-abort"
  log_line "PHASE2_POWER_RESTORE_ABORT_CHECKED /usr/local/bin/phase2-power-restore-abort"
  return 127
}

ups_maintenance_commbad() {
  local ups_name="$1"
  local decision_output=""

  decision_output="$(/usr/local/sbin/nut-ups-maintenance-decision --target-ups "$ups_name" 2>/dev/null || true)"

  log_line "UPS_MAINTENANCE_COMM_BAD ${ups_name} ${decision_output}"

  if echo "$decision_output" | grep -q 'decision=GRID_CONFIRMED'; then
    /usr/local/sbin/nut-ups-maintenance-state --event UPS_MAINTENANCE_UPS_OFFLINE --ups "$ups_name" --mode commbad --status active --message "UPS communication lost while grid power appears present. Automatic shutdown suppression not implemented yet." >> "$LOG_FILE" 2>&1 || true
    send_outage_email "commbad" "$ups_name communication lost while grid power appears present"
    return 0
  fi

  if echo "$decision_output" | grep -q 'decision=WARNING_ONLY'; then
    /usr/local/sbin/nut-ups-maintenance-state --event UPS_MAINTENANCE_TIMEOUT_WARNING --ups "$ups_name" --mode commbad --status warning --message "UPS communication lost with only one online witness. Warning-only maintenance state recorded. Automatic shutdown suppression not implemented yet." >> "$LOG_FILE" 2>&1 || true
    send_outage_email "commbad" "$ups_name communication lost with only one online grid witness"
    return 0
  fi

  /usr/local/sbin/nut-ups-maintenance-state --event UPS_MAINTENANCE_REAL_OUTAGE_DETECTED --ups "$ups_name" --mode commbad --status warning --message "UPS communication lost but grid witness confidence was not sufficient for maintenance classification." >> "$LOG_FILE" 2>&1 || true
  send_outage_email "commbad" "$ups_name communication lost and grid witness confidence was insufficient"
}

ups_maintenance_commok() {
  local ups_name="$1"

  log_line "UPS_MAINTENANCE_COMM_OK ${ups_name}"
  /usr/local/sbin/nut-ups-maintenance-state --event UPS_MAINTENANCE_UPS_RETURNED --ups "$ups_name" --mode commok --status initialized --message "UPS communication restored. Replacement/consolidation identity review is not implemented yet." >> "$LOG_FILE" 2>&1 || true
  send_outage_email "commok" "$ups_name communication restored"
}

ups_lowbatt_alert() {
  local ups_name="$1"

  log_line "UPS_LOWBATT_DETECTED ${ups_name}"
  send_outage_email "lowbatt" "$ups_name entered low-battery state"
}

ups_maintenance_suppresses_commit() {
  local ups_name="$1"
  local result=""
  local rc=1

  result="$(/usr/local/sbin/nut-ups-maintenance-suppression-check --ups "$ups_name" 2>&1)"
  rc=$?

  if [ "$rc" -eq 0 ]; then
    log_line "UPS_MAINTENANCE_SHUTDOWN_SUPPRESSED ${ups_name} ${result}"
    write_state "$ups_name" "$ups_name" "shutdown_suppressed_by_ups_maintenance" "UPS Maintenance Mode" 0 0 "Shutdown suppressed because UPS Maintenance Mode is active"
    /usr/local/sbin/nut-ups-maintenance-state --event UPS_MAINTENANCE_NOTE --ups "$ups_name" --mode suppression --status active --message "Shutdown commit suppressed because UPS Maintenance Mode is active. No shutdown actions performed." >> "$LOG_FILE" 2>&1 || true
    return 0
  fi

  if [ "$rc" -eq 2 ]; then
    log_line "UPS_MAINTENANCE_SUPPRESSION_CHECK_ERROR ${ups_name} ${result}"
  else
    log_line "UPS_MAINTENANCE_SUPPRESSION_NOT_ACTIVE ${ups_name} ${result}"
  fi

  return 1
}

commit_placeholder() {
  local ups_name="$1"
  local rc=0

  if ups_maintenance_suppresses_commit "$ups_name"; then
    return 0
  fi

  if ! production_mode_allows_commit "$ups_name"; then
    return 0
  fi

  case "$ups_name" in
    ups7)
      log_line "UPS_SHUTDOWN_COMMITTED ups7 targeted shutdown started"

      log_line "UPS_TARGET_ACTION_ATTEMPT ups7 DB01 method='telnet solaris wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / DB target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase3-full DB_LIVE_APPROVED=1 /usr/local/sbin/nut-db-shutdown.sh DB01 >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups7 DB01"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups7 DB01 rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_ATTEMPT ups7 DB02 method='telnet solaris wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / DB target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase3-full DB_LIVE_APPROVED=1 /usr/local/sbin/nut-db-shutdown.sh DB02 >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups7 DB02"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups7 DB02 rc=$rc"
      fi

      write_state "ups7" "ups7" "shutdown_committed" "targeted shutdown" 0 0 "Committed; DB01 and DB02 wrapper calls executed"
      ;;

    ups2)
      log_line "UPS_SHUTDOWN_COMMITTED ups2 targeted shutdown started"

      log_line "UPS_TARGET_ACTION_ATTEMPT ups2 Blue Iris method='native shutdown.exe via wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / Blue Iris target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase3-full BLUEIRIS_LIVE_APPROVED=1 /usr/local/sbin/nut-blueiris-shutdown.sh >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups2 Blue Iris"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups2 Blue Iris rc=$rc"
      fi

      write_state "ups2" "ups2" "shutdown_committed" "targeted shutdown" 0 0 "Committed; Blue Iris wrapper executed"
      ;;

    ups8)
      log_line "UPS_SHUTDOWN_COMMITTED ups8 targeted shutdown started"

      log_line "UPS_TARGET_ACTION_ATTEMPT ups8 VOIP method='linux wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / VOIP target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase3-full VOIP_LIVE_APPROVED=1 /usr/local/sbin/nut-voip-shutdown.sh >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups8 VOIP"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups8 VOIP rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_SKIPPED ups8 VME Server reason='alert only'"
      log_line "UPS_TARGET_ACTION_SKIPPED ups8 Merlin phone switch reason='alert only'"

      write_state "ups8" "ups8" "shutdown_committed" "targeted shutdown" 0 0 "Committed; VOIP wrapper executed, VME and Merlin alert only"
      ;;

    ups6)
      log_line "UPS_SHUTDOWN_COMMITTED ups6 targeted shutdown started"

      log_line "UPS_TARGET_ACTION_ATTEMPT ups6 Lansweeper method='native shutdown.exe via wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / Lansweeper target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase1-lansweeper LANSWEEPER_LIVE_APPROVED=1 /usr/local/sbin/nut-lansweeper-shutdown.sh >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups6 Lansweeper"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups6 Lansweeper rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_SKIPPED ups6 Cisco Asa 5508 reason='alert only'"
      log_line "UPS_TARGET_ACTION_SKIPPED ups6 AT&T 4808 Router reason='alert only'"

      write_state "ups6" "ups6" "shutdown_committed" "targeted shutdown" 0 0 "Committed; Lansweeper wrapper executed, network gear alert only"
      ;;

    ups9)
      log_line "UPS_SHUTDOWN_COMMITTED ups9 broader VMware shutdown started"

      log_line "UPS_TARGET_ACTION_ATTEMPT ups9 VMware method='vCenter API with PowerCLI fallback'"
    send_outage_email "shutdown" "shutdown sequence started / VMware target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=full-production VMWARE_LIVE_APPROVED=1 ALLOW_ESXI_SSH_FALLBACK=1 VMWARE_HOST_ACTION_APPROVED=1 CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN=1 /usr/local/sbin/nut-vmware-shutdown.sh shutdown_domain >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups9 VMware"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups9 VMware rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_ATTEMPT ups9 Albl-synology1 method='synology wrapper'"
    send_outage_email "shutdown" "shutdown sequence started / Synology target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=phase3-full SYNOLOGY_LIVE_APPROVED=1 /usr/local/sbin/nut-synology-shutdown.sh >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups9 Albl-synology1"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups9 Albl-synology1 rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_ATTEMPT ups9 Alblnetapp01 method='ONTAP CLI halt over SSH'"
    send_outage_email "shutdown" "shutdown sequence started / NetApp target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=full-production NETAPP_LIVE_APPROVED=1 /usr/local/sbin/nut-netapp-halt.sh Alblnetapp01 >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups9 Alblnetapp01"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups9 Alblnetapp01 rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_ATTEMPT ups9 Alblnetapp02 method='ONTAP CLI halt over SSH'"
    send_outage_email "shutdown" "shutdown sequence started / NetApp target action attempted"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=full-production NETAPP_LIVE_APPROVED=1 /usr/local/sbin/nut-netapp-halt.sh Alblnetapp02 >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups9 Alblnetapp02"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups9 Alblnetapp02 rc=$rc"
      fi

      log_line "UPS_TARGET_ACTION_ATTEMPT ups9 nutserver method='local final shutdown wrapper - should run last'"
    send_outage_email "final" "final NUT server shutdown step reached"
      SIMULATE=0 ALLOW_REAL_TEST=1 REAL_TEST_PHASE=full-production NUTSERVER_LIVE_APPROVED=1 /usr/local/sbin/nut-local-final-shutdown.sh >> "$LOG_FILE" 2>&1
      rc=$?
      if [ "$rc" -eq 0 ]; then
        log_line "UPS_TARGET_ACTION_SUCCESS ups9 nutserver final shutdown"
      else
        log_line "UPS_TARGET_ACTION_FAILED ups9 nutserver final shutdown rc=$rc"
      fi

      write_state "ups9" "ups9" "shutdown_committed" "broader VMware shutdown" 0 0 "Committed; VMware wrapper executed, Synology wrapper executed, NetApp wrappers executed, NUT server final shutdown wrapper executed last"
      ;;

    ups3)
      log_line "UPS_SHUTDOWN_COMMITTED ups3 phase2 validation commit reached"
      write_state "ups3" "ups3" "shutdown_committed" "phase2 validation" 0 0 "Committed; Phase 2 ups3 validation timer expired"
      ;;

    *)
      log_line "UPS_SHUTDOWN_COMMITTED ${ups_name} no action handler defined"
      write_state "$ups_name" "$ups_name" "shutdown_committed" "unknown" 0 0 "No action handler defined"
      ;;
  esac
}

EMAIL_STATE_DIR="/var/www/html/nut-state"

email_ups_from_reason() {
  printf '%s\n' "${1:-}" | grep -oE 'ups[0-9]+' | head -1
}

email_mark_outage_start() {
  local ups_name="${1:-unknown}"
  mkdir -p "$EMAIL_STATE_DIR" 2>/dev/null || true
  date +%s > "$EMAIL_STATE_DIR/email-outage-start-${ups_name}.epoch" 2>/dev/null || true
}

email_duration_for_ups() {
  local ups_name="${1:-unknown}"
  local file="$EMAIL_STATE_DIR/email-outage-start-${ups_name}.epoch"
  local start now elapsed minutes seconds

  if [ ! -s "$file" ]; then
    echo "unavailable - outage start timestamp was not found"
    return 0
  fi

  start="$(cat "$file" 2>/dev/null || echo "")"
  now="$(date +%s)"

  case "$start" in
    ''|*[!0-9]*)
      echo "unavailable - outage start timestamp was invalid"
      return 0
      ;;
  esac

  elapsed=$((now - start))
  if [ "$elapsed" -lt 0 ]; then
    elapsed=0
  fi

  minutes=$((elapsed / 60))
  seconds=$((elapsed % 60))
  echo "${minutes} minutes ${seconds} seconds"
}

email_context_for_type() {
  local kind="${1:-}"
  local reason="${2:-}"
  local ups_name

  ups_name="$(email_ups_from_reason "$reason")"

  export NUT_EMAIL_REASON="$reason"
  export NUT_OUTAGE_DURATION=""
  export NUT_SHUTDOWN_ATTEMPTED=""
  export NUT_SYSTEMS_SCHEDULED=""
  export NUT_SYSTEMS_SHUT_DOWN=""
  export NUT_SYSTEMS_STILL_RUNNING=""
  export NUT_MANUAL_RECOVERY_REQUIRED=""

  case "$kind" in
    onbatt)
      [ -n "$ups_name" ] && email_mark_outage_start "$ups_name"
      export NUT_SHUTDOWN_ATTEMPTED="No"
      export NUT_SYSTEMS_STILL_RUNNING="Protected systems remain online. Shutdown countdown has started only if this UPS has a configured timer."
      export NUT_MANUAL_RECOVERY_REQUIRED="No, unless equipment shows issues."
      ;;
    online|cancelled)
      if [ -n "$ups_name" ]; then
        export NUT_OUTAGE_DURATION="$(email_duration_for_ups "$ups_name")"
      else
        export NUT_OUTAGE_DURATION="unavailable - UPS name was not available"
      fi
      export NUT_SHUTDOWN_ATTEMPTED="No"
      export NUT_SYSTEMS_SHUT_DOWN="None reported by the NUT orchestrator before power returned."
      export NUT_SYSTEMS_STILL_RUNNING="Protected systems remained online or shutdown was canceled before additional action was required."
      export NUT_MANUAL_RECOVERY_REQUIRED="No, unless equipment shows issues."
      ;;
    shutdown)
      export NUT_SHUTDOWN_ATTEMPTED="Yes"
      export NUT_SYSTEMS_SCHEDULED="${reason}"
      export NUT_SYSTEMS_STILL_RUNNING="Status pending. Review NUT event log and target system status after shutdown sequence completes."
      export NUT_MANUAL_RECOVERY_REQUIRED="Yes if any shutdown action fails or a protected target does not return cleanly."
      ;;
    final)
      export NUT_SHUTDOWN_ATTEMPTED="Yes"
      export NUT_SYSTEMS_SCHEDULED="Final NUT server shutdown step reached."
      export NUT_SYSTEMS_STILL_RUNNING="Automated visibility may end shortly after this email."
      export NUT_MANUAL_RECOVERY_REQUIRED="Yes. Follow the power-drain documentation before rebooting or restarting affected equipment."
      ;;
  esac
}

send_outage_email() {
  local kind="${1:-}"
  local reason="${2:-automatic UPS power event}"
  local email_cmd="/usr/local/sbin/nut-email-alert-test-send"
  local rc=0

  if [ -z "$kind" ]; then
    return 0
  fi

  if [ ! -x "$email_cmd" ]; then
    if declare -F log_line >/dev/null 2>&1; then
      log_line "EMAIL_NOTIFY_SKIPPED type=${kind} reason=\"email_command_missing\""
    fi
    return 0
  fi

  email_context_for_type "$kind" "$reason"
  sudo -n "$email_cmd" --send "$kind" >> "$LOG_FILE" 2>&1
  rc=$?

  if [ "$rc" -eq 0 ]; then
    if declare -F log_line >/dev/null 2>&1; then
      log_line "EMAIL_NOTIFY_SENT type=${kind} reason=\"${reason}\""
    fi
  else
    if declare -F log_line >/dev/null 2>&1; then
      log_line "EMAIL_NOTIFY_FAILED type=${kind} rc=${rc} reason=\"${reason}\""
    fi
  fi

  return 0
}


case "${1:-}" in
  # ============================================================
  # UPS1 / UPS4 / UPS5 - ALERT ONLY
  # Monitoring, email, event logging, and state only.
  # NO shutdown countdowns.
  # NO shutdown commits.
  # NO equipment shutdown actions.
  # ============================================================

  ups1-onbatt)
    log_line "UPS_ONBATT_DETECTED ups1 scope='alert_only' countdown='none'"
    send_outage_email "onbatt" "ups1 on battery / grid power lost"
    write_state "ups1" "ups1" "on_battery_alert" "alert_only" 0 0 "UPS on battery; alert-only monitoring; no automatic shutdown configured"
    ;;

  ups1-online)
    log_line "UPS_POWER_RESTORED ups1 scope='alert_only'"
    write_state "ups1" "ups1" "normal" "alert_only" 0 0 "Power restored; alert-only UPS returned online"
    send_outage_email "online" "ups1 power restored / grid returned"
    ;;

  ups1-lowbatt)
    ups_lowbatt_alert "ups1"
    ;;

  ups1-commbad)
    ups_maintenance_commbad "ups1"
    ;;

  ups1-commok)
    ups_maintenance_commok "ups1"
    ;;

  ups4-onbatt)
    log_line "UPS_ONBATT_DETECTED ups4 scope='alert_only' countdown='none'"
    send_outage_email "onbatt" "ups4 on battery / grid power lost"
    write_state "ups4" "ups4" "on_battery_alert" "alert_only" 0 0 "UPS on battery; alert-only monitoring; no automatic shutdown configured"
    ;;

  ups4-online)
    log_line "UPS_POWER_RESTORED ups4 scope='alert_only'"
    write_state "ups4" "ups4" "normal" "alert_only" 0 0 "Power restored; alert-only UPS returned online"
    send_outage_email "online" "ups4 power restored / grid returned"
    ;;

  ups4-lowbatt)
    ups_lowbatt_alert "ups4"
    ;;

  ups4-commbad)
    ups_maintenance_commbad "ups4"
    ;;

  ups4-commok)
    ups_maintenance_commok "ups4"
    ;;

  ups5-onbatt)
    log_line "UPS_ONBATT_DETECTED ups5 scope='alert_only' countdown='none'"
    send_outage_email "onbatt" "ups5 on battery / grid power lost"
    write_state "ups5" "ups5" "on_battery_alert" "alert_only" 0 0 "UPS on battery; alert-only monitoring; no automatic shutdown configured"
    ;;

  ups5-online)
    log_line "UPS_POWER_RESTORED ups5 scope='alert_only'"
    write_state "ups5" "ups5" "normal" "alert_only" 0 0 "Power restored; alert-only UPS returned online"
    send_outage_email "online" "ups5 power restored / grid returned"
    ;;

  ups5-lowbatt)
    ups_lowbatt_alert "ups5"
    ;;

  ups5-commbad)
    ups_maintenance_commbad "ups5"
    ;;

  ups5-commok)
    ups_maintenance_commok "ups5"
    ;;

  ups7-lowbatt)
    ups_lowbatt_alert "ups7"
    ;;

  ups2-lowbatt)
    ups_lowbatt_alert "ups2"
    ;;

  ups8-lowbatt)
    ups_lowbatt_alert "ups8"
    ;;

  ups6-lowbatt)
    ups_lowbatt_alert "ups6"
    ;;

  ups9-lowbatt)
    ups_lowbatt_alert "ups9"
    ;;

  ups3-lowbatt)
    ups_lowbatt_alert "ups3"
    ;;

  ups7-commbad)
    ups_maintenance_commbad "ups7"
    ;;

  ups7-commok)
    ups_maintenance_commok "ups7"
    ;;

  ups2-commbad)
    ups_maintenance_commbad "ups2"
    ;;

  ups2-commok)
    ups_maintenance_commok "ups2"
    ;;

  ups8-commbad)
    ups_maintenance_commbad "ups8"
    ;;

  ups8-commok)
    ups_maintenance_commok "ups8"
    ;;

  ups6-commbad)
    ups_maintenance_commbad "ups6"
    ;;

  ups6-commok)
    ups_maintenance_commok "ups6"
    ;;

  ups9-commbad)
    ups_maintenance_commbad "ups9"
    ;;

  ups9-commok)
    ups_maintenance_commok "ups9"
    ;;

  ups3-commbad)
    ups_maintenance_commbad "ups3"
    ;;

  ups3-commok)
    ups_maintenance_commok "ups3"
    ;;

  ups7-onbatt)
    log_line "UPS_ONBATT_DETECTED ups7 runtime='18m' countdown='240s'"
    send_outage_email "onbatt" "ups7 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups7 scope='targeted shutdown' countdown='240s'"
    write_state "ups7" "ups7" "on_battery_pending" "targeted shutdown" 240 240 "DB01 and DB02 pending graceful shutdown"
    ;;

  ups7-online)
    log_line "UPS_SHUTDOWN_CANCELED_POWER_RESTORED ups7 before_commit='yes'"
    write_state "ups7" "ups7" "power_restored_canceled" "targeted shutdown" 0 0 "Shutdown canceled / power restored"
    send_outage_email "online" "ups7 power restored / grid returned"
    send_outage_email "cancelled" "ups7 power restored before shutdown"
    ;;

  ups7-commit)
    commit_placeholder "ups7"
    ;;

  ups2-onbatt)
    log_line "UPS_ONBATT_DETECTED ups2 runtime='30m' countdown='420s'"
    send_outage_email "onbatt" "ups2 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups2 scope='targeted shutdown' countdown='420s'"
    write_state "ups2" "ups2" "on_battery_pending" "targeted shutdown" 420 420 "Blue Iris pending graceful shutdown"
    ;;

  ups2-online)
    log_line "UPS_SHUTDOWN_CANCELED_POWER_RESTORED ups2 before_commit='yes'"
    write_state "ups2" "ups2" "power_restored_canceled" "targeted shutdown" 0 0 "Shutdown canceled / power restored"
    send_outage_email "online" "ups2 power restored / grid returned"
    send_outage_email "cancelled" "ups2 power restored before shutdown"
    ;;

  ups2-commit)
    commit_placeholder "ups2"
    ;;

  ups8-onbatt)
    log_line "UPS_ONBATT_DETECTED ups8 runtime='15m' countdown='180s'"
    send_outage_email "onbatt" "ups8 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups8 scope='targeted shutdown' countdown='180s'"
    write_state "ups8" "ups8" "on_battery_pending" "targeted shutdown" 180 180 "ups8 framework active; VOIP executable, VME and Merlin alert only"
    ;;

  ups8-online)
    log_line "UPS_SHUTDOWN_CANCELED_POWER_RESTORED ups8 before_commit='yes'"
    write_state "ups8" "ups8" "power_restored_canceled" "targeted shutdown" 0 0 "Shutdown canceled / power restored"
    send_outage_email "online" "ups8 power restored / grid returned"
    send_outage_email "cancelled" "ups8 power restored before shutdown"
    ;;

  ups8-commit)
    commit_placeholder "ups8"
    ;;

  ups6-onbatt)
    log_line "UPS_ONBATT_DETECTED ups6 runtime='19h2m' countdown='300s'"
    send_outage_email "onbatt" "ups6 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups6 scope='targeted shutdown' countdown='300s'"
    write_state "ups6" "ups6" "on_battery_pending" "targeted shutdown" 300 300 "Lansweeper pending graceful shutdown; network gear alert only"
    ;;

  ups6-online)
    log_line "UPS_SHUTDOWN_CANCELED_POWER_RESTORED ups6 before_commit='yes'"
    write_state "ups6" "ups6" "power_restored_canceled" "targeted shutdown" 0 0 "Shutdown canceled / power restored"
    send_outage_email "online" "ups6 power restored / grid returned"
    send_outage_email "cancelled" "ups6 power restored before shutdown"
    ;;

  ups6-commit)
    commit_placeholder "ups6"
    ;;

  ups9-onbatt)
    log_line "UPS_ONBATT_DETECTED ups9 runtime='37m' countdown='360s'"
    send_outage_email "onbatt" "ups9 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups9 scope='broader VMware shutdown' countdown='360s'"
    write_state "ups9" "ups9" "on_battery_pending" "broader VMware shutdown" 360 360 "VMware/storage domain pending shutdown"
    ;;

  ups9-online)
    log_line "UPS_SHUTDOWN_CANCELED_POWER_RESTORED ups9 before_commit='yes'"
    write_state "ups9" "ups9" "power_restored_canceled" "broader VMware shutdown" 0 0 "Shutdown canceled / power restored"
    send_outage_email "online" "ups9 power restored / grid returned"
    send_outage_email "cancelled" "ups9 power restored before shutdown"
    ;;

  ups9-commit)
    commit_placeholder "ups9"
    ;;

  ups3-onbatt)
    log_line "UPS_ONBATT_DETECTED ups3 runtime='unknown' countdown='300s'"
    send_outage_email "onbatt" "ups3 on battery / grid power lost"
    log_line "UPS_COUNTDOWN_STARTED ups3 scope='phase2 validation' countdown='300s'"
    write_state "ups3" "ups3" "on_battery_pending" "phase2 validation" 300 300 "Phase 2 ups3 power-restore-abort validation pending"
    ;;

  phase2-power-restore-abort-ups3)
    # Production notification must never depend on the legacy Phase 2 helper.
    write_state "ups3" "ups3" "power_restored_canceled" "phase2 validation" 0 0 "Power restored before UPS3 shutdown commit"
    send_outage_email "online" "ups3 power restored / grid returned"
    send_outage_email "cancelled" "ups3 power restored before shutdown"

    run_phase2_power_restore_abort "ups3"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      log_line "PHASE2_POWER_RESTORE_ABORT_NONFATAL ups3 rc=${rc}"
    fi

    exit 0
    ;;

  ups3-commit)
    commit_placeholder "ups3"
    ;;

  *)
    log_line "UNKNOWN_EVENT arg='${1:-none}'"
    ;;
esac
