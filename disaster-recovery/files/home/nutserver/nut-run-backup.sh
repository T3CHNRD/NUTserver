#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/opt/nut-admin/repo-template"
INVENTORY_SRC="$HOME/nut_backup_inventory.md"
INVENTORY_DST="$REPO/docs/nut_backup_inventory.md"

echo "===== NUT BACKUP RUN START ====="
date
echo

echo "[1/6] Refresh sanitized repo-template from live config set"
sudo /opt/nut-admin/bin/nut_inventory_and_stage.sh apply

echo
echo "[2/6] Refresh protected local backup"
sudo /opt/nut-admin/bin/nut_protected_backup.sh

echo
echo "[3/6] Harden latest protected local backup"
"$HOME/nut-harden-latest-protected-backup.sh"

echo
echo "[4/6] Re-copy approved extra GitHub files"
sudo bash -c '
cd /opt/nut-admin/repo-template || exit 1

mkdir -p ./docs ./var/www/html ./etc/nut

cp -a /etc/nut/upsd.conf ./etc/nut/upsd.conf

sed -E \
  -e "s/([0-9]{1,3}\.){3}[0-9]{1,3}/REDACTED_IP/g" \
  /etc/nut/hosts.conf > ./etc/nut/hosts.conf

cp -a /var/www/html/nutserver-dashboard.html ./var/www/html/nutserver-dashboard.html
cp -a /home/nutserver/Desktop/nutserver-project-export/docs/ROLLBACK.md ./docs/ROLLBACK.md

for src in $(find /etc/systemd/system -path "*/nut-driver@*.service.d/*.conf" | sort); do
  rel="${src#/}"
  mkdir -p "$(dirname "$rel")"
  cp -a "$src" "$rel"
done

chown -R nutserver:nutserver /opt/nut-admin/repo-template
find /opt/nut-admin/repo-template -type f -exec chmod 644 {} \;
find /opt/nut-admin/repo-template -type d -exec chmod 775 {} \;
chmod 664 /opt/nut-admin/repo-template/.gitignore /opt/nut-admin/repo-template/README.md 2>/dev/null || true
'

echo
echo "[5/6] Refresh inventory doc in repo"
mkdir -p "$REPO/docs"
cp -a "$INVENTORY_SRC" "$INVENTORY_DST"

echo
echo "[6/6] Show git status"
cd "$REPO"
git status --short

echo
echo "===== NUT BACKUP RUN COMPLETE ====="
