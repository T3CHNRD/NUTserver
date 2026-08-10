#!/usr/bin/env bash
set -uo pipefail

FAIL=0
WARN=0

pass() {
    echo "PASS: $*"
}

warn() {
    echo "WARN: $*"
    WARN=$((WARN + 1))
}

fail() {
    echo "FAIL: $*"
    FAIL=$((FAIL + 1))
}

echo "===== NUT DISASTER RECOVERY POST-RESTORE VERIFICATION ====="

echo
echo "===== REQUIRED FILES ====="

for file in \
    /etc/nut/ups.conf \
    /etc/nut/upsd.conf \
    /etc/nut/upsmon.conf \
    /etc/nut/upssched.conf \
    /etc/nut/nut.conf \
    /usr/local/bin/nut-orchestrator.sh \
    /opt/nut-orchestrator-ui/app.py \
    /opt/nut-orchestrator-ui/templates/control-center.html
do
    if [ -f "$file" ]; then
        pass "$file"
    else
        fail "$file missing"
    fi
done

echo
echo "===== SCRIPT SYNTAX ====="

for file in \
    /usr/local/bin/nut-orchestrator.sh \
    /usr/local/sbin/nut-email-alert-test-send \
    /usr/local/sbin/nut-sync-live-to-repo-for-backup
do
    if [ -f "$file" ]; then
        if bash -n "$file" >/dev/null 2>&1; then
            pass "syntax: $file"
        else
            fail "syntax error: $file"
        fi
    fi
done

echo
echo "===== PYTHON UI ====="

if python3 -m py_compile /opt/nut-orchestrator-ui/app.py >/dev/null 2>&1; then
    pass "NUT UI Python syntax"
else
    fail "NUT UI Python syntax"
fi

echo
echo "===== SUDOERS ====="

if sudo visudo -c >/dev/null 2>&1; then
    pass "sudoers configuration"
else
    fail "sudoers configuration"
fi

echo
echo "===== SYSTEMD UNITS ====="

systemctl daemon-reload >/dev/null 2>&1

for unit in \
    nut-server.service \
    nut-monitor.service \
    nut-orchestrator-ui.service
do
    if systemctl cat "$unit" >/dev/null 2>&1; then
        pass "$unit exists"
    else
        fail "$unit missing"
    fi
done

echo
echo "===== UPS MONITOR DEFINITIONS ====="

MONITORS="$(
    awk '$1=="MONITOR"{c++} END{print c+0}' \
    /etc/nut/upsmon.conf 2>/dev/null
)"

if [ "$MONITORS" -eq 9 ]; then
    pass "upsmon contains 9 monitored UPS definitions"
else
    fail "upsmon monitor count=$MONITORS expected=9"
fi

echo
echo "===== UPS DEFINITIONS ====="

for ups in ups1 ups2 ups3 ups4 ups5 ups6 ups7 ups8 ups9; do
    if grep -q "^\[$ups\]" /etc/nut/ups.conf 2>/dev/null; then
        pass "$ups configured"
    else
        fail "$ups missing from ups.conf"
    fi
done

echo
echo "===== SECRET PLACEHOLDERS ====="

if grep -q '\*\*\*\*\*\*\*\*' /etc/nut/upsmon.conf 2>/dev/null; then
    warn "upsmon still contains sanitized password placeholder"
fi

if [ ! -s /etc/nut/vcenter.pass ] 2>/dev/null; then
    warn "vCenter secret is absent/empty and must be entered locally if required"
fi

echo
echo "===== PRODUCTION MODE SAFETY ====="

if command -v /usr/local/sbin/nut-production-status >/dev/null 2>&1; then
    MODE_OUTPUT="$(
        /usr/local/sbin/nut-production-status 2>/dev/null || true
    )"

    if printf '%s\n' "$MODE_OUTPUT" | grep -qiE '"mode"[[:space:]]*:[[:space:]]*"off"|OFF'; then
        pass "server remains in OFF/safe mode"
    else
        warn "confirm production mode is OFF before completing rebuild"
    fi
fi

echo
echo "===== OPTIONAL LIVE SERVICE CHECKS ====="

for unit in nut-server.service nut-monitor.service nut-orchestrator-ui.service; do
    STATE="$(systemctl is-active "$unit" 2>/dev/null || true)"

    if [ "$STATE" = "active" ]; then
        pass "$unit active"
    else
        warn "$unit state=$STATE"
    fi
done

echo
echo "===== FINAL RESULT ====="

echo "Failures: $FAIL"
echo "Warnings: $WARN"

if [ "$FAIL" -ne 0 ]; then
    echo "RESULT=FAIL"
    exit 1
fi

if [ "$WARN" -ne 0 ]; then
    echo "RESULT=PASS_WITH_WARNINGS"
    exit 0
fi

echo "RESULT=PASS"
