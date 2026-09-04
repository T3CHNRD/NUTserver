# Reference Runbook - 18 approved targets yml

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/18_approved_targets_yml.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - approved-targets.yml

Path:
  /etc/nut/config.d/approved-targets.yml

Purpose:
  Defines approved or recognized targets for orchestrated actions.

Controls:
  - Which targets are approved for orchestration.
  - Target metadata used by scripts or UI validation.

Risk:
  High. Incorrect changes can authorize the wrong target or remove an expected target.

Use only when:
  - Adding approved shutdown targets.
  - Removing decommissioned targets.
  - Correcting target names or metadata.