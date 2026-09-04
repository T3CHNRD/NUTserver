# Notification and Power Event Reference

## Purpose

This article explains the major NUT notification and power-event types and what an operator should expect to see in email, Telegram, logs, and the Control Center.

Notifications report what the protection system is seeing or doing.

Notification settings do not normally change shutdown protection by themselves.

---

## ONBATT - Power Outage

ONBATT means the UPS reports that normal utility/input power has been lost and the UPS is operating on battery.

Depending on the UPS, this may:

- create a power event
- send configured email notifications
- send configured Telegram critical-power notifications
- start a configured shutdown timer
- update the Control Center with an active outage/pending action

ONBATT does not automatically mean that equipment has already shut down.

### Operator Expectation

The notification should make it obvious that this is a:

**POWER OUTAGE**

Useful information should include, when available:

- UPS ID
- friendly UPS name
- rack/location
- event time
- shutdown timer
- affected shutdown domain
- systems scheduled for automatic action

Search phrases:

- power outage
- ONBATT
- UPS on battery
- what happens when power goes out

---

## ONLINE - Power Restored

ONLINE means the UPS reports that normal utility/input power has returned.

When ONLINE follows ONBATT, the normal expectation is:

- the outage is recorded as restored
- a pending shutdown timer is cancelled when cancellation is still allowed
- restoration notifications are sent when enabled
- the Control Center returns the UPS to normal state after recording the event

### Operator Expectation

The notification should make it obvious that this is:

**POWER RESTORED**

When available, restoration information should include:

- UPS ID
- friendly UPS name
- rack/location
- restoration time
- outage duration
- whether a shutdown timer was cancelled
- whether shutdown actions had already started
- final restoration status

Search phrases:

- power restored
- ONLINE
- utility power returned
- what happens when power comes back

---

## Shutdown Notification

A shutdown notification means a configured shutdown sequence has reached the point where the orchestrator is attempting a protected-system action.

It does not necessarily mean the target successfully powered off.

The target wrapper and verification logic determine whether the action succeeded.

Examples include:

- Blue Iris shutdown attempt
- <DATABASE_SERVER_1> / <DATABASE_SERVER_2> shutdown attempt
- VOIP shutdown attempt
- Lansweeper shutdown attempt
- VMware shutdown sequence
- storage shutdown

Search phrases:

- shutdown notification
- shutdown started
- NUT shutdown email

---

## Cancelled Shutdown

A cancelled-shutdown notification means a pending shutdown was cancelled before the committed shutdown action occurred.

The most common reason is utility power returning before the shutdown timer expires.

A cancelled shutdown should not be interpreted as a shutdown failure.

It means the protection system no longer needs to execute the pending shutdown action.

Search phrases:

- shutdown cancelled
- canceled shutdown
- power restored before shutdown
- timer cancelled

---

## Final Shutdown

The final-shutdown notification identifies the last stage of a broader shutdown sequence.

In the current UPS9 sequence, the NUT server is intentionally the final system to shut down.

This allows the NUT server to coordinate and log:

1. VMware shutdown
2. Synology shutdown
3. NetApp shutdown
4. final local NUT server shutdown

Search phrases:

- final shutdown
- NUT server last
- final power shutdown
- why NUT server shuts down last

---

## LOWBATT

LOWBATT means the UPS reports a low-battery condition.

This is more urgent than a normal ONBATT state.

The exact automated behavior depends on the configured UPS event path and orchestrator logic.

Operators should treat LOWBATT as a high-priority power condition and review:

- affected UPS
- remaining runtime
- current shutdown state
- protected systems
- recent event history

Search phrases:

- LOWBATT
- low battery UPS
- UPS battery almost empty

---

## COMMBAD

COMMBAD means NUT has lost reliable communication with a UPS.

COMMBAD does not automatically prove that utility power has failed.

Possible causes include:

- network communication loss
- USB communication failure
- UPS interface/card issue
- service/driver issue
- UPS maintenance activity

The current environment also uses UPS Maintenance logic to distinguish communication problems from confirmed grid-loss conditions.

Search phrases:

- COMMBAD
- UPS communication lost
- UPS offline
- cannot communicate with UPS

---

## COMMOK

COMMOK means communication with the UPS has been restored after a communication failure.

Operators should confirm that:

- the UPS is visible again
- current UPS state is reasonable
- no shutdown state remains unexpectedly active
- any maintenance condition is understood

Search phrases:

- COMMOK
- UPS communication restored
- UPS online again

---

## Daily Health Email

The Daily Health Email is a scheduled operational report.

It is separate from critical power-event notifications.

The report may include:

- current UPS health
- UPS availability
- system health information
- maintenance/weather information
- warnings or notable conditions
- optional weather-based closing thought when enabled

Turning Daily Health Email OFF suppresses the scheduled report.

It does not by itself disable normal shutdown protection.

Search phrases:

- Daily Health Email
- daily UPS report
- health email
- morning health report

---

## Telegram Daily Health / Health Push

Telegram health reporting provides a shorter operational health view through Telegram when enabled.

It is separate from critical power alerts and heartbeat messages.

Search phrases:

- Telegram health report
- Daily Health Push
- /health

---

## Telegram Heartbeat

The Telegram heartbeat is a scheduled confirmation that the monitoring/notification environment is alive.

It is not a power-outage alert.

A heartbeat should be short and clearly distinguishable from a critical event.

The heartbeat may also direct operators to the Daily Health Email for more detailed information.

Search phrases:

- Telegram heartbeat
- heartbeat message
- is NUT alive
- monitoring heartbeat

---

## Email Format Expectations

Power-event emails should clearly identify the event type before the operator has to read the detailed body.

### Required Identification

Where available, include:

- UPS ID
- friendly UPS name
- rack/location
- event type
- event time

### Power Outage

The message should prominently identify:

**POWER OUTAGE**

### Power Restored

The message should prominently identify:

**POWER RESTORED**

Restoration messages should include useful restoration details when available, such as:

- outage duration
- whether the shutdown timer was cancelled
- whether shutdown actions had started
- affected UPS/system domain

### TEST Messages

Any notification generated by a safe notification test must be clearly labeled as:

**TEST**

A test message must not look like a genuine production power outage.

---

## Notification Settings Versus Shutdown Protection

Notification controls and shutdown protection are separate concepts.

Examples:

- turning Daily Health Email OFF suppresses the scheduled Daily Health Email
- turning Telegram Heartbeat OFF suppresses the scheduled heartbeat
- turning Telegram Critical Power Alerts OFF controls Telegram critical-event delivery

These settings do not normally disable UPS monitoring or automatic shutdown logic.

Protection Mode controls the broader protection state.

OFF mode is the major exception because OFF intentionally disables the operational protection environment, including monitoring and scheduled reporting.

---

## If a Notification Does Not Arrive

Check:

1. the event actually occurred
2. the applicable notification setting is enabled
3. recipient configuration is correct
4. sender/service status
5. notification logs
6. SMTP or Telegram connectivity
7. recent EMAIL_NOTIFY_FAILED or Telegram errors

Do not create a real UPS outage simply to test notification delivery.

Use supported notification-test procedures instead.

---

## Related Help

- Notification Settings
- Email
- Telegram
- Events
- Shutdown Orchestration
- Monitoring
- Maintenance and Weather
- Logs
- Troubleshooting
