# Reference Runbook - 19 dashboard ui json

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/19_dashboard_ui_json.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - dashboard-ui.json

Path:
  /etc/nut/config.d/dashboard-ui.json

Purpose:
  Controls dashboard/UI behavior.

Controls:
  - UI-facing dashboard settings.
  - Display behavior or configurable dashboard options depending on current JSON content.

Risk:
  Lower than shutdown scripts/configs. This is the preferred file for a future controlled Save test.

Use only when:
  - Testing Control Center Save safely.
  - Adjusting dashboard/UI behavior.