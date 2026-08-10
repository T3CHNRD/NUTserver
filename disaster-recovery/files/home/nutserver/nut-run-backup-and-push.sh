#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/opt/nut-admin/repo-template"
TARGET_BRANCH="backup-sanitized-initial"
LOG_FILE="/var/log/nut-orchestrator-ui/backup.log"
HOST_USER="nutserver"
HOST_GROUP="nutserver"

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
  sudo test -f "$src" || {
    log "SKIP missing file: $src"
    return 0
  }

  sudo cat "$src" > "$dest"
  chmod "$mode" "$dest"
  chown "$HOST_USER:$HOST_GROUP" "$dest"
  log "Copied $src -> $dest"
}

copy_executable_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"
  sudo test -f "$src" || {
    log "SKIP missing file: $src"
    return 0
  }

  sudo cat "$src" > "$dest"
  chmod 755 "$dest"
  chown "$HOST_USER:$HOST_GROUP" "$dest"
  log "Copied executable $src -> $dest"
}

main() {
  require_cmd git
  require_cmd sudo

  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Repo not found: $REPO_DIR" >&2
    exit 1
  fi

  cd "$REPO_DIR"

  log "BUTTON-PROOF: nut-run-backup-and-push.sh entered"
  log "===== BACKUP START ====="
  log "Repo: $REPO_DIR"

  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  log "Current local branch: $CURRENT_BRANCH"

  REMOTE_URL="$(git remote get-url origin)"
  log "Remote URL: $REMOTE_URL"

  log "Fetching latest changes"
  git fetch origin

  log "Pulling latest repo state with rebase"
  git pull --rebase origin "$TARGET_BRANCH"

  log "Creating target directories"
  mkdir -p ./opt/nut-orchestrator-ui/lib
  mkdir -p ./opt/nut-orchestrator-ui/templates
  mkdir -p ./opt/nut-orchestrator-ui/static
  mkdir -p ./etc/systemd/system
  mkdir -p ./usr/local/sbin
  mkdir -p ./etc/nut/config.d

  log "Copying safe UI files"
  copy_text_file /opt/nut-orchestrator-ui/app.py ./opt/nut-orchestrator-ui/app.py 644
  copy_text_file /opt/nut-orchestrator-ui/requirements.txt ./opt/nut-orchestrator-ui/requirements.txt 644
  copy_text_file /opt/nut-orchestrator-ui/lib/config_registry.json ./opt/nut-orchestrator-ui/lib/config_registry.json 644
  copy_executable_file /opt/nut-orchestrator-ui/lib/validators.sh ./opt/nut-orchestrator-ui/lib/validators.sh
  copy_text_file /opt/nut-orchestrator-ui/templates/index.html ./opt/nut-orchestrator-ui/templates/index.html 644
  copy_text_file /opt/nut-orchestrator-ui/static/app.js ./opt/nut-orchestrator-ui/static/app.js 644

  copy_text_file /etc/systemd/system/nut-orchestrator-ui.service ./etc/systemd/system/nut-orchestrator-ui.service 644

  copy_executable_file /usr/local/sbin/nut-ui-apply-config ./usr/local/sbin/nut-ui-apply-config
  copy_executable_file /usr/local/sbin/nut-ui-run-test ./usr/local/sbin/nut-ui-run-test
  copy_executable_file /usr/local/sbin/nut-ui-backup-now ./usr/local/sbin/nut-ui-backup-now
  copy_executable_file /usr/local/sbin/nut-ui-rollback ./usr/local/sbin/nut-ui-rollback
  copy_executable_file /usr/local/sbin/nut-inventory-configs.sh ./usr/local/sbin/nut-inventory-configs.sh

  copy_text_file /etc/nut/config.d/nut-orchestrator.conf ./etc/nut/config.d/nut-orchestrator.conf 640
  copy_text_file /etc/nut/config.d/dashboard-ui.json ./etc/nut/config.d/dashboard-ui.json 640
  copy_text_file /etc/nut/config.d/approved-targets.yml ./etc/nut/config.d/approved-targets.yml 640

  log "Normalizing repo ownership"
  chown -R "$HOST_USER:$HOST_GROUP" "$REPO_DIR"

  log "Git status after copy"
  git status --short | tee -a "$LOG_FILE"

  log "Staging changes"
  git add \
    ./opt/nut-orchestrator-ui \
    ./etc/systemd/system/nut-orchestrator-ui.service \
    ./usr/local/sbin/nut-ui-apply-config \
    ./usr/local/sbin/nut-ui-run-test \
    ./usr/local/sbin/nut-ui-backup-now \
    ./usr/local/sbin/nut-ui-rollback \
    ./usr/local/sbin/nut-inventory-configs.sh \
    ./etc/nut/config.d/nut-orchestrator.conf \
    ./etc/nut/config.d/dashboard-ui.json \
    ./etc/nut/config.d/approved-targets.yml

  if git diff --cached --quiet; then
    log "No changes to commit"
  else
    COMMIT_MSG="Update sanitized NUT orchestrator UI backup $(date +%Y-%m-%d\ %H:%M:%S)"
    log "Committing changes"
    git commit -m "$COMMIT_MSG"
    log "Pushing to origin/$TARGET_BRANCH"
    git push origin HEAD:"$TARGET_BRANCH"
  fi

  log "Last 5 commits"
  git log --oneline -n 5 | tee -a "$LOG_FILE"

  log "===== BACKUP END ====="
}

main "$@"
