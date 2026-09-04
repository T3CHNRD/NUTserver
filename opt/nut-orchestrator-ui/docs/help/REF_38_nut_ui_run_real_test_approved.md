# Reference Runbook - 38 nut ui run real test approved

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/38_nut_ui_run_real_test_approved.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

SCRIPT RUNBOOK - nut-ui-run-real-test-approved

Path:
  /usr/local/sbin/nut-ui-run-real-test-approved

Purpose:
  Approved wrapper for Real Test execution.

Controls:
  - Real Test safety gating.
  - ALLOW_REAL_TEST behavior.
  - REAL_TEST_PHASE behavior.
  - Calls into nut-ui-run-test real mode.

Risk:
  Very high. This is the gate between passphrase approval and live test execution.

Use only when:
  - Auditing Real Test safety.
  - Updating approved phase handling.
  - Troubleshooting Real Test launch behavior.