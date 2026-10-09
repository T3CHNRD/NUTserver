# Reference Runbook - 33 nut db shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/33_nut_db_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-db-shutdown.sh

Path:
  /usr/local/sbin/nut-db-shutdown.sh

Purpose:
  Controls database-related shutdown behavior.

Controls:
  - DB shutdown sequence.
  - Telnet/API/remote shutdown behavior depending on script content.
  - Safety checks and logging.

Risk:
  High. Live execution can affect database availability.

Use only when:
  - Updating DB shutdown method.
  - Troubleshooting DB shutdown test behavior.