#!/bin/bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
#
# Dedicated Sun Fire V240 shutdown validation wrapper.
#
# SAFETY:
#   This test wrapper may ONLY target TEST_SOLARIS at 198.51.100.100.
#   It must never target DB_SERVER_1, DB_SERVER_2, or the future/final .13 address of this
#   same physical V240; controlled testing is locked to its temporary .85 IP.

set -u
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMON_EXPECT="$SCRIPT_DIR/solaris-v240-common.exp"

TARGET="${1:-}"

TEST_HOST="198.51.100.10"

DB01_PROD="198.51.100.11"
DB02_PROD="198.51.100.12"
V240_FUTURE="198.51.100.13"

SECRET_FILE="/etc/nut/secrets/v240-test-shutdown.env"
PRODUCTION_ENV="/etc/nut/production-mode.conf"
LOG_FILE="/var/log/nut-v240-test-shutdown.log"

SIMULATE="${SIMULATE:-1}"
ALLOW_V240_TEST="${ALLOW_V240_TEST:-0}"
V240_TEST_CONFIRM="${V240_TEST_CONFIRM:-}"

LOGIN_TIMEOUT="${V240_TEST_LOGIN_TIMEOUT:-20}"
COMMAND_TIMEOUT="${V240_TEST_COMMAND_TIMEOUT:-30}"
VERIFY_TIMEOUT="${V240_TEST_VERIFY_TIMEOUT:-300}"

SHUTDOWN_COMMAND="/usr/sbin/shutdown -i5 -g0 -y"

ts() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    echo "[$(ts)] $*" | tee -a "$LOG_FILE"
}

die() {
    log "BLOCKED: $*"
    exit 1
}

get_live_actions_allowed() {
    if [ -f "$PRODUCTION_ENV" ]; then
        # shellcheck disable=SC1090
        . "$PRODUCTION_ENV"
    fi

    echo "${NUT_ALLOW_LIVE_ACTIONS:-0}"
}

if [ "$TARGET" != "TEST_SOLARIS" ]; then
    die "only target TEST_SOLARIS is permitted"
fi

HOST="$TEST_HOST"

case "$HOST" in
    "$DB01_PROD"|"$DB02_PROD"|"$V240_FUTURE")
        die "production/future V240 address explicitly prohibited: $HOST"
        ;;
esac

if [ "$HOST" != "198.51.100.10" ]; then
    die "test host safety lock failed"
fi

log "TEST_SOLARIS wrapper starting"
log "Target=$TARGET"
log "Host=$HOST"
log "SIMULATE=$SIMULATE"

log "COMMAND PREVIEW: telnet $HOST; authenticate using protected local secret; send Solaris shutdown command"

if [ "$SIMULATE" != "0" ]; then
    log "SIMULATION ONLY: no network connection made and no shutdown command sent"
    exit 0
fi

if [ "$ALLOW_V240_TEST" != "1" ]; then
    die "ALLOW_V240_TEST is not 1"
fi

if [ "$V240_TEST_CONFIRM" != "TEST_SOLARIS-198.51.100.10" ]; then
    die "V240_TEST_CONFIRM does not exactly match TEST_SOLARIS-198.51.100.10"
fi

LIVE_ALLOWED="$(get_live_actions_allowed)"

log "NUT_ALLOW_LIVE_ACTIONS=$LIVE_ALLOWED"

if [ "$LIVE_ALLOWED" != "1" ]; then
    die "current NUT mode does not allow live actions"
fi

if [ ! -r "$SECRET_FILE" ]; then
    die "protected test credential file is missing"
fi

# shellcheck disable=SC1090
. "$SECRET_FILE"

V240_TEST_USERNAME="${V240_TEST_USERNAME:-}"
V240_TEST_PASSWORD="${V240_TEST_PASSWORD:-}"

if [ -z "$V240_TEST_USERNAME" ]; then
    die "V240_TEST_USERNAME is missing"
fi

if [ -z "$V240_TEST_PASSWORD" ]; then
    die "V240_TEST_PASSWORD is missing"
fi

if [ "$V240_TEST_USERNAME" != "root" ]; then
    die "TEST_SOLARIS requires direct root Telnet login"
fi

if ! command -v expect >/dev/null 2>&1; then
    die "expect is not installed"
fi

if ! command -v telnet >/dev/null 2>&1; then
    die "telnet client is not installed"
fi

#
# A live test must begin with the target online.
# Otherwise an already-off machine could be falsely classified as
# a successful shutdown.
#
if ! ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
    die "TEST_SOLARIS is not reachable before shutdown attempt"
fi

#
# Confirm Telnet port is reachable before sending any command.
#
if ! timeout 5 bash -c "</dev/tcp/${HOST}/23" >/dev/null 2>&1; then
    die "TEST_SOLARIS Telnet port 23 is not reachable"
fi

log "PRECHECK PASS: TEST_SOLARIS responds to ping and Telnet port 23"

export V240_HOST="$HOST"
export V240_USERNAME="$V240_TEST_USERNAME"
export V240_PASSWORD="$V240_TEST_PASSWORD"
export V240_LOGIN_TIMEOUT="$LOGIN_TIMEOUT"
export V240_COMMAND_TIMEOUT="$COMMAND_TIMEOUT"
export V240_SHUTDOWN_COMMAND="$SHUTDOWN_COMMAND"

/usr/bin/expect "$COMMON_EXPECT" >> "$LOG_FILE" 2>&1

COMMAND_RC=$?

if [ "$COMMAND_RC" -ne 0 ]; then
    log "FAIL: Telnet shutdown command failed rc=$COMMAND_RC"
    exit "$COMMAND_RC"
fi

log "COMMAND SENT: waiting for TEST_SOLARIS shutdown verification"

VERIFY_RC=99

if [ -x /usr/local/sbin/nut-verify-target-down.sh ]; then
    /usr/local/sbin/nut-verify-target-down.sh \
        TEST_SOLARIS \
        "$HOST" \
        "$VERIFY_TIMEOUT"

    VERIFY_RC=$?
else
    log "WARN: shutdown verification helper missing"
fi

if [ -x /usr/local/sbin/nut-classify-shutdown-result ]; then
    /usr/local/sbin/nut-classify-shutdown-result \
        TEST_SOLARIS \
        "$COMMAND_RC" \
        "$VERIFY_RC"

    CLASSIFY_RC=$?
else
    log "WARN: shutdown classifier missing"
    CLASSIFY_RC=3
fi

case "$CLASSIFY_RC" in
    0)
        log "PASS: TEST_SOLARIS shutdown confirmed"
        ;;
    1)
        log "FAIL: TEST_SOLARIS shutdown failed or remained online"
        ;;
    2)
        log "UNKNOWN: shutdown could not be verified"
        ;;
    *)
        log "WARN: shutdown command sent but result was not conclusively verified"
        ;;
esac

exit "$CLASSIFY_RC"
