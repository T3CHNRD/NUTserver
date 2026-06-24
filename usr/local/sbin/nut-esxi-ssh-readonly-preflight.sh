#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="/var/log/nut-vmware-inventory"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="${OUT_DIR}/esxi-ssh-readonly-preflight-${STAMP}.txt"
LATEST_FILE="${OUT_DIR}/esxi-ssh-readonly-preflight-latest.txt"

ESXI_USER="${ESXI_USER:-root}"
SSH_KEY="${ESXI_SSH_KEY:-/root/.ssh/id_rsa}"

HOSTS=(
  "alblvmhost01.albl.com"
  "alblvmhost02.albl.com"
  "alblvmhost03.albl.com"
)

mkdir -p "$OUT_DIR"

log() {
  echo "$*" | tee -a "$OUT_FILE"
}

run_readonly() {
  local host="$1"
  local label="$2"
  local command="$3"

  log
  log "----- ${host}: ${label} -----"
  log "READ_ONLY_COMMAND: ${command}"

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=8 \
    -o StrictHostKeyChecking=yes \
    -i "$SSH_KEY" \
    "${ESXI_USER}@${host}" \
    "$command" 2>&1 | tee -a "$OUT_FILE" || {
      log "WARN: command failed or SSH unavailable for ${host}: ${label}"
      return 1
    }
}

log "===== ESXI SSH READ-ONLY PREFLIGHT ====="
log "generated_at=$(date -Is)"
log "mode=READ_ONLY"
log "safety=no_vm_shutdown_no_host_shutdown_no_maintenance_mode"
log "esxi_user=${ESXI_USER}"
log "ssh_key=${SSH_KEY}"
log

if [ ! -r "$SSH_KEY" ]; then
  log "WARN: SSH key not readable: $SSH_KEY"
  log "No SSH commands will be attempted."
  cp -f "$OUT_FILE" "$LATEST_FILE"
  exit 1
fi

for host in "${HOSTS[@]}"
do
  log
  log "===== HOST: ${host} ====="

  run_readonly "$host" "hostname" "hostname" || true
  run_readonly "$host" "vmware version" "vmware -v" || true
  run_readonly "$host" "esxcli system version" "esxcli system version get" || true
  run_readonly "$host" "esxcli system hostname" "esxcli system hostname get" || true
  run_readonly "$host" "registered VMs" "vim-cmd vmsvc/getallvms" || true
  run_readonly "$host" "running VM processes" "esxcli vm process list" || true
done

log
log "===== COMPLETE ====="
log "No maintenance mode command was sent."
log "No shutdown command was sent."
log "No VM power command was sent."
log "No destructive command was sent."

cp -f "$OUT_FILE" "$LATEST_FILE"
