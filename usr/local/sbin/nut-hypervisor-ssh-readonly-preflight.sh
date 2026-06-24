#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -euo pipefail

CONFIG="/etc/nut/hypervisors/hypervisor-ssh-fallback.conf"
OUT_DIR="/var/log/nut-vmware-inventory"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="${OUT_DIR}/hypervisor-ssh-readonly-preflight-${STAMP}.txt"
LATEST_FILE="${OUT_DIR}/hypervisor-ssh-readonly-preflight-latest.txt"

MODE="${1:-summary}"

mkdir -p "$OUT_DIR"

log() {
  echo "$*" | tee -a "$OUT_FILE"
}

if [ ! -f "$CONFIG" ]; then
  echo "FAIL: missing config: $CONFIG"
  exit 2
fi

# shellcheck disable=SC1090
. "$CONFIG"

SSH_KEY="${HYPERVISOR_SSH_KEY:-/root/.ssh/nut_hypervisor_shutdown_ed25519}"

run_ssh_readonly() {
  local provider="$1"
  local user="$2"
  local host="$3"
  local label="$4"
  local command="$5"

  log
  log "----- ${provider}: ${host}: ${label} -----"
  log "READ_ONLY_COMMAND: ${command}"

  if [ "$host" = "UNKNOWN" ] || [ -z "$host" ]; then
    log "SKIP: host is UNKNOWN"
    return 0
  fi

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=8 \
    -o StrictHostKeyChecking=yes \
    -i "$SSH_KEY" \
    "${user}@${host}" \
    "$command" 2>&1 | tee -a "$OUT_FILE" || {
      log "WARN: SSH unavailable or read-only command failed for ${provider} host ${host}: ${label}"
      return 1
    }
}

run_esxi_host() {
  local host="$1"
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "hostname" "hostname" || true
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "vmware version" "vmware -v" || true
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "esxcli system version" "esxcli system version get" || true
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "esxcli system hostname" "esxcli system hostname get" || true
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "registered VMs" "vim-cmd vmsvc/getallvms" || true
  run_ssh_readonly "ESXi" "$ESXI_SSH_USER" "$host" "running VM processes" "esxcli vm process list" || true
}

run_proxmox_host() {
  local host="$1"
  run_ssh_readonly "Proxmox" "$PROXMOX_SSH_USER" "$host" "hostname" "hostname" || true
  run_ssh_readonly "Proxmox" "$PROXMOX_SSH_USER" "$host" "pve version" "pveversion" || true
  run_ssh_readonly "Proxmox" "$PROXMOX_SSH_USER" "$host" "node status" "pvesh get /nodes" || true
  run_ssh_readonly "Proxmox" "$PROXMOX_SSH_USER" "$host" "VM list" "qm list" || true
  run_ssh_readonly "Proxmox" "$PROXMOX_SSH_USER" "$host" "container list" "pct list" || true
}

log "===== HYPERVISOR SSH READ-ONLY PREFLIGHT ====="
log "generated_at=$(date -Is)"
log "mode=${MODE}"
log "safety=no_vm_shutdown_no_host_shutdown_no_maintenance_mode_no_poweroff_no_reboot"
log "config=${CONFIG}"
log "ssh_key=${SSH_KEY}"
log "fallback_configured=${HYPERVISOR_SSH_FALLBACK_CONFIGURED:-0}"
log "fallback_enabled=${HYPERVISOR_SSH_FALLBACK_ENABLED:-0}"
log

if [ ! -r "$SSH_KEY" ]; then
  log "WARN: SSH key not readable: $SSH_KEY"
  log "No SSH commands attempted."
  cp -f "$OUT_FILE" "$LATEST_FILE"
  exit 1
fi

case "$MODE" in
  summary)
    log "Summary only. No SSH commands attempted."
    log "ESXi candidate IPs: ${ESXI_CANDIDATE_IP_1:-UNKNOWN}, ${ESXI_CANDIDATE_IP_2:-UNKNOWN}, ${ESXI_CANDIDATE_IP_3:-UNKNOWN}"
    log "ESXi mapped IPs: ${ESXI_HOST_01_IP:-UNKNOWN}, ${ESXI_HOST_02_IP:-UNKNOWN}, ${ESXI_HOST_03_IP:-UNKNOWN}"
    log "Proxmox mapped IPs: ${PROXMOX_HOST_01_IP:-UNKNOWN}, ${PROXMOX_HOST_02_IP:-UNKNOWN}, ${PROXMOX_HOST_03_IP:-UNKNOWN}"
    ;;
  esxi)
    run_esxi_host "${ESXI_HOST_01_IP:-UNKNOWN}"
    run_esxi_host "${ESXI_HOST_02_IP:-UNKNOWN}"
    run_esxi_host "${ESXI_HOST_03_IP:-UNKNOWN}"
    ;;
  esxi-candidates)
    run_esxi_host "${ESXI_CANDIDATE_IP_1:-UNKNOWN}"
    run_esxi_host "${ESXI_CANDIDATE_IP_2:-UNKNOWN}"
    run_esxi_host "${ESXI_CANDIDATE_IP_3:-UNKNOWN}"
    ;;
  proxmox)
    run_proxmox_host "${PROXMOX_HOST_01_IP:-UNKNOWN}"
    run_proxmox_host "${PROXMOX_HOST_02_IP:-UNKNOWN}"
    run_proxmox_host "${PROXMOX_HOST_03_IP:-UNKNOWN}"
    ;;
  *)
    log "FAIL: unknown mode: $MODE"
    log "Valid modes: summary, esxi, esxi-candidates, proxmox"
    cp -f "$OUT_FILE" "$LATEST_FILE"
    exit 2
    ;;
esac

log
log "===== COMPLETE ====="
log "No maintenance mode command was sent."
log "No shutdown command was sent."
log "No poweroff command was sent."
log "No reboot command was sent."
log "No VM power command was sent."

cp -f "$OUT_FILE" "$LATEST_FILE"
