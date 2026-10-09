# Reference Runbook - 30 nut lansweeper shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/30_nut_lansweeper_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-lansweeper-shutdown.sh

Path:
  /usr/local/sbin/nut-lansweeper-shutdown.sh

Purpose:
  Controls Lansweeper shutdown behavior.

Controls:
  - Lansweeper shutdown method.
  - Phase 1 live-test target behavior.
  - Safety gates for live execution.
  - Logging and classification for Lansweeper shutdown.

Risk:
  High. Live execution can shut down Lansweeper.

Use only when:
  - Preparing or adjusting Phase 1 live test.
  - Correcting Lansweeper shutdown behavior.