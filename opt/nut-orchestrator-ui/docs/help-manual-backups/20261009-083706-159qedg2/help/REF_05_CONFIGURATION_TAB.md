# Reference Runbook - 05 CONFIGURATION TAB

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/05_CONFIGURATION_TAB.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

CONTROL CENTER TAB - CONFIGURATION

Purpose:
  Contains approved Editable Live Config and Read-Only Reference tools.

Includes:
  - Editable Live Config selector
  - Read-Only Reference selector
  - Config Editor
  - Reference Viewer
  - Reload
  - Validate
  - Revert
  - Save Disabled

Current safety state:
  - Reload is available.
  - Validate is available.
  - Revert is available.
  - Save is disabled.

Important:
  Save should remain disabled until a controlled dashboard-ui.json save test is approved.

Risk:
  Configuration viewing is safe.
  Editing without Save is reversible using Revert.
  Save remains disabled to prevent accidental live config changes.