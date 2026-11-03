#!/usr/bin/env bash
# Copyright (c) 2026 T3CHNRD. All rights reserved.
# Observium UPS9 shutdown wrapper. Simulation by default.
set -u
umask 077

CONFIG=/etc/nut/nut-orchestrator.conf
KNOWN_HOSTS=/etc/nut/observium_known_hosts
SIMULATE=${SIMULATE:-1}

if [[ "$SIMULATE" != "0" ]]; then
  printf '%s\n' 'SIMULATION ONLY: Observium shutdown command not sent'
  exit 0
fi

if [[ "${ALLOW_REAL_TEST:-0}" != "1" || "${REAL_TEST_PHASE:-}" != "full-production" || "${OBSERVIUM_LIVE_APPROVED:-0}" != "1" ]]; then
  printf '%s\n' 'BLOCKED: Observium live shutdown requires explicit approvals' >&2
  exit 2
fi

if [[ ! -r "$CONFIG" ]]; then
  printf '%s\n' 'FAIL: NUT credentials configuration is not readable' >&2
  exit 1
fi

# Existing NUT config is a privileged shell assignment file.
# shellcheck disable=SC1090
. "$CONFIG"

if [[ "${OBSERVIUM_HOST:-}" != '192.168.3.230' || "${OBSERVIUM_USERNAME:-}" != 'root' || -z "${OBSERVIUM_PASSWORD:-}" ]]; then
  printf '%s\n' 'FAIL: Observium host, SSH username, or password invalid or missing' >&2
  exit 1
fi

if [[ ! -s "$KNOWN_HOSTS" || ! -r "$KNOWN_HOSTS" ]]; then
  printf '%s\n' 'BLOCKED: trusted Observium SSH host-key file missing or unreadable' >&2
  exit 2
fi

if [[ ! -x /usr/bin/sshpass || ! -x /usr/bin/ssh ]]; then
  printf '%s\n' 'BLOCKED: SSH or sshpass unavailable' >&2
  exit 2
fi

printf '%s\n' 'ATTEMPT: Observium graceful shutdown via SSH'
SSHPASS="$OBSERVIUM_PASSWORD" /usr/bin/sshpass -e /usr/bin/ssh \
  -o BatchMode=no \
  -o PreferredAuthentications=password,keyboard-interactive \
  -o PubkeyAuthentication=no \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$KNOWN_HOSTS" \
  -o ConnectTimeout=10 \
  -- "${OBSERVIUM_USERNAME}@${OBSERVIUM_HOST}" '/sbin/shutdown -h now'
rc=$?
printf 'RESULT: SSH command returned rc=%s; shutdown not independently verified\n' "$rc"
exit "$rc"
