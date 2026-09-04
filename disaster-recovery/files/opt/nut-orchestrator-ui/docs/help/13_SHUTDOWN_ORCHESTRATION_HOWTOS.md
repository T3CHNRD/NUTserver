# Shutdown Orchestration - Complete Operator How-Tos

## Purpose

Shutdown orchestration is the logic NUT uses to respond to UPS power events, wait the configured amount of time, cancel actions when power returns in time, and execute approved protected-system shutdown workflows when required.

This is one of the highest-impact areas of the NUT server.

---


## Current Event Chain

The current shutdown-event path is:

`upsmon -> upssched -> custom NUT orchestrator -> protected-system wrapper`

This allows each UPS to have its own:

- timer
- cancellation behavior
- protected-system action
- alert-only behavior
- verification path

For the current UPS1 through UPS9 mapping, use [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).

For the meaning of ONBATT, ONLINE, LOWBATT, COMMBAD, COMMOK, shutdown, and cancellation notifications, use the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).

---

## How the Shutdown Flow Works

At a high level:

1. NUT detects the UPS power event.
2. The event is passed through upsmon/upssched.
3. The configured timer for that UPS begins when applicable.
4. NUT records the event and performs configured notification actions.
5. If utility power returns before the shutdown threshold, the pending workflow is cancelled when the configuration allows cancellation.
6. If the threshold expires, the orchestrator begins the approved shutdown sequence for systems mapped to that UPS.
7. The NUT server itself is intended to remain available long enough to coordinate the protected-system shutdown process.

Technical references:

- /etc/nut/upsmon.conf
- /etc/nut/upssched.conf
- /usr/sbin/upssched
- /usr/local/bin/nut-orchestrator.sh

---

## How to Understand an ONBATT Event

ONBATT means the affected UPS has reported that it is operating on battery.

An ONBATT event does not necessarily mean systems shut down immediately.

For shutdown-enabled UPS paths, the configured timer determines when protected-system actions become eligible to run.

Search phrases:

- UPS went on battery
- ONBATT
- power went out
- when will servers shut down
- what happens during power outage

---

## How to Understand an ONLINE Event

ONLINE means the UPS reports that utility/input power has returned.

When power returns before a pending shutdown workflow reaches its execution point, NUT can cancel the outstanding timed shutdown action according to the configured orchestration logic.

Search phrases:

- power came back
- ONLINE
- cancel shutdown
- outage ended
- UPS returned online

---

## How Shutdown Cancellation Works

1. UPS enters ONBATT.
2. A configured shutdown timer begins.
3. Utility power returns.
4. UPS reports ONLINE.
5. NUT processes the restoration event.
6. Eligible pending shutdown actions are cancelled.
7. Cancellation/restoration is recorded and notification behavior runs according to configuration.

Never assume a shutdown was cancelled merely because building power appears to be back.

Verify the NUT event state and logs.

---

## Current Documented Shutdown Timer Baseline

- UPS7: 240 seconds
- UPS2: 420 seconds
- UPS8: 180 seconds
- UPS6: 300 seconds
- UPS9: 360 seconds
- UPS3: 300 seconds

Current documented alert-only UPS paths:

- UPS1
- UPS4
- UPS5

Always verify the live configuration before changing or relying on these values.

---


## UPS9 Shutdown Sequence

UPS9 uses the broad VMware/storage shutdown domain.

The current live sequence is:

1. VMware domain
   - configured guest shutdown phases
   - VCSA shutdown
   - ESXi shutdown
2. Synology
3. NetApp01
4. NetApp02
5. local NUT server final shutdown

The NUT server runs last so it remains available to coordinate and log the earlier shutdown actions.

For VMware-specific behavior, use [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md) and the [VMware shutdown wrapper reference](REF_35_nut_vmware_shutdown.md).

For the full UPS9 mapping, use [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).

---

## How to Check Which Systems Are Scheduled to Shut Down

1. Identify the UPS involved.
2. Review the UPS-to-system mapping.
3. Review approved-targets configuration.
4. Review the associated shutdown wrapper.
5. Confirm the system is physically powered by the UPS you are evaluating.
6. Confirm the logical mapping matches the physical connection.

Do not assume rack position alone determines UPS mapping.

---

## How to Verify Shutdown Logic Without Shutting Anything Down

1. Use the Control Center Simulated Test where applicable.
2. Review the selected target carefully.
3. Review the expected wrapper/action.
4. Review connectivity/authentication checks.
5. Confirm PASS/FAIL output.
6. Review logs.
7. Stop if any validation fails.

Do not escalate a failed simulated test into a Real Test.

---

## How to Change a Shutdown Timer

Search Help for:

- change UPS shutdown time
- change UPS7 timer
- shutdown delay

Use the Configuration How-Tos article.

Changing a timer is a high-impact configuration change and must be verified against the live upssched/orchestrator configuration.

---

## How to Troubleshoot a Shutdown Workflow Failure

1. Identify the UPS event using the [Notification and Power Event Reference](21_NOTIFICATION_EVENT_REFERENCE.md).
2. Identify the protected system that failed using [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md).
3. Determine whether the failure occurred before or after the configured delay.
4. Review orchestrator output using [Logs](16_LOGS_HOWTOS.md).
5. Review the protected-system wrapper and its reference in [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md).
6. Check authentication using the approved process in [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md) without exposing credentials.
7. Check network connectivity.
8. Check approved-target mapping using the [approved-targets.yml reference](REF_18_approved_targets_yml.md).
9. Run only the supported non-disruptive validation described in [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md).
10. Correct the verified fault.
11. Repeat the simulated/non-destructive validation.

Do not perform a live production shutdown merely to prove a troubleshooting change.

---

## Production-Hours Safety

SAFE:

- reviewing mappings
- reviewing timers
- reviewing logs
- running approved non-disruptive validation
- running supported Simulated Tests

HIGH RISK / DO NOT RUN WITHOUT APPROVAL:

- changing shutdown timers
- changing protected-system mappings
- changing live shutdown commands
- Real Test
- intentionally forcing a UPS ONBATT condition
- shutting down production DB01
- shutting down production DB02
- shutting down VMware/storage production systems

---

## Monitoring Impact

Reviewing orchestration is read-only.

Changes to upsmon, upssched, target mappings, or orchestrator logic can directly affect outage response.

## Notification Impact

ONBATT, ONLINE, shutdown, cancelled, and final events may generate configured notifications.

## Shutdown-Protection Impact

Incorrect timers, mappings, credentials, or wrapper commands can prevent systems from shutting down correctly during a real outage.

---


## Technical References

- /etc/nut/upsmon.conf
- /etc/nut/upssched.conf
- /usr/local/bin/nut-orchestrator.sh
- approved-targets.yml
- shutdown-verification-targets.conf
- Reference Runbook - nut orchestrator sh
- Reference Runbook - nut local final shutdown

---

## UPS Inventory and Physical Mapping

For the current UPS1 through UPS9 location, physical-equipment, automatic-action, alert-only, timer, and wrapper matrix, see:

[UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md)

Use that article when answering questions such as:

- what is plugged into UPS3
- what does UPS7 shut down
- which UPS protects DB01
- which UPS protects DB02
- what is connected to UPS9
- which UPS devices are alert only

Remember that physical power connection and automatic shutdown behavior are separate facts.
