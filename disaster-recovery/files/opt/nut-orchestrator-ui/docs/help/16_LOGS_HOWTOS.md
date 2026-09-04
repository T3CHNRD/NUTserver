# Logs - Complete Operator How-Tos

## Purpose

Use this section to determine which log or journal should be checked for a NUT problem.

---

## How to Find the Correct Log for a NUT Problem

Start with the feature that failed.

### Control Center or Help problem

Check:

journalctl -u nut-orchestrator-ui.service --since today

Examples:

- page will not load
- button returns an error
- Help article does not load
- API request fails

### UPS monitoring problem

Check:

journalctl -u nut-monitor.service --since today

and review NUT server status as appropriate.

### NUT server communication problem

Check:

journalctl -u nut-server.service --since today

### Email problem

Review:

- EMAIL_NOTIFY_FAILED output
- email sender/helper output
- related service journal

### Telegram problem

Review:

- Telegram helper/bot output
- notification logs
- relevant service journal

### Protected-system shutdown problem

Review:

- orchestrator output
- target-specific shutdown wrapper output
- relevant authentication/connectivity errors

Search phrases:

- where are NUT logs
- which log do I check
- find error log
- NUT troubleshooting logs

---

## Useful Journal Commands

Recent entries:

journalctl -u SERVICE-NAME --since today

Last 100 entries:

journalctl -u SERVICE-NAME -n 100 --no-pager

Follow live output when specifically needed:

journalctl -u SERVICE-NAME -f

Use live-follow mode only while actively troubleshooting and exit with Ctrl+C.

---

## How to Collect Logs Safely

1. Identify the affected component.
2. Capture only the relevant time range.
3. Review output before sharing.
4. Mask passwords, secrets, tokens, and sensitive identifiers.
5. Use Export Logs when the Control Center provides an approved export.

Never paste raw secret-bearing logs into Help, chat, email, or tickets.

---

## Production-Hours Safety

Read-only log review is safe during production hours.

Log review should not:

- change configuration
- generate a UPS event
- restart a service
- execute shutdown

---

## Related Help

- Tests and Logs
- Troubleshooting
- Services and Timers
- Security
