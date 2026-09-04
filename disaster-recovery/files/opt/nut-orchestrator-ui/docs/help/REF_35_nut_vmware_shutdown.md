# Reference Runbook - 35 nut vmware shutdown

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/35_nut_vmware_shutdown.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-vmware-shutdown.sh

Path:
  /usr/local/sbin/nut-vmware-shutdown.sh

Purpose:
  Controls VMware shutdown behavior.

Controls:
  - VMware/vCenter/ESXi shutdown orchestration.
  - VM or host handling depending on script content.
  - Safety checks and sequencing.

Risk:
  Very high. Live execution can affect VMs or ESXi hosts.

Use only when:
  - Updating VMware shutdown sequence.
  - Preparing VMware live testing.
  - Correcting VMware/vCenter integration behavior.