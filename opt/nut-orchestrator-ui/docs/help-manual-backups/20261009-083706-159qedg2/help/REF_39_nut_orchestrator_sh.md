# Reference Runbook - 39 nut orchestrator sh

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/39_nut_orchestrator_sh.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-orchestrator.sh

Path:
  /usr/local/bin/nut-orchestrator.sh

Purpose:
  Main orchestration script.

Controls:
  - Overall shutdown orchestration flow.
  - Target order.
  - Integration calls.
  - Logging/classification.
  - Final orchestration behavior during UPS events.

Risk:
  Very high. This is the core production orchestration script.

Use only when:
  - Updating shutdown order.
  - Updating orchestration logic.
  - Troubleshooting real event behavior.