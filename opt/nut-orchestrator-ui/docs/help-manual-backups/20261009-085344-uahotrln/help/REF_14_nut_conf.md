# Reference Runbook - 14 nut conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/14_nut_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - nut.conf

Path:
  /etc/nut/nut.conf

Purpose:
  Defines the NUT operating mode.

Controls:
  - Whether the system behaves as standalone, netserver, or netclient.

Risk:
  Incorrect changes can prevent NUT services from behaving as the main UPS data server.

Use only when:
  - Changing the NUT server/client architecture.
  - Correcting NUT service startup mode.