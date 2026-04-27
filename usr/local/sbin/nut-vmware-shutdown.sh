#!/usr/bin/env bash
set -u

LOG_FILE="/var/log/nut-vmware-shutdown.log"
CONFIG_FILE="/etc/nut/nut-orchestrator.conf"
SIMULATE="${SIMULATE:-1}"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

[ -f "$CONFIG_FILE" ] || { log "ERROR config missing"; exit 1; }
. "$CONFIG_FILE"

ACTION="${1:-shutdown_domain}"

# =========================
# REAL ENVIRONMENT PLAN
# =========================

PHASE1=(
"192.168.1.75"
"192.168.1.150"
"192.168.99.86"
"192.168.1.23"
"192.168.1.21"
"192.168.1.20"
"192.168.3.250"
"192.168.99.92"
"192.168.99.88"
"192.168.1.230"
"192.168.1.14"
)

PHASE2=(
"192.168.99.70"
"192.168.99.72"
"192.168.99.71"
)

VCENTER_VM="192.168.99.84"

HOSTS=(
"192.168.99.62"
"192.168.99.61"
"192.168.99.60"
)

run_wave() {
  for t in "$@"; do
    log ""
    log "TARGET: $t"
    log "MODE: SIMULATED / DRY-RUN"
    log "ACTION: would shutdown $t"
    log "PASS $t simulated execution OK"
  done
}

simulate() {
  log "===== VMWARE SHUTDOWN PLAN ====="

  run_wave "${PHASE1[@]}"
  run_wave "${PHASE2[@]}"

  log ""
  log "TARGET: ${VCENTER_VM}"
  log "MODE: SIMULATED / DRY-RUN"
  log "ACTION: would shutdown vCenter"
  log "PASS ${VCENTER_VM} simulated execution OK"

  run_wave "${HOSTS[@]}"

  log "SUMMARY PASS"
}

if [ "$SIMULATE" != "1" ]; then
  log "ERROR: real execution not yet implemented"
  exit 2
fi

case "$ACTION" in
  shutdown_domain) simulate ;;
  detect_vcsa_host) log "SIMULATED detect VCSA host"; exit 0 ;;
  *) log "Unknown action"; exit 1 ;;
esac
