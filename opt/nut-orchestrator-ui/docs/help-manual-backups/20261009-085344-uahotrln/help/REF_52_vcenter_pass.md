# Reference Runbook - 52 vcenter pass

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/52_vcenter_pass.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

PROTECTED FILE RUNBOOK - vcenter.pass

Path:
  /etc/nut/vcenter.pass

Purpose:
  Stores or references the vCenter password used by VMware integration.

Risk:
  Sensitive credential material.

Use only when:
  - Rotating vCenter password.
  - Moving VMware integration away from fallback config.
  - Correcting VMware authentication.

Important:
  Do not paste real credential values into chat.