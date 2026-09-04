# Monitoring - Complete Operator How-Tos

## Purpose

The Monitoring section shows the current state of the UPS systems monitored by NUT.

Use this section for normal day-to-day UPS checks before changing configuration or running tests.

---

## How to Check the Status of a UPS

1. Open the NUT Control Center.
2. Click Monitoring.
3. Select the UPS you want to inspect.
4. Review the current UPS status.
5. Review battery charge.
6. Review reported runtime.
7. Review UPS load.
8. Review input/output voltage where available.
9. Look for warnings, offline indications, or communication errors.

Expected result:

The selected UPS displays current monitoring information without requiring any configuration change.

Search phrases:

- check UPS
- UPS status
- is UPS online
- battery status
- UPS health
- check UPS7

---

## How to Select a Different UPS

1. Open [Monitoring](03_MONITORING_HOWTOS.md).
2. Locate the UPS selector or UPS list.
3. Select the UPS number/name you want to view.
4. Wait for the monitoring panel to update.
5. Confirm the displayed UPS identity matches the one you selected.

Do not assume the displayed values belong to the newly selected UPS until the name/identifier has updated.

Search phrases:

- select UPS
- change UPS
- view UPS7
- view another UPS
- switch UPS

---

## How to Interpret UPS Status

Common states include:

- ONLINE: utility/input power is available and the UPS is operating normally.
- ONBATT: the UPS reports that it is operating on battery.
- OFFLINE or unavailable: NUT cannot currently retrieve expected UPS data.

An ONBATT status is an important power event and may start the configured [shutdown timing and orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md).

An ONLINE status after ONBATT normally indicates utility/input power has returned; see the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md) for restoration and cancellation behavior.

Always use the Events section to confirm the event history when investigating an outage.

---

## How to Interpret Battery Charge

Battery charge is the UPS-reported percentage of available battery capacity.

General operator use:

1. Compare the current percentage with the normal value for that UPS.
2. Look for unexpected rapid decreases.
3. During ONBATT operation, expect battery percentage to decline.
4. After utility power returns, expect the UPS to recharge over time.

Do not use battery percentage alone to predict exact shutdown time.

---

## How to Interpret UPS Load

UPS load represents the amount of UPS capacity currently being used.

1. Compare load with the normal baseline for that UPS.
2. Investigate unexpected large increases.
3. Remember that higher load usually reduces available battery runtime.

Do not change protected-system shutdown logic solely because a single load reading looks unusual.

---

## How to Interpret Runtime

Runtime is the UPS estimate of remaining battery operating time.

Runtime is an estimate, not a guaranteed countdown.

It can change based on:

- current load
- battery condition
- UPS model
- recent load changes
- battery age

Use configured NUT shutdown timers and approved power-management policy rather than relying only on displayed runtime.

---

## How to Interpret Voltage Values

Where provided by the UPS:

- input voltage represents incoming utility power
- output voltage represents the voltage supplied by the UPS

Unexpected voltage values should be investigated together with UPS status and event history.

---

## How to Refresh UPS Data

Use Refresh UPS when the displayed values appear stale or when you want a fresh monitoring update.

1. Open Monitoring.
2. Click Refresh UPS.
3. Wait for the request to finish.
4. Confirm the selected UPS is still correct.
5. Review the updated status and measurements.

Refresh UPS is a read/refresh action.

It should not:

- trigger a shutdown
- change NUT mode
- change a timer
- change a protected-system configuration

Search phrases:

- refresh UPS
- update UPS status
- UPS data stale
- monitoring not updating

---

## How to Use UPS Rack Overview

UPS Rack Overview helps identify the physical location of a UPS.

1. Open Monitoring.
2. Click UPS Rack Overview.
3. Locate the UPS number/name.
4. Review the documented rack/cabinet/location information.
5. Match the logical UPS identity with the physical equipment before performing any physical maintenance.

Important:

Physical rack location and logical system mapping are related but are not interchangeable.

Always verify actual power connections before changing UPS-to-system mapping.

Search phrases:

- UPS Rack Overview
- where is UPS7
- physical UPS location
- which rack is UPS in
- find UPS

---

## How to Determine Whether Monitoring Is Healthy

Check all of the following:

1. The Control Center loads normally.
2. UPS data is populated.
3. Expected UPS systems are present.
4. UPS values refresh.
5. No unexpected offline/missing status appears.
6. nut-server.service is active.
7. nut-monitor.service is active when NUT is intended to be monitoring.

Remember:

NUT mode OFF means monitoring and logging are intentionally off.

OFF is not a monitoring-only safe mode.

---

## Production-Hours Safety

SAFE during production hours:

- viewing UPS status
- selecting UPS systems
- refreshing UPS data
- viewing Rack Overview
- reviewing battery/load/runtime/voltage

These are read-only/operator monitoring actions.

---

## Monitoring Impact

Normal use of the Monitoring page does not change monitoring configuration.

## Notification Impact

Viewing or refreshing UPS data does not itself change notification settings.

## Shutdown-Protection Impact

Viewing Monitoring data does not change shutdown protection.

However, an actual ONBATT event can start configured shutdown logic.

---

## Troubleshooting

If an expected UPS is missing or offline:

1. Refresh UPS once.
2. Confirm the correct UPS is selected.
3. Check the Events page.
4. Check nut-server.service.
5. Check nut-monitor.service.
6. Review the UPS-specific/NUT logs.
7. Do not immediately restart multiple NUT services without identifying the problem.

Search Help for:

- UPS offline
- UPS missing
- monitoring not updating

