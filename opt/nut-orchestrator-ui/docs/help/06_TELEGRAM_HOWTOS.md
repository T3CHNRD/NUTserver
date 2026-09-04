# Telegram - Complete Operator How-Tos

## Purpose

Telegram provides remote read-only status information and configured NUT push notifications.

Telegram command access is separate from automatic push-notification delivery.

Turning Telegram Push Notifications OFF does not necessarily disable authorized slash-command replies.

---

## How to Use /status

Use `/status` for a quick read-only overview of the NUT server. For the meaning of the protection state shown in that response, see [Protection Modes](02_PROTECTION_MODES.md).

1. Open the approved NUT Telegram bot.
2. Send:

/status

3. Wait for the bot reply.
4. Review the current NUT operating state and summary information.

/status is read-only.

It should not:

- change NUT mode
- start a shutdown
- cancel a shutdown
- change notification settings
- modify configuration

Search phrases:

- Telegram status
- /status
- check NUT from phone
- is NUT working from Telegram

---

## How to Use /health

1. Open the NUT Telegram bot.
2. Send:

/health

3. Review the returned health information. For a detailed explanation of the Daily Health sources and weather information, see [Maintenance and Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md).

Use this for a read-only health summary.

---

## How to Use /ups

Send:

/ups

to review supported UPS summary information.

When supported, you can request a specific UPS, for example:

/ups 3

Use the reply to review current UPS state.

Do not treat Telegram UPS data as a substitute for the Control Center when performing maintenance.

---

## How to Use /maintenance

For CLEAR, CAUTION, BLOCK, UPS Maintenance Mode, and shutdown-suppression behavior, see [Maintenance and Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md).

Send:

/maintenance

Use the reply to review the current maintenance/weather assessment.

Possible maintenance states include:

- CLEAR
- CAUTION
- BLOCK

See Maintenance and Weather Help for the meaning of each state.

---

## How to Use /heartbeat

For what heartbeat messages mean and how they differ from critical power events, see the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).

Send:

/heartbeat

Use the reply to review heartbeat/status information supported by the bot.

This read-only command is different from the automatic scheduled Telegram Heartbeat notification setting.

---

## How to Use /schedule

Send:

/schedule

Use the reply to review supported schedule information.

This command should be treated as read-only.

---

## How to Use /access

Send:

/access

Authorized administrators may use supported access-management subcommands.

Examples of access operations in the current bot design may include:

- list
- pending
- approve
- remove
- promote
- demote
- transfer

Never expose raw Telegram chat IDs unnecessarily.

Do not approve an unknown or unexpected access request.

---

## How a New Telegram User Requests Access

1. Open the approved bot.
2. Send /start.
3. The request should appear under Pending Telegram Access.
4. An administrator verifies the person.
5. An administrator approves the request.

---

## How to Troubleshoot Telegram Notifications Not Arriving

1. Confirm Telegram Push Notifications is ON in [Notification Settings](05_NOTIFICATION_SETTINGS.md).
2. Confirm the specific child setting is ON in [Notification Settings](05_NOTIFICATION_SETTINGS.md).
3. Confirm the recipient is still approved.
4. Confirm NUT is not in [OFF mode](02_PROTECTION_MODES.md).
5. Review Telegram-related output using [Logs](16_LOGS_HOWTOS.md).
6. Confirm the bot token file exists without displaying the token.
7. Confirm outbound internet access required by the Telegram API.
8. Test only with the approved safe Telegram test method.

Do not create a real UPS event merely to test Telegram.

Search phrases:

- Telegram not working
- no Telegram alert
- Telegram message missing
- bot not replying

---

## Production-Hours Safety

SAFE:

- /status
- /health
- /ups
- /maintenance
- /heartbeat
- /schedule
- reviewing /access

USE CAUTION:

- approving/removing Telegram recipients
- changing notification delivery settings

---

## Security Rules

- Never publish the Telegram bot token.
- Never paste the token into Help or chat.
- Do not expose raw chat IDs unnecessarily.
- Verify a person before approving access.

## Technical References

- /usr/local/sbin/nut-telegram-command-bot
- /etc/nut/secrets/telegram-alerts.env
- /var/lib/nut-telegram-alerts/access.json
- /etc/nut/config.d/notification-controls.json

