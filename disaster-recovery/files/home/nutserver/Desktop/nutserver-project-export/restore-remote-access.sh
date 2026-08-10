#!/bin/bash
set -u

BACKUP_DIR="/home/nutserver/remote-access-backups"
LATEST_BACKUP="$(ls -1t "${BACKUP_DIR}"/remote-access-backup-*.tar.gz 2>/dev/null | head -n 1)"

echo
if [ -z "${LATEST_BACKUP:-}" ]; then
  echo "No backup files were found in ${BACKUP_DIR}"
  echo
  read -p "Press Enter to close..."
  exit 1
fi

echo "Latest backup found:"
echo "${LATEST_BACKUP}"
echo
read -p "Restore this backup now? (y/N): " CONFIRM

case "$CONFIRM" in
  y|Y)
    ;;
  *)
    echo
    echo "Restore cancelled."
    echo
    read -p "Press Enter to close..."
    exit 0
    ;;
esac

echo
echo "Restoring files from:"
echo "${LATEST_BACKUP}"
echo

sudo tar -xzf "${LATEST_BACKUP}" -C /

echo
echo "Reloading services..."
sudo systemctl daemon-reload
sudo systemctl restart xrdp xrdp-sesman

if systemctl list-unit-files | grep -q '^tigervnc-backup.service'; then
  sudo systemctl restart tigervnc-backup.service || true
fi

echo
echo "Restore completed."
echo
echo "Service status:"
sudo systemctl --no-pager --full status xrdp xrdp-sesman | sed -n '1,30p'

echo
read -p "Press Enter to close..."
