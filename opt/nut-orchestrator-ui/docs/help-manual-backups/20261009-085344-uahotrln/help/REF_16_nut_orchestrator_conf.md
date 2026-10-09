# Reference Runbook - 16 nut orchestrator conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/16_nut_orchestrator_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - nut-orchestrator.conf

Path:
  /etc/nut/nut-orchestrator.conf

Purpose:
  Primary live orchestration configuration.

Controls:
  - Integration settings for orchestrated shutdown behavior.
  - External system connection details.
  - Hostnames and IPs for targets.
  - Credentials or credential-file references.
  - VMware, NetApp, Lansweeper, Blue Iris, Synology, VOIP, DB, or other integration settings.

Risk:
  High. Incorrect changes can affect shutdown orchestration and integrations.

Use only when:
  - Updating target IPs or hostnames.
  - Updating integration settings.
  - Updating controlled test scope.
  - Correcting orchestration variables.