# Reference Runbook - 04 TESTS AND LOGS TAB

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/04_TESTS_AND_LOGS_TAB.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

CONTROL CENTER TAB - TESTS & LOGS

Purpose:
  Contains testing, log export, Action Output, and Advanced Live Test Controls.

Includes:
  - Simulated Test
  - Export Logs
  - Action Output
  - Advanced Live Test Controls

Real Test behavior:
  - Run Test uses the existing protected backend path.
  - Selected phase is submitted to /nut-ui/api/test/real.
  - Fake password must be rejected with: Real Test blocked: invalid passphrase.
  - Real passphrase should only be entered during an approved live-test window.

Current live-test scope:
  - Use Phase 1 - Lansweeper only unless the scope is intentionally changed.
  - Phase 2 and Phase 3 are deferred.

Risk:
  Simulated Test should be safe.
  Export Logs should be safe.
  Run Test is live-capable if the real passphrase is [REDACTED]