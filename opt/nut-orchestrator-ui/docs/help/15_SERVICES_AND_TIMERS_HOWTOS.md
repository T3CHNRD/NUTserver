# Services and Timers - Complete Operator How-Tos

## Purpose

This section explains how to check the services and scheduled timers that support the NUT server.

Use these procedures before restarting anything.

---

## How to Check the Health of Core NUT Services

Use these read-only commands:

systemctl is-active nut-server.service
systemctl is-active nut-monitor.service
systemctl is-active nut-orchestrator-ui.service

Expected normal result when the corresponding function should be running:

active

To obtain additional detail without changing anything:

systemctl status nut-server.service --no-pager
systemctl status nut-monitor.service --no-pager
systemctl status nut-orchestrator-ui.service --no-pager

Search phrases:

- check NUT services
- is NUT running
- service status
- NUT monitor service
- dashboard service

---

## Important OFF Mode Behavior

NUT mode OFF means everything is intentionally off, including monitoring and logging.

Do not diagnose expected OFF-mode behavior as a failed monitoring service without first checking the selected NUT operating mode.

---

## How to Check NUT Systemd Timers

Start with a read-only timer inventory:

systemctl list-timers --all

To narrow the output:

systemctl list-timers --all | grep -Ei "nut|ups|health|telegram|weather|maintenance"

Review:

- timer name
- next scheduled run
- last scheduled run
- associated service

To inspect a specific timer after identifying its exact live name:

systemctl status TIMER-NAME.timer --no-pager

Do not guess timer names when making changes.

Search phrases:

- NUT timers
- daily health timer
- heartbeat timer
- systemd timer
- when does NUT run

---

## How to Safely Restart Only the Control Center UI

Use this when the web interface has been changed or the UI service requires a controlled restart.

Command:

sudo systemctl restart nut-orchestrator-ui.service

Then verify:

systemctl is-active nut-orchestrator-ui.service

Expected result:

active

This restart should not require restarting nut-server.service or nut-monitor.service.

After restart:

1. Reload the Control Center.
2. Confirm the page opens.
3. Confirm Help/API functionality if Help code was changed.

Search phrases:

- restart dashboard
- restart UI
- Control Center restart
- gunicorn restart
- dashboard not loading

---

## When NOT to Restart Services

Do not restart multiple NUT services merely because one page or feature looks wrong.

First identify:

1. which feature failed
2. which service owns that feature
3. whether the issue is UI-only, monitoring-related, or configuration-related

Unnecessary restarts can erase useful troubleshooting state or interrupt monitoring.

---

## Production-Hours Safety

SAFE:

- systemctl is-active
- systemctl status
- systemctl list-timers

USE CAUTION:

- restarting nut-orchestrator-ui.service

HIGH IMPACT:

- restarting monitoring/server services
- disabling timers
- changing timer schedules

Do not make high-impact service/timer changes without understanding their effect.

---

## Monitoring Impact

Restarting only the UI should not intentionally stop UPS monitoring.

Restarting NUT monitoring/server components may interrupt monitoring and must be treated separately.

## Notification Impact

Some notification workflows may depend on scheduled services/timers.

## Shutdown-Protection Impact

Do not disable or alter timers/services involved in outage processing without approval.

---

## Related Help

- Logs
- Troubleshooting
- Monitoring
- Notification Settings
- Shutdown Orchestration

## Technical References

- nut-server.service
- nut-monitor.service
- nut-orchestrator-ui.service
- systemctl list-timers --all
