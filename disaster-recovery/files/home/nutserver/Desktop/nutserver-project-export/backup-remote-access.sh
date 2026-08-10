#!/bin/bash
set -u

BACKUP_DIR="/home/nutserver/remote-access-backups"
STAMP="$(date +%F-%H%M%S)"
ARCHIVE="${BACKUP_DIR}/remote-access-backup-${STAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo
echo "Creating backup at:"
echo "${ARCHIVE}"
echo

sudo tar -czf "${ARCHIVE}" \
  /etc/xrdp \
  /home/nutserver/.xsession \
  /home/nutserver/.xinitrc \
  /home/nutserver/.vnc \
  /etc/systemd/system/tigervnc-backup.service \
  2>/dev/null

RC=$?

echo
if [ $RC -eq 0 ]; then
  echo "Backup completed successfully."
  ls -lh "${ARCHIVE}"
else
  echo "Backup completed with warnings or missing files."
  echo "Check whether some files do not exist yet."
  ls -lh "${ARCHIVE}" 2>/dev/null || true
fi

echo
read -p "Press Enter to close..."
