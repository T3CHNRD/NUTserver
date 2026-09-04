# Reference Runbook - 36 nut netapp halt

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/36_nut_netapp_halt.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-netapp-halt.sh

Path:
  /usr/local/sbin/nut-netapp-halt.sh

Purpose:
  Controls NetApp halt/shutdown behavior.

Controls:
  - NetApp SSH/API halt method depending on script content.
  - NetApp node/cluster targeting.
  - Safety checks and logging.

Risk:
  Very high. Live execution can halt NetApp nodes.

Use only when:
  - Confirming NetApp live shutdown behavior.
  - Updating NetApp node targeting.
  - Correcting NetApp access or command behavior.