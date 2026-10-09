# Reference Runbook - 12 upsmon conf

Revision date: 2026-10-08

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/12_upsmon_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - upsmon.conf

Path:
  /etc/nut/upsmon.conf

Purpose:
  Controls NUT monitoring behavior and shutdown decision handling.

Controls:
  - UPS monitoring definitions.
  - Notification behavior.
  - NOTIFYCMD integration.
  - NOTIFYFLAG behavior.
  - Final shutdown coordination.
  - Interaction with upssched.

Current captured shutdown directives:

  SHUTDOWNCMD "/sbin/shutdown -h now"
  POWERDOWNFLAG /etc/killpower

FSD means Forced Shutdown. It is a separate upsmon state/path from the cancelable per-UPS timers handled by upssched and the custom orchestrator. Utility power returning or an ONLINE event does not simply clear FSD. The configured SHUTDOWNCMD directly invokes `/sbin/shutdown -h now` and bypasses `nut-local-final-shutdown.sh`.

Changing either SHUTDOWNCMD or POWERDOWNFLAG requires a full upsmon stop/start. A reload alone is not sufficient. Do not perform a service stop/start as part of documentation review.

Risk:
  Critical shutdown-behavior file. Incorrect changes can affect whether outage
  events trigger correctly.

Use only when:
  - Adjusting NUT outage handling.
  - Adjusting notification behavior.
  - Adjusting upsmon/upssched integration.
  - Troubleshooting missed ONBATT, ONLINE, or LOWBATT events.
