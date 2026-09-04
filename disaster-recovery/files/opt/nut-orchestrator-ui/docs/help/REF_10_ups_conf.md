# Reference Runbook - 10 ups conf

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/10_ups_conf.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

EDITABLE LIVE CONFIG - ups.conf

Path:
  /etc/nut/ups.conf

Purpose:
  Defines the UPS devices known to NUT.

Controls:
  - UPS names such as ups1, ups2, ups3, etc.
  - Driver type, such as snmp-ups or usbhid-ups.
  - Network UPS IP/port definitions.
  - USB UPS matching values.
  - SNMP community and SNMP version.
  - Poll interval.
  - UPS descriptions shown in monitoring tools.

Risk:
  Incorrect changes can cause one or more UPS units to stop reporting data.

Use only when:
  - Adding a UPS.
  - Removing a UPS.
  - Correcting a UPS IP address.
  - Correcting SNMP or USB driver settings.
  - Updating descriptions.