#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-dry-run}"
STAMP="$(date +%F_%H%M%S)"
BASE="/opt/nut-admin"
OUTDIR="${BASE}/inventory/${STAMP}"
STAGE="${BASE}/repo-template"
BACKUPDIR="${BASE}/backup/${STAMP}"
REPORT="${BASE}/reports/inventory_${STAMP}.md"

mkdir -p "$OUTDIR" "$BACKUPDIR" "$STAGE" "$(dirname "$REPORT")"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root." >&2
    exit 1
  fi
}

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

EXCLUDE_PATHS=(
  "/etc/nut/lansweeper.creds"
  "/etc/shadow"
  "/etc/gshadow"
  "/root/.ssh"
  "/etc/ssh/ssh_host_rsa_key"
  "/etc/ssh/ssh_host_ecdsa_key"
  "/etc/ssh/ssh_host_ed25519_key"
  "/etc/ssl/private"
  "/var/lib"
  "/var/log"
  "/etc/pve"
)

SAFE_STAGE_FILES=(
  "/etc/nut/apache-notes.txt"
  "/etc/nut/nut.conf"
  "/etc/nut/upsmon.conf"
  "/etc/nut/upssched.conf"
  "/etc/nut/upsset.conf"
  "/etc/systemd/system/nut-boot-event-log.service"
  "/etc/systemd/system/nut-fix-sockets.service"
  "/etc/systemd/system/nut-monitor.service.d/override.conf"
  "/etc/systemd/system/tigervnc-backup.service"
  "/etc/systemd/system/x11vnc.service"
  "/usr/local/bin/nut-test-logic.sh"
  "/usr/local/sbin/nut-boot-event-log.sh"
  "/usr/local/sbin/nut-fix-sockets.sh"
  "/usr/local/sbin/rollback-remote-access.sh"
)

CANDIDATES=(
  "/etc/nut"
  "/usr/local/sbin"
  "/usr/local/bin"
  "/etc/systemd/system"
  "/opt"
)

SECRET_PATTERNS='[REDACTED]'
SENSITIVE_INFRA_PATTERNS='([0-9]{1,3}\.){3}[0-9]{1,3}|([A-Za-z0-9._-]+\.)+(local|lan|corp|internal)|vcenter|esxi|netapp|proxmox|synology|blueiris|lansweeper|cisco|vmware'

is_excluded_path() {
  local f="$1"
  local p
  for p in "${EXCLUDE_PATHS[@]}"; do
    [[ "$f" == "$p" ]] && return 0
  done
  return 1
}

is_safe_allowlisted() {
  local f="$1"
  local p
  for p in "${SAFE_STAGE_FILES[@]}"; do
    [[ "$f" == "$p" ]] && return 0
  done
  return 1
}

list_candidate_files() {
  local root
  for root in "${CANDIDATES[@]}"; do
    [[ -e "$root" ]] || continue
    find "$root" -xdev -type f \( \
      -name "*.conf" -o -name "*.service" -o -name "*.timer" -o \
      -name "*.sh" -o -name "*.py" -o -name "*.pl" -o \
      -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o \
      -name "*.ini" -o -name "*.md" -o -name "*.txt" -o -name "README*" \
    \) 2>/dev/null
  done | sort -u
}

safe_relpath() {
  local f="$1"
  printf '%s' "${f#/}"
}

copy_sanitized() {
  local src="$1"
  local rel dest tmp
  rel="$(safe_relpath "$src")"
  dest="${STAGE}/${rel}"
  mkdir -p "$(dirname "$dest")"

  tmp="$(mktemp)"
  sed -E \
    -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/REDACTED_IP/g' \
    -e 's/(password|passwd|secret|token|apikey|api_key)[[:space:]]*[:=][[:space:]]*.+/\1=REDACTED/gI' \
    -e 's/(user(name)?)[[:space:]]*[:=][[:space:]]*.+/\1=REDACTED/gI' \
    -e 's/(host(name)?)[[:space:]]*[:=][[:space:]]*.+/\1=REDACTED/gI' \
    -e 's/(community)[[:space:]]*[:=][[:space:]]*.+/\1=REDACTED/gI' \
    -e 's/(bindpw)[[:space:]]*[:=][[:space:]]*.+/\1=REDACTED/gI' \
    -e 's/^(MONITOR[[:space:]]+[^[:space:]]+[[:space:]]+[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+)[^[:space:]]+([[:space:]]+.*)$/\1REDACTED\2/I' \
    "$src" > "$tmp" || cp -a "$src" "$tmp"

  mv "$tmp" "$dest"
  chmod 640 "$dest" || true
}

backup_original() {
  local src="$1"
  local rel dest
  rel="$(safe_relpath "$src")"
  dest="${BACKUPDIR}/${rel}"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
}

require_root

FILES_FILE="${OUTDIR}/candidate_files.txt"
META_CSV="${OUTDIR}/inventory.csv"
STAGE_LIST="${OUTDIR}/stage_list.txt"
SKIP_LIST="${OUTDIR}/skip_list.txt"

: > "$FILES_FILE"
: > "$META_CSV"
: > "$STAGE_LIST"
: > "$SKIP_LIST"

echo 'path,owner,group,mode,sha256,contains_secret_pattern,contains_infra_pattern' > "$META_CSV"

while IFS= read -r f; do
  [[ -f "$f" ]] || continue

  if is_excluded_path "$f"; then
    echo "$f" >> "$SKIP_LIST"
    continue
  fi

  owner="$(stat -c '%U' "$f")"
  group="$(stat -c '%G' "$f")"
  mode="$(stat -c '%a' "$f")"
  sum="$(sha256_file "$f")"

  secret_flag="[REDACTED]"
  infra_flag="no"

  if grep -Eqi "$SECRET_PATTERNS" "$f" 2>/dev/null; then
    secret_flag="[REDACTED]"
  fi

  if grep -Eqi "$SENSITIVE_INFRA_PATTERNS" "$f" 2>/dev/null; then
    infra_flag="yes"
  fi

  printf '%s,%s,%s,%s,%s,%s,%s\n' \
    "$f" "$owner" "$group" "$mode" "$sum" "$secret_flag" "$infra_flag" >> "$META_CSV"

  echo "$f" >> "$FILES_FILE"

  if [[ "$secret_flag" == "yes" ]] || [[ "$infra_flag" == "yes" ]] || ! is_safe_allowlisted "$f"; then
    echo "$f" >> "$SKIP_LIST"
    continue
  fi

  echo "$f" >> "$STAGE_LIST"

  if [[ "$MODE" == "apply" ]]; then
    backup_original "$f"
    copy_sanitized "$f"
  fi
done < <(list_candidate_files)

cat > "$REPORT" <<MD
# NUT Server Config / Code Inventory

Generated: $(date)

## Summary
- Mode: ${MODE}
- Inventory file: \`${META_CSV}\`
- Candidate file list: \`${FILES_FILE}\`
- Stage list: \`${STAGE_LIST}\`
- Skip list: \`${SKIP_LIST}\`
- Backup dir: \`${BACKUPDIR}\`
- Staging dir: \`${STAGE}\`

## Rules Applied
- Secret-bearing files are excluded from Git staging
- Infra-bearing files are excluded from Git staging by default
- Only explicitly allowlisted files can be staged
- Known sensitive files like \`/etc/nut/lansweeper.creds\` are always excluded
MD

log "Done. Report: ${REPORT}"
