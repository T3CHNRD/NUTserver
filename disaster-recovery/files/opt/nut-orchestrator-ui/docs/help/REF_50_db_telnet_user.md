# Reference Runbook - 50 db telnet user

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/50_db_telnet_user.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

PROTECTED FILE RUNBOOK - db-telnet.user

Path:
  /etc/nut/db-telnet.user

Purpose:
  Stores or references the DB telnet username used by DB shutdown logic.

Risk:
  Sensitive credential material.

Use only when:
  - Rotating DB telnet username.
  - Correcting DB access settings.

Important:
  Do not paste real credential values into chat.