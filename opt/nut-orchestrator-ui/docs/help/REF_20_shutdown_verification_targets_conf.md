# Reference Runbook - 20 shutdown verification targets conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/20_shutdown_verification_targets_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - shutdown-verification-targets.conf

Path:
  /etc/nut/config.d/shutdown-verification-targets.conf

Purpose:
  Defines shutdown verification targets and expected verification behavior.

Controls:
  - Which systems are checked after shutdown actions.
  - Verification method such as ping/API/other script behavior depending on current config.
  - Result classification such as confirmed down, unknown, failed, or similar logic depending on scripts.

Risk:
  High. Incorrect changes can cause shutdown verification results to be misleading.

Use only when:
  - Adding or removing verification targets.
  - Changing how shutdown success is classified.
  - Correcting target IPs, names, or expected behavior.