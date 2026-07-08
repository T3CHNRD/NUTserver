#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u

TARGET="${1:-}"

LOG_FILE="/var/log/nut-db-shutdown.log"
CONFIG_FILE="/etc/nut/db-shutdown.conf"
PRODUCTION_ENV="/etc/nut/production-mode.conf"

SIMULATE="${SIMULATE:-1}"
ALLOW_REAL_TEST="${ALLOW_REAL_TEST:-0}"
REAL_TEST_PHASE="${REAL_TEST_PHASE:-}"
DB_LIVE_APPROVED="${DB_LIVE_APPROVED:-0}"

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(ts)] $1" | tee -a "$LOG_FILE"
}

get_live_actions_allowed() {
  if [ -f "$PRODUCTION_ENV" ]; then
    # shellcheck disable=SC1090
    . "$PRODUCTION_ENV"
  fi

  echo "${NUT_ALLOW_LIVE_ACTIONS:-0}"
}

load_db_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR DB config missing: $CONFIG_FILE"
    exit 10
  fi

  # shellcheck disable=SC1090
  . "$CONFIG_FILE"

  DB_SHUTDOWN_METHOD="${DB_SHUTDOWN_METHOD:-telnet}"
  DB01_HOST="${DB01_HOST:-192.168.1.9}"
  DB02_HOST="${DB02_HOST:-192.168.1.11}"
  DB_USERNAME="${DB_USERNAME:-}"
  DB_PASSWORD="${DB_PASSWORD:-}"
  DB_TELNET_LOGIN_TIMEOUT="${DB_TELNET_LOGIN_TIMEOUT:-20}"
  DB_TELNET_COMMAND_TIMEOUT="${DB_TELNET_COMMAND_TIMEOUT:-30}"
  DB_TELNET_SHUTDOWN_COMMAND="${DB_TELNET_SHUTDOWN_COMMAND:-/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'}"
  DB_SSH_SHUTDOWN_COMMAND="${DB_SSH_SHUTDOWN_COMMAND:-sudo /usr/sbin/poweroff}"
}

validate_common_config() {
  if [ -z "${DB_USERNAME:-}" ]; then
    log "ERROR DB_USERNAME is missing in $CONFIG_FILE"
    exit 11
  fi

  case "$DB_SHUTDOWN_METHOD" in
    telnet|ssh)
      ;;
    *)
      log "ERROR unsupported DB_SHUTDOWN_METHOD='$DB_SHUTDOWN_METHOD' in $CONFIG_FILE"
      exit 12
      ;;
  esac

  if [ "$DB_SHUTDOWN_METHOD" = "telnet" ]; then
    if [ -z "${DB_PASSWORD:-}" ] || [ "$DB_PASSWORD" = "CHANGE_IN_CONTROL_CENTER" ]; then
      log "ERROR DB_PASSWORD is missing or still set to placeholder in $CONFIG_FILE"
      exit 13
    fi

    if ! command -v expect >/dev/null 2>&1; then
      log "ERROR expect is required for DB Telnet automation but is not installed"
      exit 14
    fi

    if ! command -v telnet >/dev/null 2>&1; then
      log "ERROR telnet is required for DB Telnet automation but is not installed"
      exit 15
    fi
  fi
}

resolve_target_host() {
  case "$TARGET" in
    DB01)
      HOST="${DB01_HOST:-}"
      ;;
    DB02)
      HOST="${DB02_HOST:-}"
      ;;
    *)
      log "ERROR unknown target '$TARGET'"
      exit 1
      ;;
  esac

  if [ -z "$HOST" ]; then
    log "ERROR host is missing for target '$TARGET' in $CONFIG_FILE"
    exit 16
  fi
}

run_telnet_shutdown() {
  export DB_HOST="$HOST"
  export DB_USERNAME
  export DB_PASSWORD
  export DB_TELNET_LOGIN_TIMEOUT
  export DB_TELNET_COMMAND_TIMEOUT
  export DB_TELNET_SHUTDOWN_COMMAND

  /usr/bin/expect <<'EXPECT'
set timeout $env(DB_TELNET_LOGIN_TIMEOUT)
set host $env(DB_HOST)
set username $env(DB_USERNAME)
set password $env(DB_PASSWORD)
set shutdown_cmd $env(DB_TELNET_SHUTDOWN_COMMAND)

spawn telnet $host

expect {
  -re "(?i)(login|username).*: *$" {
    send -- "$username\r"
  }
  timeout {
    puts "ERROR telnet login prompt timeout"
    exit 40
  }
  eof {
    puts "ERROR telnet ended before login prompt"
    exit 41
  }
}

expect {
  -re "(?i)password.*: *$" {
    send -- "$password\r"
  }
  timeout {
    puts "ERROR telnet password prompt timeout"
    exit 42
  }
  eof {
    puts "ERROR telnet ended before password prompt"
    exit 43
  }
}

set timeout $env(DB_TELNET_COMMAND_TIMEOUT)

expect {
  -re {[$#%>] *$} {
    send -- "$shutdown_cmd\r"
  }
  timeout {
    puts "ERROR shell prompt timeout after login"
    exit 44
  }
  eof {
    puts "ERROR telnet ended before shell prompt"
    exit 45
  }
}

expect {
  eof {
    exit 0
  }
  timeout {
    puts "INFO command sent; telnet session did not close before timeout"
    exit 0
  }
}
EXPECT
}

run_ssh_shutdown() {
  ssh -o BatchMode=yes -o ConnectTimeout=10 "${DB_USERNAME}@${HOST}" "$DB_SSH_SHUTDOWN_COMMAND"
}

if [ -z "$TARGET" ]; then
  log "ERROR no target provided"
  exit 1
fi

load_db_config
validate_common_config
resolve_target_host

log "Starting DB shutdown wrapper for $TARGET at $HOST"
log "Method=$DB_SHUTDOWN_METHOD"
log "SIMULATE=$SIMULATE"
log "ALLOW_REAL_TEST=$ALLOW_REAL_TEST"
log "REAL_TEST_PHASE=$REAL_TEST_PHASE"
log "DB_LIVE_APPROVED=$DB_LIVE_APPROVED"

case "$DB_SHUTDOWN_METHOD" in
  telnet)
    log "COMMAND PREVIEW: telnet ${HOST}; login user from ${CONFIG_FILE}; send DB_TELNET_SHUTDOWN_COMMAND"
    ;;
  ssh)
    log "COMMAND PREVIEW: ssh ${DB_USERNAME}@${HOST} DB_SSH_SHUTDOWN_COMMAND"
    ;;
esac

if [ "$SIMULATE" != "0" ]; then
  log "SIMULATION ONLY: no DB shutdown command sent for $TARGET"
  exit 0
fi

if [ "$ALLOW_REAL_TEST" != "1" ]; then
  log "BLOCKED: ALLOW_REAL_TEST is not 1"
  exit 20
fi

if [ "$REAL_TEST_PHASE" != "phase3-full" ] && [ "$REAL_TEST_PHASE" != "ups-event" ]; then
  log "BLOCKED: REAL_TEST_PHASE must be phase3-full or ups-event"
  exit 21
fi

if [ "$DB_LIVE_APPROVED" != "1" ]; then
  log "BLOCKED: DB_LIVE_APPROVED is not 1"
  exit 22
fi

LIVE_ALLOWED="$(get_live_actions_allowed)"
log "NUT_ALLOW_LIVE_ACTIONS=$LIVE_ALLOWED"

if [ "$LIVE_ALLOWED" != "1" ]; then
  log "BLOCKED: production mode does not allow live actions"
  exit 23
fi

log "LIVE APPROVED: sending DB shutdown command for $TARGET using method=$DB_SHUTDOWN_METHOD"

case "$DB_SHUTDOWN_METHOD" in
  telnet)
    run_telnet_shutdown >> "$LOG_FILE" 2>&1
    RC=$?
    ;;
  ssh)
    run_ssh_shutdown >> "$LOG_FILE" 2>&1
    RC=$?
    ;;
  *)
    log "ERROR unsupported DB_SHUTDOWN_METHOD='$DB_SHUTDOWN_METHOD'"
    exit 24
    ;;
esac

if [ "$RC" -ne 0 ]; then
  log "ERROR shutdown command failed for $TARGET rc=$RC"
  exit "$RC"
fi

log "SUCCESS shutdown command sent to $TARGET"
exit 0
