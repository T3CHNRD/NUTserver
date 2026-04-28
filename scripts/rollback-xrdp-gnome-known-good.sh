#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="/opt/nut-admin/repo-template"
BACKUP_ROOT="$REPO_DIR/backups/display-xrdp-known-good"

echo "===== XRDP/GNOME KNOWN-GOOD ROLLBACK START ====="

LATEST_BACKUP="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1 || true)"

if [ -z "$LATEST_BACKUP" ]; then
  echo "FAIL: No known-good display backup found under $BACKUP_ROOT"
  exit 1
fi

echo "Using backup: $LATEST_BACKUP"

if [ -f "$LATEST_BACKUP/etc/xrdp/startwm.sh" ]; then
  cp -av "$LATEST_BACKUP/etc/xrdp/startwm.sh" /etc/xrdp/startwm.sh
  chmod +x /etc/xrdp/startwm.sh
fi

if [ -f "$LATEST_BACKUP/etc/gdm3/custom.conf" ]; then
  cp -av "$LATEST_BACKUP/etc/gdm3/custom.conf" /etc/gdm3/custom.conf
fi

if [ -f "$LATEST_BACKUP/home/nutserver/.xsession" ]; then
  cp -av "$LATEST_BACKUP/home/nutserver/.xsession" /home/nutserver/.xsession
  chown nutserver:nutserver /home/nutserver/.xsession
  chmod +x /home/nutserver/.xsession
fi

if [ -f "$LATEST_BACKUP/home/nutserver/.xsessionrc" ]; then
  cp -av "$LATEST_BACKUP/home/nutserver/.xsessionrc" /home/nutserver/.xsessionrc
  chown nutserver:nutserver /home/nutserver/.xsessionrc
fi

if [ -f "$LATEST_BACKUP/home/nutserver/.profile" ]; then
  cp -av "$LATEST_BACKUP/home/nutserver/.profile" /home/nutserver/.profile
  chown nutserver:nutserver /home/nutserver/.profile
fi

echo
echo "Restarting XRDP services..."
systemctl restart xrdp xrdp-sesman

echo
echo "===== SERVICE CHECK ====="
systemctl is-active xrdp xrdp-sesman

echo
echo "===== XRDP/GNOME KNOWN-GOOD ROLLBACK COMPLETE ====="
echo "PASS: Known-good XRDP/GNOME config restored"
