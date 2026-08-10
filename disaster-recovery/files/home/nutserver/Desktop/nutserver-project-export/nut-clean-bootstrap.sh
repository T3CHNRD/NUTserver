#!/bin/bash
#
# nut-clean-bootstrap.sh
#
# Purpose:
#   Clean out any previous NUT/apache partial setup, back it up, reinstall a fresh
#   Plan B NUT environment, discover connected UPS devices, generate staged configs,
#   pause for human review, optionally apply configs, enable NUT + Apache/NUT-CGI,
#   and produce inventory/runbook/validation artifacts.
#
# Target OS:
#   Ubuntu Server 24.04 LTS
#
# Notes:
#   - Safe-first design
#   - Makes backups before removal
#   - Uses staged config generation
#   - Prompts for human confirmation at key checkpoints
#   - Defaults to MODE=netserver
#

set -u
set -o pipefail

########################################
# Defaults / Globals
########################################

SCRIPT_NAME="$(basename "$0")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/root/nut-backups/${TIMESTAMP}"
WORK_DIR="/root/nut-bootstrap"
DISCOVERY_DIR="${WORK_DIR}/discovery"
GENERATED_DIR="${WORK_DIR}/generated-configs"
REPORTS_DIR="${WORK_DIR}/reports"
STATE_DIR="${WORK_DIR}/state"

LOG_FILE="${WORK_DIR}/bootstrap.log"
RUNBOOK_MD="${WORK_DIR}/runbook.md"
INVENTORY_CSV="${WORK_DIR}/inventory.csv"
VALIDATION_REPORT="${REPORTS_DIR}/validation-report.txt"
DISCOVERY_SUMMARY="${REPORTS_DIR}/discovery-summary.txt"

NUT_MODE="netserver"
REMOTE_LISTEN_IP=""
ENABLE_SECOND_MONITOR="no"
APPLY_CHANGES="no"
FORCE_YES="no"

NUT_MONITOR_USER="upsmon"
NUT_MONITOR_PASS="[REDACTED]"
NUT_SECOND_USER="upsmon2"
NUT_SECOND_PASS="[REDACTED]"

DEFAULT_SHUTDOWN_CMD="/sbin/shutdown -h now"
DEFAULT_POWERDOWNFLAG="/etc/killpower"

########################################
# Helper functions
########################################

log() {
    local msg="$1"
    mkdir -p "$WORK_DIR" >/dev/null 2>&1 || true
    echo "[$(date '+%F %T')] $msg" | tee -a "$LOG_FILE"
}

warn() {
    local msg="$1"
    echo "[$(date '+%F %T')] WARNING: $msg" | tee -a "$LOG_FILE" >&2
}

err() {
    local msg="$1"
    echo "[$(date '+%F %T')] ERROR: $msg" | tee -a "$LOG_FILE" >&2
}

die() {
    local msg="$1"
    err "$msg"
    exit 1
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-no}"
    local answer

    if [[ "$FORCE_YES" == "yes" ]]; then
        log "Auto-approving prompt due to --yes: $prompt"
        return 0
    fi

    while true; do
        if [[ "$default" == "yes" ]]; then
            read -r -p "$prompt [Y/n]: " answer
            answer="${answer:-Y}"
        else
            read -r -p "$prompt [y/N]: " answer
            answer="${answer:-N}"
        fi

        case "$answer" in
            Y|y|Yes|yes) return 0 ;;
            N|n|No|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

pause_for_human() {
    local message="$1"
    echo
    echo "============================================================"
    echo "HUMAN REVIEW REQUIRED"
    echo "============================================================"
    echo "$message"
    echo
    read -r -p "Press ENTER to continue..."
}

run_cmd() {
    local description="$1"
    shift
    log "$description"
    "$@"
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        die "Command failed (${description}) with exit code $rc"
    fi
}

maybe_run_cmd() {
    local description="$1"
    shift
    log "$description"
    "$@" || warn "Non-fatal command failed: ${description}"
}

ensure_dir() {
    mkdir -p "$1"
}

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        log "Backing up $path to $BACKUP_DIR"
        cp -a "$path" "$BACKUP_DIR/" 2>/dev/null || warn "Could not back up $path"
    else
        log "Path not present, skipping backup: $path"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log "Detected OS: ${PRETTY_NAME:-unknown}"
        if [[ "${ID:-}" != "ubuntu" ]]; then
            warn "This script is written for Ubuntu. Detected ID=${ID:-unknown}"
        fi
        if [[ "${VERSION_ID:-}" != "24.04" ]]; then
            warn "This script was targeted for Ubuntu 24.04. Detected VERSION_ID=${VERSION_ID:-unknown}"
        fi
    else
        warn "/etc/os-release not found; unable to confirm OS version."
    fi
}

usage() {
    cat <<EOF
Usage: sudo $SCRIPT_NAME [options]

Options:
  --apply                   Apply generated configs into /etc/nut after review
  --remote-listen-ip IP     Add LISTEN IP to upsd.conf for remote NUT clients
  --enable-second-monitor   Add a second upsmon user block and sample monitor lines
  --mode MODE               NUT mode: standalone or netserver (default: netserver)
  --yes                     Auto-approve yes/no prompts where safe
  -h, --help                Show this help

Examples:
  sudo ./$SCRIPT_NAME
  sudo ./$SCRIPT_NAME --apply
  sudo ./$SCRIPT_NAME --apply --remote-listen-ip 192.168.1.10
  sudo ./$SCRIPT_NAME --apply --enable-second-monitor
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply)
                APPLY_CHANGES="yes"
                shift
                ;;
            --remote-listen-ip)
                REMOTE_LISTEN_IP="${2:-}"
                [[ -n "$REMOTE_LISTEN_IP" ]] || die "--remote-listen-ip requires a value"
                shift 2
                ;;
            --enable-second-monitor)
                ENABLE_SECOND_MONITOR="yes"
                shift
                ;;
            --mode)
                NUT_MODE="${2:-}"
                [[ "$NUT_MODE" == "standalone" || "$NUT_MODE" == "netserver" ]] || die "--mode must be standalone or netserver"
                shift 2
                ;;
            --yes)
                FORCE_YES="yes"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
    done
}

########################################
# Preflight
########################################

preflight_checks() {
    [[ $EUID -eq 0 ]] || die "Run this script as root or with sudo."

    ensure_dir "$WORK_DIR"
    ensure_dir "$BACKUP_DIR"
    ensure_dir "$DISCOVERY_DIR"
    ensure_dir "$GENERATED_DIR"
    ensure_dir "$REPORTS_DIR"
    ensure_dir "$STATE_DIR"

    : > "$LOG_FILE"
    log "Starting $SCRIPT_NAME"
    detect_os

    maybe_run_cmd "Checking network reachability to Ubuntu archive" bash -c "getent hosts archive.ubuntu.com >/dev/null 2>&1"
    maybe_run_cmd "Checking free disk space" df -h /
}

########################################
# Backup and removal
########################################

backup_existing_install() {
    log "Creating backups under $BACKUP_DIR"

    backup_if_exists /etc/nut
    backup_if_exists /var/log/nut
    backup_if_exists /var/lib/nut
    backup_if_exists /etc/apache2
    backup_if_exists /etc/systemd/system
    backup_if_exists /var/www/html
}

stop_existing_services() {
    log "Stopping existing services if present"
    maybe_run_cmd "Stopping nut-server" systemctl stop nut-server
    maybe_run_cmd "Stopping nut-monitor" systemctl stop nut-monitor
    maybe_run_cmd "Stopping apache2" systemctl stop apache2
    maybe_run_cmd "Stopping prometheus" systemctl stop prometheus
    maybe_run_cmd "Stopping grafana-server" systemctl stop grafana-server
}

disable_existing_services() {
    log "Disabling existing services if present"
    maybe_run_cmd "Disabling nut-server" systemctl disable nut-server
    maybe_run_cmd "Disabling nut-monitor" systemctl disable nut-monitor
    maybe_run_cmd "Disabling apache2" systemctl disable apache2
}

remove_old_packages() {
    log "Removing previous NUT/Apache packages for a clean rebuild"
    maybe_run_cmd "apt remove old packages" apt remove -y nut nut-server nut-client nut-cgi nut-snmp apache2 apache2-bin apache2-data apache2-utils
    maybe_run_cmd "apt purge old packages" apt purge -y nut nut-server nut-client nut-cgi nut-snmp apache2 apache2-bin apache2-data apache2-utils
    maybe_run_cmd "apt autoremove" apt autoremove -y
}

remove_old_directories() {
    log "Removing leftover directories"
    maybe_run_cmd "Remove /etc/nut" rm -rf /etc/nut
    maybe_run_cmd "Remove /var/lib/nut" rm -rf /var/lib/nut
    maybe_run_cmd "Remove /run/nut" rm -rf /run/nut
    maybe_run_cmd "Remove /var/run/nut" rm -rf /var/run/nut
}

########################################
# Install packages
########################################

install_fresh_packages() {
    log "Updating package lists"
    run_cmd "apt update" apt update

    log "Installing fresh Plan B packages"
    run_cmd "apt install packages" apt install -y \
        nut nut-server nut-client nut-cgi nut-snmp \
        apache2 apache2-bin apache2-data apache2-utils \
        usbutils curl lsof net-tools
}

########################################
# Discovery
########################################

run_discovery() {
    log "Running hardware and service discovery"

    maybe_run_cmd "Capture lsusb" bash -c "lsusb > '${DISCOVERY_DIR}/lsusb.txt'"
    maybe_run_cmd "Capture dmesg USB" bash -c "dmesg | grep -i usb > '${DISCOVERY_DIR}/dmesg-usb.txt'"
    maybe_run_cmd "Capture dmesg UPS" bash -c "dmesg | grep -Ei 'ups|apc|tripp|tripplite|hid|serial|ttyUSB|ttyS' > '${DISCOVERY_DIR}/dmesg-ups.txt'"
    maybe_run_cmd "Capture serial devices" bash -c "ls -l /dev/serial/by-id > '${DISCOVERY_DIR}/serial-by-id.txt'"
    maybe_run_cmd "Capture tty devices" bash -c "ls -l /dev/ttyUSB* /dev/ttyS* > '${DISCOVERY_DIR}/tty-devices.txt' 2>/dev/null"

    if command_exists nut-scanner; then
        maybe_run_cmd "Run nut-scanner -U" bash -c "nut-scanner -U > '${DISCOVERY_DIR}/nut-scanner-U.txt' 2>&1"
        maybe_run_cmd "Run nut-scanner -S" bash -c "nut-scanner -S > '${DISCOVERY_DIR}/nut-scanner-S.txt' 2>&1"
    else
        warn "nut-scanner not found; discovery will rely on lsusb/dmesg/serial device inspection."
        echo "nut-scanner not installed or not in PATH" > "${DISCOVERY_DIR}/nut-scanner-U.txt"
        echo "nut-scanner not installed or not in PATH" > "${DISCOVERY_DIR}/nut-scanner-S.txt"
    fi

    if command_exists upsdrvctl; then
        maybe_run_cmd "List available drivers via upsdrvctl -l" bash -c "upsdrvctl -l > '${DISCOVERY_DIR}/upsdrvctl-drivers.txt' 2>&1"
    else
        warn "upsdrvctl not found in PATH during discovery."
        echo "upsdrvctl not found in PATH" > "${DISCOVERY_DIR}/upsdrvctl-drivers.txt"
    fi

    {
        echo "Discovery Summary - ${TIMESTAMP}"
        echo "======================================"
        echo
        echo "Files generated:"
        ls -1 "$DISCOVERY_DIR" 2>/dev/null || true
        echo
        echo "Potential UPS-related USB lines:"
        grep -Ei 'APC|Tripp|Tripplite|UPS|battery|Back-UPS|Smart-UPS' "${DISCOVERY_DIR}/lsusb.txt" 2>/dev/null || true
        echo
        echo "Potential serial device mappings:"
        cat "${DISCOVERY_DIR}/serial-by-id.txt" 2>/dev/null || true
    } > "$DISCOVERY_SUMMARY"

    log "Discovery complete. Review files under $DISCOVERY_DIR"
}

########################################
# Generate inventory and runbook
########################################

generate_inventory_csv() {
    log "Generating inventory CSV template at $INVENTORY_CSV"
    cat > "$INVENTORY_CSV" <<'EOF'
UPS_NAME,BRAND,MODEL,INTERFACE_TYPE,PORT_CONNECTION,LIKELY_DRIVER,VENDOR_ID,PRODUCT_ID,IP_OR_HOSTNAME,SNMP_COMMUNITY,NOTES,CONFIRMED_BY_HUMAN
ups1,APC,,USB,auto,usbhid-ups,,,,,Review detected USB mapping,no
ups2,APC,,USB,auto,usbhid-ups,,,,,Review detected USB mapping,no
ups3,TrippLite,,USB,auto,tripplite_usb,,,,,Review detected USB mapping,no
ups4,,,,,,,,,,,no
ups5,,,,,,,,,,,no
ups6,,,,,,,,,,,no
ups7,,,,,,,,,,,no
ups8,,,,,,,,,,,no
ups9,,,,,,,,,,,no
EOF
}

generate_runbook_md() {
    log "Generating runbook markdown at $RUNBOOK_MD"
    cat > "$RUNBOOK_MD" <<EOF
# NUT Plan B Runbook

Generated: $(date)

## Purpose
This server is being built as a clean-slate NUT host on Ubuntu Server 24.04 LTS.

## Directory Layout
- Work directory: \`${WORK_DIR}\`
- Discovery: \`${DISCOVERY_DIR}\`
- Generated configs: \`${GENERATED_DIR}\`
- Reports: \`${REPORTS_DIR}\`
- Backups: \`${BACKUP_DIR}\`

## Packages Installed
- nut
- nut-server
- nut-client
- nut-cgi
- nut-snmp
- apache2
- usbutils
- curl
- lsof
- net-tools

## NUT Mode
- ${NUT_MODE}

## Human Review Steps
1. Review discovery output under \`${DISCOVERY_DIR}\`
2. Update \`${INVENTORY_CSV}\` with confirmed UPS information
3. Review staged config files under \`${GENERATED_DIR}\`
4. Confirm usernames, passwords, UPS names, drivers, and ports
5. Approve applying config into \`/etc/nut\`
6. After service restart, run controlled validation tests

## Important Commands
### Check service status
\`\`\`bash
systemctl status nut-server
systemctl status nut-monitor
systemctl status apache2
\`\`\`

### Query UPS status
\`\`\`bash
upsc ups1@localhost
\`\`\`

### Check listening ports
\`\`\`bash
ss -tulpn | grep -E '3493|80|443'
\`\`\`

### View logs
\`\`\`bash
journalctl -u nut-server -n 100 --no-pager
journalctl -u nut-monitor -n 100 --no-pager
journalctl -u apache2 -n 100 --no-pager
\`\`\`

## NUT CGI URL
Once Apache and CGI are working, test:

- http://localhost/cgi-bin/nut/upsstats.cgi
- http://<server-ip>/cgi-bin/nut/upsstats.cgi

## Security Notes
- /etc/nut should not be world-readable
- Sensitive files should be root:nut with mode 640
- Add LAN LISTEN IP only if required
- Firewall rules are intentionally not changed by this script

## Validation Checklist
- [ ] Each UPS responds to \`upsc\`
- [ ] UPS names are human-friendly and accurate
- [ ] Drivers are confirmed against hardware/HCL
- [ ] Apache serves the NUT CGI page
- [ ] Port 3493 is listening as expected
- [ ] One controlled power-loss test is scheduled
EOF
}

########################################
# Generate staged configs
########################################

generate_nut_conf() {
    cat > "${GENERATED_DIR}/nut.conf" <<EOF
MODE=${NUT_MODE}
EOF
}

generate_ups_conf() {
    cat > "${GENERATED_DIR}/ups.conf" <<'EOF'
# ------------------------------------------------------------------
# GENERATED TEMPLATE: /etc/nut/ups.conf
# Review and edit each UPS block before applying.
# Replace placeholder values with confirmed data from discovery/HCL.
# ------------------------------------------------------------------

maxretry = 3

[ups1]
    driver = usbhid-ups
    port = auto
    desc = "UPS 1 - REVIEW REQUIRED"

# Example serial UPS block
#[ups2]
#    driver = apcsmart
#    port = /dev/ttyUSB0
#    desc = "UPS 2 - APC serial - REVIEW REQUIRED"

# Example Tripp Lite USB block
#[ups3]
#    driver = tripplite_usb
#    port = auto
#    desc = "UPS 3 - Tripp Lite USB - REVIEW REQUIRED"

# Example SNMP UPS block
#[ups4]
#    driver = snmp-ups
#    port = 192.168.1.50
#    community = public
#    snmp_version = v1
#    desc = "UPS 4 - SNMP - REVIEW REQUIRED"

# Add additional UPS entries for ups5 through ups9 after confirming:
# - driver
# - port
# - vendor/product IDs if needed
# - serial/SNMP details if applicable
EOF
}

generate_upsd_conf() {
    {
        echo "# ------------------------------------------------------------------"
        echo "# GENERATED TEMPLATE: /etc/nut/upsd.conf"
        echo "# ------------------------------------------------------------------"
        echo "LISTEN 127.0.0.1 3493"
        if [[ -n "$REMOTE_LISTEN_IP" ]]; then
            echo "LISTEN ${REMOTE_LISTEN_IP} 3493"
        fi
    } > "${GENERATED_DIR}/upsd.conf"
}

generate_upsd_users() {
    {
        echo "# ------------------------------------------------------------------"
        echo "# GENERATED TEMPLATE: /etc/nut/upsd.users"
        echo "# Review credentials before applying."
        echo "# ------------------------------------------------------------------"
        echo
        echo "[${NUT_MONITOR_USER}]"
        echo "  password = ${NUT_MONITOR_PASS}"
        echo "  upsmon master"
        echo
        if [[ "$ENABLE_SECOND_MONITOR" == "yes" ]]; then
            echo "[${NUT_SECOND_USER}]"
            echo "  password = ${NUT_SECOND_PASS}"
            echo "  upsmon slave"
            echo
        fi
        echo "[admin]"
        echo "  password = [REDACTED]
        echo "  actions = SET"
        echo "  actions = FSD"
        echo "  instcmds = ALL"
        echo
    } > "${GENERATED_DIR}/upsd.users"
}

generate_upsmon_conf() {
    {
        echo "# ------------------------------------------------------------------"
        echo "# GENERATED TEMPLATE: /etc/nut/upsmon.conf"
        echo "# Review MONITOR lines before applying."
        echo "# ------------------------------------------------------------------"
        echo
        echo "RUN_AS_USER nut"
        echo "MONITOR ups1@localhost 1 ${NUT_MONITOR_USER} ${NUT_MONITOR_PASS} master"
        if [[ "$ENABLE_SECOND_MONITOR" == "yes" ]]; then
            echo "# Example second monitor account usage:"
            echo "# MONITOR ups1@localhost 1 ${NUT_SECOND_USER} ${NUT_SECOND_PASS} slave"
        fi
        echo "MINSUPPLIES 1"
        echo "SHUTDOWNCMD \"${DEFAULT_SHUTDOWN_CMD}\""
        echo "POWERDOWNFLAG ${DEFAULT_POWERDOWNFLAG}"
        echo "POLLFREQ 5"
        echo "POLLFREQALERT 5"
        echo "HOSTSYNC 15"
        echo "DEADTIME 15"
        echo "RBWARNTIME 43200"
        echo "NOCOMMWARNTIME 300"
        echo "FINALDELAY 5"
    } > "${GENERATED_DIR}/upsmon.conf"
}

generate_apache_notes() {
    cat > "${GENERATED_DIR}/apache-notes.txt" <<'EOF'
Apache/NUT-CGI notes:
- Package: nut-cgi
- Apache CGI usually needs:
    a2enmod cgi
- NUT CGI path is commonly:
    /usr/lib/cgi-bin/nut/
  or
    /usr/lib/cgi-bin/
- Test URLs:
    http://localhost/cgi-bin/nut/upsstats.cgi
    http://<server-ip>/cgi-bin/nut/upsstats.cgi

If the CGI path differs on your system:
- inspect package files:
    dpkg -L nut-cgi
EOF
}

generate_all_configs() {
    log "Generating staged configuration files under $GENERATED_DIR"
    generate_nut_conf
    generate_ups_conf
    generate_upsd_conf
    generate_upsd_users
    generate_upsmon_conf
    generate_apache_notes
}

########################################
# Review prompts
########################################

review_discovery_prompt() {
    pause_for_human "Review discovery results in:
  ${DISCOVERY_DIR}

Key files:
  - lsusb.txt
  - dmesg-ups.txt
  - serial-by-id.txt
  - nut-scanner-U.txt
  - upsdrvctl-drivers.txt

Also update:
  ${INVENTORY_CSV}

Confirm likely drivers, ports, and UPS identities before continuing."
}

review_generated_configs_prompt() {
    pause_for_human "Review staged configs in:
  ${GENERATED_DIR}

Check:
  - ups.conf
  - upsd.users
  - upsmon.conf
  - upsd.conf

Make any edits needed before apply.
This is where human confirmation is required for:
  - correct driver
  - correct port
  - correct UPS name
  - credentials
  - remote LISTEN IP"
}

########################################
# Apply generated configs
########################################

apply_configs() {
    if [[ "$APPLY_CHANGES" != "yes" ]]; then
        log "Apply flag not set. Skipping copy into /etc/nut."
        return 0
    fi

    if ! prompt_yes_no "Apply staged configs from ${GENERATED_DIR} into /etc/nut?" "no"; then
        log "User chose not to apply configs."
        return 0
    fi

    log "Applying configs into /etc/nut"
    ensure_dir /etc/nut

    cp -f "${GENERATED_DIR}/nut.conf" /etc/nut/nut.conf
    cp -f "${GENERATED_DIR}/ups.conf" /etc/nut/ups.conf
    cp -f "${GENERATED_DIR}/upsd.conf" /etc/nut/upsd.conf
    cp -f "${GENERATED_DIR}/upsd.users" /etc/nut/upsd.users
    cp -f "${GENERATED_DIR}/upsmon.conf" /etc/nut/upsmon.conf

    chown root:nut /etc/nut/nut.conf /etc/nut/ups.conf /etc/nut/upsd.conf /etc/nut/upsd.users /etc/nut/upsmon.conf || warn "Could not set root:nut ownership"
    chmod 750 /etc/nut || warn "Could not chmod 750 /etc/nut"
    chmod 640 /etc/nut/nut.conf /etc/nut/ups.conf /etc/nut/upsd.conf /etc/nut/upsd.users /etc/nut/upsmon.conf || warn "Could not set mode 640 on NUT configs"

    log "Config apply complete"
}

########################################
# Apache / CGI setup
########################################

configure_apache_for_nut_cgi() {
    log "Configuring Apache for NUT CGI"

    maybe_run_cmd "Enable Apache CGI module" a2enmod cgi

    # Try to discover nut-cgi installed files
    maybe_run_cmd "List nut-cgi package files" bash -c "dpkg -L nut-cgi > '${REPORTS_DIR}/nut-cgi-files.txt'"

    # We do not force-create custom Apache site files here because package layouts can differ.
    # Restart Apache after enabling CGI.
    maybe_run_cmd "Enable apache2" systemctl enable apache2
    maybe_run_cmd "Restart apache2" systemctl restart apache2
}

########################################
# Start/restart services
########################################

enable_and_restart_services() {
    log "Enabling and restarting NUT/Apache services"

    maybe_run_cmd "Enable nut-server" systemctl enable nut-server
    maybe_run_cmd "Enable nut-monitor" systemctl enable nut-monitor
    maybe_run_cmd "Restart nut-server" systemctl restart nut-server
    maybe_run_cmd "Restart nut-monitor" systemctl restart nut-monitor

    configure_apache_for_nut_cgi
}

########################################
# Validation
########################################

validate_services() {
    log "Running validation checks"
    : > "$VALIDATION_REPORT"

    {
        echo "Validation Report - ${TIMESTAMP}"
        echo "============================================================"
        echo
        echo "Service Status"
        echo "------------------------------------------------------------"
        systemctl status nut-server --no-pager || true
        echo
        systemctl status nut-monitor --no-pager || true
        echo
        systemctl status apache2 --no-pager || true
        echo
        echo "Listening Ports"
        echo "------------------------------------------------------------"
        ss -tulpn | grep -E '3493|:80|:443' || true
        echo
        echo "UPS Query Test"
        echo "------------------------------------------------------------"
        upsc ups1@localhost || true
        echo
        echo "Apache URL Probe"
        echo "------------------------------------------------------------"
        curl -I http://localhost/ || true
        echo
        curl -I http://localhost/cgi-bin/nut/upsstats.cgi || true
        echo
        echo "Recent Logs"
        echo "------------------------------------------------------------"
        journalctl -u nut-server -n 50 --no-pager || true
        echo
        journalctl -u nut-monitor -n 50 --no-pager || true
        echo
        journalctl -u apache2 -n 50 --no-pager || true
    } >> "$VALIDATION_REPORT"

    log "Validation report written to $VALIDATION_REPORT"
}

########################################
# Main
########################################

main() {
    parse_args "$@"
    preflight_checks

    log "Selected options:"
    log "  NUT mode: $NUT_MODE"
    log "  Remote listen IP: ${REMOTE_LISTEN_IP:-<none>}"
    log "  Enable second monitor: $ENABLE_SECOND_MONITOR"
    log "  Apply changes: $APPLY_CHANGES"

    if prompt_yes_no "Proceed with backup and clean removal of any previous NUT/Apache install?" "yes"; then
        backup_existing_install
        stop_existing_services
        disable_existing_services
        remove_old_packages
        remove_old_directories
    else
        die "User aborted before clean removal."
    fi

    install_fresh_packages
    run_discovery
    generate_inventory_csv
    generate_runbook_md
    generate_all_configs

    review_discovery_prompt
    review_generated_configs_prompt

    apply_configs

    if [[ "$APPLY_CHANGES" == "yes" ]]; then
        if prompt_yes_no "Start/restart services and run validation now?" "yes"; then
            enable_and_restart_services
            validate_services
            pause_for_human "Review validation report:
  ${VALIDATION_REPORT}

Important:
  - A clean service status does NOT prove shutdown behavior is correct.
  - Perform a controlled human-led power test before production use."
        else
            warn "User skipped service start/validation."
        fi
    else
        log "Configs were not applied. Skipping service start and validation."
    fi

    log "Bootstrap process complete."
    echo
    echo "Work directory:      ${WORK_DIR}"
    echo "Backups directory:   ${BACKUP_DIR}"
    echo "Discovery files:     ${DISCOVERY_DIR}"
    echo "Generated configs:   ${GENERATED_DIR}"
    echo "Inventory CSV:       ${INVENTORY_CSV}"
    echo "Runbook:             ${RUNBOOK_MD}"
    echo "Validation report:   ${VALIDATION_REPORT}"
    echo
    echo "Done."
}

main "$@"
