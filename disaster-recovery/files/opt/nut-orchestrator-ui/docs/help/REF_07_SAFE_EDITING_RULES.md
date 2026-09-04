# Reference Runbook - 07 SAFE EDITING RULES

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/07_SAFE_EDITING_RULES.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SAFE EDITING RULES

General rules:
  - Do not edit live shutdown scripts casually.
  - Prefer Reload and Validate before any Save.
  - Keep Save disabled until the controlled dashboard-ui.json test is approved.
  - Do not paste real passwords into chat.
  - Do not use Phase 2 or Phase 3 unless the live-test scope is intentionally expanded.
  - Back up to GitHub after meaningful changes.
  - Record major readiness/test status in the event log.

Before any Real Test:
  - Confirm selected phase.
  - Confirm test window.
  - Confirm affected systems.
  - Confirm monitoring is open.
  - Confirm Action Output is visible.
  - Confirm Events tab / Power Boot Event Log is available.
  - Confirm GitHub backup is current.

Tonight's Phase 1 rule:
  Use Phase 1 - Lansweeper only.
  Do not select Phase 2 or Phase 3 unless the scope is intentionally changed.