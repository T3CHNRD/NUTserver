#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

LOG_FILE="/var/log/nut-vmware-shutdown.log"
CONFIG_FILE="/etc/nut/nut-orchestrator.conf"
SIMULATE="${SIMULATE:-1}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

power_classification() {
  local result="$1"
  local reason="$2"
  local extra="${3:-}"

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    if [ -n "$extra" ]; then
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"VMware\" reason=\"${reason}\" ${extra}"
    else
      /usr/local/sbin/nut-power-event-log "SHUTDOWN_CLASSIFICATION ${result} target=\"VMware\" reason=\"${reason}\""
    fi
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi
}

if [ ! -f "$CONFIG_FILE" ]; then
  log "ERROR config file missing: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

VCENTER_PASS_FILE="/etc/nut/vcenter.pass"
VMWARE_VM_MAP_FILE="/etc/nut/config.d/vmware-vm-map.conf"

if [ -s "$VCENTER_PASS_FILE" ]; then
  VCENTER_PASSWORD="$(tr -d '\r\n' < "$VCENTER_PASS_FILE")"
fi

ACTION="${1:-shutdown_domain}"

PHASE1=(
"WebServer-1"
"albl-Webserver-2"
"Maint-VM2"
"Cisco IQ-Link"
)

PHASE2=(
"Albl-exch2019"
"ALBL-Exch"
"OEL-DB01"
"albl-SageSQL"
"alblvvsaa"
)

PHASE3=(
"ALBL-WSUS"
"ALBL-ActiveIQ"
"ALBL-ParkView-1"
)

PHASE4=(
"ALBL-SDC1"
)

VCENTER_VM="${VMWARE_VCSA_VM:-ALBL-VCSA}"

HYPERVISOR_FALLBACK_CONFIG="/etc/nut/hypervisors/hypervisor-ssh-fallback.conf"

if [ -f "$HYPERVISOR_FALLBACK_CONFIG" ]; then
  # shellcheck disable=SC1090
  . "$HYPERVISOR_FALLBACK_CONFIG" 2>/dev/null || true
fi

ESXI_HOSTS=(
"${ESXI_HOST_01_IP:-}"
"${ESXI_HOST_02_IP:-}"
"${ESXI_HOST_03_IP:-}"
)
ESXI_HOST_NAMES=(
"${ESXI_HOST_01_NAME:-}"
"${ESXI_HOST_02_NAME:-}"
"${ESXI_HOST_03_NAME:-}"
)

UPS9_CHECKPOINT_CLI="/usr/local/sbin/nut-ups9-checkpoint"
UPS9_SEQUENCE_ID=""
UPS9_CHECKPOINT_REQUIRED=0

ups9_checkpoint_record() {
  local target="$1" stage="$2" outcome="$3" reason="$4" result_rc="${5:-}"
  [ "${UPS9_CHECKPOINT_REQUIRED:-0}" = "1" ] || return 0
  [ -n "$UPS9_SEQUENCE_ID" ] || return 1
  if [ -n "$result_rc" ]; then
    "$UPS9_CHECKPOINT_CLI" record --sequence "$UPS9_SEQUENCE_ID" --target "$target" \
      --stage "$stage" --outcome "$outcome" --reason "$reason" --return-code "$result_rc"
  else
    "$UPS9_CHECKPOINT_CLI" record --sequence "$UPS9_SEQUENCE_ID" --target "$target" \
      --stage "$stage" --outcome "$outcome" --reason "$reason"
  fi
}

ups9_checkpoint_finish() {
  local outcome="$1" reason="$2" result_rc="${3:-}"
  [ -n "$UPS9_SEQUENCE_ID" ] || return 1
  if [ -n "$result_rc" ]; then
    "$UPS9_CHECKPOINT_CLI" finish-vmware --sequence "$UPS9_SEQUENCE_ID" \
      --outcome "$outcome" --reason "$reason" --return-code "$result_rc"
  else
    "$UPS9_CHECKPOINT_CLI" finish-vmware --sequence "$UPS9_SEQUENCE_ID" \
      --outcome "$outcome" --reason "$reason"
  fi
}

require_python() {
  python3 - <<'PY' >/dev/null 2>&1
import requests
PY
}

run_wave_sim() {
  local phase="$1"
  shift
  local name

  log "SIMULATION PHASE ${phase}"
  for name in "$@"; do
    log "TARGET: ${name}"
    log "MODE: SIMULATED / DRY-RUN"
    log "ACTION: would request VMware guest shutdown for ${name}"
    log "PASS ${name} simulated execution OK"
  done
}

simulate_shutdown_domain() {
  log "===== VMWARE SHUTDOWN PLAN ====="
  log "Provider=vmware Mode=${VMWARE_MODE:-vcenter-api} vCenter=${VCENTER_SERVER:-unknown}"
  run_wave_sim "1_NON_CRITICAL_APPS" "${PHASE1[@]}"
  run_wave_sim "2_BUSINESS_APPS" "${PHASE2[@]}"
  run_wave_sim "3_CLUSTER_SUPPORT" "${PHASE3[@]}"
  run_wave_sim "4_CORE_IDENTITY" "${PHASE4[@]}"
  run_wave_sim "5_VCENTER_APPLIANCE" "$VCENTER_VM"
  run_wave_sim "6_ESXI_HOSTS_SIM_ONLY" "${ESXI_HOSTS[@]}"
  log "SIMULATION NOTE: ESXi host shutdown is included in the real workflow only when strict ESXi host shutdown gates are enabled"
  log "SIMULATION NOTE: NetApp/storage shutdown is handled by separate wrapper/orchestrator path"

  if [ -x /usr/local/sbin/nut-power-event-log ]; then
    /usr/local/sbin/nut-power-event-log 'SHUTDOWN_CLASSIFICATION WARN target="VMware" reason="simulation_only_command_not_sent"'
  fi

  if [ -x /usr/local/sbin/nut-publish-power-events-json ]; then
    /usr/local/sbin/nut-publish-power-events-json >/dev/null 2>&1 || true
  fi

  log "SUMMARY PASS"
}

vc_api_login() {
  require_python || return 1

  python3 - <<PY
import requests, sys
server="${VCENTER_SERVER:-}"
user="${VCENTER_USERNAME:-}"
password="${VCENTER_PASSWORD:-}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
if not server or not user or not password:
    print("ERROR:missing vCenter server/user/password")
    sys.exit(1)
url=f"https://{server}/rest/com/vmware/cis/session"
try:
    r=requests.post(url, auth=(user,password), verify=verify, timeout=20)
    r.raise_for_status()
    print(r.json()["value"])
except Exception as e:
    print(f"ERROR:{e}")
    sys.exit(1)
PY
}

vmware_map_lookup() {
  local intended_name="$1"
  local field="${2:-vm_id}"

  if [ ! -f "$VMWARE_VM_MAP_FILE" ]; then
    return 1
  fi

  awk -F'|' -v target="$intended_name" -v field="$field" '
    BEGIN { found=0 }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    $1 == target {
      if (field == "vcenter_name") print $2
      else if (field == "vm_id") print $3
      else if (field == "notes") print $4
      found=1
      exit
    }
    END { if (found == 0) exit 1 }
  ' "$VMWARE_VM_MAP_FILE"
}

vc_api_get_vm_id() {
  local session_id="$1"
  local vm_name="$2"
  local expected_id="${3:-}"

  T04_SERVER="${VCENTER_SERVER:-}" T04_SESSION="$session_id" \
  T04_VM_NAME="$vm_name" T04_EXPECTED_ID="$expected_id" \
  T04_INSECURE="${VCENTER_INSECURE:-1}" python3 - <<'PY_LOOKUP'
import os
import re
import sys
import requests
try:
    response = requests.get(
        "https://" + os.environ["T04_SERVER"] + "/rest/vcenter/vm",
        headers={"vmware-api-session-id": os.environ["T04_SESSION"]},
        verify=os.environ["T04_INSECURE"] != "1", timeout=20,
    )
    response.raise_for_status()
    matches = [vm for vm in response.json()["value"]
               if vm.get("name") == os.environ["T04_VM_NAME"]]
    if len(matches) != 1:
        sys.exit(2)
    vm_id = matches[0].get("vm", "")
    expected = os.environ["T04_EXPECTED_ID"]
    if not re.fullmatch(r"vm-[0-9]+", vm_id) or (expected and expected != vm_id):
        sys.exit(2)
    print(vm_id)
except Exception:
    sys.exit(1)
PY_LOOKUP
}

vc_api_guest_shutdown() {
  local session_id="$1"
  local vm_id="$2"
  local vm_name="$3"

  local detail rc
  detail="$(python3 - <<PY
import requests, sys
server="${VCENTER_SERVER:-}"
session="${session_id}"
vm_id="${vm_id}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
headers={"vmware-api-session-id": session}
url=f"https://{server}/rest/vcenter/vm/{vm_id}/guest/power?action=shutdown"
try:
    r=requests.post(url, headers=headers, verify=verify, timeout=20)
    if 200 <= r.status_code < 300:
        print(f"HTTP_STATUS={r.status_code}")
        sys.exit(0)
    if 400 <= r.status_code < 500 and r.status_code != 408:
        print(f"HTTP_STATUS={r.status_code}")
        sys.exit(3)
    print(f"HTTP_STATUS={r.status_code}")
    sys.exit(2)
except requests.Timeout:
    print("REQUEST_TIMEOUT")
    sys.exit(2)
except requests.RequestException as e:
    print("REQUEST_ERROR=" + type(e).__name__)
    sys.exit(2)
except Exception as e:
    print("REQUEST_ERROR=" + type(e).__name__)
    sys.exit(2)
PY
  )"
  rc=$?
  if [[ "$detail" == HTTP_STATUS=* ]]; then
    log "COMMAND_SENT VMware guest shutdown request reached vCenter vm=${vm_name} ${detail}"
  fi
  if [ "$rc" -eq 0 ]; then
    log "COMMAND_ACCEPTED VMware guest shutdown request accepted vm=${vm_name} ${detail}; physical power-off is not asserted"
  elif [ "$rc" -eq 3 ]; then
    log "COMMAND_FAILED VMware guest shutdown request rejected vm=${vm_name} rc=${rc} ${detail}"
  elif [ "$rc" -eq 2 ]; then
    log "COMMAND_OUTCOME_UNKNOWN VMware guest shutdown request may have been sent vm=${vm_name} rc=${rc} ${detail}"
  else
    log "COMMAND_FAILED VMware guest shutdown request failed before acceptance vm=${vm_name} rc=${rc} ${detail}"
  fi

  return "$rc"
}

vc_api_get_power_state() {
  local session_id="$1"
  local vm_id="$2"
  T04_SERVER="${VCENTER_SERVER:-}" T04_SESSION="$session_id" \
  T04_VM_ID="$vm_id" T04_INSECURE="${VCENTER_INSECURE:-1}" \
  python3 - <<'PY_STATE'
import os
import re
import sys
import requests
try:
    vm_id = os.environ["T04_VM_ID"]
    if not re.fullmatch(r"vm-[0-9]+", vm_id):
        sys.exit(2)
    response = requests.get(
        "https://" + os.environ["T04_SERVER"] + f"/rest/vcenter/vm/{vm_id}/power",
        headers={"vmware-api-session-id": os.environ["T04_SESSION"]},
        verify=os.environ["T04_INSECURE"] != "1", timeout=20,
    )
    response.raise_for_status()
    state = response.json()["value"]["state"]
    if state not in ("POWERED_OFF", "POWERED_ON", "SUSPENDED"):
        sys.exit(2)
    print(state)
except Exception:
    sys.exit(2)
PY_STATE
}

vc_api_detect_vcsa_host() {
  local session_id="${1:-unused}"
  local mapped_vcsa_name expected_vcsa_id vcsa_id placement_json
  mapped_vcsa_name="$(vmware_map_lookup "$VCENTER_VM" vcenter_name 2>/dev/null || true)"
  expected_vcsa_id="$(vmware_map_lookup "$VCENTER_VM" vm_id 2>/dev/null || true)"
  vcsa_id="$(vc_api_get_vm_id "$session_id" "${mapped_vcsa_name:-$VCENTER_VM}" "$expected_vcsa_id" 2>/dev/null)" || {
    log "UNKNOWN VCSA identity is not uniquely resolved or conflicts with the stored mapping"
    return 2
  }

  # Preferred read-only placement path:
  # Bind placement to the uniquely resolved VCSA MoRef; do not use the
  # helper's first case-insensitive name match when duplicate names exist.
  # This does not request guest shutdown, poweroff, reboot, or host shutdown.
  if [ -x /usr/local/sbin/nut-vmware-readonly-placement.py ]; then
    placement_json="$(/usr/local/sbin/nut-vmware-readonly-placement.py --all --json 2>/dev/null)" || return 2
    printf '%s\n' "$placement_json" | T04_VCSA_ID="$vcsa_id" T04_VCSA_NAME="${mapped_vcsa_name:-$VCENTER_VM}" python3 -c '
import json
import os
import sys

try:
    records = json.load(sys.stdin)
    matches = [r for r in records
               if r.get("vm_moref") == os.environ["T04_VCSA_ID"]
               and r.get("name") == os.environ["T04_VCSA_NAME"]]
    if len(matches) != 1:
        sys.exit(2)
    record = matches[0]
    if not record.get("host_name") or not record.get("host_moref"):
        sys.exit(2)
    print(record["host_name"])
except Exception:
    sys.exit(2)
'
    return "$?"
  fi

  # Fallback REST-only placement lookup, using the already unique VM MoRef.
  T04_SERVER="${VCENTER_SERVER:-}" T04_SESSION="$session_id" \
  T04_VM_ID="$vcsa_id" T04_INSECURE="${VCENTER_INSECURE:-1}" python3 - <<'PY2'
import os
import requests, sys
server=os.environ["T04_SERVER"]
verify = os.environ["T04_INSECURE"] != "1"
headers={"vmware-api-session-id": os.environ["T04_SESSION"]}
try:
    detail=requests.get(f"https://{server}/rest/vcenter/vm/{os.environ['T04_VM_ID']}", headers=headers, verify=verify, timeout=20)
    detail.raise_for_status()
    host_id=detail.json().get("value", {}).get("host")
    if not host_id:
        sys.exit(2)

    hosts=requests.get(f"https://{server}/rest/vcenter/host", headers=headers, verify=verify, timeout=20)
    hosts.raise_for_status()
    matches=[item for item in hosts.json().get("value", []) if item.get("host") == host_id]
    if len(matches) != 1 or not matches[0].get("name"):
        sys.exit(2)
    print(matches[0]["name"])
except Exception:
    sys.exit(2)
PY2
}
shutdown_vm_list() {
  local session_id="$1"
  shift
  local vm_name vm_id mapped_name expected_id state shutdown_rc
  local group_failed=0 group_unknown=0

  for vm_name in "$@"; do
    log "CHECK VMware guest identity and current state vm=${vm_name}"
    vm_id="$(vmware_map_lookup "$vm_name" vm_id 2>/dev/null || true)"
    mapped_name="$(vmware_map_lookup "$vm_name" vcenter_name 2>/dev/null || true)"
    expected_id="$vm_id"
    vm_id="$(vc_api_get_vm_id "$session_id" "${mapped_name:-$vm_name}" "$expected_id" 2>/dev/null)" || {
      log "UNKNOWN VMware current VM identity could not be uniquely resolved vm=${vm_name}"
      ups9_checkpoint_record "$vm_name" vmware_guest UNKNOWN "VM identity could not be uniquely resolved" || group_unknown=1
      power_classification "UNKNOWN" "vm_identity_unverified" "vm=\"${vm_name}\""
      group_unknown=1
      continue
    }
    state="$(vc_api_get_power_state "$session_id" "$vm_id" 2>/dev/null)" || {
      log "UNKNOWN VMware guest power state unavailable vm=${vm_name}"
      ups9_checkpoint_record "$vm_name" vmware_guest UNKNOWN "Guest power state unavailable" || group_unknown=1
      power_classification "UNKNOWN" "guest_power_state_unavailable" "vm=\"${vm_name}\""
      group_unknown=1
      continue
    }
    case "$state" in
      POWERED_OFF)
        log "VERIFIED_OFF VMware guest was already POWERED_OFF before this request vm=${vm_name}"
        ups9_checkpoint_record "$vm_name" vmware_guest VERIFIED_OFF "POWERED_OFF observed before a shutdown request" || group_unknown=1
        power_classification "VERIFIED_OFF" "guest_already_powered_off_observed_before_request" "vm=\"${vm_name}\""
        continue
        ;;
      POWERED_ON) ;;
      *)
        log "FAIL VMware guest state is not eligible for graceful shutdown vm=${vm_name} state=${state}"
        ups9_checkpoint_record "$vm_name" vmware_guest FAILED "Guest state was not eligible: ${state}" || group_unknown=1
        power_classification "FAIL" "guest_state_not_powered_on" "vm=\"${vm_name}\""
        group_failed=1
        continue
        ;;
    esac

    log "ATTEMPT VMware guest shutdown for ${vm_name}"
    if ! ups9_checkpoint_record "$vm_name" vmware_guest ATTEMPTED "vCenter guest shutdown request about to be sent"; then
      log "BLOCKED VMware guest request because durable checkpoint attempt could not be recorded vm=${vm_name}"
      group_unknown=1
      continue
    fi
    shutdown_rc=0
    vc_api_guest_shutdown "$session_id" "$vm_id" "${mapped_name:-$vm_name}" || shutdown_rc=$?
    case "$shutdown_rc" in
      0)
        ups9_checkpoint_record "$vm_name" vmware_guest COMMAND_ACCEPTED "vCenter accepted guest shutdown request" 0 || group_unknown=1
        power_classification "COMMAND_ACCEPTED" "guest_shutdown_request_accepted" "vm=\"${vm_name}\""
        ;;
      3)
        ups9_checkpoint_record "$vm_name" vmware_guest COMMAND_FAILED "vCenter rejected guest shutdown request" "$shutdown_rc" || group_unknown=1
        power_classification "COMMAND_FAILED" "guest_shutdown_request_rejected" "vm=\"${vm_name}\" rc=${shutdown_rc}"
        group_failed=1
        ;;
      2)
        ups9_checkpoint_record "$vm_name" vmware_guest UNKNOWN "vCenter guest request outcome ambiguous" "$shutdown_rc" || group_unknown=1
        power_classification "UNKNOWN" "guest_shutdown_request_outcome_unknown" "vm=\"${vm_name}\""
        group_unknown=1
        ;;
      *)
        ups9_checkpoint_record "$vm_name" vmware_guest COMMAND_FAILED "vCenter guest shutdown request failed" "$shutdown_rc" || group_unknown=1
        power_classification "COMMAND_FAILED" "guest_shutdown_request_failed" "vm=\"${vm_name}\" rc=${shutdown_rc}"
        group_failed=1
        ;;
    esac
  done
  [ "$group_failed" -eq 0 ] || return 1
  [ "$group_unknown" -eq 0 ] || return 2
  return 0
}


resolve_vcsa_ssh_endpoint() {
  local vcsa_host="${1:-}" i configured_name match_ip="" matches=0
  local normalized_vcsa
  [ -n "$vcsa_host" ] || return 1
  normalized_vcsa="$(printf '%s' "$vcsa_host" | tr '[:upper:]' '[:lower:]')"
  for i in 0 1 2; do
    configured_name="${ESXI_HOST_NAMES[$i]:-}"
    [ -n "$configured_name" ] || continue
    if [ "$(printf '%s' "$configured_name" | tr '[:upper:]' '[:lower:]')" = "$normalized_vcsa" ]; then
      match_ip="${ESXI_HOSTS[$i]:-}"
      matches=$((matches + 1))
    fi
  done
  [ "$matches" -eq 1 ] && [ -n "$match_ip" ] || return 1
  printf '%s\n' "$match_ip"
}

preflight_esxi_host_shutdown() {
  local vcsa_host="${1:-}" host ip j
  log "SAFETY CHECK: HYPERVISOR_SSH_FALLBACK_CONFIGURED=${HYPERVISOR_SSH_FALLBACK_CONFIGURED:-0}"
  log "SAFETY CHECK: HYPERVISOR_SSH_FALLBACK_ENABLED=${HYPERVISOR_SSH_FALLBACK_ENABLED:-0}"
  log "SAFETY CHECK: VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD=${VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD:-unset}"
  log "SAFETY CHECK: VMWARE_HOST_ACTION_APPROVED=${VMWARE_HOST_ACTION_APPROVED:-0}"
  log "SAFETY CHECK: CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN=${CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN:-0}"
  log "SAFETY CHECK: ALLOW_ESXI_SSH_FALLBACK=${ALLOW_ESXI_SSH_FALLBACK:-0}"

  [ "${HYPERVISOR_SSH_FALLBACK_CONFIGURED:-0}" = "1" ] || { log "BLOCKED ESXi SSH host action: fallback is not configured"; return 10; }
  [ "${HYPERVISOR_SSH_FALLBACK_ENABLED:-0}" = "1" ] || { log "BLOCKED ESXi SSH host action: fallback is disabled"; return 10; }
  [ "${VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD:-}" = "esxi_ssh" ] || { log "BLOCKED ESXi SSH host action: configured method is not esxi_ssh"; return 10; }
  [ "${ALLOW_ESXI_SSH_FALLBACK:-0}" = "1" ] || { log "BLOCKED ESXi SSH host action: mode gate is not approved"; return 10; }
  [ "${VMWARE_HOST_ACTION_APPROVED:-0}" = "1" ] || { log "BLOCKED ESXi SSH host action: target approval is absent"; return 10; }
  [ "${CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN:-0}" = "1" ] || { log "BLOCKED ESXi SSH host action: final confirmation is absent"; return 10; }
  [ -r "${HYPERVISOR_SSH_KEY:-/root/.ssh/id_rsa}" ] || { log "BLOCKED ESXi SSH host action: SSH key is unavailable"; return 10; }
  ip="$(resolve_vcsa_ssh_endpoint "$vcsa_host")" || { log "BLOCKED ESXi host order: current VCSA placement has no unique configured name/IP mapping"; return 10; }
  local any=0 i
  for i in 0 1 2; do
    host="${ESXI_HOSTS[$i]:-}"
    [ -n "$host" ] || continue
    [ -n "${ESXI_HOST_NAMES[$i]:-}" ] || { log "BLOCKED ESXi host order: configured host endpoint lacks an identity name"; return 10; }
    for j in 0 1 2; do
      [ "$j" -gt "$i" ] || continue
      [ -n "${ESXI_HOSTS[$j]:-}" ] || continue
      [ "$host" != "${ESXI_HOSTS[$j]}" ] || { log "BLOCKED ESXi host order: duplicate configured host endpoint"; return 10; }
    done
    any=1
  done
  [ "$any" -eq 1 ] || { log "BLOCKED ESXi host action: no hosts are configured"; return 10; }
  return 0
}

shutdown_esxi_hosts() {
  local vcsa_host="${1:-}" host host_name vcsa_ip i
  local any_host=0 unknown=0 failed=0 accepted=0 rc=0
  local delay="${ESXI_SHUTDOWN_DELAY_SECONDS:-60}"
  local reason="${ESXI_SHUTDOWN_REASON:-power outage}"
  local reason_safe="${reason//\'/ }"
  local ssh_user="${ESXI_SSH_USER:-root}"
  local ssh_key="${HYPERVISOR_SSH_KEY:-/root/.ssh/id_rsa}"
  local ordered_hosts=() ordered_names=()

  log "===== ESXI HOST SHUTDOWN PHASE ====="
  preflight_esxi_host_shutdown "$vcsa_host" || return $?
  vcsa_ip="$(resolve_vcsa_ssh_endpoint "$vcsa_host")" || return 10
  for i in 0 1 2; do
    host="${ESXI_HOSTS[$i]:-}"
    host_name="${ESXI_HOST_NAMES[$i]:-}"
    [ -n "$host" ] || continue
    [ "$host" = "$vcsa_ip" ] && continue
    ordered_hosts+=("$host")
    ordered_names+=("$host_name")
  done
  ordered_hosts+=("$vcsa_ip")
  ordered_names+=("$vcsa_host")

  for i in "${!ordered_hosts[@]}"; do
    host="${ordered_hosts[$i]}"
    host_name="${ordered_names[$i]}"
    any_host=1

    log "ATTEMPT ESXi host shutdown host=${host_name} endpoint=${host} method=ssh command='esxcli system shutdown poweroff'"
    if ! ups9_checkpoint_record "$host_name" esxi_host ATTEMPTED "SSH ESXi shutdown request about to be sent"; then
      unknown=1
      log "BLOCKED ESXi host request because durable checkpoint attempt could not be recorded host=${host_name}"
      break
    fi
    if ssh \
      -o BatchMode=yes \
      -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=accept-new \
      -i "$ssh_key" \
      "${ssh_user}@${host}" \
      "esxcli system shutdown poweroff -d ${delay} -r '${reason_safe}'" >> "$LOG_FILE" 2>&1; then
      accepted=$((accepted + 1))
      log "COMMAND_ACCEPTED ESXi host shutdown request accepted host=${host_name}; physical host-off is not asserted"
      if ! ups9_checkpoint_record "$host_name" esxi_host COMMAND_ACCEPTED "SSH accepted ESXi shutdown request; physical host-off not verified" 0; then
        unknown=1
        break
      fi
      power_classification "COMMAND_ACCEPTED" "esxi_host_shutdown_request_accepted" "host=\"${host_name}\""
    else
      rc=$?
      unknown=1
      log "COMMAND_OUTCOME_UNKNOWN ESXi host SSH result host=${host_name} rc=${rc}; no retry"
      if ! ups9_checkpoint_record "$host_name" esxi_host UNKNOWN "SSH outcome ambiguous; no retry" "$rc"; then
        log "BLOCKED remaining ESXi host requests because ambiguous outcome could not be durably recorded"
        break
      fi
      power_classification "UNKNOWN" "esxi_host_ssh_outcome_unknown" "host=\"${host_name}\" command_rc=${rc}"
    fi
  done

  if [ "$any_host" -ne 1 ]; then
    log "ERROR ESXi host shutdown blocked: no ESXi hosts are configured"
    power_classification "FAIL" "esxi_host_shutdown_blocked_no_hosts_configured"
    return 2
  fi

  [ "$unknown" -eq 0 ] || return 2
  [ "$failed" -eq 0 ] || return 1
  [ "$accepted" -eq "${#ordered_hosts[@]}" ] || return 2
  # Keep the established host/storage interlock. SSH acceptance is a command
  # result only and does not establish that dependent storage is safe to stop.
  log "BLOCKED dependent storage: no supported physical host-off confirmation source is available"
  power_classification "BLOCKED" "host_off_dependency_not_confirmed"
  return 11
}


real_shutdown_domain() {
  local workflow_failed=0 workflow_unknown=0 guest_rc=0 host_rc=0
  log "MODE: REAL / LIVE"
  log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
  log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
  log "SAFETY CHECK: VMWARE_LIVE_APPROVED=${VMWARE_LIVE_APPROVED:-0}"
  log "SCOPE: vCenter guest shutdown followed by gated ESXi host shutdown"

  if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
    log "ERROR VMware live shutdown blocked: ALLOW_REAL_TEST is not 1"
    power_classification "FAIL" "blocked_allow_real_test_not_set"
    exit 2
  fi

  if [ "${REAL_TEST_PHASE:-}" != "full-production" ] && [ "${REAL_TEST_PHASE:-}" != "phase-vmware" ]; then
    log "ERROR VMware live shutdown blocked: REAL_TEST_PHASE is not approved for VMware"
    power_classification "FAIL" "blocked_wrong_real_test_phase" "phase=\"${REAL_TEST_PHASE:-unset}\""
    exit 2
  fi

  if [ "${VMWARE_LIVE_APPROVED:-0}" != "1" ]; then
    log "ERROR VMware live shutdown blocked: VMWARE_LIVE_APPROVED is not 1"
    power_classification "FAIL" "blocked_vmware_live_not_approved"
    exit 2
  fi

  log "APPROVED: starting VMware vCenter guest shutdown workflow"

  local session_id
  session_id="$(vc_api_login 2>/dev/null)"
  local rc=$?

  if [ "$rc" -ne 0 ] || [[ "$session_id" == ERROR:* ]] || [ -z "$session_id" ]; then
    log "ERROR unable to login to vCenter API"
    power_classification "FAIL" "vcenter_api_login_failed"
    exit 1
  fi

  local vcsa_host=""
  if ! vcsa_host="$(vc_api_detect_vcsa_host "$session_id" 2>/dev/null)" || [ -z "$vcsa_host" ]; then
    log "UNKNOWN current VCSA host placement could not be resolved; no guest or host request sent"
    power_classification "UNKNOWN" "vcsa_current_host_unresolved"
    exit 2
  fi
  log "Detected ${VCENTER_VM} current host placement: ${vcsa_host}"

  # Validate the existing host approval/configuration and exact current-name
  # mapping before any guest request can leave the terminal workflow half-run.
  preflight_esxi_host_shutdown "$vcsa_host" || exit 10

  UPS9_CHECKPOINT_REQUIRED=1
  if [ ! -x "$UPS9_CHECKPOINT_CLI" ]; then
    log "BLOCKED UPS9 durable checkpoint helper unavailable; no VMware guest request sent"
    power_classification "BLOCKED" "ups9_checkpoint_helper_unavailable"
    exit 10
  fi
  local checkpoint_args=() checkpoint_guest checkpoint_host
  for checkpoint_guest in "${PHASE1[@]}" "${PHASE2[@]}" "${PHASE3[@]}" "${PHASE4[@]}" "$VCENTER_VM"; do
    checkpoint_args+=(--guest "$checkpoint_guest")
  done
  for checkpoint_host in "${ESXI_HOST_NAMES[@]}"; do
    [ -n "$checkpoint_host" ] && checkpoint_args+=(--host "$checkpoint_host")
  done
  UPS9_SEQUENCE_ID="$("$UPS9_CHECKPOINT_CLI" begin --vcsa-host "$vcsa_host" "${checkpoint_args[@]}")" || {
    log "BLOCKED UPS9 checkpoint creation failed; no VMware guest request sent"
    power_classification "BLOCKED" "ups9_checkpoint_creation_failed"
    exit 10
  }
  [ -n "$UPS9_SEQUENCE_ID" ] || { log "BLOCKED UPS9 checkpoint returned no sequence ID"; exit 10; }
  export UPS9_SEQUENCE_ID UPS9_CHECKPOINT_REQUIRED
  log "UPS9_CHECKPOINT_CREATED sequence_id=${UPS9_SEQUENCE_ID} status=VMWARE_DISPATCHING"

  # Preserve configured guest order and attempt each independent request once.
  # A failed/unknown guest result does not suppress later guest requests, but it
  # prevents host shutdown because a guest may still depend on that host.
  shutdown_vm_list "$session_id" "${PHASE1[@]}" || { guest_rc=$?; [ "$guest_rc" -eq 2 ] && workflow_unknown=1 || workflow_failed=1; }
  shutdown_vm_list "$session_id" "${PHASE2[@]}" || { guest_rc=$?; [ "$guest_rc" -eq 2 ] && workflow_unknown=1 || workflow_failed=1; }
  shutdown_vm_list "$session_id" "${PHASE3[@]}" || { guest_rc=$?; [ "$guest_rc" -eq 2 ] && workflow_unknown=1 || workflow_failed=1; }
  shutdown_vm_list "$session_id" "${PHASE4[@]}" || { guest_rc=$?; [ "$guest_rc" -eq 2 ] && workflow_unknown=1 || workflow_failed=1; }
  if ! vcsa_host="$(vc_api_detect_vcsa_host "$session_id" 2>/dev/null)" || [ -z "$vcsa_host" ]; then
    log "UNKNOWN current VCSA placement unavailable immediately before VCSA shutdown; VCSA and host requests not sent"
    ups9_checkpoint_finish UNKNOWN "VCSA current placement unavailable before final guest stage" 2 || true
    power_classification "UNKNOWN" "vcsa_current_host_refresh_unavailable"
    exit 2
  fi
  if ! resolve_vcsa_ssh_endpoint "$vcsa_host" >/dev/null; then
    log "BLOCKED current VCSA host has no unique approved SSH endpoint; VCSA and host requests not sent"
    ups9_checkpoint_finish BLOCKED "VCSA host endpoint unresolved before final guest stage" 10 || true
    power_classification "BLOCKED" "vcsa_current_host_ssh_endpoint_unresolved"
    exit 10
  fi
  # VCSA is deliberately last in the configured guest request order.
  shutdown_vm_list "$session_id" "$VCENTER_VM" || { [ "$?" -eq 2 ] && workflow_unknown=1 || workflow_failed=1; }

  if [ "$workflow_unknown" -ne 0 ]; then
    log "COMMAND_OUTCOME_UNKNOWN VMware guest sequence contains an unresolved target; ESXi and dependent storage stages blocked"
    ups9_checkpoint_finish UNKNOWN "VMware guest dispatch had unknown or unpersisted outcome" 2 || true
    power_classification "UNKNOWN" "vmware_guest_command_outcome_unknown"
    exit 2
  fi
  if [ "$workflow_failed" -ne 0 ] || [ "$guest_rc" -ne 0 ]; then
    log "COMMAND_FAILED VMware guest sequence contains a rejected or unissued target; ESXi and dependent storage stages blocked"
    ups9_checkpoint_finish FAILED "VMware guest dispatch failed; host and storage stages blocked" 1 || true
    power_classification "FAIL" "vmware_guest_command_sequence_incomplete"
    exit 1
  fi

  log "COMMANDS_ACCEPTED VMware guest shutdown requests accepted or target was already POWERED_OFF; no post-request power-off claim"
  power_classification "COMMAND_ACCEPTED" "vmware_guest_commands_accepted_not_independently_verified"

  host_rc=0
  shutdown_esxi_hosts "$vcsa_host" || host_rc=$?
  case "$host_rc" in
    0) exit 0 ;;
    11)
      log "COMMANDS_ACCEPTED_DEPENDENCY_UNRESOLVED VMware SSH host requests were accepted; storage interlock remains closed without supported host-off evidence"
      if ! "$UPS9_CHECKPOINT_CLI" pending-host-verification --sequence "$UPS9_SEQUENCE_ID" >/dev/null; then
        ups9_checkpoint_finish UNKNOWN "Host requests completed but pending-verification checkpoint failed" 2 || true
        exit 2
      fi
      exit 11
      ;;
    10) ups9_checkpoint_finish BLOCKED "ESXi host preflight blocked" 10 || true; exit 10 ;;
    2) ups9_checkpoint_finish UNKNOWN "ESXi host request outcome unknown" 2 || true; exit 2 ;;
    *) ups9_checkpoint_finish FAILED "ESXi host request failed" "$host_rc" || true; exit 1 ;;
  esac
}

real_detect_vcsa_host() {
  log "MODE: REAL / LIVE VCSA HOST DETECT"
  log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"

  if [ "${ALLOW_REAL_TEST:-0}" != "1" ]; then
    log "ERROR VMware VCSA detect blocked: ALLOW_REAL_TEST is not 1"
    exit 2
  fi

  local session_id
  session_id="$(vc_api_login 2>/dev/null)" || exit 1
  vc_api_detect_vcsa_host "$session_id"
}

case "$ACTION" in
  shutdown_domain)
    if [ "$SIMULATE" = "1" ]; then
      simulate_shutdown_domain
    else
      real_shutdown_domain
    fi
    ;;
  detect_vcsa_host)
    if [ "$SIMULATE" = "1" ]; then
      log "SIMULATED detect VCSA host"
      exit 0
    else
      real_detect_vcsa_host
    fi
    ;;
  *)
    log "ERROR unknown action: $ACTION"
    exit 1
    ;;
esac
