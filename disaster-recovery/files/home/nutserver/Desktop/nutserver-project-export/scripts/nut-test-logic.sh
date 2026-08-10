#!/bin/bash
exec 2>> /var/log/nut-test-logic.log  # Redirect all errors to our new log
exec 1>> /var/log/nut-test-logic.log  # Redirect all output to our new log

echo "--- START EVENT: $1 AT $(date) ---"
echo "Running as user: $(id)"

TARGET_IP="192.168.1.24"
CREDS="/etc/nut/win2003-192.168.1.24.creds"

case "$1" in
  power-down)
    /usr/bin/net rpc shutdown -S "$TARGET_IP" -A "$CREDS" -f -t 115 -C "UPS Power Loss - Shutdown in 2 minutes."
    sudo /usr/sbin/shutdown -h +2 "UPS on battery"
    ;;
  power-up)
    /usr/bin/net rpc abortshutdown -S "$TARGET_IP" -A "$CREDS"
    sudo /usr/sbin/shutdown -c
    ;;
esac
echo "--- END EVENT (Exit Code: $?) ---"
