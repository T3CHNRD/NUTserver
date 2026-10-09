# Reference Runbook - 05 CONFIGURATION TAB

Revision date: 2026-10-08

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
  - Save (enabled for approved editable live configurations after validation)

Current safety state:
  - Reload is available.
  - Validate is available.
  - Revert is available.
  - Main Configuration editor Save is enabled for approved editable live configurations; Validate first.
  - Restore Lab is a separate interface. Its captured dashboard-ui.json Save control remains disabled pending a controlled save test.

Important:
The older blanket statement that Save is disabled is stale for the main Configuration editor. The disabled Save state applies to the separate Restore Lab dashboard-ui.json control only.

Risk:
  Configuration viewing is safe.
  Saving an approved live config is a production change; use the required review and validation controls.
