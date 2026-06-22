#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/opt/nut-admin/repo-template"
TARGET_BRANCH="backup-sanitized-initial"
LOG_FILE="/var/log/nut-orchestrator-ui/backup.log"
HOST_USER="nutserver"
HOST_GROUP="nutserver"
CREATED_PRE_PULL_COMMIT="0"
CREATED_BACKUP_COMMIT="0"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  AS_ROOT=""
else
  AS_ROOT="sudo"
fi

run_git() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    GIT_SSH_COMMAND='ssh -i /etc/nut-orchestrator-ui/ssh/nutserver_github_ed25519 -o UserKnownHostsFile=/etc/nut-orchestrator-ui/ssh/known_hosts -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes' git "$@"
  else
    GIT_SSH_COMMAND='ssh -i /home/nutserver/.ssh/id_ed25519 -o UserKnownHostsFile=/home/nutserver/.ssh/known_hosts -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new' git "$@"
  fi
}

log() {
  echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

repo_has_changes() {
  if ! git diff --quiet; then
    return 0
  fi

  if ! git diff --cached --quiet; then
    return 0
  fi

  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    return 0
  fi

  return 1
}

fail_if_repo_has_secrets() {
  if find "$REPO_DIR" -type f \( \
      -path '*/root/.ssh/*' \
      -o -path '*/.ssh/*' \
      -o -name '*.pass' \
      -o -name '*.secret' \
      -o -name '*.creds' \
      -o -name 'vcenter.pass' \
      -o -name 'db-telnet.pass' \
      -o -name '*.key' \
      -o -name '*.pem' \
      -o -name '*.p12' \
      -o -name '*.pfx' \
    \) | grep -q .; then
    log "FAIL: secret-like file detected in repo; refusing to commit"
    find "$REPO_DIR" -type f \( \
      -path '*/root/.ssh/*' \
      -o -path '*/.ssh/*' \
      -o -name '*.pass' \
      -o -name '*.secret' \
      -o -name '*.creds' \
      -o -name 'vcenter.pass' \
      -o -name 'db-telnet.pass' \
      -o -name '*.key' \
      -o -name '*.pem' \
      -o -name '*.p12' \
      -o -name '*.pfx' \
    \) | tee -a "$LOG_FILE"
    exit 1
  fi
}

commit_pending_repo_changes_before_pull() {
  if ! repo_has_changes; then
    log "No pending repo changes before pull"
    return 0
  fi

  log "Pending repo changes detected before pull; protecting them in a pre-pull commit"
  log "Repo status before pre-pull commit:"
  git status --short | tee -a "$LOG_FILE"

  fail_if_repo_has_secrets

  run_git add -A

  if git diff --cached --quiet; then
    log "No staged changes after add; continuing"
    return 0
  fi

  run_git commit -m "Pre-pull saved backup state $(date)"
  CREATED_PRE_PULL_COMMIT="1"
  log "Pre-pull pending repo changes committed"
}

copy_text_file() {
  local src="$1"
  local dest="$2"
  local mode="$3"

  mkdir -p "$(dirname "$dest")"
  ${AS_ROOT} test -f "$src" || {
    log "SKIP missing file: $src"
    return 0
  }

  ${AS_ROOT} cat "$src" > "$dest"
  chmod "$mode" "$dest"
  chown "$HOST_USER:$HOST_GROUP" "$dest"
  log "Copied $src -> $dest"
}

copy_executable_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  ${AS_ROOT} test -f "$src" || {
    log "SKIP missing file: $src"
    return 0
  }

  ${AS_ROOT} cat "$src" > "$dest"
  chmod 755 "$dest"
  chown "$HOST_USER:$HOST_GROUP" "$dest"
  log "Copied executable $src -> $dest"
}

copy_sanitized_config_file() {
  local src="$1"
  local dest="$2"
  local mode="${3:-640}"

  mkdir -p "$(dirname "$dest")"
  ${AS_ROOT} test -f "$src" || {
    log "SKIP missing file: $src"
    return 0
  }

  ${AS_ROOT} sed -E \
    -e 's/^([A-Za-z0-9_]*(PASSWORD|PASS|TOKEN|SECRET|KEY)[A-Za-z0-9_]*=).*/\1"REDACTED"/I' \
    "$src" > "$dest"

  chmod "$mode" "$dest"
  chown "$HOST_USER:$HOST_GROUP" "$dest"
  log "Copied sanitized config $src -> $dest"
}

main() {
  require_cmd git
  require_cmd sudo

  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  cd "$REPO_DIR"

  log "===== BACKUP START ====="

  commit_pending_repo_changes_before_pull

  run_git fetch origin
  run_git pull --rebase origin "$TARGET_BRANCH"

  log "Syncing safe live files into repo after pull"
  /usr/local/sbin/nut-sync-live-to-repo-for-backup

  mkdir -p ./opt/nut-orchestrator-ui/{lib,templates,static}
  mkdir -p ./etc/systemd/system
  mkdir -p ./usr/local/sbin
  mkdir -p ./usr/local/bin
  mkdir -p ./etc/nut/config.d
  mkdir -p ./etc/nut

  # UI + backend
  copy_text_file /opt/nut-orchestrator-ui/app.py ./opt/nut-orchestrator-ui/app.py 644
  copy_text_file /opt/nut-orchestrator-ui/requirements.txt ./opt/nut-orchestrator-ui/requirements.txt 644
  copy_text_file /opt/nut-orchestrator-ui/lib/config_registry.json ./opt/nut-orchestrator-ui/lib/config_registry.json 644
  copy_executable_file /opt/nut-orchestrator-ui/lib/validators.sh ./opt/nut-orchestrator-ui/lib/validators.sh
  copy_text_file /opt/nut-orchestrator-ui/templates/index.html ./opt/nut-orchestrator-ui/templates/index.html 644
  copy_text_file /opt/nut-orchestrator-ui/templates/control-center.html ./opt/nut-orchestrator-ui/templates/control-center.html 644
  copy_text_file /opt/nut-orchestrator-ui/static/app.js ./opt/nut-orchestrator-ui/static/app.js 644
  copy_text_file /opt/nut-orchestrator-ui/static/nut-ui-theme.css ./opt/nut-orchestrator-ui/static/nut-ui-theme.css 644

  # Dashboard + shared power event feed generator
  mkdir -p ./var/www/html
  copy_text_file /var/www/html/nutserver-dashboard.priority1.html ./var/www/html/nutserver-dashboard.priority1.html 644
  copy_executable_file /usr/local/sbin/nut-get-power-events-json ./usr/local/sbin/nut-get-power-events-json
  copy_executable_file /usr/local/sbin/nut-apc-idf-event-monitor.sh ./usr/local/sbin/nut-apc-idf-event-monitor.sh

  # systemd
  copy_text_file /etc/systemd/system/nut-orchestrator-ui.service ./etc/systemd/system/nut-orchestrator-ui.service 644
  copy_text_file /etc/systemd/system/nut-power-events-refresh.service ./etc/systemd/system/nut-power-events-refresh.service 644
  copy_text_file /etc/systemd/system/nut-power-events-refresh.timer ./etc/systemd/system/nut-power-events-refresh.timer 644
  copy_text_file /etc/systemd/system/nut-apc-idf-event-monitor.service ./etc/systemd/system/nut-apc-idf-event-monitor.service 644
  copy_text_file /etc/systemd/system/nut-apc-idf-event-monitor.timer ./etc/systemd/system/nut-apc-idf-event-monitor.timer 644

  # core UI scripts
  copy_executable_file /usr/local/sbin/nut-ui-apply-config ./usr/local/sbin/nut-ui-apply-config
  copy_executable_file /usr/local/sbin/nut-ui-run-test ./usr/local/sbin/nut-ui-run-test
  copy_executable_file /usr/local/sbin/nut-ui-run-real-test-approved ./usr/local/sbin/nut-ui-run-real-test-approved
  copy_executable_file /usr/local/sbin/nut-ui-backup-now ./usr/local/sbin/nut-ui-backup-now
  copy_executable_file /usr/local/sbin/nut-run-backup-and-push.sh ./usr/local/sbin/nut-run-backup-and-push.sh
  copy_executable_file /usr/local/sbin/nut-sync-live-to-repo-for-backup ./usr/local/sbin/nut-sync-live-to-repo-for-backup
  copy_executable_file /usr/local/sbin/nut-ui-rollback ./usr/local/sbin/nut-ui-rollback
  copy_executable_file /usr/local/sbin/nut-inventory-configs.sh ./usr/local/sbin/nut-inventory-configs.sh

  # orchestration scripts
  copy_executable_file /usr/local/sbin/nut-lansweeper-shutdown.sh ./usr/local/sbin/nut-lansweeper-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-vmware-export-inventory.sh ./usr/local/sbin/nut-vmware-export-inventory.sh
  copy_executable_file /usr/local/sbin/nut-vmware-shutdown.sh ./usr/local/sbin/nut-vmware-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-vmware-readonly-placement.py ./usr/local/sbin/nut-vmware-readonly-placement.py
  copy_executable_file /usr/local/sbin/nut-netapp-halt.sh ./usr/local/sbin/nut-netapp-halt.sh
  copy_executable_file /usr/local/sbin/nut-synology-shutdown.sh ./usr/local/sbin/nut-synology-shutdown.sh

  copy_sanitized_config_file /etc/nut/synology-api.conf ./etc/nut/synology-api.conf 640

  copy_executable_file /usr/local/sbin/nut-voip-shutdown.sh ./usr/local/sbin/nut-voip-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-db-shutdown.sh ./usr/local/sbin/nut-db-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-blueiris-shutdown.sh ./usr/local/sbin/nut-blueiris-shutdown.sh
  copy_executable_file /usr/local/bin/nut-orchestrator.sh ./usr/local/bin/nut-orchestrator.sh
  copy_executable_file /usr/local/sbin/nut-local-final-shutdown.sh ./usr/local/sbin/nut-local-final-shutdown.sh

  # Core NUT configuration files.
  copy_text_file /etc/nut/ups.conf ./etc/nut/ups.conf 640

  # config.d safe files
  copy_text_file /etc/nut/config.d/nut-orchestrator.conf ./etc/nut/config.d/nut-orchestrator.conf 640
  copy_text_file /etc/nut/config.d/dashboard-ui.json ./etc/nut/config.d/dashboard-ui.json 640
  copy_text_file /etc/nut/config.d/approved-targets.yml ./etc/nut/config.d/approved-targets.yml 640
  copy_text_file /etc/nut/config.d/shutdown-verification-targets.conf ./etc/nut/config.d/shutdown-verification-targets.conf 644

  if [ -f /etc/nut/restore-live-test-probe.txt ]; then
    copy_text_file /etc/nut/restore-live-test-probe.txt ./etc/nut/restore-live-test-probe.txt 644
  fi

  # sanitized main config
  copy_sanitized_config_file /etc/nut/nut-orchestrator.conf ./etc/nut/nut-orchestrator.conf 640

  # Hypervisor SSH fallback support files.
  # Safe backup only: do not copy private SSH keys.
  if [ -f /etc/nut/hypervisors/hypervisor-ssh-fallback.conf ]; then
    mkdir -p ./etc/nut/hypervisors
    copy_text_file /etc/nut/hypervisors/hypervisor-ssh-fallback.conf ./etc/nut/hypervisors/hypervisor-ssh-fallback.conf 640
  fi

  if [ -f /usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh ]; then
    copy_executable_file /usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh ./usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh
  fi

  if [ -f /usr/local/sbin/nut-vcenter-host-action-dry-run.sh ]; then
    copy_executable_file /usr/local/sbin/nut-vcenter-host-action-dry-run.sh ./usr/local/sbin/nut-vcenter-host-action-dry-run.sh
  fi

  if [ -f /usr/local/sbin/nut-ui-live-restore-dry-run ]; then
    copy_executable_file /usr/local/sbin/nut-ui-live-restore-dry-run ./usr/local/sbin/nut-ui-live-restore-dry-run
  fi

  if [ -f /usr/local/sbin/nut-ui-live-restore-selected-dry-run ]; then
    copy_executable_file /usr/local/sbin/nut-ui-live-restore-selected-dry-run ./usr/local/sbin/nut-ui-live-restore-selected-dry-run
  fi

  if [ -f /usr/local/sbin/nut-ui-live-restore-selected ]; then
    copy_executable_file /usr/local/sbin/nut-ui-live-restore-selected ./usr/local/sbin/nut-ui-live-restore-selected
  fi

  chown -R "$HOST_USER:$HOST_GROUP" "$REPO_DIR"

  fail_if_repo_has_secrets

  run_git add -A

  if git diff --cached --quiet; then
    log "No new backup changes to commit after sync"

    if [ "$CREATED_PRE_PULL_COMMIT" = "1" ]; then
      log "Pushing pre-pull commit to GitHub"
      run_git push origin HEAD:"$TARGET_BRANCH"
    else
      log "No changes to push"
    fi
  else
    run_git commit -m "Full sanitized system backup $(date)"
    CREATED_BACKUP_COMMIT="1"
    run_git push origin HEAD:"$TARGET_BRANCH"
  fi

  log "created_pre_pull_commit=${CREATED_PRE_PULL_COMMIT}"
  log "created_backup_commit=${CREATED_BACKUP_COMMIT}"
  log "===== BACKUP END ====="
}

main "$@"
