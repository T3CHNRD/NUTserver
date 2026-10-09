# Reference Runbook - 11 upsd conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/11_upsd_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - upsd.conf

Path:
  /etc/nut/upsd.conf

Purpose:
  Controls the NUT UPS data server.

Controls:
  - How NUT exposes UPS data to clients.
  - Network listen behavior.
  - Local or remote access behavior depending on LISTEN lines.

Risk:
  Incorrect changes can prevent clients or dashboards from reading UPS data.

Use only when:
  - Changing NUT server listen behavior.
  - Adjusting client access design.
  - Troubleshooting NUT client connectivity.