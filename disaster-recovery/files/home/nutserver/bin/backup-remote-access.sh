#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%F-%H%M%S)"
BASE="/var/backups/remote-access/${STAMP}"

echo "[INFO] Creating backup at ${BASE}"
sudo mkdir -p "${BASE}"/{etc/systemd/system,etc/xrdp,etc/X11,home/nutserver/.vnc,home/rdpadmin,var/log}

backup_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    sudo cp -a "$src" "$dst"
  fi
}

backup_if_exists /etc/systemd/system/tigervnc-backup.service "${BASE}/etc/systemd/system/"
backup_if_exists /etc/systemd/system/x11vnc.service "${BASE}/etc/systemd/system/"
backup_if_exists /etc/xrdp "${BASE}/etc/"
backup_if_exists /etc/X11/Xwrapper.config "${BASE}/etc/X11/"
backup_if_exists /home/nutserver/.vnc "${BASE}/home/nutserver/"
backup_if_exists /home/nutserver/.config/autostart "${BASE}/home/nutserver/.config/"
backup_if_exists /home/rdpadmin/.xsession "${BASE}/home/rdpadmin.xsession"
backup_if_exists /home/nutserver/.xsession "${BASE}/home/nutserver.xsession"

sudo systemctl cat tigervnc-backup.service > "${BASE}/tigervnc-backup.systemctl-cat.txt" 2>/dev/null || true
sudo systemctl cat xrdp > "${BASE}/xrdp.systemctl-cat.txt" 2>/dev/null || true
sudo systemctl cat xrdp-sesman > "${BASE}/xrdp-sesman.systemctl-cat.txt" 2>/dev/null || true

sudo systemctl status xrdp xrdp-sesman tigervnc-backup.service --no-pager -l > "${BASE}/service-status.txt" 2>&1 || true
sudo ss -tulpn > "${BASE}/ss-tulpn.txt" 2>&1 || true
dpkg -l | grep -E 'xrdp|xorgxrdp|tigervnc|xfce4|x11vnc' > "${BASE}/packages.txt" 2>&1 || true
sudo journalctl -u xrdp -u xrdp-sesman -u tigervnc-backup.service --no-pager -n 300 > "${BASE}/journals.txt" 2>&1 || true

echo "${BASE}" | sudo tee /var/backups/remote-access/LATEST >/dev/null
echo "[OK] Backup complete: ${BASE}"
