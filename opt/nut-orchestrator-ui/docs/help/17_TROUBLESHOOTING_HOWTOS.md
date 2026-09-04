# Troubleshooting - Complete Operator How-Tos

## Purpose

This section provides first-response procedures for common NUT Control Center problems.

The goal is to identify the fault without creating a second problem.

---

## How to Troubleshoot a UPS That Shows Offline or Missing

1. Confirm which UPS is affected.
2. Click Refresh UPS once.
3. Confirm other UPS systems are still reporting normally.
4. Check the Events page.
5. Check nut-server.service.
6. Check nut-monitor.service.
7. Review the relevant logs.
8. Review the UPS configuration only if the service/log evidence points there.
9. Do not restart multiple services without identifying the failing component.

If only one UPS is affected, investigate that UPS path before treating the entire NUT server as failed.

Do not unplug or power-cycle an UPS merely to test monitoring.

Search phrases:

- UPS offline
- UPS missing
- UPS unavailable
- UPS communication failed
- UPS not showing

---

## How to Troubleshoot a Stale Control Center Display

1. Click the appropriate Refresh control once.
2. Confirm whether the page itself is responsive.
3. Refresh the browser.
4. Check nut-orchestrator-ui.service.
5. Check whether the underlying NUT data is current.
6. Compare Monitoring with Events.
7. Review the UI journal.
8. Restart only nut-orchestrator-ui.service if the problem is confirmed to be UI-only.

Do not restart nut-server.service or nut-monitor.service solely because the browser appears stale.

Search phrases:

- dashboard stale
- Control Center not updating
- old UPS data
- page not refreshing

---

## How to Troubleshoot Telegram Notifications Not Arriving

1. Confirm Telegram Push Notifications is ON.
2. Confirm the relevant child notification setting is ON.
3. Confirm the intended recipient is approved.
4. Confirm NUT is not in OFF mode.
5. Review Telegram-related logs/helper output.
6. Confirm the token file exists without displaying the token.
7. Confirm outbound network access.
8. Use only the approved safe Telegram test.

Do not create a real ONBATT event merely to test Telegram.

Search phrases:

- Telegram not sending
- no Telegram alert
- Telegram notification missing
- bot message failed

---

## How to Troubleshoot Email Notifications Not Arriving

1. Confirm the intended email recipient is configured.
2. Confirm the relevant notification path is enabled.
3. Check for EMAIL_NOTIFY_FAILED.
4. Review sender/helper output.
5. Check SMTP connectivity.
6. Check authentication without displaying credentials.
7. Check recipient rejection or filtering.
8. Run the approved safe email test.

Do not create a UPS outage merely to test email delivery.

Search phrases:

- email not sending
- no email alert
- EMAIL_NOTIFY_FAILED
- email notification missing

---

## General Troubleshooting Order

Use this order whenever possible:

1. Identify the exact symptom.
2. Identify the affected component.
3. Check current status.
4. Check logs.
5. Check configuration.
6. Perform a non-disruptive validation.
7. Change only the verified cause.
8. Verify the fix.

Do not begin with service restarts or configuration changes when read-only evidence is available.

---

## Production-Hours Safety

Start with read-only troubleshooting during production hours.

Escalate to configuration/service changes only after the failing component is identified.

---

## Related Help

- Monitoring
- Events
- Logs
- Services and Timers
- Telegram
- Email
- Tests and Logs
- Configuration
