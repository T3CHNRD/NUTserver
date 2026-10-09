# Reference Runbook - 13 upssched conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/13_upssched_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - upssched.conf

Path:
  /etc/nut/upssched.conf

Purpose:
  Controls scheduled/timed actions triggered by upsmon events.

Controls:
  - Timer behavior for ONBATT, ONLINE, LOWBATT, and related events.
  - Which command script runs when a timer fires.
  - Cancellation behavior when power returns.
  - FIFO/lock paths used by upssched.

Risk:
  Incorrect changes can cause delayed actions to run too early, too late, or not at all.

Use only when:
  - Adjusting outage delay timers.
  - Adjusting power-restore cancellation behavior.
  - Changing the command script used for timed NUT events.