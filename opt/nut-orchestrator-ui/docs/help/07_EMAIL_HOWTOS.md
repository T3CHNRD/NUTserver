# Email - Complete Operator How-Tos

## Purpose

NUT uses email for configured health reports and event notifications.

This section explains safe email testing and troubleshooting, including EMAIL_NOTIFY_FAILED.

---

For the meaning and expected format of POWER OUTAGE, POWER RESTORED, shutdown, cancellation, LOWBATT, COMMBAD, COMMOK, Daily Health, and TEST messages, see the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).

## How to Troubleshoot EMAIL_NOTIFY_FAILED

EMAIL_NOTIFY_FAILED means the NUT email notification path attempted to send an email and the send operation did not complete successfully.

Do not assume the UPS event itself failed just because email delivery failed.

### Step 1 - Confirm the failure

1. Review the NUT event/output that reported `EMAIL_NOTIFY_FAILED`, then use [Logs](16_LOGS_HOWTOS.md) to inspect the applicable notification logs.
2. Record the timestamp.
3. Identify which message type was being sent.
4. Do not expose SMTP credentials while collecting output.

### Step 2 - Check the sender path

Current sender reference:

- /usr/local/sbin/nut-email-alert-test-send

Check the script with the appropriate Bash syntax validation when code has changed:

bash -n /usr/local/sbin/nut-email-alert-test-send

### Step 3 - Check the email configuration

Review email-related settings through [Notification Settings](05_NOTIFICATION_SETTINGS.md) and use [Configuration](09_CONFIGURATION_HOWTOS.md) when a live configuration file must be inspected.

Current configuration reference:

- /etc/nut/nut-email-alerts.conf

Verify:

- file exists
- expected ownership
- expected restrictive permissions
- SMTP server/port configuration
- recipient configuration

Never print SMTP_PASSWORD, SMTP_PASS, PASSWORD, PASS, SECRET, TOKEN, or similar secret fields into chat or documentation.

### Step 4 - Check logs

Use the [Logs operator guide](16_LOGS_HOWTOS.md) to locate the relevant email, notification, service, and orchestration output.

Review the sender output and relevant NUT/UI/service journal around the failure timestamp.

Look for:

- DNS/network failure
- SMTP connection failure
- authentication failure
- TLS/certificate failure
- sender rejection
- recipient rejection
- configuration parsing error

### Step 5 - Run only a safe email test

Use the approved non-disruptive test path described in [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md).

Use the approved non-UPS email delivery test.

Do not create ONBATT or another real UPS event merely to test email.

### Expected result

The approved test message is accepted for delivery and no EMAIL_NOTIFY_FAILED result is produced.

Search phrases:

- EMAIL_NOTIFY_FAILED
- email failed
- NUT email not sending
- SMTP error
- no email alert

---

## How to Validate Email Delivery Without Causing a UPS Event

1. Confirm the intended recipient list in [Notification Settings](05_NOTIFICATION_SETTINGS.md).
2. Confirm the Daily Health Email setting does not need to be changed for this test.
3. Use the approved test-email sender/path.
4. Send only a test message.
5. Confirm the command reports success.
6. Confirm the expected recipient receives it.
7. Review logs if delivery does not arrive.

Do not:

- unplug a UPS
- create ONBATT
- trigger a shutdown timer
- invoke a real protected-system action

Search phrases:

- test email
- safe email test
- send test NUT email
- test notifications without outage

---

## How to Add or Remove Email Recipients

Use Notification Settings Help for:

- add email address
- remove email address
- add email recipient
- stop email notifications to someone

---

## How to Troubleshoot Email Notifications Not Arriving

1. Confirm the expected recipient is configured.
2. Confirm the relevant notification type is enabled in [Notification Settings](05_NOTIFICATION_SETTINGS.md).
3. Check for `EMAIL_NOTIFY_FAILED` and review the applicable [notification logs](16_LOGS_HOWTOS.md).
4. Check sender output.
5. Check SMTP connectivity.
6. Check authentication without exposing credentials.
7. Check recipient rejection or mail filtering.
8. Use the safe email test.

---

## Production-Hours Safety

SAFE:

- reviewing email configuration
- reviewing recipients
- running approved non-UPS email tests
- reading logs

USE CAUTION:

- changing SMTP configuration
- changing recipients
- disabling critical notification delivery

---

## Monitoring Impact

Email delivery settings do not normally disable UPS monitoring.

## Shutdown-Protection Impact

Email failure does not normally stop shutdown orchestration.

However, operators may not receive important warning messages.

## Security Rules

- Never expose SMTP passwords.
- Do not paste configuration files without masking secret fields.
- Keep email credential files properly restricted.

## Technical References

- /usr/local/sbin/nut-email-alert-test-send
- /etc/nut/nut-email-alerts.conf
- /usr/local/sbin/nut-notification-recipients

