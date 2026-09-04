# Reference Runbook - 37 nut ui run test

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/37_nut_ui_run_test.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-ui-run-test

Path:
  /usr/local/sbin/nut-ui-run-test

Purpose:
  Main backend test runner used by the UI.

Controls:
  - Simulated test behavior.
  - Real test behavior when called by the approved wrapper.
  - Phase-specific orchestration paths.
  - Test output returned to the UI.

Risk:
  High. This is core test/orchestration logic.

Use only when:
  - Updating simulated test behavior.
  - Updating real-test phase behavior.
  - Troubleshooting UI test output.