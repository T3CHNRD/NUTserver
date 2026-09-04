# Copyright (c) 2026 T3CHNRD. All rights reserved.
sudo cp -a /usr/local/bin/nut-test-logic.sh "/usr/local/bin/nut-test-logic.sh.bak.$(date +%F-%H%M%S)"

sudo tee /usr/local/bin/nut-test-logic.sh >/dev/null <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/nut-test-logic.log"

# Redirect all output/errors to log.
exec 2>> "$LOG_FILE"
exec 1>> "$LOG_FILE"

echo "--- START EVENT: $* AT $(date) ---"
echo "Running as user: $(id)"

TARGET_IP="198.51.100.10"
CREDS="/etc/nut/windows-rpc.creds"

PHASE2_ABORT_SCRIPT="/usr/local/sbin/phase2-power-restore-abort"

event="$1"
ups_arg="$3"

case "$event" in

  power-down)
    echo "Event: power-down"
    echo "Target IP: $TARGET_IP"

    /usr/bin/net rpc shutdown \
      -S "$TARGET_IP" \
      -A "$CREDS" \
      -f \
      -t 115 \
      -C "UPS Power Loss - Shutdown in 2 minutes"

    rpc_exit=$?
    echo "net rpc shutdown exit code: $rpc_exit"

    sudo /usr/sbin/shutdown -h +2 "UPS on battery"

    shutdown_exit=$?
    echo "local shutdown exit code: $shutdown_exit"
    ;;

  power-up)
    echo "Event: power-up"
    echo "Target IP: $TARGET_IP"

    /usr/bin/net rpc abortshutdown \
      -S "$TARGET_IP" \
      -A "$CREDS"

    rpc_exit=$?
    echo "net rpc abortshutdown exit code: $rpc_exit"

    sudo /usr/sbin/shutdown -c

    shutdown_exit=$?
    echo "local shutdown cancel exit code: $shutdown_exit"
    ;;

  phase2-power-restore-abort-ups3)
    echo "Event: phase2-power-restore-abort"
    echo "UPS target: ups3"

    if [ ! -x "$PHASE2_ABORT_SCRIPT" ]; then
      echo "ERROR: Missing or non-executable script: $PHASE2_ABORT_SCRIPT"
      echo "--- END EVENT (Exit Code: 127) ---"
      exit 127
    fi

    "$PHASE2_ABORT_SCRIPT" --ups ups3

    phase2_exit=$?
    echo "phase2-power-restore-abort ups3 exit code: $phase2_exit"
    ;;

  phase2-power-restore-abort)
    echo "Event: phase2-power-restore-abort"

    if [ "$2" != "--ups" ] || [ -z "$ups_arg" ]; then
      echo "ERROR: Usage expected: phase2-power-restore-abort --ups <ups_name>"
      echo "--- END EVENT (Exit Code: 64) ---"
      exit 64
    fi

    case "$ups_arg" in
      ups3)
        echo "UPS target: $ups_arg"

        if [ ! -x "$PHASE2_ABORT_SCRIPT" ]; then
          echo "ERROR: Missing or non-executable script: $PHASE2_ABORT_SCRIPT"
          echo "--- END EVENT (Exit Code: 127) ---"
          exit 127
        fi

        "$PHASE2_ABORT_SCRIPT" --ups "$ups_arg"

        phase2_exit=$?
        echo "phase2-power-restore-abort $ups_arg exit code: $phase2_exit"
        ;;

      *)
        echo "ERROR: Unsupported Phase 2 UPS target: $ups_arg"
        echo "Allowed Phase 2 UPS targets from this wrapper: ups3"
        echo "--- END EVENT (Exit Code: 65) ---"
        exit 65
        ;;
    esac
    ;;

  *)
    echo "ERROR: Unknown event: $event"
    echo "Allowed events:"
    echo "  power-down"
    echo "  power-up"
    echo "  phase2-power-restore-abort-ups3"
    echo "  phase2-power-restore-abort --ups ups3"
    echo "--- END EVENT (Exit Code: 66) ---"
    exit 66
    ;;

esac

final_exit=$?
echo "--- END EVENT (Exit Code: $final_exit) ---"
exit "$final_exit"
EOF

sudo chmod 750 /usr/local/bin/nut-test-logic.sh
sudo chown root:root /usr/local/bin/nut-test-logic.sh
