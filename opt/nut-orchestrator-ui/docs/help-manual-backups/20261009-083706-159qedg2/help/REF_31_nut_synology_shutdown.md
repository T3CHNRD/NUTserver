# Reference Runbook - 31 nut synology shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/31_nut_synology_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-synology-shutdown.sh

Path:
  /usr/local/sbin/nut-synology-shutdown.sh

Purpose:
  Controls Synology DSM API shutdown behavior.

Controls:
  - Synology DSM API login/logout.
  - Synology shutdown API call.
  - Simulation vs live behavior.
  - Safety gate checks.
  - Shutdown classification logging.

Risk:
  High. Live execution can shut down the Synology.

Use only when:
  - Updating Synology shutdown method.
  - Correcting DSM API behavior.
  - Troubleshooting Synology shutdown classification.