# Reference Runbook - 01 CONTROL CENTER OVERVIEW

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
  - Real Test is live-ready.
  - Real Test is locked behind the existing Real Test passphrase.
  - Fake-password proof passed.
  - Save is disabled.
  - Phase 1 - Lansweeper only is the intended live-test scope.
  - Phase 2 and Phase 3 are deferred unless intentionally approved.

Important warning:
  Do not enter the real Real Test passphrase unless you are ready for the
  selected live-test phase to run.