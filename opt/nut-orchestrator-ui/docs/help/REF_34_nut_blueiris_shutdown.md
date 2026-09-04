# Reference Runbook - 34 nut blueiris shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/34_nut_blueiris_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-blueiris-shutdown.sh

Path:
  /usr/local/sbin/nut-blueiris-shutdown.sh

Purpose:
  Controls Blue Iris shutdown behavior.

Controls:
  - Blue Iris shutdown sequence.
  - Remote command method.
  - Safety checks and logging.

Risk:
  High. Live execution can shut down Blue Iris or its host.

Use only when:
  - Preparing Blue Iris live shutdown testing.
  - Updating Blue Iris shutdown behavior.