# NUT Protection Modes

## Purpose

NUT Protection Mode controls whether the NUT server is actively monitoring power events and whether live protected-system shutdown actions are allowed.

The NUT Control Center has three modes:

1. PROTECTING
2. STANDBY
3. OFF

These are operational controls and should not be changed casually.

## Quick Reference

| Mode | Monitoring | Logging | Scheduled Health Email | Live Shutdown Actions |
|---|---|---|---|---|
| PROTECTING | ON | ON | ON | ALLOWED when safety/event rules are satisfied |
| STANDBY | ON | ON | ON | BLOCKED |
| OFF | OFF | OFF | OFF | OFF |

Important:

- PROTECTING does not mean there is a problem.
- PROTECTING is the normal fully operational protection state.
- STANDBY keeps monitoring active while blocking live shutdown actions.
- OFF is not a monitoring-only safe mode.
- OFF stops monitoring, logging, scheduled reporting, and live actions.

## Where to Find Protection Mode

The Protection Mode controls are located near the top of the NUT Control Center.

The buttons are Protecting, Standby, and Off.

The current mode is also shown in the Control Center status area.

## PROTECTING

### What PROTECTING Does

PROTECTING is the normal fully operational NUT mode.

When PROTECTING is active:

- UPS monitoring is active.
- NUT event monitoring is active.
- Power-event logging is active.
- Scheduled reporting is allowed.
- Notifications operate according to Notification Settings.
- Real qualifying UPS events may create shutdown timers.
- Approved protected-system shutdown actions may run when all configured safety conditions are satisfied.

PROTECTING alone is not a CAUTION or warning condition.

### When to Use PROTECTING

Use PROTECTING when normal monitoring and automatic shutdown protection should be available.

### How to Put the NUT Server into PROTECTING Mode

1. Open the NUT Control Center.
2. Review current UPS and system status.
3. Do not change modes during an unexplained active power event.
4. Click Protecting.
5. Review and confirm the change.
6. Wait for the Control Center to update.

### How to Verify PROTECTING

Run:

    sudo /usr/local/sbin/nut-production-status

Expected values include mode armed, mode_label PROTECTING, nut_monitor active, and allow_live_actions 1.

Also verify:

    systemctl is-active nut-server.service
    systemctl is-active nut-monitor.service

### Production-Hours Safety

Changing from STANDBY to PROTECTING does not itself shut down equipment. However, PROTECTING allows configured live shutdown actions to run if a real qualifying UPS event occurs and all configured safety conditions are satisfied.

## STANDBY

### What STANDBY Does

STANDBY keeps NUT monitoring and logging active while blocking live protected-system shutdown actions.

Use STANDBY for approved configuration, notification, or troubleshooting work when monitoring should continue but live production shutdown actions must remain blocked.

### How to Put the NUT Server into STANDBY Mode

1. Open the NUT Control Center.
2. Confirm there is no active outage or shutdown sequence requiring investigation.
3. Click Standby.
4. Complete any confirmation shown.
5. Wait for the status to update.

### How to Verify STANDBY

Run sudo /usr/local/sbin/nut-production-status and confirm STANDBY, monitoring active, and live actions blocked.

## OFF

### What OFF Does

OFF intentionally disables the operational NUT protection environment.

OFF means monitoring OFF, operational event logging OFF, scheduled Daily Health Email OFF, live shutdown actions OFF, and automated protection behavior OFF.

OFF is not a monitoring-only safe mode.

### When to Use OFF

Use OFF only when the NUT environment intentionally needs to be stopped for approved maintenance or troubleshooting. If monitoring should continue but live shutdown actions should be blocked, use STANDBY instead.

### How to Turn NUT Operational Monitoring OFF

1. Open the NUT Control Center.
2. Confirm stopping NUT monitoring is intentional.
3. Confirm no active production outage requires NUT protection.
4. Click Off.
5. Complete any confirmation shown.
6. Wait for the status to update.

### How to Verify OFF

Run sudo /usr/local/sbin/nut-production-status and confirm the mode reports OFF and monitoring is not active.

### How to Return from OFF to Normal Operation

1. Complete the work that required OFF.
2. Review NUT service health.
3. Choose STANDBY if monitoring should resume while live actions remain blocked.
4. Choose PROTECTING if full production protection should resume.
5. Verify the resulting mode.
6. Confirm UPS monitoring has resumed.

## Notifications and Protection Mode

Protection Mode and Notification Settings are separate controls. Notification switches control message delivery and do not independently change shutdown protection. OFF is the exception because OFF intentionally stops the broader operational environment, including scheduled reporting.

## Shutdown Protection Summary

- PROTECTING: live shutdown actions can be permitted by qualifying real events and configured safety rules.
- STANDBY: live shutdown actions are blocked while monitoring remains active.
- OFF: monitoring and live shutdown protection are stopped.

## Troubleshooting a Mode Change

If the button changes but backend status does not:

1. Refresh the Control Center.
2. Run sudo /usr/local/sbin/nut-production-status.
3. Review /var/log/nut-production-mode.log if present.
4. Check systemctl is-active nut-orchestrator-ui.service.
5. Do not repeatedly click mode buttons while troubleshooting.

## Relevant Logs

- /var/log/nut-production-mode.log
- /var/log/nut-orchestrator.log
- Power / Boot Event Log in the Control Center

## Related Help

- Monitoring
- Notification Settings
- Shutdown Orchestration
- Tests and Logs
- Configuration

## Technical Reference

- /usr/local/sbin/nut-production-mode
- /usr/local/sbin/nut-production-status
- /var/www/html/nut-state/production-mode.json
- POST /api/production-mode

## Security and Safety

Never place passwords, SMTP secrets, Telegram tokens, vCenter credentials, database credentials, or Real Test passphrases in Help documentation.
