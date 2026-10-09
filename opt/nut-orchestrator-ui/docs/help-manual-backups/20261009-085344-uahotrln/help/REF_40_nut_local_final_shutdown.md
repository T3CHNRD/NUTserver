# Reference Runbook - 40 nut local final shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/40_nut_local_final_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-local-final-shutdown.sh

Path:
  /usr/local/sbin/nut-local-final-shutdown.sh

Purpose:
  Handles the local final shutdown behavior for the NUT server.

Controls:
  - Local server final shutdown behavior.
  - Final-stage shutdown logic after orchestration.
  - Safety handling depending on current script content.

Risk:
  Very high. Live execution can shut down the NUT server itself.

Use only when:
  - Updating final local shutdown behavior.
  - Troubleshooting final shutdown sequence.
  - Preparing production cutover.