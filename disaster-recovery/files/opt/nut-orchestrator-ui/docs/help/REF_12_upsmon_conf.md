# Reference Runbook - 12 upsmon conf

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

Risk:
  Critical shutdown-behavior file. Incorrect changes can affect whether outage
  events trigger correctly.

Use only when:
  - Adjusting NUT outage handling.
  - Adjusting notification behavior.
  - Adjusting upsmon/upssched integration.
  - Troubleshooting missed ONBATT, ONLINE, or LOWBATT events.