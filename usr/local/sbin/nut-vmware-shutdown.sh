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

ESXI_HOSTS=(
"192.168.99.84"
"192.168.99.72"
"192.168.99.71"
"192.168.99.70"
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
  log "SIMULATION NOTE: ESXi host shutdown is listed for Wave 2 visibility only; real ESXi shutdown is not implemented in this wrapper"
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
  local session_id="$1"

  python3 - <<PY
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
        if item.get("name") == vcsa_name:
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
PY
}

shutdown_vm_list() {
  local session_id="$1"
  shift
  local vm_name
  local vm_id
  local rc=0

  for vm_name in "$@"; do
    log "ATTEMPT VMware guest shutdown for ${vm_name}"
    vm_id="$(vc_api_get_vm_id "$session_id" "$vm_name" 2>/dev/null)"
    rc=$?

    if [ "$rc" -ne 0 ] || [ -z "$vm_id" ]; then
      log "ERROR could not find VM id for ${vm_name}"
      power_classification "FAIL" "vm_id_not_found" "vm=\"${vm_name}\""
      continue
    fi

    vc_api_guest_shutdown "$session_id" "$vm_id" "$vm_name"
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

real_shutdown_domain() {
  log "MODE: REAL / LIVE"
  log "SAFETY CHECK: ALLOW_REAL_TEST=${ALLOW_REAL_TEST:-0}"
  log "SAFETY CHECK: REAL_TEST_PHASE=${REAL_TEST_PHASE:-unset}"
  log "SAFETY CHECK: VMWARE_LIVE_APPROVED=${VMWARE_LIVE_APPROVED:-0}"
  log "SCOPE: vCenter guest shutdown only; ESXi host shutdown not implemented here"

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

  log "VMWARE_HOST_SHUTDOWN_NOT_IMPLEMENTED"
  power_classification "WARN" "esxi_host_shutdown_not_implemented"
  log "SUCCESS VMware vCenter guest shutdown workflow completed"
  power_classification "WARN" "workflow_completed_guest_shutdowns_requested_not_verified"
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
