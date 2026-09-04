#!/usr/bin/env bash

set -u

TARGET="${1:-}"

V24013_HOST="198.51.100.10"

DB01_PROD="198.51.100.11"
DB02_PROD="198.51.100.12"
TESTV240_OLD="198.51.100.13"

SECRET_FILE="/etc/nut/secrets/solaris-server-shutdown.env"

SIMULATE="${SIMULATE:-1}"
ALLOW_REAL_TEST="${ALLOW_REAL_TEST:-0}"
REAL_TEST_PHASE="${REAL_TEST_PHASE:-}"
V24013_LIVE_APPROVED="${V24013_LIVE_APPROVED:-0}"

COMMAND_TIMEOUT="${V24013_COMMAND_TIMEOUT:-30}"

SHUTDOWN_COMMAND="/usr/sbin/shutdown -i5 -g0 -y 'UPS power event'"

LOG_FILE="/var/log/nut-solaris-server-shutdown.log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE"
}

die() {
    log "BLOCKED: $*"
    exit 1
}

get_live_actions() {
    if [ -x /usr/local/sbin/nut-production-status ]; then
        /usr/local/sbin/nut-production-status 2>/dev/null \
            | python3 -c '
import json
import sys

try:
    d = json.load(sys.stdin)
    print(d.get("allow_live_actions", "0"))
except Exception:
    print("0")
'
    else
        echo "0"
    fi
}

if [ "$TARGET" != "SOLARIS_SERVER" ]; then
    die "only target SOLARIS_SERVER is permitted"
fi

HOST="$V24013_HOST"

case "$HOST" in
    "$DB01_PROD")
        die "DB_SERVER_1 production address is prohibited"
        ;;
    "$DB02_PROD")
        die "DB_SERVER_2 production address is prohibited"
        ;;
    "$TESTV240_OLD")
        die "old TEST_SOLARIS address is prohibited"
        ;;
esac

if [ "$HOST" != "198.51.100.10" ]; then
    die "SOLARIS_SERVER host does not exactly match 198.51.100.10"
fi

log "SOLARIS_SERVER shutdown wrapper starting"
log "Target=$TARGET"
log "Host=$HOST"
log "SIMULATE=$SIMULATE"
log "COMMAND PREVIEW: telnet $HOST; authenticate using protected local secret; send Solaris shutdown command"

if [ "$SIMULATE" != "0" ]; then
    log "SIMULATION ONLY: no network connection made and no shutdown command sent"
    exit 0
fi

#
# Live execution is permitted only from the production outage path.
#
if [ "$ALLOW_REAL_TEST" != "1" ]; then
    die "ALLOW_REAL_TEST is not 1"
fi

if [ "$REAL_TEST_PHASE" != "full-production" ]; then
    die "REAL_TEST_PHASE must equal full-production"
fi

if [ "$V24013_LIVE_APPROVED" != "1" ]; then
    die "V24013_LIVE_APPROVED is not 1"
fi

LIVE_ALLOWED="$(get_live_actions)"

log "NUT_ALLOW_LIVE_ACTIONS=$LIVE_ALLOWED"

if [ "$LIVE_ALLOWED" != "1" ]; then
    die "production mode does not allow live actions"
fi

if [ ! -r "$SECRET_FILE" ]; then
    die "protected SOLARIS_SERVER credential file is unavailable"
fi

# shellcheck disable=SC1090
. "$SECRET_FILE"

V24013_USERNAME="${V24013_USERNAME:-}"
V24013_PASSWORD="${V24013_PASSWORD:-}"

if [ -z "$V24013_USERNAME" ]; then
    die "V24013_USERNAME is missing"
fi

if [ -z "$V24013_PASSWORD" ]; then
    die "V24013_PASSWORD is missing"
fi

if ! ping -c 2 -W 2 "$HOST" >/dev/null 2>&1; then
    die "SOLARIS_SERVER is not reachable before shutdown attempt"
fi

if ! timeout 5 bash -c "</dev/tcp/${HOST}/23" >/dev/null 2>&1; then
    die "SOLARIS_SERVER Telnet port 23 is not reachable"
fi

log "PRECHECK PASS: SOLARIS_SERVER responds to ping and Telnet port 23"

export V24013_HOST
export V24013_USERNAME
export V24013_PASSWORD
export V24013_SHUTDOWN_COMMAND="$SHUTDOWN_COMMAND"
export V24013_COMMAND_TIMEOUT="$COMMAND_TIMEOUT"

expect <<'EXPECT'
set timeout 15

set host $env(V24013_HOST)
set username $env(V24013_USERNAME)
set password $env(V24013_PASSWORD)
set shutdown_cmd $env(V24013_SHUTDOWN_COMMAND)

spawn telnet $host

expect {
    -nocase -re {login:[[:space:]]*$} {
        send -- "$username\r"
    }
    timeout {
        puts "ERROR: Telnet login prompt timeout"
        exit 40
    }
    eof {
        puts "ERROR: Telnet ended before login prompt"
        exit 41
    }
}

expect {
    -nocase -re {password:[[:space:]]*$} {
        log_user 0
        send -- "$password\r"
        log_user 1
    }
    timeout {
        puts "ERROR: password prompt timeout"
        exit 42
    }
    eof {
        puts "ERROR: Telnet ended before password prompt"
        exit 43
    }
}

set timeout $env(V24013_COMMAND_TIMEOUT)

expect {
    -re {[$#%>] *$} {
        send -- "$shutdown_cmd\r"
    }
    timeout {
        puts "ERROR: shell prompt timeout after login"
        exit 44
    }
    eof {
        puts "ERROR: Telnet ended before shell prompt"
        exit 45
    }
}

expect {
    eof {
        exit 0
    }
    timeout {
        puts "INFO: shutdown command sent; Telnet session remained open through command timeout"
        exit 0
    }
}
EXPECT

COMMAND_RC=$?

if [ "$COMMAND_RC" -ne 0 ]; then
    log "FAIL: SOLARIS_SERVER Telnet shutdown command failed rc=$COMMAND_RC"
    exit "$COMMAND_RC"
fi

log "COMMAND SENT: SOLARIS_SERVER Solaris shutdown command accepted"
exit 0
