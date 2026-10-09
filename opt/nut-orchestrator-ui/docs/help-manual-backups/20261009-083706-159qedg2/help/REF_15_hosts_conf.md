# Reference Runbook - 15 hosts conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/15_hosts_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - hosts.conf

Path:
  /etc/nut/hosts.conf

Purpose:
  Controls host display definitions used by some NUT web/status tools.

Controls:
  - Display names for monitored UPS hosts.
  - Host entries shown by compatible NUT CGI/status pages.

Risk:
  Usually lower risk than shutdown files, but incorrect entries can confuse status displays.

Use only when:
  - Cleaning up visible UPS names.
  - Correcting host display entries.