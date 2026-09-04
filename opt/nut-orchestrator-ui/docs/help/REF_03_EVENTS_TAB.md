# Reference Runbook - 03 EVENTS TAB

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/03_EVENTS_TAB.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

CONTROL CENTER TAB - EVENTS

Purpose:
  Shows the shared Power / Boot Event Log.

Used to review:
  - Power outage events
  - Power restored events
  - APC / IDF monitor events
  - Simulated test events
  - Real test events
  - Shutdown classification events
  - Control Center readiness/staged events

Expected behavior:
  - Newest events should appear first.
  - Event feed should match the shared dashboard/NUT event source.
  - Page should auto-refresh.

Risk:
  Read-only event review section.