# Notification Settings - Complete How-To

## Purpose

Notification Settings control delivery of NUT email and Telegram messages.

These settings do NOT change UPS monitoring, shutdown timers, or protected-system shutdown logic.

The main exception is NUT Protection Mode OFF, which intentionally disables the broader NUT operational environment.

---

For definitions of ONBATT, ONLINE, LOWBATT, COMMBAD, COMMOK, shutdown, cancellation, Daily Health, and heartbeat messages, use the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).

## Where to Find Notification Settings

1. Open the NUT Control Center.
2. Click Configuration.
3. Locate Notification Settings near the top of the Configuration page.

Available controls include:

- Daily Health Email
- Weather-Based Closing Thoughts
- Email Recipients
- Telegram Push Notifications
- Daily Health Push
- Critical Power Alerts
- Heartbeat
- Telegram Recipients
- Pending Telegram Access

---

## How to Turn ALL Telegram Push Notifications OFF

Use this when you want NUT to stop sending automated Telegram messages.

1. Open [Configuration](09_CONFIGURATION_HOWTOS.md).
2. Locate Notification Settings.
3. Find Telegram Push Notifications.
4. Move the Telegram Push Notifications switch to OFF.
5. Read the warning explaining that Critical UPS power-event notifications will not be delivered through Telegram.
6. Confirm the setting is OFF.

Expected result:

- Automated Telegram delivery stops.
- Saved child settings such as Daily Health Push, Critical Power Alerts, and Heartbeat are preserved.
- Those child settings remain inactive while the Telegram master switch is OFF.
- Interactive Telegram slash-command behavior is separate from automated push delivery.
- UPS monitoring continues.
- Event logging continues when NUT is otherwise operational.
- Shutdown protection is not disabled by this notification switch.

Search phrases:

- turn off telegram notifications
- disable telegram
- stop telegram alerts
- stop NUT telegram messages

---

## How to Turn ALL Telegram Push Notifications ON

1. Open Configuration.
2. Locate Notification Settings.
3. Move Telegram Push Notifications to ON.
4. Review the child switches below it.
5. Confirm Daily Health Push, Critical Power Alerts, and Heartbeat are set the way you want.

Expected result:

Telegram delivery becomes available according to the individual child settings.

---

## How to Turn Daily Health Push ON or OFF

1. Make sure Telegram Push Notifications is ON.
2. Find Daily Health Push.
3. Set it to ON to allow the scheduled Telegram health report.
4. Set it to OFF to suppress the scheduled Telegram health report.

This does not disable Critical Power Alerts or Heartbeat.

---

## How to Turn Critical Power Alerts ON or OFF

1. Open [Notification Settings](05_NOTIFICATION_SETTINGS.md).
2. Make sure Telegram Push Notifications is ON; see the [Telegram operator guide](06_TELEGRAM_HOWTOS.md) for Telegram behavior and commands.
3. Find Critical Power Alerts. For the events these alerts represent, see the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).
4. Set it to ON to allow configured critical UPS Telegram alerts.
5. Set it to OFF to suppress critical UPS Telegram delivery.
6. Read the warning before leaving this disabled.

Important:

Turning Critical Power Alerts OFF affects Telegram message delivery only.
It does NOT disable UPS monitoring, shutdown timers, or shutdown orchestration.

---

## How to Turn Telegram Heartbeat ON or OFF

1. Open Notification Settings.
2. Make sure Telegram Push Notifications is ON.
3. Find Heartbeat. For what the heartbeat means, see the [Telegram Heartbeat reference](21_NOTIFICATION_EVENT_REFERENCE.md).
4. Set it to ON to allow scheduled heartbeat messages.
5. Set it to OFF to suppress scheduled Telegram heartbeat messages.

---

## How to Turn Daily Health Email ON or OFF

1. Open Notification Settings.
2. Find Daily Health Email. For delivery/testing guidance, see [Email](07_EMAIL_HOWTOS.md).
3. Set it to ON to allow the scheduled Daily Health Email.
4. Set it to OFF to suppress the scheduled Daily Health Email.

Important:

Daily Health Email controls the scheduled health report only.
It does NOT disable outage/event email notifications.

---

## How to Turn Weather-Based Closing Thoughts ON or OFF

1. Make sure Daily Health Email is ON.
2. Find Weather-Based Closing Thoughts.
3. Set it to ON to include the weather-based closing thought.
4. Set it to OFF to omit the closing thought.

The underlying weather and maintenance evaluation remains separate from this presentation option.

---

## How to Add an Email Address

1. Open Configuration.
2. Locate Notification Settings.
3. Find Email Recipients. For email delivery and testing guidance, see [Email](07_EMAIL_HOWTOS.md).
4. Choose the Add Email Recipient control.
5. Enter the new email address.
6. Review the address carefully for spelling mistakes.
7. Save/Add the recipient.
8. Confirm the new address appears in the Email Recipients list.

Expected result:

The address becomes part of the NUT email recipient list.

Verification:

- Confirm the address appears in the Control Center.
- If required, perform the approved non-UPS email delivery test.
- Do not generate a real UPS event merely to test an email address.

Search phrases:

- add email address
- add email recipient
- send NUT alerts to another person
- add someone to NUT emails

---

## How to Remove an Email Address

1. Open Notification Settings.
2. Find Email Recipients.
3. Locate the address to remove.
4. Click Remove for that address.
5. Confirm the removal if prompted.
6. Verify the address disappears from the recipient list.

The Control Center should prevent removal when doing so would violate the configured minimum-recipient safety rule.

Search phrases:

- remove email address
- remove email recipient
- stop sending NUT email to someone
- delete email notification user

---

## How a New Telegram User Requests Access

1. Open the approved NUT Telegram bot.
2. Send /start.
3. The request should enter Pending Telegram Access.
4. An administrator must approve the request before normal authorized use.

Never manually publish or document raw Telegram chat IDs.

---

## How to Approve a Pending Telegram User

1. Open Configuration.
2. Locate Notification Settings.
3. Find Pending Telegram Access.
4. Identify the expected person by the displayed safe information.
5. Click Approve.
6. Confirm the person moves into Telegram Recipients.

Do not approve an unexpected request without verifying who requested access.

---

## How to Remove a Telegram Recipient

1. Open Notification Settings.
2. Find Telegram Recipients.
3. Locate the person to remove.
4. Click Remove.
5. Confirm the action if prompted.
6. Verify the person disappears from Telegram Recipients.

Current design requirement:

Every approved Telegram recipient, including the PRIMARY ADMIN, must ultimately have a safe Remove control in the dashboard.

If the live dashboard does not yet permit PRIMARY ADMIN removal, treat that as an implementation gap rather than changing access files manually.

---

## How to Verify Notification Settings

After changing a setting:

1. Refresh the Control Center.
2. Return to Notification Settings.
3. Confirm the switch or recipient list still shows the intended value.
4. For delivery testing, use only the approved non-disruptive procedure in [Email](07_EMAIL_HOWTOS.md) or [Telegram](06_TELEGRAM_HOWTOS.md), as applicable.
5. Never create a real UPS ONBATT condition simply to test notifications; review [ONBATT / POWER OUTAGE behavior](21_NOTIFICATION_EVENT_REFERENCE.md) instead.

---

## Production-Hours Safety

SAFE during production hours:

- Reviewing notification settings.
- Adding or removing an approved recipient.
- Turning routine notification delivery options on or off when the operational impact is understood.

USE CAUTION:

- Disabling Telegram Critical Power Alerts.
- Disabling all Telegram push notifications.
- Removing recipients who depend on NUT alerts.

These changes do not shut down equipment, but they can prevent people from receiving important warnings.

---

## Monitoring Impact

Notification switches do not normally disable UPS monitoring.

## Shutdown-Protection Impact

Notification switches do not normally disable NUT shutdown protection.

## Notification Impact

The switches control delivery of the specific message type described by each setting.

---

## Troubleshooting

If a setting does not appear to save:

1. Refresh the Control Center.
2. Recheck the setting.
3. Check nut-orchestrator-ui.service.
4. Review the Control Center service journal.
5. Review the notification-control helper only if the UI continues to disagree with backend state.

If email fails, search Help for EMAIL_NOTIFY_FAILED.

If Telegram messages do not arrive, search Help for Telegram notifications not arriving.

