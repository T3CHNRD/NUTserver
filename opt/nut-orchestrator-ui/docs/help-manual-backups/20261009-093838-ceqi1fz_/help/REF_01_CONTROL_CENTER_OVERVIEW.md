# Reference Runbook - 01 CONTROL CENTER OVERVIEW

Revision date: 2026-10-08

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/01_CONTROL_CENTER_OVERVIEW.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

NUT CONTROL CENTER OVERVIEW

URL:
  http://192.168.3.251/nut-ui/control-center

Purpose:
  The NUT Control Center is the consolidated page for UPS monitoring,
  event review, safe testing, configuration review, GitHub backup visibility,
  weather display, and live-test readiness.

Current sections:
  - Monitoring
  - Events
  - Tests & Logs
  - Configuration

Current safety state:
  - Real Test is live-capable only through its protected backend path; a UI control or historical passphrase test is not live authorization.
  - Current main Configuration editor Save is enabled for approved editable live configurations after validation.
  - Restore Lab is a separate interface; its captured dashboard-ui.json Save control remains disabled pending its controlled save test.
  - Phase 1 - Lansweeper only is the intended live-test scope.
  - Phase 2 and Phase 3 have historical scope restrictions; consult current task-specific status before any test.

Important warning:
  Do not enter the real Real Test passphrase unless you are ready for the
  selected live-test phase to run.
