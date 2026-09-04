#!/usr/bin/env bash
set -Eeuo pipefail

STAMP="$(date +%F_%H%M%S)"
DEST="/opt/nut-admin/protected-backups/${STAMP}"
mkdir -p "${DEST}"

copy_if_exists() {
  local src="$1"
  local rel="${src#/}"
  if [ -e "$src" ]; then
    mkdir -p "${DEST}/$(dirname "$rel")"
    cp -a "$src" "${DEST}/${rel}"
    echo "[COPIED] $src"
  else
    echo "[MISSING] $src"
  fi
}

echo "Protected backup destination: ${DEST}"
echo

# Project-critical but not for GitHub
copy_if_exists /etc/nut/nut-orchestrator.conf
copy_if_exists /etc/nut/lansweeper.creds
copy_if_exists /etc/nut/upsd.users
copy_if_exists /etc/nut/hosts.conf
copy_if_exists /etc/nut/ups.conf
copy_if_exists /etc/nut/upsd.conf

copy_if_exists /usr/local/bin/nut-orchestrator.sh
copy_if_exists /usr/local/bin/nut-test-logic.sh

copy_if_exists /usr/local/sbin/nut-vmware-shutdown.sh
copy_if_exists /usr/local/sbin/nut-netapp-halt.sh
copy_if_exists /usr/local/sbin/nut-synology-shutdown.sh
copy_if_exists /usr/local/sbin/nut-lansweeper-shutdown.sh
copy_if_exists /usr/local/sbin/nut-voip-shutdown.sh
copy_if_exists /usr/local/sbin/nut-db-shutdown.sh
copy_if_exists /usr/local/sbin/nut-blueiris-shutdown.sh
copy_if_exists /usr/local/sbin/start-x11vnc.sh

copy_if_exists /opt/nut-auto/network-seeds.txt
copy_if_exists /opt/nut-auto/nut-auto-discover.sh
copy_if_exists /opt/nut-auto/output/inventory.json
copy_if_exists /opt/nut-auto/output/verified-ups-notes.txt

copy_if_exists /etc/xrdp
copy_if_exists /etc/X11/Xwrapper.config
copy_if_exists /home/nutserver/.vnc
copy_if_exists /home/nutserver/.config/autostart
copy_if_exists /home/rdpadmin/.xsession
copy_if_exists /home/nutserver/.xsession

chmod -R go-rwx "${DEST}" || true

echo
echo "===== PROTECTED BACKUP CREATED ====="
echo "${DEST}"
find "${DEST}" -maxdepth 4 | sort
