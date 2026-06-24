#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -euo pipefail

LATEST_FILE="/var/backups/remote-access/LATEST"

echo
echo "[INFO] Remote access rollback starting..."
echo "[INFO] If you are connected by VNC, that session will disconnect during rollback."
echo "[INFO] Wait 10 seconds after completion, then reconnect."
echo

if [ ! -f "${LATEST_FILE}" ]; then
  echo "[ERROR] No backup marker found at ${LATEST_FILE}"
  exit 1
fi

BASE="$(cat "${LATEST_FILE}")"

if [ ! -d "${BASE}" ]; then
  echo "[ERROR] Backup directory does not exist: ${BASE}"
  exit 1
fi

echo "[INFO] Restoring from backup: ${BASE}"

sudo systemctl stop tigervnc-backup.service 2>/dev/null || true
sudo systemctl stop x11vnc.service 2>/dev/null || true
sudo systemctl stop xrdp 2>/dev/null || true
sudo systemctl stop xrdp-sesman 2>/dev/null || true

if [ -d "${BASE}/etc/xrdp" ]; then
  echo "[INFO] Restoring /etc/xrdp"
  sudo rm -rf /etc/xrdp
  sudo cp -a "${BASE}/etc/xrdp" /etc/
fi

if [ -f "${BASE}/etc/X11/Xwrapper.config" ]; then
  echo "[INFO] Restoring /etc/X11/Xwrapper.config"
  sudo cp -a "${BASE}/etc/X11/Xwrapper.config" /etc/X11/Xwrapper.config
fi

if [ -f "${BASE}/etc/systemd/system/tigervnc-backup.service" ]; then
  echo "[INFO] Restoring tigervnc-backup.service"
  sudo cp -a "${BASE}/etc/systemd/system/tigervnc-backup.service" /etc/systemd/system/tigervnc-backup.service
fi

if [ -f "${BASE}/etc/systemd/system/x11vnc.service" ]; then
  echo "[INFO] Restoring x11vnc.service"
  sudo cp -a "${BASE}/etc/systemd/system/x11vnc.service" /etc/systemd/system/x11vnc.service
else
  sudo rm -f /etc/systemd/system/x11vnc.service
fi

if [ -d "${BASE}/home/nutserver/.vnc" ]; then
  echo "[INFO] Restoring /home/nutserver/.vnc"
  sudo rm -rf /home/nutserver/.vnc
  sudo cp -a "${BASE}/home/nutserver/.vnc" /home/nutserver/
  sudo chown -R nutserver:nutserver /home/nutserver/.vnc
fi

if [ -d "${BASE}/home/nutserver/.config/autostart" ]; then
  echo "[INFO] Restoring /home/nutserver/.config/autostart"
  sudo mkdir -p /home/nutserver/.config
  sudo rm -rf /home/nutserver/.config/autostart
  sudo cp -a "${BASE}/home/nutserver/.config/autostart" /home/nutserver/.config/
  sudo chown -R nutserver:nutserver /home/nutserver/.config
fi

if [ -f "${BASE}/home/rdpadmin.xsession" ]; then
  echo "[INFO] Restoring /home/rdpadmin/.xsession"
  sudo cp -a "${BASE}/home/rdpadmin.xsession" /home/rdpadmin/.xsession
  sudo chown rdpadmin:rdpadmin /home/rdpadmin/.xsession
fi

if [ -f "${BASE}/home/nutserver.xsession" ]; then
  echo "[INFO] Restoring /home/nutserver/.xsession"
  sudo cp -a "${BASE}/home/nutserver.xsession" /home/nutserver/.xsession
  sudo chown nutserver:nutserver /home/nutserver/.xsession
fi

echo "[INFO] Reloading systemd"
sudo systemctl daemon-reload

echo "[INFO] Enabling services"
sudo systemctl enable xrdp xrdp-sesman tigervnc-backup.service >/dev/null 2>&1 || true

echo "[INFO] Restarting XRDP and VNC services"
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman
sudo systemctl restart tigervnc-backup.service

echo
echo "[OK] Rollback complete from ${BASE}"
echo "[INFO] VNC may have disconnected during rollback."
echo "[INFO] Wait 10 seconds, then reconnect to VNC."
echo
echo "[INFO] Current service state:"
sudo systemctl status xrdp xrdp-sesman tigervnc-backup.service --no-pager -l || true
