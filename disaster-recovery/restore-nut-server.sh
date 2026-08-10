#!/usr/bin/env bash
set -euo pipefail

DR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES="$DR_DIR/files"
META="$DR_DIR/metadata"
LOG="/var/log/nut-disaster-recovery-restore.log"

MODE="${1:-}"

if [ "$MODE" != "--check" ] && [ "$MODE" != "--apply" ]; then
    echo "Usage:"
    echo "  sudo $0 --check"
    echo "  sudo $0 --apply"
    echo
    echo "--check performs a non-destructive rebuild readiness check."
    echo "--apply performs the actual disaster-recovery restoration."
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "FAIL: run this script with sudo/root"
    exit 1
fi

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" | tee -a "$LOG"
}

die() {
    log "FAIL: $*"
    exit 1
}

log "===== NUT DISASTER RECOVERY RESTORE ====="
log "mode=$MODE"

[ -d "$FILES" ] || die "DR files directory missing"
[ -f "$META/packages.tsv" ] || die "package inventory missing"
[ -f "$META/file-permissions.txt" ] || die "permission inventory missing"

echo
echo "===== OPERATING SYSTEM ====="

if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "Detected: ${PRETTY_NAME:-unknown}"
else
    die "/etc/os-release missing"
fi

if [ "${ID:-}" != "ubuntu" ]; then
    die "This recovery package is intended for Ubuntu"
fi

echo
echo "===== REQUIRED DR CONTENT ====="

required_files=(
    "etc/nut/ups.conf"
    "etc/nut/upsd.conf"
    "etc/nut/upsmon.conf"
    "etc/nut/upssched.conf"
    "etc/nut/nut.conf"
    "usr/local/bin/nut-orchestrator.sh"
    "opt/nut-orchestrator-ui/app.py"
    "opt/nut-orchestrator-ui/templates/control-center.html"
    "opt/nut-orchestrator-ui/static/app.js"
)

for file in "${required_files[@]}"; do
    if [ -f "$FILES/$file" ]; then
        echo "PASS: $file"
    else
        die "required DR file missing: $file"
    fi
done

echo
echo "===== SECRET SAFETY ====="

secret_markers=(
    "etc/nut/vcenter.pass"
    "etc/nut/nut-email-alerts.secret"
    "etc/nut/upsd.users"
)

for secret in "${secret_markers[@]}"; do
    if [ -f "$FILES/$secret" ]; then
        die "secret file unexpectedly present in GitHub snapshot: $secret"
    else
        echo "PASS: excluded: $secret"
    fi
done

if [ "$MODE" = "--check" ]; then
    echo
    echo "===== CHECK RESULT ====="
    echo "PASS: DR package is structurally ready for restoration"
    echo
    echo "No live files were changed."
    exit 0
fi

echo
echo "===== APPLY MODE SAFETY ====="

echo "This command is intended for rebuilding a replacement NUT server."
echo
echo "It will:"
echo "  - install required software"
echo "  - restore sanitized files from GitHub"
echo "  - restore systemd configuration"
echo "  - restore NUT/UI/application files"
echo "  - leave production secrets unset/redacted"
echo "  - leave protection actions disabled until verification"
echo

read -r -p "Type REBUILD-NUT-SERVER to continue: " CONFIRM

if [ "$CONFIRM" != "REBUILD-NUT-SERVER" ]; then
    die "rebuild cancelled"
fi

log "Beginning disaster-recovery apply"

echo
echo "===== INSTALL CORE SOFTWARE ====="

export DEBIAN_FRONTEND=noninteractive

apt-get update

CORE_PACKAGES=(
    nut
    nut-client
    nut-server
    nut-cgi
    apache2
    git
    curl
    wget
    jq
    python3
    python3-pip
    python3-venv
    python3-requests
    python3-pyvmomi
    msmtp
    msmtp-mta
    openssh-client
    openssh-server
    rsync
    sudo
)

for pkg in "${CORE_PACKAGES[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        apt-get install -y "$pkg"
    else
        log "WARN: package unavailable: $pkg"
    fi
done

echo
echo "===== CREATE REQUIRED DIRECTORIES ====="

mkdir -p \
    /etc/nut \
    /etc/nut/config.d \
    /etc/nut/hypervisors \
    /etc/nut/restore \
    /opt/nut-orchestrator-ui \
    /usr/local/bin \
    /usr/local/sbin \
    /var/www/html \
    /var/log/nut \
    /run/nut/upssched

echo
echo "===== RESTORE CURRENT SYSTEM FILES ====="

restore_tree() {
    src="$1"
    dst="$2"

    if [ -d "$FILES/$src" ]; then
        mkdir -p "$dst"
        rsync -a "$FILES/$src/" "$dst/"
        log "RESTORED $src -> $dst"
    fi
}

restore_tree "etc/nut" "/etc/nut"
restore_tree "opt/nut-orchestrator-ui" "/opt/nut-orchestrator-ui"
restore_tree "usr/local/bin" "/usr/local/bin"
restore_tree "usr/local/sbin" "/usr/local/sbin"
restore_tree "etc/systemd/system" "/etc/systemd/system"
restore_tree "etc/sudoers.d" "/etc/sudoers.d"
restore_tree "var/www/html" "/var/www/html"

echo
echo "===== DO NOT RESTORE HISTORICAL HOME COPIES INTO PRODUCTION ====="
echo "Historical /home/nutserver material remains available in GitHub for reference."

echo
echo "===== RESTORE RECORDED FILE MODES ====="

python3 - "$META/file-permissions.txt" <<'PY'
from pathlib import Path
import os
import sys

meta = Path(sys.argv[1])

for line in meta.read_text(errors="replace").splitlines():
    parts = line.split("|")

    if len(parts) != 4:
        continue

    path_text, mode_text, user, group = parts
    path = Path(path_text)

    if not path.exists():
        continue

    try:
        mode = int(mode_text, 8)
        os.chmod(path, mode)
    except Exception:
        pass
PY

echo
echo "===== VALIDATE SUDOERS BEFORE CONTINUING ====="

if ! visudo -c; then
    die "sudoers validation failed"
fi

echo
echo "===== FORCE SAFE POST-RESTORE MODE ====="

if [ -x /usr/local/sbin/nut-production-mode ]; then
    /usr/local/sbin/nut-production-mode off || true
fi

echo
echo "===== SYSTEMD RELOAD ====="

systemctl daemon-reload

echo
echo "===== SECRET RE-ENTRY REQUIRED ====="

cat <<'NOTICE'

GitHub intentionally does NOT contain production credentials.

Before enabling Protecting mode, manually restore/configure required secrets.

Review:

    disaster-recovery/SECRETS-NOT-IN-GITHUB.md

Typical required secrets include:

    NUT monitor authentication
    Exchange/SMTP authentication if used
    vCenter authentication
    Synology authentication
    Lansweeper authentication
    NetApp authentication
    Blue Iris/RPC authentication
    APC/IDF authentication
    SSH private keys
    API credentials
    private certificate keys

DO NOT put these values into GitHub.

NOTICE

echo
echo "===== RESTORE COMPLETE - SAFE STATE ====="

log "DR files restored"
log "Secrets still require local configuration"
log "Protection must remain OFF until verification passes"

echo
echo "NEXT:"
echo "  1. Enter required secrets locally."
echo "  2. Run:"
echo
echo "     sudo $DR_DIR/verify-restored-server.sh"
echo
echo "  3. Do not enable Protecting until verification passes."
