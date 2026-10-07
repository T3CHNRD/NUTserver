#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
set -u
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMON_EXPECT="$SCRIPT_DIR/solaris-v240-common.exp"

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
  DB01_HOST="${DB01_HOST:-198.51.100.10}"
  DB02_HOST="${DB02_HOST:-198.51.100.11}"
  DB01_USERNAME="${DB01_USERNAME:-}"
  DB01_PASSWORD="${DB01_PASSWORD:-}"
  DB02_USERNAME="${DB02_USERNAME:-}"
  DB02_PASSWORD="${DB02_PASSWORD:-}"
  DB_TELNET_LOGIN_TIMEOUT="${DB_TELNET_LOGIN_TIMEOUT:-20}"
  DB_TELNET_COMMAND_TIMEOUT="${DB_TELNET_COMMAND_TIMEOUT:-30}"
  DB_TELNET_SHUTDOWN_COMMAND="/usr/sbin/shutdown -i5 -g0 -y"
}

validate_common_config() {
  if [ "$DB_SHUTDOWN_METHOD" != "telnet" ]; then
    log "ERROR DB_SERVER_1/DB_SERVER_2 Solaris V240 targets require the common Telnet method"
    exit 12
  fi

  if ! command -v expect >/dev/null 2>&1; then
    log "ERROR expect is required for DB Telnet automation but is not installed"
    exit 14
  fi

  if ! command -v telnet >/dev/null 2>&1; then
    log "ERROR telnet is required for DB Telnet automation but is not installed"
    exit 15
  fi
}

resolve_target_host() {
  case "$TARGET" in
    DB_SERVER_1)
      HOST="${DB01_HOST:-}"
      DB_USERNAME="${DB01_USERNAME:-}"
      DB_PASSWORD="${DB01_PASSWORD:-}"
      ;;
    DB_SERVER_2)
      HOST="${DB02_HOST:-}"
      DB_USERNAME="${DB02_USERNAME:-}"
      DB_PASSWORD="${DB02_PASSWORD:-}"
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

  if [ "$DB_SHUTDOWN_METHOD" = "telnet" ]; then
    if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "CHANGE_IN_CONTROL_CENTER" ]; then
      log "ERROR target-specific root credentials are missing for '$TARGET'"
      exit 17
    fi
    if [ "$DB_USERNAME" != "root" ]; then
      log "ERROR Solaris V240 target '$TARGET' requires direct root Telnet login"
      exit 25
    fi
  fi
}

run_telnet_shutdown() {
  export V240_HOST="$HOST"
  export V240_USERNAME="$DB_USERNAME"
  export V240_PASSWORD="$DB_PASSWORD"
  export V240_LOGIN_TIMEOUT="$DB_TELNET_LOGIN_TIMEOUT"
  export V240_COMMAND_TIMEOUT="$DB_TELNET_COMMAND_TIMEOUT"
  export V240_SHUTDOWN_COMMAND="$DB_TELNET_SHUTDOWN_COMMAND"
  /usr/bin/expect "$COMMON_EXPECT"
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

log "COMMAND PREVIEW: telnet ${HOST}; login user from ${CONFIG_FILE}; send DB_TELNET_SHUTDOWN_COMMAND"

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

run_telnet_shutdown >> "$LOG_FILE" 2>&1
RC=$?

if [ "$RC" -ne 0 ]; then
  log "FAIL shutdown dialogue or command rejected for $TARGET rc=$RC"
  exit 1
fi

log "COMMAND SENT to $TARGET; independent shutdown verification required"
VERIFY_TIMEOUT="${DB_TELNET_VERIFY_TIMEOUT:-300}"
VERIFY_RC=99
CLASSIFY_RC=3
if [ -x /usr/local/sbin/nut-verify-target-down.sh ]; then
  /usr/local/sbin/nut-verify-target-down.sh "$TARGET" "$HOST" "$VERIFY_TIMEOUT" >> "$LOG_FILE" 2>&1
  VERIFY_RC=$?
else
  log "WARN shutdown verification helper unavailable"
fi
if [ -x /usr/local/sbin/nut-classify-shutdown-result ]; then
  /usr/local/sbin/nut-classify-shutdown-result "$TARGET" "$RC" "$VERIFY_RC" >> "$LOG_FILE" 2>&1
  CLASSIFY_RC=$?
else
  log "WARN shutdown result classifier unavailable"
fi
case "$CLASSIFY_RC" in
  0) log "PASS shutdown confirmed for $TARGET" ;;
  1) log "FAIL $TARGET remained online or command failed" ;;
  2) log "UNKNOWN shutdown could not be verified for $TARGET" ;;
  *) log "UNKNOWN shutdown result for $TARGET" ;;
esac
exit "$CLASSIFY_RC"
