# Reference Runbook - 17 config d nut orchestrator conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/17_config_d_nut_orchestrator_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - config.d nut-orchestrator.conf

Path:
  /etc/nut/config.d/nut-orchestrator.conf

Purpose:
  Additional orchestrator configuration under /etc/nut/config.d.

Controls:
  - Modularized orchestrator settings.
  - Configuration values used by shutdown/test scripts.

Risk:
  High. Incorrect changes can affect target selection, credentials, or shutdown behavior.

Use only when:
  - Updating orchestrator modular config.
  - Confirming or changing shutdown target configuration.