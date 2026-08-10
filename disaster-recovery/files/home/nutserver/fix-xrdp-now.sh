#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with: sudo bash ~/fix-xrdp-now.sh"
  exit 1
fi

TARGET_USER="nutserver"
HOME_DIR="/home/$TARGET_USER"
STAMP="$(date +%F-%H%M%S)"
BACKUP_DIR="/var/backups/remote-access/$STAMP"

echo "[1/8] Backing up current remote-access config to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a /etc/gdm3/custom.conf "$BACKUP_DIR/" 2>/dev/null || true
cp -a /etc/xrdp "$BACKUP_DIR/etc-xrdp" 2>/dev/null || true
cp -a /etc/systemd/system/tigervnc-backup.service "$BACKUP_DIR/" 2>/dev/null || true
cp -a "$HOME_DIR/.xsession" "$BACKUP_DIR/${TARGET_USER}.xsession" 2>/dev/null || true
cp -a "$HOME_DIR/.vnc" "$BACKUP_DIR/${TARGET_USER}.vnc" 2>/dev/null || true

echo "[2/8] Stopping the broken TigerVNC service for now"
systemctl disable --now tigervnc-backup.service 2>/dev/null || true

echo "[3/8] Installing XRDP + Xorg backend + XFCE"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  xrdp xorgxrdp xserver-xorg-core xserver-xorg-input-all \
  xfce4 xfce4-goodies

echo "[4/8] Granting xrdp access to the ssl-cert group"
adduser xrdp ssl-cert || true

echo "[5/8] Forcing GDM to use Xorg instead of Wayland"
if grep -Eq '^[#[:space:]]*WaylandEnable=' /etc/gdm3/custom.conf; then
  sed -ri 's/^[#[:space:]]*WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
elif grep -q '^\[daemon\]' /etc/gdm3/custom.conf; then
  sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
else
  printf '[daemon]\nWaylandEnable=false\n' >> /etc/gdm3/custom.conf
fi

echo "[6/8] Setting XRDP to start XFCE for user $TARGET_USER"
printf 'startxfce4\n' > "$HOME_DIR/.xsession"
chown "$TARGET_USER:$TARGET_USER" "$HOME_DIR/.xsession"
chmod 644 "$HOME_DIR/.xsession"

cat > /etc/profile.d/99-xrdp-desktop.sh <<'EOFX'
[ -n "$XRDP_SESSION" ] && export DESKTOP_SESSION=xfce
EOFX
chmod 644 /etc/profile.d/99-xrdp-desktop.sh

touch "$HOME_DIR/.Xauthority" "$HOME_DIR/.ICEauthority"
chown "$TARGET_USER:$TARGET_USER" "$HOME_DIR/.Xauthority" "$HOME_DIR/.ICEauthority"

echo "[7/8] Enabling and restarting XRDP"
systemctl enable xrdp
systemctl restart xrdp xrdp-sesman

echo "[8/8] Done"
echo
echo "Backup saved to: $BACKUP_DIR"
echo "Next command: sudo reboot"
