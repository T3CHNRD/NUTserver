#!/usr/bin/env bash
set -Eeuo pipefail

LATEST="$(ls -1dt /opt/nut-admin/protected-backups/* | head -n 1)"

if [ -z "${LATEST:-}" ] || [ ! -d "$LATEST" ]; then
  echo "[ERROR] No protected backup directory found."
  exit 1
fi

echo "===== HARDENING PROTECTED BACKUP ====="
echo "$LATEST"
echo

sudo chown -R root:root "$LATEST"
sudo chmod -R go-rwx "$LATEST"

sudo bash -c '
LATEST="$1"
find "$LATEST" -type f -print0 | sort -z | xargs -0 sha256sum > "$LATEST/SHA256SUMS.txt"
chmod 600 "$LATEST/SHA256SUMS.txt"
' _ "$LATEST"

echo "===== TOP-LEVEL PERMS ====="
sudo find "$LATEST" -maxdepth 3 -printf "%M %u %g %p\n" | sort | sed -n '1,120p'

echo
echo "===== MANIFEST SAMPLE ====="
sudo sed -n '1,40p' "$LATEST/SHA256SUMS.txt"
