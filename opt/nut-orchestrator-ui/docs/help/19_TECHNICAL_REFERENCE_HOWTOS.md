# Technical Reference - Feature to Component Map

## Purpose

Use this section when you need to determine which configuration file, script, service, or API controls a NUT feature.

---

## How to Identify Which Component Controls a Feature

1. Identify the user-facing feature.
2. Find it in the map below.
3. Review the current Help article first.
4. Use the technical reference only when deeper troubleshooting or maintenance is required.
5. Never edit a file merely because it appears in this map.

Search phrases:

- which script controls this
- which config controls this
- what service runs this
- technical reference
- where is this setting stored

---

## Control Center UI

Primary components:

- /opt/nut-orchestrator-ui/app.py
- /opt/nut-orchestrator-ui/templates/control-center.html
- nut-orchestrator-ui.service

---

## Help System

Primary components:

- /opt/nut-orchestrator-ui/docs/help/
- /opt/nut-orchestrator-ui/docs/help-sources/
- GET /api/help/articles
- GET /api/help/article/<filename>
- Help JavaScript in control-center.html

---

## UPS Definitions and Monitoring

Primary references:

- /etc/nut/ups.conf
- /etc/nut/upsmon.conf
- nut-server.service
- nut-monitor.service

---

## UPS Event Scheduling

Primary references:

- /etc/nut/upssched.conf
- /usr/sbin/upssched
- /usr/local/bin/nut-orchestrator.sh

---

## Notification Settings

Primary references:

- /etc/nut/config.d/notification-controls.json
- /usr/local/sbin/nut-notification-controls
- /usr/local/sbin/nut-notification-recipients
- /etc/nut/nut-email-alerts.conf

---

## Telegram

Primary references:

- /usr/local/sbin/nut-telegram-command-bot
- /etc/nut/secrets/telegram-alerts.env
- /var/lib/nut-telegram-alerts/access.json

---

## Email

Primary references:

- /usr/local/sbin/nut-email-alert-test-send
- /etc/nut/nut-email-alerts.conf

---

## <DATABASE_SERVER_1> / <DATABASE_SERVER_2> Shutdown

Primary reference:

- /usr/local/sbin/nut-db-shutdown.sh

Production addresses currently documented:

- <DATABASE_SERVER_1>: <INTERNAL_IP>
- <DATABASE_SERVER_2>: <INTERNAL_IP>

---

## Sun Fire V240 Shutdown

Primary reference:

- /usr/local/sbin/nut-v24013-shutdown.sh

Current planned production address:

- <INTERNAL_IP>

---

## VMware / vCenter

Primary reference:

- /usr/local/sbin/nut-vmware-shutdown.sh

---

## Synology

Primary reference:

- /usr/local/sbin/nut-synology-shutdown.sh

---

## NetApp

Primary reference:

- /usr/local/sbin/nut-netapp-halt.sh

---

## Blue Iris

Primary reference:

- /usr/local/sbin/nut-blueiris-shutdown.sh

---

## Lansweeper

Primary reference:

- /usr/local/sbin/nut-lansweeper-shutdown.sh

---

## VoIP

Primary reference:

- /usr/local/sbin/nut-voip-shutdown.sh

---

## Approved Targets

Primary reference:

- approved-targets.yml

---

## Backup / Restore

Use the current Backup and Restore/DR Help articles before working directly with implementation scripts.

---

## Security Rule

This technical map identifies locations only.

It must never display the contents of password, token, or secret files.


## Flask Route Inventory

This inventory was generated from the current live `/opt/nut-orchestrator-ui/app.py` during the Help documentation update.

It documents the Flask route, accepted HTTP method, and implementing Python function. It does **not** expose credentials, request secrets, or protected configuration contents.

| Method | Route | Flask function |
|---|---|---|
| `GET` | `/` | `index` |
| `GET` | `/control-center` | `control_center` |
| `GET` | `/control-center-restore-lab` | `control_center_restore_lab` |
| `GET` | `/healthz` | `healthz` |
| `GET` | `/api/maintenance-status` | `maintenance_status_api` |
| `GET` | `/api/config/<reference_id>/content-ref` | `get_reference_content` |
| `GET` | `/api/config/<config_id>/content` | `get_config_content` |
| `POST` | `/api/config/<config_id>` | `update_config` |
| `GET` | `/api/notification-recipients` | `notification_recipients` |
| `POST` | `/api/notification-recipients/email` | `notification_email_recipient_change` |
| `POST` | `/api/notification-recipients/telegram` | `notification_telegram_recipient_change` |
| `GET, POST` | `/api/notification-controls` | `notification_controls_api` |
| `POST` | `/api/test/<mode>` | `run_test` |
| `POST` | `/api/backup` | `backup_now` |
| `GET` | `/api/restore/branches` | `restore_branches` |
| `POST` | `/api/restore` | `restore_now` |
| `POST` | `/api/restore/live-dry-run` | `restore_live_dry_run` |
| `GET` | `/api/restore/targets` | `restore_targets` |
| `POST` | `/api/restore/selected-file-live` | `restore_selected_file_live` |
| `GET` | `/api/restore/full-status` | `restore_full_status` |
| `GET` | `/api/restore/full-job/<job_id>` | `restore_full_job` |
| `POST` | `/api/restore/full-preflight` | `restore_full_preflight` |
| `POST` | `/api/restore/full-live` | `restore_full_live` |
| `GET` | `/api/help/articles` | `help_articles` |
| `GET` | `/api/help/search` | `api_help_search` |
| `GET` | `/api/help/article/<filename>` | `help_article` |
| `GET` | `/api/power-events` | `power_events` |
| `GET` | `/api/power-events-table` | `power_events_table` |
| `GET` | `/api/export-logs` | `export_logs` |
| `POST` | `/api/rollback/<config_id>` | `rollback` |
| `POST` | `/api/production-mode` | `api_production_mode` |
| `POST` | `/api/ups-locator-identify` | `api_ups_locator_identify` |
| `POST` | `/api/ups-locator-beep` | `api_ups_locator_identify` |

When troubleshooting a Control Center function, use this inventory together with the [feature-to-component map](19_TECHNICAL_REFERENCE_HOWTOS.md#how-to-identify-which-component-controls-a-feature) and [Logs](16_LOGS_HOWTOS.md).

Because this is documentation rather than executable routing configuration, verify `app.py` again if the Control Center code has changed since this article was updated.

---

## Control Center and Help API Endpoints

The current Control Center Flask application exposes the following `/api/` routes:

| Method | Route | Flask function |
|---|---|---|
| `GET` | `/api/maintenance-status` | `maintenance_status_api` |
| `GET` | `/api/config/<reference_id>/content-ref` | `get_reference_content` |
| `GET` | `/api/config/<config_id>/content` | `get_config_content` |
| `POST` | `/api/config/<config_id>` | `update_config` |
| `GET` | `/api/notification-recipients` | `notification_recipients` |
| `POST` | `/api/notification-recipients/email` | `notification_email_recipient_change` |
| `POST` | `/api/notification-recipients/telegram` | `notification_telegram_recipient_change` |
| `GET, POST` | `/api/notification-controls` | `notification_controls_api` |
| `POST` | `/api/test/<mode>` | `run_test` |
| `POST` | `/api/backup` | `backup_now` |
| `GET` | `/api/restore/branches` | `restore_branches` |
| `POST` | `/api/restore` | `restore_now` |
| `POST` | `/api/restore/live-dry-run` | `restore_live_dry_run` |
| `GET` | `/api/restore/targets` | `restore_targets` |
| `POST` | `/api/restore/selected-file-live` | `restore_selected_file_live` |
| `GET` | `/api/restore/full-status` | `restore_full_status` |
| `GET` | `/api/restore/full-job/<job_id>` | `restore_full_job` |
| `POST` | `/api/restore/full-preflight` | `restore_full_preflight` |
| `POST` | `/api/restore/full-live` | `restore_full_live` |
| `GET` | `/api/help/articles` | `help_articles` |
| `GET` | `/api/help/search` | `api_help_search` |
| `GET` | `/api/help/article/<filename>` | `help_article` |
| `GET` | `/api/power-events` | `power_events` |
| `GET` | `/api/power-events-table` | `power_events_table` |
| `GET` | `/api/export-logs` | `export_logs` |
| `POST` | `/api/rollback/<config_id>` | `rollback` |
| `POST` | `/api/production-mode` | `api_production_mode` |
| `POST` | `/api/ups-locator-identify` | `api_ups_locator_identify` |
| `POST` | `/api/ups-locator-beep` | `api_ups_locator_identify` |

### Help API

The Help interface currently uses three primary Help endpoints:

- `GET /api/help/articles` - enumerates Markdown Help articles available from the approved Help directory.
- `GET /api/help/search` - performs Help search and returns matching article/section information.
- `GET /api/help/article/<filename>` - returns one approved Help Markdown article for rendering in the Control Center.

The browser-facing Control Center accesses these through the deployed `/nut-ui/` application path, while direct backend verification can use the local Flask/Gunicorn listener when appropriate.

The Help API must not be used to bypass the Help-directory boundary or expose arbitrary filesystem paths.

See the [Help Index](00_HELP_INDEX.md) for operator documentation and the [Control Center access-control model](18_SECURITY_HOWTOS.md#control-center-access-control-model) for application-level safety controls.

---

## Related Help

- Configuration
- Protected Systems
- Services and Timers
- Logs
- Security
