#!/bin/bash
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
)

PHASE2=(
"Albl-exch2019"
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

  python3 - <<PY
import requests, sys
server="${VCENTER_SERVER:-}"
session="${session_id}"
vm_name="${vm_name}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
headers={"vmware-api-session-id": session}
try:
    r=requests.get(f"https://{server}/rest/vcenter/vm", headers=headers, verify=verify, timeout=20)
    r.raise_for_status()
    for item in r.json().get("value", []):
        if item.get("name") == vm_name:
            print(item.get("vm"))
            sys.exit(0)
    sys.exit(2)
except Exception as e:
    print(f"ERROR:{e}")
    sys.exit(1)
PY
}

vc_api_guest_shutdown() {
  local session_id="$1"
  local vm_id="$2"
  local vm_name="$3"

  python3 - <<PY
import requests, sys
server="${VCENTER_SERVER:-}"
session="${session_id}"
vm_id="${vm_id}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
headers={"vmware-api-session-id": session}
url=f"https://{server}/rest/vcenter/vm/{vm_id}/guest/power?action=shutdown"
try:
    r=requests.post(url, headers=headers, verify=verify, timeout=20)
    if r.status_code in (200, 204):
        sys.exit(0)
    if r.status_code == 400:
        sys.exit(3)
    r.raise_for_status()
    sys.exit(0)
except Exception:
    sys.exit(1)
PY

  local rc=$?
  if [ "$rc" -eq 0 ]; then
    log "SUCCESS vCenter API guest shutdown requested for ${vm_name}"
  elif [ "$rc" -eq 3 ]; then
    log "WARN vCenter API could not guest-shutdown ${vm_name}; VMware Tools/state issue possible"
  else
    log "ERROR vCenter API guest shutdown failed for ${vm_name}"
  fi

  return "$rc"
}

vc_api_detect_vcsa_host() {
  local session_id="${1:-unused}"

  # Preferred read-only placement path:
  # Uses pyVmomi helper to resolve VM runtime host placement.
  # This does not request guest shutdown, poweroff, reboot, or host shutdown.
  if [ -x /usr/local/sbin/nut-vmware-readonly-placement.py ]; then
    /usr/local/sbin/nut-vmware-readonly-placement.py --vm "$VCENTER_VM" --json | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
    host = data.get("host_name")
    if not host:
        sys.exit(3)
    print(host)
except Exception:
    sys.exit(1)
'
    return "$?"
  fi

  # Fallback legacy REST-only detection.
  python3 - <<PY2
import requests, sys
server="${VCENTER_SERVER:-}"
session="${session_id}"
vcsa_name="${VCENTER_VM}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
headers={"vmware-api-session-id": session}
try:
    vms=requests.get(f"https://{server}/rest/vcenter/vm", headers=headers, verify=verify, timeout=20)
    vms.raise_for_status()
    vcsa_id=None
    for item in vms.json().get("value", []):
        if item.get("name", "").lower() == vcsa_name.lower():
            vcsa_id=item.get("vm")
            break
    if not vcsa_id:
        sys.exit(2)

    detail=requests.get(f"https://{server}/rest/vcenter/vm/{vcsa_id}", headers=headers, verify=verify, timeout=20)
    detail.raise_for_status()
    host_id=detail.json().get("value", {}).get("host")
    if not host_id:
        sys.exit(3)

    hosts=requests.get(f"https://{server}/rest/vcenter/host", headers=headers, verify=verify, timeout=20)
    hosts.raise_for_status()
    for item in hosts.json().get("value", []):
        if item.get("host") == host_id:
            print(item.get("name"))
            sys.exit(0)
    sys.exit(4)
except Exception:
    sys.exit(1)
PY2
}
shutdown_vm_list() {
  local session_id="$1"
  shift
  local vm_name
  local vm_id
  local rc=0

  for vm_name in "$@"; do
    log "ATTEMPT VMware guest shutdown for ${vm_name}"
    vm_id="$(vmware_map_lookup "$vm_name" vm_id 2>/dev/null || true)"
    mapped_name="$(vmware_map_lookup "$vm_name" vcenter_name 2>/dev/null || true)"

    if [ -n "$vm_id" ]; then
      log "MAPPED ${vm_name} -> ${mapped_name:-unknown} (${vm_id})"
    else
      vm_id="$(vc_api_get_vm_id "$session_id" "$vm_name" 2>/dev/null)"
      rc=$?

      if [ "$rc" -ne 0 ] || [ -z "$vm_id" ]; then
        log "ERROR could not find VM id for ${vm_name}"
        power_classification "FAIL" "vm_id_not_found" "vm=\"${vm_name}\""
        continue
      fi
    fi

    vc_api_guest_shutdown "$session_id" "$vm_id" "${mapped_name:-$vm_name}"
    shutdown_rc="$?"

    case "$shutdown_rc" in
      0)
        power_classification "WARN" "guest_shutdown_requested_not_verified" "vm=\"${vm_name}\""
        ;;
      3)
        power_classification "WARN" "guest_shutdown_tools_or_state_issue" "vm=\"${vm_name}\""
        ;;
      *)
        power_classification "FAIL" "guest_shutdown_command_failed" "vm=\"${vm_name}\" command_rc=${shutdown_rc}"
        ;;
    esac
    sleep 5
  done
}


shutdown_esxi_hosts() {
  local host
  local any_host=0
  local failed=0
  local rc=0
  local delay="${ESXI_SHUTDOWN_DELAY_SECONDS:-60}"
  local reason="${ESXI_SHUTDOWN_REASON:-power outage}"
  local reason_safe="${reason//\'/ }"
  local ssh_user="${ESXI_SSH_USER:-root}"
  local ssh_key="${HYPERVISOR_SSH_KEY:-/root/.ssh/id_rsa}"

  log "===== ESXI HOST SHUTDOWN PHASE ====="
  log "SAFETY CHECK: HYPERVISOR_SSH_FALLBACK_CONFIGURED=${HYPERVISOR_SSH_FALLBACK_CONFIGURED:-0}"
  log "SAFETY CHECK: HYPERVISOR_SSH_FALLBACK_ENABLED=${HYPERVISOR_SSH_FALLBACK_ENABLED:-0}"
  log "SAFETY CHECK: VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD=${VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD:-unset}"
  log "SAFETY CHECK: VMWARE_HOST_ACTION_APPROVED=${VMWARE_HOST_ACTION_APPROVED:-0}"
  log "SAFETY CHECK: CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN=${CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN:-0}"
  log "SAFETY CHECK: ALLOW_ESXI_SSH_FALLBACK=${ALLOW_ESXI_SSH_FALLBACK:-0}"

  if [ "${HYPERVISOR_SSH_FALLBACK_CONFIGURED:-0}" != "1" ]; then
    log "ERROR ESXi host shutdown blocked: fallback config is not marked configured"
    power_classification "FAIL" "esxi_host_shutdown_blocked_not_configured"
    return 2
  fi

  if [ "${HYPERVISOR_SSH_FALLBACK_ENABLED:-0}" != "1" ]; then
    log "ERROR ESXi host shutdown blocked: HYPERVISOR_SSH_FALLBACK_ENABLED is not 1"
    power_classification "FAIL" "esxi_host_shutdown_blocked_fallback_disabled"
    return 2
  fi

  if [ "${VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD:-}" != "esxi_ssh" ]; then
    log "ERROR ESXi host shutdown blocked: VMWARE_FALLBACK_HOST_SHUTDOWN_METHOD is not esxi_ssh"
    power_classification "FAIL" "esxi_host_shutdown_blocked_wrong_method"
    return 2
  fi

  if [ "${ALLOW_ESXI_SSH_FALLBACK:-0}" != "1" ]; then
    log "ERROR ESXi host shutdown blocked: ALLOW_ESXI_SSH_FALLBACK is not 1"
    power_classification "FAIL" "esxi_host_shutdown_blocked_mode_gate"
    return 2
  fi

  if [ "${VMWARE_HOST_ACTION_APPROVED:-0}" != "1" ]; then
    log "ERROR ESXi host shutdown blocked: VMWARE_HOST_ACTION_APPROVED is not 1"
    power_classification "FAIL" "esxi_host_shutdown_blocked_host_action_not_approved"
    return 2
  fi

  if [ "${CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN:-0}" != "1" ]; then
    log "ERROR ESXi host shutdown blocked: CONFIRM_POWER_OUTAGE_HOST_SHUTDOWN is not 1"
    power_classification "FAIL" "esxi_host_shutdown_blocked_missing_final_confirmation"
    return 2
  fi

  if [ ! -r "$ssh_key" ]; then
    log "ERROR ESXi host shutdown blocked: SSH key is not readable"
    power_classification "FAIL" "esxi_host_shutdown_blocked_ssh_key_unreadable"
    return 2
  fi

  for host in "${ESXI_HOSTS[@]}"; do
    [ -n "$host" ] || continue
    any_host=1

    log "ATTEMPT ESXi host shutdown host=${host} method=ssh command='esxcli system shutdown poweroff'"
    if ssh \
      -o BatchMode=yes \
      -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=accept-new \
      -i "$ssh_key" \
      "${ssh_user}@${host}" \
      "esxcli system shutdown poweroff -d ${delay} -r '${reason_safe}'" >> "$LOG_FILE" 2>&1; then
      log "SUCCESS ESXi host shutdown command accepted host=${host}"
      power_classification "WARN" "esxi_host_shutdown_command_accepted_not_verified" "host=\"${host}\""
    else
      rc=$?
      failed=1
      log "ERROR ESXi host shutdown command failed host=${host} rc=${rc}"
      power_classification "FAIL" "esxi_host_shutdown_command_failed" "host=\"${host}\" command_rc=${rc}"
    fi
  done

  if [ "$any_host" -ne 1 ]; then
    log "ERROR ESXi host shutdown blocked: no ESXi hosts are configured"
    power_classification "FAIL" "esxi_host_shutdown_blocked_no_hosts_configured"
    return 2
  fi

  if [ "$failed" -ne 0 ]; then
    return 1
  fi

  return 0
}


real_shutdown_domain() {
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
  vcsa_host="$(vc_api_detect_vcsa_host "$session_id" 2>/dev/null)" || true
  if [ -n "$vcsa_host" ]; then
    log "Detected ${VCENTER_VM} currently on host: ${vcsa_host}"
  else
    log "WARN could not dynamically detect ${VCENTER_VM} host"
  fi

  shutdown_vm_list "$session_id" "${PHASE1[@]}"
  shutdown_vm_list "$session_id" "${PHASE2[@]}"
  shutdown_vm_list "$session_id" "${PHASE3[@]}"
  shutdown_vm_list "$session_id" "${PHASE4[@]}"
  shutdown_vm_list "$session_id" "$VCENTER_VM"

  log "VMWARE_GUEST_SHUTDOWN_PHASE_COMPLETE"
  power_classification "WARN" "workflow_guest_shutdowns_requested_not_verified"

  if shutdown_esxi_hosts; then
    log "SUCCESS VMware ESXi host shutdown phase completed"
  else
    rc=$?
    log "ERROR VMware ESXi host shutdown phase failed or was blocked rc=${rc}"
    exit "$rc"
  fi

  log "SUCCESS VMware vCenter guest plus ESXi host shutdown workflow completed"
  power_classification "WARN" "workflow_completed_guest_and_host_shutdowns_requested_not_verified"
  exit 0
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
