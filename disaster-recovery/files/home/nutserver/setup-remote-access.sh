#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="nutserver"
HOME_DIR="/home/${TARGET_USER}"
STAMP="$(date +%F-%H%M%S)"
BACKUP_ROOT="/var/backups/remote-access"
BACKUP_DIR="${BACKUP_ROOT}/${STAMP}"
ROLLBACK_SCRIPT="/usr/local/sbin/rollback-remote-access.sh"
SETUP_LOG="/var/log/setup-remote-access.log"

exec > >(tee -a "${SETUP_LOG}") 2>&1

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with: sudo bash /home/nutserver/setup-remote-access.sh"
  exit 1
fi

echo "== Creating backup directory =="
mkdir -p "${BACKUP_DIR}"

echo "== Backing up current config =="
mkdir -p "${BACKUP_DIR}/etc" "${BACKUP_DIR}/home"
cp -a /etc/gdm3 "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/xrdp "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/systemd/system/tigervnc-backup.service "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/systemd/system/x11vnc.service "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/profile.d/99-xrdp-desktop.sh "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a "${HOME_DIR}/.xsession" "${BACKUP_DIR}/home/" 2>/dev/null || true
cp -a "${HOME_DIR}/.vnc" "${BACKUP_DIR}/home/" 2>/dev/null || true

echo "== Stopping broken VNC services =="
systemctl disable --now tigervnc-backup.service 2>/dev/null || true
systemctl disable --now x11vnc.service 2>/dev/null || true

echo "== Installing packages =="
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  xrdp xorgxrdp xserver-xorg-core xserver-xorg-input-all \
  xfce4 xfce4-goodies x11vnc

echo "== Ensuring xrdp can use certs =="
adduser xrdp ssl-cert || true

echo "== Forcing GDM to Xorg =="
if grep -Eq '^[#[:space:]]*WaylandEnable=' /etc/gdm3/custom.conf; then
  sed -ri 's/^[#[:space:]]*WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
elif grep -q '^\[daemon\]' /etc/gdm3/custom.conf; then
  sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
else
  printf '[daemon]\nWaylandEnable=false\n' >> /etc/gdm3/custom.conf
fi

echo "== Setting XRDP desktop to XFCE =="
printf 'startxfce4\n' > "${HOME_DIR}/.xsession"
chown "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.xsession"
chmod 644 "${HOME_DIR}/.xsession"

cat > /etc/profile.d/99-xrdp-desktop.sh <<'EOFX'
[ -n "$XRDP_SESSION" ] && export DESKTOP_SESSION=xfce
EOFX
chmod 644 /etc/profile.d/99-xrdp-desktop.sh

touch "${HOME_DIR}/.Xauthority" "${HOME_DIR}/.ICEauthority"
chown "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.Xauthority" "${HOME_DIR}/.ICEauthority"

echo "== Creating VNC password =[REDACTED]
mkdir -p "${HOME_DIR}/.vnc"
chown "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.vnc"
chmod 700 "${HOME_DIR}/.vnc"

echo
echo "You will now set the VNC password for x11vnc."
echo "Use the SAME account you use to log into the server."
sudo -u "${TARGET_USER}" x11vnc -storepasswd "${HOME_DIR}/.vnc/passwd"
chmod 600 "${HOME_DIR}/.vnc/passwd"
chown "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.vnc/passwd"

echo "== Creating x11vnc systemd service =="
cat > /etc/systemd/system/x11vnc.service <<'EOSVC'
[Unit]
Description=Backup VNC server for physical console on port 5900
After=display-manager.service network.target
Wants=display-manager.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/x11vnc -display :0 -env FD_XDM=1 -auth guess -forever -shared -rfbauth /home/nutserver/.vnc/passwd -rfbport 5900
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOSVC

echo "== Enabling services =="
systemctl daemon-reload
systemctl enable xrdp
systemctl enable x11vnc

echo "== Optional firewall rules =="
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi active; then
    ufw allow from 192.168.0.0/16 to any port 3389 proto tcp || true
    ufw allow from 192.168.0.0/16 to any port 5900 proto tcp || true
  fi
fi

echo "== Creating rollback script =="
cat > "${ROLLBACK_SCRIPT}" <<'EOROLL'
#!/usr/bin/env bash
set -euo pipefail

LATEST_BACKUP="$(ls -1dt /var/backups/remote-access/* 2>/dev/null | head -n 1 || true)"
if [ -z "${LATEST_BACKUP}" ]; then
  echo "No backup found."
  exit 1
fi

echo "Restoring from: ${LATEST_BACKUP}"

systemctl disable --now x11vnc.service 2>/dev/null || true
systemctl disable --now tigervnc-backup.service 2>/dev/null || true
systemctl disable --now xrdp 2>/dev/null || true

if [ -d "${LATEST_BACKUP}/etc/gdm3" ]; then
  rm -rf /etc/gdm3
  cp -a "${LATEST_BACKUP}/etc/gdm3" /etc/
fi

if [ -d "${LATEST_BACKUP}/etc/xrdp" ]; then
  rm -rf /etc/xrdp
  cp -a "${LATEST_BACKUP}/etc/xrdp" /etc/
fi

if [ -f "${LATEST_BACKUP}/etc/tigervnc-backup.service" ]; then
  cp -a "${LATEST_BACKUP}/etc/tigervnc-backup.service" /etc/systemd/system/
fi

if [ -f "${LATEST_BACKUP}/etc/x11vnc.service" ]; then
  cp -a "${LATEST_BACKUP}/etc/x11vnc.service" /etc/systemd/system/
else
  rm -f /etc/systemd/system/x11vnc.service
fi

if [ -f "${LATEST_BACKUP}/etc/99-xrdp-desktop.sh" ]; then
  cp -a "${LATEST_BACKUP}/etc/99-xrdp-desktop.sh" /etc/profile.d/
else
  rm -f /etc/profile.d/99-xrdp-desktop.sh
fi

if [ -f "${LATEST_BACKUP}/home/.xsession" ]; then
  cp -a "${LATEST_BACKUP}/home/.xsession" /home/nutserver/.xsession
  chown nutserver:nutserver /home/nutserver/.xsession
fi

if [ -d "${LATEST_BACKUP}/home/.vnc" ]; then
  rm -rf /home/nutserver/.vnc
  cp -a "${LATEST_BACKUP}/home/.vnc" /home/nutserver/
  chown -R nutserver:nutserver /home/nutserver/.vnc
fi

systemctl daemon-reload
echo "Rollback complete. Reboot recommended."
EOROLL

chmod 755 "${ROLLBACK_SCRIPT}"
chown root:root "${ROLLBACK_SCRIPT}"

echo
echo "SETUP COMPLETE"
echo "Backup stored at: ${BACKUP_DIR}"
echo "Rollback script: ${ROLLBACK_SCRIPT}"
echo "Next: reboot the server"
