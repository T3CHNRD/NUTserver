# Reference Runbook - 32 nut voip shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/32_nut_voip_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-voip-shutdown.sh

Path:
  /usr/local/sbin/nut-voip-shutdown.sh

Purpose:
  Controls VOIP/PBX shutdown behavior.

Controls:
  - Remote shutdown behavior for the VOIP server.
  - SSH/systemctl-based shutdown behavior depending on script content.
  - Safety gate checks.

Risk:
  High. Live execution can shut down the VOIP/PBX system.

Use only when:
  - Updating VOIP shutdown method.
  - Correcting VOIP host/user settings.
  - Preparing VOIP live shutdown testing.