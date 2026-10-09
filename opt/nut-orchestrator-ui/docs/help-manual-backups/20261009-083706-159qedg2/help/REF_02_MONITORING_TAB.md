# Reference Runbook - 02 MONITORING TAB

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/02_MONITORING_TAB.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

CONTROL CENTER TAB - MONITORING

Purpose:
  Shows live UPS information pulled from the same NUT JSON source used by the
  existing UPS Monitoring Dashboard.

Includes:
  - Selected UPS
  - Battery charge
  - UPS load
  - Runtime remaining
  - Input voltage
  - Output voltage
  - UPS status
  - Last refresh time
  - Pontiac weather near the clock
  - UPS picker
  - UPS Rack Overview popup
  - UPS Load graph popup
  - UPS trivia / legend

Expected behavior:
  - Monitoring is the default tab.
  - Selected UPS rotates automatically.
  - Clicking Selected UPS opens the UPS picker.
  - Clicking UPS Load opens the load graph.
  - Clicking UPS Rack Overview opens rack/location details.
  - UPS status visually shows online/warning/offline state.
  - Pontiac temperature updates automatically.

Risk:
  Read-only monitoring section. Normal use should not change system behavior.