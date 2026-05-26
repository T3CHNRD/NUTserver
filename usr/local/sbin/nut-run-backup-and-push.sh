#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/opt/nut-admin/repo-template"
TARGET_BRANCH="backup-sanitized-initial"
LOG_FILE="/var/log/nut-orchestrator-ui/backup.log"
HOST_USER="nutserver"
HOST_GROUP="nutserver"

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

main() {
  require_cmd git
  require_cmd sudo

  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  cd "$REPO_DIR"

  log "===== BACKUP START ====="

  run_git fetch origin
  run_git pull --rebase origin "$TARGET_BRANCH"

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
  copy_executable_file /usr/local/sbin/nut-ui-rollback ./usr/local/sbin/nut-ui-rollback
  copy_executable_file /usr/local/sbin/nut-inventory-configs.sh ./usr/local/sbin/nut-inventory-configs.sh

  # orchestration scripts
  copy_executable_file /usr/local/sbin/nut-lansweeper-shutdown.sh ./usr/local/sbin/nut-lansweeper-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-vmware-export-inventory.sh ./usr/local/sbin/nut-vmware-export-inventory.sh
  copy_executable_file /usr/local/sbin/nut-vmware-shutdown.sh ./usr/local/sbin/nut-vmware-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-vmware-readonly-placement.py ./usr/local/sbin/nut-vmware-readonly-placement.py
  copy_executable_file /usr/local/sbin/nut-netapp-halt.sh ./usr/local/sbin/nut-netapp-halt.sh
  copy_executable_file /usr/local/sbin/nut-synology-shutdown.sh ./usr/local/sbin/nut-synology-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-voip-shutdown.sh ./usr/local/sbin/nut-voip-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-db-shutdown.sh ./usr/local/sbin/nut-db-shutdown.sh
  copy_executable_file /usr/local/sbin/nut-blueiris-shutdown.sh ./usr/local/sbin/nut-blueiris-shutdown.sh
  copy_executable_file /usr/local/bin/nut-orchestrator.sh ./usr/local/bin/nut-orchestrator.sh

  # config.d (safe)
  copy_text_file /etc/nut/config.d/nut-orchestrator.conf ./etc/nut/config.d/nut-orchestrator.conf 640
  copy_text_file /etc/nut/config.d/dashboard-ui.json ./etc/nut/config.d/dashboard-ui.json 640
  copy_text_file /etc/nut/config.d/approved-targets.yml ./etc/nut/config.d/approved-targets.yml 640

  # sanitized main config
  if ${AS_ROOT} test -f /etc/nut/nut-orchestrator.conf; then
    ${AS_ROOT} sed \
      -e 's/VCENTER_PASSWORD=.*/VCENTER_PASSWORD="REDACTED"/' \
      -e 's/LANSWEEPER_PASSWORD=.*/LANSWEEPER_PASSWORD="REDACTED"/' \
      /etc/nut/nut-orchestrator.conf > ./etc/nut/nut-orchestrator.conf

    chmod 640 ./etc/nut/nut-orchestrator.conf
    chown "$HOST_USER:$HOST_GROUP" ./etc/nut/nut-orchestrator.conf
    log "Copied sanitized nut-orchestrator.conf"
  fi

  chown -R "$HOST_USER:$HOST_GROUP" "$REPO_DIR"

  run_git add .

  if git diff --cached --quiet; then
    log "No changes to commit"
  else
    run_git commit -m "Full sanitized system backup $(date)"
    run_git push origin HEAD:"$TARGET_BRANCH"
  fi

  log "===== BACKUP END ====="
}

main "$@"
