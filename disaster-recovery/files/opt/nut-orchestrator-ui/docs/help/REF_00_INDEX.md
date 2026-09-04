# Reference Runbook - 00 INDEX

> **REFERENCE RUNBOOK**
>
> This material was imported from existing NUT project documentation.
> It may contain procedures or assumptions from an earlier implementation.
> For an operational change, prefer the current task-specific Help article when one exists.
> Verify the live configuration before performing any disruptive action.

---

SOURCE FILE: runbooks/00_INDEX.txt
SECURITY: Sanitized copy; credential-like values are redacted.
==============================================================================

NUT CONTROL CENTER RUNBOOK INDEX

Purpose:
  This folder contains separate TXT runbooks for the NUT Control Center,
  each Control Center tab, each important editable config, each shutdown/test
  script, and protected credential files.

Control Center URL:
  http://192.168.3.251/nut-ui/control-center

Current known state:
  - Control Center uses tabbed sections.
  - Pontiac temperature is shown by the clock.
  - Real Test is live-ready.
  - Real Test is passphrase locked.
  - Fake-password proof passed.
  - Fake-password proof returned: Real Test blocked: [REDACTED]
  - Phase 1 - Lansweeper only is the intended live-test scope.
  - Phase 2 and Phase 3 are deferred unless intentionally approved.
  - Save remains disabled.

Recommended reading order:
  01_CONTROL_CENTER_OVERVIEW.txt
  02_MONITORING_TAB.txt
  03_EVENTS_TAB.txt
  04_TESTS_AND_LOGS_TAB.txt
  05_CONFIGURATION_TAB.txt
  06_PHASE1_LANSWEEPER_LIVE_TEST.txt
  07_SAFE_EDITING_RULES.txt

Editable config runbooks:
  10_ups_conf.txt
  11_upsd_conf.txt
  12_upsmon_conf.txt
  13_upssched_conf.txt
  14_nut_conf.txt
  15_hosts_conf.txt
  16_nut_orchestrator_conf.txt
  17_config_d_nut_orchestrator_conf.txt
  18_approved_targets_yml.txt
  19_dashboard_ui_json.txt
  20_shutdown_verification_targets_conf.txt

Shutdown / orchestration script runbooks:
  30_nut_lansweeper_shutdown.txt
  31_nut_synology_shutdown.txt
  32_nut_voip_shutdown.txt
  33_nut_db_shutdown.txt
  34_nut_blueiris_shutdown.txt
  35_nut_vmware_shutdown.txt
  36_nut_netapp_halt.txt
  37_nut_ui_run_test.txt
  38_nut_ui_run_real_test_approved.txt
  39_nut_orchestrator_sh.txt
  40_nut_local_final_shutdown.txt

Protected / sensitive file runbooks:
  50_db_telnet_user.txt
  51_db_telnet_pass.txt
  52_vcenter_pass.txt