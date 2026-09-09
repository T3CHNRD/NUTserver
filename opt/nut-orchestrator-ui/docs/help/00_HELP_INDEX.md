# NUT Control Center Help & Runbook

## Purpose

This Help & Runbook is the operator and administrator knowledge base for the
NUT Control Center.

The documentation is not complete until every user-facing feature, setting,
button, field, workflow, service, configuration item, notification function,
test, backup/restore function, protected-system workflow, and troubleshooting
area has step-by-step instructions.

## Required Article Standard

Every applicable article must explain:

1. What the feature is
2. What it controls
3. Where to find it
4. When to use it
5. When not to use it
6. Step-by-step instructions
7. Expected result
8. How to verify success
9. How to undo or revert
10. Production-hours safety
11. Monitoring impact
12. Notification impact
13. Shutdown-protection impact
14. Relevant logs
15. Troubleshooting
16. Related features
17. Technical reference
18. Security or secret-handling warnings

## Categories

### 01 - Getting Started
- [Control Center overview](01_GETTING_STARTED.md#step-1-open-the-nut-control-center)
- [Daily operator checklist](01_GETTING_STARTED.md#how-to-begin-a-normal-nut-control-center-operator-session)
- [System status](01_GETTING_STARTED.md#how-to-determine-whether-the-nut-server-is-healthy)
- [Protection modes](02_PROTECTION_MODES.md#quick-reference)

### 02 - System Overview
- [Health](01_GETTING_STARTED.md#how-to-determine-whether-the-nut-server-is-healthy)
- [Selected UPS](03_MONITORING_HOWTOS.md#how-to-select-a-different-ups)
- [Latest event](04_EVENTS_HOWTOS.md#how-the-latest-event-card-works)
- Clock/date **(Documentation needed)**
- [Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-read-the-weather-summary)
- [Maintenance status](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-verify-maintenance-status)
- [Refresh](01_GETTING_STARTED.md#how-to-use-the-main-refresh-button) / refresh countdown **(countdown documentation needs expansion)**
- [Backup](11_BACKUP_HOWTOS.md#how-to-run-backup-all-from-the-control-center) / [Refresh](01_GETTING_STARTED.md#how-to-use-the-main-refresh-button) / [Restore](12_RESTORE_AND_DR_HOWTOS.md#how-to-use-the-restore-button-safely)

### 03 - Monitoring
- [UPS selector](03_MONITORING_HOWTOS.md#how-to-select-a-different-ups)
- [UPS metrics](03_MONITORING_HOWTOS.md#how-to-check-the-status-of-a-ups)
- [UPS status](03_MONITORING_HOWTOS.md#how-to-interpret-ups-status)
- Load graph **(Documentation needed)**
- [UPS Rack Overview](03_MONITORING_HOWTOS.md#how-to-use-ups-rack-overview)
- UPS Trivia / Legend **(Documentation needed)**
- [Refresh UPS](03_MONITORING_HOWTOS.md#how-to-refresh-ups-data)

### 04 - Events
- [Power / Boot Event Log](04_EVENTS_HOWTOS.md#how-to-review-recent-power-and-boot-events)
- [Event types](21_NOTIFICATION_EVENT_REFERENCE.md)
- [Refresh Event Log](04_EVENTS_HOWTOS.md#how-to-refresh-the-event-log)
- [Event troubleshooting](04_EVENTS_HOWTOS.md#troubleshooting)

### 05 - Notification Settings
- [Daily Health Email](05_NOTIFICATION_SETTINGS.md#how-to-turn-daily-health-email-on-or-off)
- [Weather-Based Closing Thoughts](05_NOTIFICATION_SETTINGS.md#how-to-turn-weather-based-closing-thoughts-on-or-off)
- [Email Recipients](07_EMAIL_HOWTOS.md#how-to-add-or-remove-email-recipients)
- [Telegram master](05_NOTIFICATION_SETTINGS.md#how-to-turn-all-telegram-push-notifications-off)
- [Daily Health Push](05_NOTIFICATION_SETTINGS.md#how-to-turn-daily-health-push-on-or-off)
- [Critical Power Alerts](05_NOTIFICATION_SETTINGS.md#how-to-turn-critical-power-alerts-on-or-off)
- [Heartbeat](05_NOTIFICATION_SETTINGS.md#how-to-turn-telegram-heartbeat-on-or-off)
- [Telegram Recipients](05_NOTIFICATION_SETTINGS.md#how-to-remove-a-telegram-recipient)
- [Pending Telegram Access](05_NOTIFICATION_SETTINGS.md#how-to-approve-a-pending-telegram-user)

### 06 - Telegram
- [Access request](06_TELEGRAM_HOWTOS.md#how-a-new-telegram-user-requests-access)
- [Approval](05_NOTIFICATION_SETTINGS.md#how-to-approve-a-pending-telegram-user)
- [Removal](05_NOTIFICATION_SETTINGS.md#how-to-remove-a-telegram-recipient)
- Roles **(Documentation needs dedicated coverage/verification)**
- [Slash commands](06_TELEGRAM_HOWTOS.md)
- [Schedule](06_TELEGRAM_HOWTOS.md#how-to-use-schedule)
- [Security](06_TELEGRAM_HOWTOS.md#security-rules)
- [Troubleshooting](06_TELEGRAM_HOWTOS.md#how-to-troubleshoot-telegram-notifications-not-arriving)

### 07 - Email
- [Daily Health](21_NOTIFICATION_EVENT_REFERENCE.md#daily-health-email)
- [Power-event email types](21_NOTIFICATION_EVENT_REFERENCE.md)
- [Recipient management](07_EMAIL_HOWTOS.md#how-to-add-or-remove-email-recipients)
- SMTP rebuild / stale generated SMTP configuration recovery **(Documentation needed)**
- [Testing](07_EMAIL_HOWTOS.md#how-to-validate-email-delivery-without-causing-a-ups-event)
- [EMAIL_NOTIFY_FAILED troubleshooting](07_EMAIL_HOWTOS.md#how-to-troubleshoot-email-notify-failed)

### 08 - Maintenance and Weather
- [CLEAR](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-interpret-clear) / [CAUTION](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-interpret-caution) / [BLOCK](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-interpret-block)
- [Weather rules](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-weather-affects-maintenance-recommendations)
- [Grid-risk rules](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#weather-risk-thresholds)
- [UPS Maintenance status](08_MAINTENANCE_AND_WEATHER_HOWTOS.md#how-to-verify-maintenance-status)
- [UPS identity / inventory](20_UPS_INVENTORY_AND_ACTIONS.md#current-ups-locations)
- Maintenance Mode suppression behavior **(Documentation expansion needed)**

### 09 - Configuration
- Config Loader **(Documentation needed)**
- [Editable configs](09_CONFIGURATION_HOWTOS.md#editable-live-config-file-guide)
- [Read-only configuration review](09_CONFIGURATION_HOWTOS.md#how-to-safely-review-a-configuration)
- [Reload](09_CONFIGURATION_HOWTOS.md#how-to-reload-a-configuration)
- [Validate](09_CONFIGURATION_HOWTOS.md#how-to-validate-a-configuration)
- [Save](09_CONFIGURATION_HOWTOS.md#how-to-save-a-configuration-change)
- [Revert](09_CONFIGURATION_HOWTOS.md#how-to-revert-a-configuration-change)
- [Safe editing](REF_07_SAFE_EDITING_RULES.md)
- [Security rules](09_CONFIGURATION_HOWTOS.md#security-rules) / secret masking **(masking behavior needs dedicated coverage)**

### 10 - Tests and Logs
- [Simulated Test](10_TESTS_AND_LOGS_HOWTOS.md#how-to-run-a-safe-simulated-test)
- [Export Logs](10_TESTS_AND_LOGS_HOWTOS.md#how-to-export-logs)
- [Action Output](10_TESTS_AND_LOGS_HOWTOS.md#how-to-understand-simulated-test-output)
- [Copy Full Output](10_TESTS_AND_LOGS_HOWTOS.md#how-to-copy-full-output)
- [Real Test](10_TESTS_AND_LOGS_HOWTOS.md#how-to-run-an-approved-real-test)
- [Safety Notes](10_TESTS_AND_LOGS_HOWTOS.md#how-to-show-safety-notes)

### 11 - Backup
- [Backup button](11_BACKUP_HOWTOS.md#how-to-run-backup-all-from-the-control-center)
- [GitHub / sanitized backup workflow](11_BACKUP_HOWTOS.md#what-the-sanitized-backup-is-for)
- [Sanitization](11_BACKUP_HOWTOS.md#what-must-not-be-put-in-github)
- [Verification](11_BACKUP_HOWTOS.md#how-to-verify-a-backup-completed-successfully)
- [Troubleshooting](11_BACKUP_HOWTOS.md#troubleshooting-backup)

### 12 - Restore and Disaster Recovery
- [Repository sync](12_RESTORE_AND_DR_HOWTOS.md#how-to-sync-the-backup-repository-from-github)
- [Dry run](12_RESTORE_AND_DR_HOWTOS.md#how-to-run-a-restore-dry-run)
- [Selected restore](12_RESTORE_AND_DR_HOWTOS.md#how-to-restore-one-approved-selected-file)
- Lab restore workflow **(Documentation needs dedicated coverage/clarification)**
- [Rollback](12_RESTORE_AND_DR_HOWTOS.md#how-to-roll-back-a-bad-change)
- [Disaster recovery](12_RESTORE_AND_DR_HOWTOS.md#how-to-rebuild-nut-after-a-server-failure)

### 13 - Shutdown Orchestration
- [UPS event flow](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#current-event-chain)
- [Timers](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#current-documented-shutdown-timer-baseline)
- [Cancellation](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#how-shutdown-cancellation-works)
- [Verification](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#how-to-verify-shutdown-logic-without-shutting-anything-down)
- [Final shutdown](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#ups9-shutdown-sequence)

### 14 - Protected Systems
- [VMware](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-vmware-vcenter-shutdown)
- [ESXi](14_PROTECTED_SYSTEMS_HOWTOS.md#vmware-vcenter-esxi-shutdown-architecture)
- [Synology](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-synology-shutdown)
- [NetApp](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-netapp-shutdown)
- [<DATABASE_SERVER_1>](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-db01-shutdown-integration)
- [<DATABASE_SERVER_2>](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-db02-shutdown-integration)
- [V240](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-the-sun-fire-v240-integration)
- [Blue Iris](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-blue-iris-shutdown)
- [Lansweeper](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-lansweeper-shutdown)
- [VOIP](14_PROTECTED_SYSTEMS_HOWTOS.md#how-to-update-or-troubleshoot-voip-shutdown)
- [Local NUT server final shutdown](REF_40_nut_local_final_shutdown.md)

### 15 - Services and Timers
- [NUT services](15_SERVICES_AND_TIMERS_HOWTOS.md#how-to-check-the-health-of-core-nut-services)
- [NUT timers](15_SERVICES_AND_TIMERS_HOWTOS.md#how-to-check-nut-systemd-timers)
- Systemd path units **(Documentation needed)**
- [Service restart/troubleshooting rules](15_SERVICES_AND_TIMERS_HOWTOS.md#when-not-to-restart-services)

### 16 - Logs
- [Event / NUT problem logs](16_LOGS_HOWTOS.md#how-to-find-the-correct-log-for-a-nut-problem)
- [Shutdown logs](16_LOGS_HOWTOS.md#protected-system-shutdown-problem)
- [Notification logs](16_LOGS_HOWTOS.md#how-to-find-the-correct-log-for-a-nut-problem)
- Maintenance-specific logs **(Documentation needs dedicated coverage)**
- [Test logs](10_TESTS_AND_LOGS_HOWTOS.md#how-to-find-the-correct-log-for-a-problem)
- DR-specific logs **(Documentation needs dedicated coverage)**

### 17 - Troubleshooting
- [Control Center](17_TROUBLESHOOTING_HOWTOS.md#how-to-troubleshoot-a-stale-control-center-display)
- [UPS](17_TROUBLESHOOTING_HOWTOS.md#how-to-troubleshoot-a-ups-that-shows-offline-or-missing)
- [Events](04_EVENTS_HOWTOS.md#troubleshooting)
- [Configuration](09_CONFIGURATION_HOWTOS.md#troubleshooting)
- [Email](17_TROUBLESHOOTING_HOWTOS.md#how-to-troubleshoot-email-notifications-not-arriving)
- [Telegram](17_TROUBLESHOOTING_HOWTOS.md#how-to-troubleshoot-telegram-notifications-not-arriving)
- [Backup](11_BACKUP_HOWTOS.md#troubleshooting-backup)
- [Restore](12_RESTORE_AND_DR_HOWTOS.md)
- [Shutdown wrappers](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#how-to-troubleshoot-a-shutdown-workflow-failure)
- [Services](15_SERVICES_AND_TIMERS_HOWTOS.md#how-to-check-the-health-of-core-nut-services)

### 18 - Security
- [Credential handling](18_SECURITY_HOWTOS.md#credential-handling-rules)
- [Secrets](18_SECURITY_HOWTOS.md#what-to-do-if-a-secret-is-exposed)
- General file/credential permissions model **(Documentation needs expansion)**
- [Git exclusions / sanitized GitHub secret checks](18_SECURITY_HOWTOS.md#how-to-verify-secrets-are-excluded-from-the-sanitized-github-backup)
- Access control model **(Documentation needed)**
- [Credential / secret rotation procedures](18_CREDENTIAL_AND_PASSWORD_CHANGES.md#general-credential-change-procedure)

### 19 - Technical Reference
- [Architecture / feature-to-component map](19_TECHNICAL_REFERENCE_HOWTOS.md#how-to-identify-which-component-controls-a-feature)
- Flask routes **(Documentation needed)**
- APIs / Help API endpoints **(Documentation needed)**
- [Scripts / component map](19_TECHNICAL_REFERENCE_HOWTOS.md#how-to-identify-which-component-controls-a-feature)
- [Config files](09_CONFIGURATION_HOWTOS.md#editable-live-config-file-guide)
- [Services](15_SERVICES_AND_TIMERS_HOWTOS.md)
- [Logs](16_LOGS_HOWTOS.md)
- [File / function map](19_TECHNICAL_REFERENCE_HOWTOS.md)

### 20 - UPS Inventory and Automatic Actions
- [where each UPS is located](20_UPS_INVENTORY_AND_ACTIONS.md#current-ups-locations)
- [what equipment is associated with each UPS](20_UPS_INVENTORY_AND_ACTIONS.md#physical-connection-versus-automatic-shutdown)
- [which systems NUT shuts down automatically](20_UPS_INVENTORY_AND_ACTIONS.md#what-will-nut-automatically-shut-down)
- [which systems are alert-only](14_PROTECTED_SYSTEMS_HOWTOS.md#automatic-shutdown-versus-alert-only-equipment)
- [configured shutdown timers](20_UPS_INVENTORY_AND_ACTIONS.md#current-timer-summary)
- [shutdown wrapper relationships](20_UPS_INVENTORY_AND_ACTIONS.md)
- [historical mappings that still require physical verification](20_UPS_INVENTORY_AND_ACTIONS.md#historical-mapping-warning)

Important:

Physical power connection and automatic NUT shutdown action are documented separately.
