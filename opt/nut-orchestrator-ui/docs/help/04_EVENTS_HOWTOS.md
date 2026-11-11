# Events - Complete Operator How-Tos

## Purpose

The Events section provides the operational history of important NUT power and related events.

Use Events when you need to answer questions such as:

- Did a UPS go on battery?
- When did utility power return?
- Was a shutdown timer started?
- Was a pending shutdown cancelled?
- What happened during a power event?

---

## How to Review Recent Power and Boot Events

1. Open the NUT Control Center.
2. Click Events.
3. Review the newest events first.
4. Identify the UPS associated with the event.
5. Review the event type.
6. Review the timestamp.
7. Follow related ONBATT, ONLINE, shutdown, cancellation, or final events in chronological order.

Do not evaluate an outage from a single event line when multiple related entries are available.

Search phrases:

- power events
- event history
- what happened
- UPS event log
- boot events
- outage history

---

## How to Interpret ONBATT

ONBATT means the UPS reported that it switched to battery operation.

When an ONBATT event appears:

1. Identify which UPS reported it.
2. Check the Monitoring page.
3. Determine whether that UPS is alert-only or shutdown-enabled.
4. If shutdown-enabled, identify the configured timer.
5. Watch for an ONLINE event if power returns.
6. Review subsequent shutdown/cancellation events.

ONBATT does not automatically mean that a shutdown occurred. Review [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md) to determine whether a timer or automatic action applies.

Search phrases:

- ONBATT
- UPS on battery
- power failure
- power went out

---

## How to Interpret ONLINE

ONLINE means the UPS reports that normal input/utility power is available again.

If ONLINE follows ONBATT:

1. Compare the timestamps.
2. Determine how long the UPS was on battery.
3. Check whether a pending shutdown timer was cancelled.
4. Confirm Monitoring now reports normal UPS state.

Search phrases:

- ONLINE event
- power restored
- utility power returned
- UPS back online

---

## How to Determine Whether a Shutdown Was Cancelled

1. Find the original ONBATT event.
2. Find the corresponding ONLINE/restoration event.
3. Look for a cancellation event or cancellation message.
4. Verify that no later live shutdown action was executed.
5. Review Shutdown Orchestration if the sequence is unclear.

Do not assume cancellation merely because power returned.

---

## How to Refresh the Event Log

1. Open [Events](04_EVENTS_HOWTOS.md).
2. Click Refresh Event Log.
3. Wait for the event list to update.
4. Confirm the newest timestamp/event appears as expected.

Refresh Event Log is a read-only refresh operation.

It should not:

- create an UPS event
- change NUT mode
- execute shutdown
- change notification settings

Search phrases:

- refresh event log
- update events
- event log stale
- newest event missing

---

## How to Correlate Monitoring and Events

When investigating a power issue:

1. Use Events to determine what happened and when.
2. Use Monitoring to see the UPS current state.
3. Use Shutdown Orchestration to determine what NUT was expected to do.
4. Use Logs if the observed behavior does not match the expected workflow.

This is more reliable than using any one screen alone.

---

---

## How the Latest Event Card Works

The **Latest Event** card on the Control Center System Overview is intended to show the most recent relevant power event without leaving old transient information displayed forever.

### Normal Transient Events

Most recent/transient events age out after about **3 hours**.

If no newer relevant event occurs during that period, the Latest Event card returns to a neutral state such as:

**Clear / No recent event**

This prevents an old event from looking like a current problem.

### Active Power Outage Exception

An active **ONBATT / POWER OUTAGE** condition is stateful.

While the affected UPS is still on battery, the outage remains the Latest Event regardless of how old it is.

The normal 3-hour aging rule does **not** clear an active outage.

The outage remains displayed until actual power restoration is detected.

For ONBATT meaning and shutdown timing, see the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md) and [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md).

### When Power Is Restored

When the UPS reports **ONLINE / POWER RESTORED**:

1. The active outage condition ends.
2. POWER RESTORED becomes the Latest Event.
3. Any still-pending shutdown timer is cancelled when the configured workflow allows cancellation.
4. The restoration event remains visible for up to about **3 hours**.
5. If nothing newer occurs, the Latest Event card returns to **Clear / No recent event**.

### Why This Matters

The Latest Event card answers:

**What relevant power event is active or happened recently?**

It is not intended to be a permanent historical-event display.

Use the Events log for older event history.

Search phrases:

- how does Latest Event work
- why did Latest Event clear
- how long does Latest Event stay
- why is power outage still showing
- when does power restored disappear
- no recent event
- clear latest event

## Production-Hours Safety

SAFE during production hours:

- viewing event history
- refreshing the Event Log
- correlating Events with Monitoring

These actions are read-only.

---

## Monitoring Impact

Reviewing Events does not change UPS monitoring.

## Notification Impact

Reviewing Events does not send notifications.

Actual power events may separately trigger configured notifications.

## Shutdown-Protection Impact

Reviewing Events does not change shutdown protection.

Actual ONBATT/ONLINE conditions may affect shutdown timers and cancellation logic.

---

## Troubleshooting

If the Event Log does not update:

1. Click Refresh Event Log once.
2. Confirm the Control Center is responsive.
3. Check nut-orchestrator-ui.service.
4. Check nut-monitor.service.
5. Review relevant event/log helper output.
6. Confirm NUT is not intentionally in OFF mode.

If an expected ONBATT/ONLINE event is missing, do not manufacture a real outage simply to test logging.

