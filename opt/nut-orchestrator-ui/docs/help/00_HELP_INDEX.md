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
- Control Center overview
- Daily operator checklist
- System status
- Protection modes

Related Help:
- [Getting Started](01_GETTING_STARTED.md)
- [Protection Modes](02_PROTECTION_MODES.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)

### 02 - System Overview
- Health
- Selected UPS
- Latest event
- Clock/date
- Weather
- Maintenance status
- Refresh countdown
- Backup / Refresh / Restore

Related Help:
- [Getting Started](01_GETTING_STARTED.md)
- [Protection Modes](02_PROTECTION_MODES.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Maintenance and Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md)

### 03 - Monitoring
- UPS selector
- UPS metrics
- UPS status
- Load graph
- UPS Rack Overview
- UPS Trivia / Legend
- Refresh UPS

Related Help:
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Events](04_EVENTS_HOWTOS.md)
- [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)

### 04 - Events
- Power / Boot Event Log
- Event types
- Refresh Event Log
- Event troubleshooting

Related Help:
- [Events](04_EVENTS_HOWTOS.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)
- [Logs](16_LOGS_HOWTOS.md)

### 05 - Notification Settings
- Daily Health Email
- Weather-Based Closing Thoughts
- Email Recipients
- Telegram master
- Daily Health Push
- Critical Power Alerts
- Heartbeat
- Telegram Recipients
- Pending Telegram Access

Related Help:
- [Notification Settings](05_NOTIFICATION_SETTINGS.md)
- [Telegram](06_TELEGRAM_HOWTOS.md)
- [Email](07_EMAIL_HOWTOS.md)
- [Maintenance and Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md)

### 06 - Telegram
- Access request
- Approval
- Removal
- Roles
- Slash commands
- Schedule
- Security
- Troubleshooting

Related Help:
- [Telegram](06_TELEGRAM_HOWTOS.md)
- [Notification Settings](05_NOTIFICATION_SETTINGS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)
- [Security](18_SECURITY_HOWTOS.md)

### 07 - Email
- Daily Health
- Power-event email types
- Recipient management
- SMTP rebuild
- Testing
- EMAIL_NOTIFY_FAILED troubleshooting

Related Help:
- [Email](07_EMAIL_HOWTOS.md)
- [Notification Settings](05_NOTIFICATION_SETTINGS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)
- [Security](18_SECURITY_HOWTOS.md)

### 08 - Maintenance and Weather
- CLEAR / CAUTION / BLOCK
- Weather rules
- Grid-risk rules
- UPS Maintenance
- UPS identity
- Maintenance suppression

Related Help:
- [Maintenance and Weather](08_MAINTENANCE_AND_WEATHER_HOWTOS.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Notification Settings](05_NOTIFICATION_SETTINGS.md)
- [Email](07_EMAIL_HOWTOS.md)

### 09 - Configuration
- Config Loader
- Editable configs
- Read-only references
- Reload
- Validate
- Save
- Revert
- Safe editing
- Secret masking

Related Help:
- [Configuration](09_CONFIGURATION_HOWTOS.md)
- [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)
- [Security](18_SECURITY_HOWTOS.md)

### 10 - Tests and Logs
- Simulated Test
- Export Logs
- Action Output
- Copy Full Output
- Real Test
- Safety Notes

Related Help:
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)
- [Logs](16_LOGS_HOWTOS.md)
- [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md)
- [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md)

### 11 - Backup
- Backup button
- GitHub workflow
- Sanitization
- Verification
- Troubleshooting

Related Help:
- [Backup](11_BACKUP_HOWTOS.md)
- [Restore and Disaster Recovery](12_RESTORE_AND_DR_HOWTOS.md)
- [Security](18_SECURITY_HOWTOS.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)

### 12 - Restore and Disaster Recovery
- Repository sync
- Dry run
- Selected restore
- Lab restore
- Rollback
- Disaster recovery

Related Help:
- [Restore and Disaster Recovery](12_RESTORE_AND_DR_HOWTOS.md)
- [Backup](11_BACKUP_HOWTOS.md)
- [Configuration](09_CONFIGURATION_HOWTOS.md)
- [Security](18_SECURITY_HOWTOS.md)

### 13 - Shutdown Orchestration
- UPS event flow
- Timers
- Cancellation
- Verification
- Final shutdown

Related Help:
- [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md)
- [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md)
- [Protection Modes](02_PROTECTION_MODES.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)

### 14 - Protected Systems
- VMware
- ESXi
- Synology
- NetApp
- <DATABASE_SERVER_1>
- <DATABASE_SERVER_2>
- V240
- Blue Iris
- Lansweeper
- VOIP
- NUT server

Related Help:
- [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md)
- [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md)
- [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md)
- [Configuration](09_CONFIGURATION_HOWTOS.md)

### 15 - Services and Timers
- NUT services
- NUT timers
- Path units
- Service troubleshooting

Related Help:
- [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
- [Logs](16_LOGS_HOWTOS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)

### 16 - Logs
- Event logs
- Shutdown logs
- Notification logs
- Maintenance logs
- Test logs
- DR logs

Related Help:
- [Logs](16_LOGS_HOWTOS.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)
- [Events](04_EVENTS_HOWTOS.md)
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)

### 17 - Troubleshooting
- Control Center
- UPS
- Events
- Configuration
- Email
- Telegram
- Backup
- Restore
- Shutdown wrappers
- Services

Related Help:
- [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md)
- [Logs](16_LOGS_HOWTOS.md)
- [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md)
- [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md)

### 18 - Security
- Credential handling
- Secrets
- Permissions
- Git exclusions
- Access control
- Secret rotation

Related Help:
- [Security](18_SECURITY_HOWTOS.md)
- [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md)
- [Backup](11_BACKUP_HOWTOS.md)
- [Configuration](09_CONFIGURATION_HOWTOS.md)

### 19 - Technical Reference
- Architecture
- Flask routes
- APIs
- Scripts
- Config files
- Services
- Logs
- File/function map

Related Help:
- [Technical Reference](19_TECHNICAL_REFERENCE_HOWTOS.md)
- [Configuration](09_CONFIGURATION_HOWTOS.md)
- [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md)
- [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md)

---

### 20 - UPS Inventory and Automatic Actions

Use this article to determine:

- where each UPS is located
- what equipment is associated with each UPS
- which systems NUT shuts down automatically
- which systems are alert-only
- configured shutdown timers
- shutdown wrapper relationships
- historical mappings that still require physical verification

Important:

Physical power connection and automatic NUT shutdown action are documented separately.

Related Help:
- [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md)
- [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md)
- [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md)
- [Monitoring](03_MONITORING_HOWTOS.md)
