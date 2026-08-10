# NUT Server Architecture and Complete Feature Map

This document is the source-of-truth architecture, feature map, file map, function map, and AI handoff reference for the ABCo NUT server project.

This file is intended for:

1. Future AI chats, so fixes continue with the same assumptions.
2. Human runbook users, so they can quickly find where each feature, file, function, route, script, and log reference lives.

This file is intentionally large and searchable.

Do not store passwords, tokens, private keys, API keys, SMTP passwords, vCenter passwords, UPS passwords, or other secrets in this file.

---

## 1. Critical Safety Rules

1. OFF mode means everything is off, including monitoring, logging, email reports, and live actions.
2. OFF is not monitoring-only.
3. Standby is the preferred mode while making changes.
4. Protecting allows live actions only for valid UPS events that reach configured thresholds.
5. Do not run real shutdown actions unless explicitly approved.
6. Do not expose passwords, tokens, keys, or credential values.
7. If a secret is exposed, treat it as compromised and rotate it.
8. Use one or two steps at a time.
9. Use explicit PASS/FAIL gates.
10. Do not move to the next task until the current task is verified complete.
11. Do not commit until behavior is verified.
12. Do not enable ESXi SSH fallback unless explicitly reviewed and approved.

---

## 2. Environment Summary

| Item | Value |
|---|---|
| Hostname | `nutserver` |
| OS | Ubuntu 24.04 LTS |
| Main repo | `/opt/nut-admin/repo-template` |
| Live Control Center app | `/opt/nut-orchestrator-ui` |
| Control Center URL | `http://192.168.3.251/nut-ui` |
| Dashboard URL | `http://192.168.3.251/nutserver-dashboard.priority1.html` |
| Flask/Gunicorn bind | `127.0.0.1:5080` |
| Apache role | Reverse proxy for `/nut-ui/` and static dashboard hosting |
| GitHub backup branch | `origin/backup-sanitized-initial` |

---

## 3. Protection Mode Model

| User-facing mode | Internal state | Monitoring | Logging | Email reports | Live actions |
|---|---|---:|---:|---:|---:|
| Protecting | `armed` | On | On | On | Allowed |
| Standby | `disarmed` | On | On | On | Blocked |
| Off | `off` | Off | Off | Off | Blocked |

---

## 4. Event Pipeline

```text
UPS event
  -> NUT drivers
  -> upsmon
  -> upssched
  -> /usr/local/bin/nut-orchestrator.sh
  -> mode/safety checks
  -> target wrapper scripts
  -> logs, dashboard events, Control Center output, email notifications
```


---

## 5. Human Feature Index

Use this section first when trying to find a feature, workflow, button, script, route, or troubleshooting area.

| Feature | Entry point | Primary files / functions | Notes |
|---|---|---|---|
| NUT Protection Mode | Control Center mode buttons / production mode helpers | `usr/local/sbin/nut-production-mode`, `usr/local/sbin/nut-production-status`, `var/www/html/nut-state/production-mode.json` | Protecting allows live actions; Standby blocks live actions; Off stops monitoring/logging/email/live actions |
| Protecting guard | Backend mutating routes | `opt/nut-orchestrator-ui/app.py`, `block_if_protecting()` | Blocks dangerous changes while Protecting |
| Control Center UI | Main web UI | `opt/nut-orchestrator-ui/templates/control-center.html` | Restart `nut-orchestrator-ui.service` after template changes and press Ctrl+F5 in browser |
| Flask backend | API routes | `opt/nut-orchestrator-ui/app.py` | Restart `nut-orchestrator-ui.service` after backend changes |
| Config editor | Config dropdown/editor | `app.py` config routes, `opt/nut-orchestrator-ui/lib/config_registry.json` | Secrets must stay redacted and preserved |
| Safe simulated test | Run Simulated Test button | `app.py`, `/api/test/<mode>` | Must remain safe and must not send live shutdown commands |
| Export logs | Export Logs button | `app.py`, `/api/export-logs` | Should include key troubleshooting logs |
| Backup all to GitHub | Backup button | `app.py`, `/api/backup`, `usr/local/sbin/nut-ui-backup-now`, `usr/local/sbin/nut-run-backup-and-push.sh`, `usr/local/sbin/nut-sync-live-to-repo-for-backup` | Must capture intended live/project changes |
| Restore from GitHub | Restore UI / restore lab | `usr/local/sbin/nut-ui-restore-github`, selected restore helpers | Use preview/dry-run when possible |
| Power / Boot Event Log | Dashboard and Control Center event panels | `app.py`, `/api/power-events`, `/api/power-events-table`, `var/www/html/nut-state/events.log`, `/var/log/nut-orchestrator-ui/power-events.log` | 5-day newest-first shared feed |
| Copy Full Output | Action Output area | `control-center.html`, `ccCopyFullActionOutput()`, `ccWeatherFlashColor()`, `ccCopyTextFallback()`, `ccSelectActionOutput()` | Selects text, copies output, weather/temp flash |
| Email alerts | Outage/restore/shutdown/final/weekly emails | `usr/local/sbin/nut-email-alert-test-send`, `usr/local/bin/nut-orchestrator.sh`, `etc/nut/nut-email-alerts.conf` | Never expose SMTP secrets |
| UPS locator | Deferred hidden feature | `usr/local/sbin/nut-ups-locator-beep.sh` | Code remains; user-facing buttons hidden |
| APC IDF monitoring | APC IDF event scripts/config | `usr/local/sbin/nut-apc-idf-event-monitor.sh`, `etc/nut/apc-idf-web.conf` | IDF3 verification previously completed |
| Wrapper shutdowns | NUT event orchestrator target actions | `usr/local/sbin/nut-*-shutdown.sh` | Verify permissions, configs, and logs before live reliance |
| VMware workflow | VMware wrapper | `usr/local/sbin/nut-vmware-shutdown.sh`, `etc/nut/config.d/vmware-vm-map.conf`, `etc/nut/hypervisors/*` | ESXi SSH fallback remains disabled unless approved |
| Synology workflow | Synology wrapper | `usr/local/sbin/nut-synology-shutdown.sh` | Verify config readability and log writing |
| NetApp workflow | Storage target workflow | Orchestrator/config mappings | Verify exact wrapper/config path before testing |
| Lansweeper workflow | Lansweeper wrapper | `usr/local/sbin/nut-lansweeper-shutdown.sh` | Known prior issue involved credentials/log permissions |
| DB workflow | DB wrapper | `usr/local/sbin/nut-db-shutdown.sh`, `etc/nut/db-shutdown.conf` | Verify config readability and log writing |
| VOIP workflow | VOIP wrapper | `usr/local/sbin/nut-voip-shutdown.sh` | Verify before live reliance |
| Blue Iris workflow | Blue Iris wrapper | `usr/local/sbin/nut-blueiris-shutdown.sh` | Pending/skipped static readiness |
| Final local NUT shutdown | Final local shutdown wrapper | `usr/local/sbin/nut-local-final-shutdown.sh` | Only run during approved live/final shutdown |


---

## 6. Every File in the Repo

This section is generated from `/tmp/nut-architecture-inventory/01_all_files.txt`.

| File |
|---|
| `docs/nut_backup_inventory.md` |
| `docs/ROLLBACK.md` |
| `etc/nut/apache-notes.txt` |
| `etc/nut/apc-idf-web.conf` |
| `etc/nut/apc-idf-web.conf.template` |
| `etc/nut/config.d/approved-targets.yml` |
| `etc/nut/config.d/dashboard-ui.json` |
| `etc/nut/config.d/nut-orchestrator.conf` |
| `etc/nut/config.d/nut-orchestrator.conf.template` |
| `etc/nut/config.d/shutdown-verification-targets.conf` |
| `etc/nut/config.d/vmware-vm-map.conf` |
| `etc/nut/db-shutdown.conf` |
| `etc/nut/db-shutdown.conf.template` |
| `etc/nut/db-telnet.conf` |
| `etc/nut/db-telnet.pass.template` |
| `etc/nut/db-telnet.user.template` |
| `etc/nut/hosts.conf` |
| `etc/nut/hypervisors/hypervisor-ssh-fallback.conf` |
| `etc/nut/hypervisors/hypervisor-ssh-fallback.conf.template` |
| `etc/nut/lansweeper.creds.template` |
| `etc/nut/netapp.creds.template` |
| `etc/nut/nut.conf` |
| `etc/nut/nut-email-alerts.conf` |
| `etc/nut/nut-email-alerts.conf.template` |
| `etc/nut/nut-email-alerts.secret.template` |
| `etc/nut/nut-orchestrator.conf` |
| `etc/nut/nut-orchestrator.conf.template` |
| `etc/nut/production-mode.conf` |
| `etc/nut/proxmox.creds.template` |
| `etc/nut/real-test-passphrase.sha256.template` |
| `etc/nut/restore-live-test-probe.txt` |
| `etc/nut/restore/restore-targets.json.template` |
| `etc/nut/synology-api.conf` |
| `etc/nut/synology-api.conf.template` |
| `etc/nut/ups.conf` |
| `etc/nut/ups.conf.template` |
| `etc/nut/upsd.conf` |
| `etc/nut/upsd.users.template` |
| `etc/nut/upsmon.conf` |
| `etc/nut/upssched.conf` |
| `etc/nut/upsset.conf` |
| `etc/nut/upsstats.html` |
| `etc/nut/upsstats-single.html` |
| `etc/nut/vcenter.pass.template` |
| `etc/nut/vmware.creds.template` |
| `etc/nut/win2003-192.168.1.24.creds.template` |
| `etc/sudoers.d/nut-orchestrator-ui` |
| `etc/sudoers.d/nut-orchestrator-ui-production-mode` |
| `etc/sudoers.d/nut-orchestrator-ui-ups-locator` |
| `etc/sudoers.d/nut-ui-log-export` |
| `etc/systemd/system/nut-apc-idf-event-monitor.service` |
| `etc/systemd/system/nut-apc-idf-event-monitor.timer` |
| `etc/systemd/system/nut-boot-event-log.service` |
| `etc/systemd/system/nut-daily-health-email.service` |
| `etc/systemd/system/nut-daily-health-email.timer` |
| `etc/systemd/system/nut-driver@.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated-checksum.conf` |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf` |
| `etc/systemd/system/nut-fix-sockets.service` |
| `etc/systemd/system/nut-monitor.service.d/override.conf` |
| `etc/systemd/system/nut-orchestrator-ui.service` |
| `etc/systemd/system/nut-power-events-refresh.service` |
| `etc/systemd/system/nut-power-events-refresh.timer` |
| `etc/systemd/system/tigervnc-backup.service` |
| `etc/systemd/system/x11vnc.service` |
| `.gitignore` |
| `opt/nut-orchestrator-ui/app.py` |
| `opt/nut-orchestrator-ui/Dashboard-README.md` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` |
| `opt/nut-orchestrator-ui/lib/validators.sh` |
| `opt/nut-orchestrator-ui/README.md` |
| `opt/nut-orchestrator-ui/requirements.txt` |
| `opt/nut-orchestrator-ui/static/app.js` |
| `opt/nut-orchestrator-ui/static/nut-ui-theme.css` |
| `opt/nut-orchestrator-ui/templates/control-center.html` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` |
| `opt/nut-orchestrator-ui/templates/index.html` |
| `README.md` |
| `usr/local/bin/nut-orchestrator.sh` |
| `usr/local/bin/nut-test-logic.sh` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` |
| `usr/local/sbin/nut-boot-event-log.sh` |
| `usr/local/sbin/nut-classify-shutdown-result` |
| `usr/local/sbin/nut-classify-target-shutdown` |
| `usr/local/sbin/nut-db-shutdown.sh` |
| `usr/local/sbin/nut-email-alert-test-send` |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` |
| `usr/local/sbin/nut-export-test-logs` |
| `usr/local/sbin/nut-fix-sockets.sh` |
| `usr/local/sbin/nut-get-power-events-json` |
| `usr/local/sbin/nut-get-verification-target` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` |
| `usr/local/sbin/nut-inventory-configs.sh` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` |
| `usr/local/sbin/nut-local-final-shutdown.sh` |
| `usr/local/sbin/nut-netapp-halt.sh` |
| `usr/local/sbin/nut-power-event-log` |
| `usr/local/sbin/nut-production-mode` |
| `usr/local/sbin/nut-production-status` |
| `usr/local/sbin/nut-publish-power-events-json` |
| `usr/local/sbin/nut-rebuild-msmtp-from-email-config` |
| `usr/local/sbin/nut-run-backup-and-push.sh` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` |
| `usr/local/sbin/nut-synology-shutdown.sh` |
| `usr/local/sbin/nut-ui-apply-config` |
| `usr/local/sbin/nut-ui-backup-now` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` |
| `usr/local/sbin/nut-ui-live-restore-selected` |
| `usr/local/sbin/nut-ui-live-restore-selected-dry-run` |
| `usr/local/sbin/nut-ui-read-config` |
| `usr/local/sbin/nut-ui-read-reference` |
| `usr/local/sbin/nut-ui-restore-github` |
| `usr/local/sbin/nut-ui-rollback` |
| `usr/local/sbin/nut-ui-run-real-test-approved` |
| `usr/local/sbin/nut-ui-run-test` |
| `usr/local/sbin/nut-ups-locator-beep.sh` |
| `usr/local/sbin/nut-verify-target-down.sh` |
| `usr/local/sbin/nut-vmware-export-inventory.sh` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` |
| `usr/local/sbin/nut-vmware-shutdown.sh` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` |
| `usr/local/sbin/nut-voip-shutdown.sh` |
| `usr/local/sbin/phase2-power-restore-abort` |
| `usr/local/sbin/rollback-remote-access.sh` |
| `usr/local/sbin/start-x11vnc.sh` |
| `var/www/html/index.html` |
| `var/www/html/nutserver-dashboard.html` |
| `var/www/html/nutserver-dashboard.priority1.html` |
| `var/www/html/ups-rack-map.txt` |

---

## 7. Every File with Assigned Role

This section is generated from `/tmp/nut-architecture-inventory/02_file_roles.tsv`.

| File | Role |
|---|---|
| `.gitignore` | Repository file |
| `README.md` | Repository file |
| `docs/ROLLBACK.md` | Documentation |
| `docs/nut_backup_inventory.md` | Documentation |
| `etc/nut/apache-notes.txt` | NUT configuration/template |
| `etc/nut/apc-idf-web.conf` | NUT configuration/template |
| `etc/nut/apc-idf-web.conf.template` | NUT configuration/template |
| `etc/nut/config.d/approved-targets.yml` | NUT configuration/template |
| `etc/nut/config.d/dashboard-ui.json` | NUT configuration/template |
| `etc/nut/config.d/nut-orchestrator.conf` | NUT configuration/template |
| `etc/nut/config.d/nut-orchestrator.conf.template` | NUT configuration/template |
| `etc/nut/config.d/shutdown-verification-targets.conf` | NUT configuration/template |
| `etc/nut/config.d/vmware-vm-map.conf` | NUT configuration/template |
| `etc/nut/db-shutdown.conf` | NUT configuration/template |
| `etc/nut/db-shutdown.conf.template` | NUT configuration/template |
| `etc/nut/db-telnet.conf` | NUT configuration/template |
| `etc/nut/db-telnet.pass.template` | NUT configuration/template |
| `etc/nut/db-telnet.user.template` | NUT configuration/template |
| `etc/nut/hosts.conf` | NUT configuration/template |
| `etc/nut/hypervisors/hypervisor-ssh-fallback.conf` | NUT configuration/template |
| `etc/nut/hypervisors/hypervisor-ssh-fallback.conf.template` | NUT configuration/template |
| `etc/nut/lansweeper.creds.template` | NUT configuration/template |
| `etc/nut/netapp.creds.template` | NUT configuration/template |
| `etc/nut/nut-email-alerts.conf` | NUT configuration/template |
| `etc/nut/nut-email-alerts.conf.template` | NUT configuration/template |
| `etc/nut/nut-email-alerts.secret.template` | NUT configuration/template |
| `etc/nut/nut-orchestrator.conf` | NUT configuration/template |
| `etc/nut/nut-orchestrator.conf.template` | NUT configuration/template |
| `etc/nut/nut.conf` | NUT configuration/template |
| `etc/nut/production-mode.conf` | NUT configuration/template |
| `etc/nut/proxmox.creds.template` | NUT configuration/template |
| `etc/nut/real-test-passphrase.sha256.template` | NUT configuration/template |
| `etc/nut/restore/restore-targets.json.template` | NUT configuration/template |
| `etc/nut/restore-live-test-probe.txt` | NUT configuration/template |
| `etc/nut/synology-api.conf` | NUT configuration/template |
| `etc/nut/synology-api.conf.template` | NUT configuration/template |
| `etc/nut/ups.conf` | NUT configuration/template |
| `etc/nut/ups.conf.template` | NUT configuration/template |
| `etc/nut/upsd.conf` | NUT configuration/template |
| `etc/nut/upsd.users.template` | NUT configuration/template |
| `etc/nut/upsmon.conf` | NUT configuration/template |
| `etc/nut/upssched.conf` | NUT configuration/template |
| `etc/nut/upsset.conf` | NUT configuration/template |
| `etc/nut/upsstats-single.html` | NUT configuration/template |
| `etc/nut/upsstats.html` | NUT configuration/template |
| `etc/nut/vcenter.pass.template` | NUT configuration/template |
| `etc/nut/vmware.creds.template` | NUT configuration/template |
| `etc/nut/win2003-192.168.1.24.creds.template` | NUT configuration/template |
| `etc/sudoers.d/nut-orchestrator-ui` | sudoers rule |
| `etc/sudoers.d/nut-orchestrator-ui-production-mode` | sudoers rule |
| `etc/sudoers.d/nut-orchestrator-ui-ups-locator` | sudoers rule |
| `etc/sudoers.d/nut-ui-log-export` | sudoers rule |
| `etc/systemd/system/nut-apc-idf-event-monitor.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-apc-idf-event-monitor.timer` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-boot-event-log.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-daily-health-email.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-daily-health-email.timer` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated-checksum.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-fix-sockets.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-monitor.service.d/override.conf` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-orchestrator-ui.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-power-events-refresh.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/nut-power-events-refresh.timer` | systemd unit/timer/drop-in |
| `etc/systemd/system/tigervnc-backup.service` | systemd unit/timer/drop-in |
| `etc/systemd/system/x11vnc.service` | systemd unit/timer/drop-in |
| `opt/nut-orchestrator-ui/Dashboard-README.md` | Control Center application file |
| `opt/nut-orchestrator-ui/README.md` | Control Center application file |
| `opt/nut-orchestrator-ui/app.py` | Flask backend |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | UI library/config registry |
| `opt/nut-orchestrator-ui/lib/validators.sh` | UI library/config registry |
| `opt/nut-orchestrator-ui/requirements.txt` | Control Center application file |
| `opt/nut-orchestrator-ui/static/app.js` | UI static asset |
| `opt/nut-orchestrator-ui/static/nut-ui-theme.css` | UI static asset |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | UI HTML template |
| `opt/nut-orchestrator-ui/templates/control-center.html` | UI HTML template |
| `opt/nut-orchestrator-ui/templates/index.html` | UI HTML template |
| `usr/local/bin/nut-orchestrator.sh` | Executable runtime script |
| `usr/local/bin/nut-test-logic.sh` | Executable runtime script |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | Administrative helper script |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-boot-event-log.sh` | Administrative helper script |
| `usr/local/sbin/nut-classify-shutdown-result` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-classify-target-shutdown` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-db-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-email-alert-test-send` | Email helper |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` | Administrative helper script |
| `usr/local/sbin/nut-export-test-logs` | Administrative helper script |
| `usr/local/sbin/nut-fix-sockets.sh` | Administrative helper script |
| `usr/local/sbin/nut-get-power-events-json` | Administrative helper script |
| `usr/local/sbin/nut-get-verification-target` | Administrative helper script |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | Administrative helper script |
| `usr/local/sbin/nut-inventory-configs.sh` | Administrative helper script |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-local-final-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-netapp-halt.sh` | Administrative helper script |
| `usr/local/sbin/nut-power-event-log` | Administrative helper script |
| `usr/local/sbin/nut-production-mode` | Protection mode helper |
| `usr/local/sbin/nut-production-status` | Protection mode helper |
| `usr/local/sbin/nut-publish-power-events-json` | Administrative helper script |
| `usr/local/sbin/nut-rebuild-msmtp-from-email-config` | Email helper |
| `usr/local/sbin/nut-run-backup-and-push.sh` | Backup helper |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | Backup helper |
| `usr/local/sbin/nut-synology-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-ui-apply-config` | Administrative helper script |
| `usr/local/sbin/nut-ui-backup-now` | Backup helper |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | Restore helper |
| `usr/local/sbin/nut-ui-live-restore-selected` | Restore helper |
| `usr/local/sbin/nut-ui-live-restore-selected-dry-run` | Restore helper |
| `usr/local/sbin/nut-ui-read-config` | Administrative helper script |
| `usr/local/sbin/nut-ui-read-reference` | Administrative helper script |
| `usr/local/sbin/nut-ui-restore-github` | Restore helper |
| `usr/local/sbin/nut-ui-rollback` | Administrative helper script |
| `usr/local/sbin/nut-ui-run-real-test-approved` | Administrative helper script |
| `usr/local/sbin/nut-ui-run-test` | Administrative helper script |
| `usr/local/sbin/nut-ups-locator-beep.sh` | Administrative helper script |
| `usr/local/sbin/nut-verify-target-down.sh` | Administrative helper script |
| `usr/local/sbin/nut-vmware-export-inventory.sh` | Administrative helper script |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | Administrative helper script |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | Administrative helper script |
| `usr/local/sbin/nut-vmware-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | Administrative helper script |
| `usr/local/sbin/nut-voip-shutdown.sh` | Shutdown wrapper/helper |
| `usr/local/sbin/phase2-power-restore-abort` | Restore helper |
| `usr/local/sbin/rollback-remote-access.sh` | Administrative helper script |
| `usr/local/sbin/start-x11vnc.sh` | Administrative helper script |
| `var/www/html/index.html` | Dashboard/static web file |
| `var/www/html/nutserver-dashboard.html` | Dashboard/static web file |
| `var/www/html/nutserver-dashboard.priority1.html` | Dashboard/static web file |
| `var/www/html/ups-rack-map.txt` | Dashboard/static web file |

---

## 8. Every Python Function and Flask Route

This section is generated from `/tmp/nut-architecture-inventory/03_python_functions_routes.tsv`.

Use this section to locate Flask routes, backend helper functions, config handling, protection-mode guards, backup routes, restore routes, event routes, and log-export routes.

| File | Line | Type | Function | Route |
|---|---:|---|---|---|
| `opt/nut-orchestrator-ui/app.py` | 16 | Python function | `load_registry` | `` |
| `opt/nut-orchestrator-ui/app.py` | 21 | Python function | `get_config_by_id` | `` |
| `opt/nut-orchestrator-ui/app.py` | 29 | Python function | `is_allowed_file` | `` |
| `opt/nut-orchestrator-ui/app.py` | 43 | Python function | `index` | `@app.route("/")` |
| `opt/nut-orchestrator-ui/app.py` | 56 | Python function | `control_center` | `@app.route("/control-center")` |
| `opt/nut-orchestrator-ui/app.py` | 69 | Python function | `control_center_restore_lab` | `@app.route("/control-center-restore-lab")` |
| `opt/nut-orchestrator-ui/app.py` | 73 | Python function | `healthz` | `@app.route("/healthz")` |
| `opt/nut-orchestrator-ui/app.py` | 81 | Python function | `get_reference_content` | `@app.route("/api/config/<reference_id>/content-ref", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 127 | Python function | `is_secret_config_line` | `` |
| `opt/nut-orchestrator-ui/app.py` | 135 | Python function | `redact_secret_config_lines` | `` |
| `opt/nut-orchestrator-ui/app.py` | 147 | Python function | `preserve_existing_secret_config_lines` | `` |
| `opt/nut-orchestrator-ui/app.py` | 177 | Python function | `get_current_protection_mode` | `` |
| `opt/nut-orchestrator-ui/app.py` | 201 | Python function | `block_if_protecting` | `` |
| `opt/nut-orchestrator-ui/app.py` | 240 | Python function | `is_secret_config_line` | `` |
| `opt/nut-orchestrator-ui/app.py` | 251 | Python function | `redact_secret_config_lines` | `` |
| `opt/nut-orchestrator-ui/app.py` | 265 | Python function | `preserve_existing_secret_config_lines` | `` |
| `opt/nut-orchestrator-ui/app.py` | 303 | Python function | `get_config_content` | `@app.route("/api/config/<config_id>/content", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 346 | Python function | `update_config` | `@app.route("/api/config/<config_id>", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 403 | Python function | `run_test` | `@app.route("/api/test/<mode>", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 471 | Python function | `backup_now` | `@app.route("/api/backup", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 491 | Python function | `restore_branches` | `@app.route("/api/restore/branches", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 512 | Python function | `restore_now` | `@app.route("/api/restore", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 534 | Python function | `restore_live_dry_run` | `@app.route("/api/restore/live-dry-run", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 581 | Python function | `load_restore_targets` | `` |
| `opt/nut-orchestrator-ui/app.py` | 610 | Python function | `restore_targets` | `@app.route("/api/restore/targets", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 634 | Python function | `restore_selected_file_live` | `@app.route("/api/restore/selected-file-live", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 719 | Python function | `power_events` | `@app.route("/api/power-events", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 739 | Python function | `power_events_table` | `@app.route("/api/power-events-table", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 743 | Python function | `parse_line` | `` |
| `opt/nut-orchestrator-ui/app.py` | 753 | Python function | `qval` | `` |
| `opt/nut-orchestrator-ui/app.py` | 851 | Python function | `export_logs` | `@app.route("/api/export-logs", methods=["GET"])` |
| `opt/nut-orchestrator-ui/app.py` | 899 | Python function | `rollback` | `@app.route("/api/rollback/<config_id>", methods=["POST"])` |
| `opt/nut-orchestrator-ui/app.py` | 924 | Python function | `api_production_mode` | `` |
| `opt/nut-orchestrator-ui/app.py` | 990 | Python function | `api_ups_locator_identify` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 33 | Python function | `load_json` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 37 | Python function | `latest_inventory_json` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 45 | Python function | `main` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 11 | Python function | `_compat_wrap_socket` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 41 | Python function | `load_config` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 52 | Python function | `connect` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 70 | Python function | `vm_record` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 84 | Python function | `main` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 17 | Python function | `_compat_wrap_socket` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 50 | Python function | `load_config` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 68 | Python function | `get_password` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 79 | Python function | `get_config_value` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 86 | Python function | `walk_vms` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 97 | Python function | `safe_get` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 104 | Python function | `main` | `` |

---

## 9. Every UI / JavaScript / HTML Entry

This section is generated from `/tmp/nut-architecture-inventory/04_ui_js_html_map.tsv`.

It includes:

- JavaScript functions
- HTML IDs
- Buttons
- Event listeners
- API/fetch references

Use this section when trying to find a Control Center button, dashboard function, browser-side behavior, API call, output panel, modal, or UI element.

| File | Line | Type | Name | Code / context |
|---|---:|---|---|---|
| `opt/nut-orchestrator-ui/static/app.js` | 36 | JavaScript function | `toast` | `function toast(message, type = "info") {` |
| `opt/nut-orchestrator-ui/static/app.js` | 41 | JavaScript function | `setTopStatus` | `function setTopStatus(text, loading = false) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 46 | JavaScript function | `setMeta` | `function setMeta(data, statusText = "Ready") {` |
| `opt/nut-orchestrator-ui/static/app.js` | 54 | JavaScript function | `normalizeActionOutputText` | `function normalizeActionOutputText(value) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 68 | JavaScript function | `classifyActionOutput` | `function classifyActionOutput(text, payload) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 80 | JavaScript function | `makeOutputSection` | `function makeOutputSection(label, value) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 92 | JavaScript function | `escapeHtml` | `function escapeHtml(value) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 99 | JavaScript function | `setOutput` | `function setOutput(title, payload) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 152 | JavaScript function | `apiJson` | `async function apiJson(url, options = {}) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 153 | API/fetch reference | `const res = await fetch(url, options);` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 160 | JavaScript function | `loadConfig` | `async function loadConfig(configId) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 165 | API/fetch reference | `const data = await apiJson(`${BASE}/api/config/${configId}/content`);` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 179 | JavaScript function | `loadReference` | `async function loadReference(refId) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 187 | API/fetch reference | `const data = await apiJson(`${BASE}/api/config/${refId}/content-ref`);` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 199 | JavaScript function | `validateCurrent` | `async function validateCurrent() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 203 | API/fetch reference | `const data = await apiJson(`${BASE}/api/config/${configId}`, {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 220 | JavaScript function | `saveCurrent` | `async function saveCurrent() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 226 | API/fetch reference | `const data = await apiJson(`${BASE}/api/config/${configId}`, {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 244 | JavaScript function | `revertCurrent` | `function revertCurrent() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 253 | JavaScript function | `runServerBackup` | `async function runServerBackup() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 262 | API/fetch reference | `const data = await apiJson(`${BASE}/api/backup`, { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 275 | JavaScript function | `runTest` | `async function runTest(mode) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 279 | API/fetch reference | `const data = await apiJson(`${BASE}/api/test/${mode}`, { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 291 | JavaScript function | `wireEvents` | `function wireEvents() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 292 | Event listener | `$("config-select").addEventListener("change", async (e) => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 296 | Event listener | `$("reference-select").addEventListener("change", async (e) => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 300 | Event listener | `$("btn-load").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 304 | Event listener | `$("btn-validate").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 308 | Event listener | `$("btn-save").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 312 | Event listener | `$("btn-revert").addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 316 | Event listener | `$("btn-sim-test").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 324 | API/fetch reference | `const data = await apiJson(`${BASE}/api/test/simulate`, { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 346 | JavaScript function | `promptRealTestPassphrase` | `function promptRealTestPassphrase(phase) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 416 | Event listener | `cancel.addEventListener("click", () => cleanup(""));` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 417 | Event listener | `submit.addEventListener("click", () => cleanup(input.value));` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 419 | Event listener | `input.addEventListener("keydown", (event) => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 428 | Event listener | `$("btn-real-test").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 466 | API/fetch reference | `const data = await apiJson(`${BASE}/api/test/real`, {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 492 | Event listener | `$("btn-backup-github").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 496 | Event listener | `$("btn-restore-github").addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 504 | API/fetch reference | `const branchData = await apiJson(`${BASE}/api/restore/branches`, { method: "GET" });` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 560 | API/fetch reference | `const data = await apiJson(`${BASE}/api/restore`, {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 586 | Event listener | `document.addEventListener("DOMContentLoaded", async () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 596 | JavaScript function | `loadPowerBootEvents` | `async function loadPowerBootEvents() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 644 | API/fetch reference | `"/api/power-events?v=" + cacheBust,` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 645 | API/fetch reference | `"/nut-orchestrator-ui/api/power-events?v=" + cacheBust,` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 646 | API/fetch reference | `"/orchestrator/api/power-events?v=" + cacheBust,` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 647 | API/fetch reference | `"/nut/api/power-events?v=" + cacheBust` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 655 | API/fetch reference | `const attempt = await fetch(url, { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 691 | JavaScript function | `formatPowerEventResult` | `function formatPowerEventResult(line) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 704 | JavaScript function | `parseLine` | `function parseLine(line) {` |
| `opt/nut-orchestrator-ui/static/app.js` | 790 | Event listener | `window.addEventListener("DOMContentLoaded", () => {` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 797 | JavaScript function | `addDownloadAllLogsButton` | `function addDownloadAllLogsButton() {` |
| `opt/nut-orchestrator-ui/static/app.js` | 805 | API/fetch reference | `window.location.href = `${BASE}/api/export-logs`;` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 816 | Event listener | `window.addEventListener("DOMContentLoaded", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2138 | HTML id | `cc-backup-github` | `<button class="cc-btn cc-btn-primary" id="cc-backup-github">Backup All to GitHub</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2138 | Button | `<button class="cc-btn cc-btn-primary" id="cc-backup-github">Backup All to GitHub</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2139 | HTML id | `cc-refresh-all` | `<button class="cc-btn" id="cc-refresh-all">Refresh</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2139 | Button | `<button class="cc-btn" id="cc-refresh-all">Refresh</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2140 | HTML id | `cc-restore-github` | `<button class="cc-btn" id="cc-restore-github">Restore from GitHub</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2140 | Button | `<button class="cc-btn" id="cc-restore-github">Restore from GitHub</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2150 | HTML id | `cc-clock-time` | `<div class="cc-clock-time" id="cc-clock-time">--:--:--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2151 | HTML id | `cc-clock-date` | `<div class="cc-clock-date" id="cc-clock-date">Loading date...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2152 | HTML id | `cc-pontiac-weather` | `<div class="cc-clock-weather" id="cc-pontiac-weather">Pontiac: loading temp...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2153 | HTML id | `cc-refresh-countdown` | `<div class="cc-clock-refresh" id="cc-refresh-countdown">Refresh countdown: 35s</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2169 | HTML id | `cc-health-text` | `<span class="cc-status-pill"><span class="cc-dot"></span><span id="cc-health-text">Loading</span></span>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2176 | HTML id | `cc-selected-ups` | `<div class="cc-metric-value" id="cc-selected-ups">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2181 | HTML id | `cc-latest-event-type` | `<div class="cc-metric-value" id="cc-latest-event-type">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2182 | HTML id | `cc-latest-event-time` | `<div class="cc-metric-note" id="cc-latest-event-time">Waiting for event feed.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2202 | HTML id | `cc-monitoring-section` | `<div class="cc-card cc-wide cc-tab-panel active" id="cc-monitoring-section">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2206 | HTML id | `cc-refresh-ups` | `<button class="cc-btn" id="cc-refresh-ups">Refresh UPS</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2206 | Button | `<button class="cc-btn" id="cc-refresh-ups">Refresh UPS</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2212 | HTML id | `cc-ups-status-bar` | `<div class="cc-ups-status-bar" id="cc-ups-status-bar">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2214 | HTML id | `cc-ups-status-main` | `<div class="cc-ups-status-main" id="cc-ups-status-main">Loading UPS status...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2215 | HTML id | `cc-ups-status-sub` | `<div class="cc-ups-status-sub" id="cc-ups-status-sub">Waiting for NUT data.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2217 | HTML id | `cc-ups-status-pill` | `<div class="cc-status-pill"><span class="cc-dot"></span><span id="cc-ups-status-pill">Checking</span></div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2220 | HTML id | `cc-ups-metrics` | `<div class="cc-metrics" id="cc-ups-metrics">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2221 | HTML id | `cc-selected-ups-card` | `<div class="cc-metric cc-ups-pick-card" id="cc-selected-ups-card" title="Click to choose UPS">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2223 | HTML id | `cc-ups-name` | `<div class="cc-metric-value" id="cc-ups-name">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2224 | HTML id | `cc-ups-model` | `<div class="cc-metric-note" id="cc-ups-model">Click to choose UPS.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2228 | HTML id | `cc-ups-charge` | `<div class="cc-metric-value" id="cc-ups-charge">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2231 | HTML id | `cc-ups-load-card` | `<div class="cc-metric cc-load-graph-click" id="cc-ups-load-card" title="Click to open load graph">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2233 | HTML id | `cc-ups-load` | `<div class="cc-metric-value" id="cc-ups-load">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2238 | HTML id | `cc-ups-runtime` | `<div class="cc-metric-value" id="cc-ups-runtime">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2243 | HTML id | `cc-ups-input` | `<div class="cc-metric-value" id="cc-ups-input">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2248 | HTML id | `cc-ups-output` | `<div class="cc-metric-value" id="cc-ups-output">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2253 | HTML id | `cc-ups-status` | `<div class="cc-metric-value" id="cc-ups-status">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2258 | HTML id | `cc-ups-refresh` | `<div class="cc-metric-value" id="cc-ups-refresh">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2263 | HTML id | `cc-ups-picker` | `<div class="cc-ups-picker" id="cc-ups-picker"></div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2264 | HTML id | `cc-picker-actions` | `<div class="cc-picker-actions" id="cc-picker-actions">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2265 | HTML id | `cc-rack-overview-button` | `<button class="cc-btn" id="cc-rack-overview-button">UPS Rack Overview</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2265 | Button | `<button class="cc-btn" id="cc-rack-overview-button">UPS Rack Overview</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2275 | HTML id | `cc-random-fact` | `<div class="cc-random-fact" id="cc-random-fact">Loading UPS fact...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2286 | HTML id | `cc-events-section` | `<div class="cc-card cc-wide cc-tab-panel" id="cc-events-section">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2290 | HTML id | `cc-refresh-events-2` | `<button class="cc-btn" id="cc-refresh-events-2">Refresh Event Log</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2290 | Button | `<button class="cc-btn" id="cc-refresh-events-2">Refresh Event Log</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2297 | HTML id | `cc-config-section` | `<div class="cc-card cc-wide cc-config-launch-card cc-tab-panel" id="cc-config-section">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2313 | HTML id | `cc-open-config-management` | `<button class="cc-btn cc-btn-primary" id="cc-open-config-management">Open Configuration Management</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2313 | Button | `<button class="cc-btn cc-btn-primary" id="cc-open-config-management">Open Configuration Management</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2318 | HTML id | `cc-event-summary` | `<div class="cc-section-subtitle" id="cc-event-summary">Loading latest event summary...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2319 | HTML id | `cc-event-box` | `<div class="cc-event-box" id="cc-event-box">Loading Power / Boot Event Log...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2324 | HTML id | `cc-config-section` | `<div class="cc-card cc-wide cc-tab-panel" id="cc-config-section">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2330 | HTML id | `cc-config-inline-status` | `<div class="cc-mini" id="cc-config-inline-status" style="margin-bottom:14px;">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2332 | HTML id | `cc-config-loader-status` | `<div class="v" id="cc-config-loader-status">Waiting to load selected config...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2339 | HTML id | `config-select` | `<select class="cc-select" id="config-select">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2348 | HTML id | `reference-select` | `<select class="cc-select" id="reference-select">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2358 | HTML id | `meta-path` | `<div class="v" id="meta-path">-</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2363 | HTML id | `meta-type` | `<div class="v" id="meta-type">-</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2368 | HTML id | `meta-status` | `<div class="v" id="meta-status">Ready</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2375 | HTML id | `editor-title` | `<div class="cc-pane-title" id="editor-title">Config Editor</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2376 | HTML id | `editor-subtitle` | `<div class="cc-pane-subtitle" id="editor-subtitle">Select a live config to load, validate, save, or revert.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2379 | HTML id | `btn-load` | `<button class="cc-btn" id="btn-load">Reload</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2379 | Button | `<button class="cc-btn" id="btn-load">Reload</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2380 | HTML id | `btn-validate` | `<button class="cc-btn cc-btn-warn" id="btn-validate">Validate</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2380 | Button | `<button class="cc-btn cc-btn-warn" id="btn-validate">Validate</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2381 | HTML id | `btn-save` | `<button class="cc-btn cc-btn-primary" id="btn-save" disabled title="Save is disabled until final controlled dashboard-ui.json test">Save Disabled</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2381 | Button | `<button class="cc-btn cc-btn-primary" id="btn-save" disabled title="Save is disabled until final controlled dashboard-ui.json test">Save Disabled</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2382 | HTML id | `btn-revert` | `<button class="cc-btn cc-btn-danger" id="btn-revert">Revert</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2382 | Button | `<button class="cc-btn cc-btn-danger" id="btn-revert">Revert</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2394 | HTML id | `config-editor` | `<textarea class="cc-editor" id="config-editor" spellcheck="false"></textarea>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2404 | HTML id | `reference-viewer` | `<textarea class="cc-editor" id="reference-viewer" spellcheck="false" readonly></textarea>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2414 | HTML id | `cc-tests-logs-live-section` | `<section class="cc-card cc-danger-zone cc-tab-panel" id="cc-tests-logs-live-section">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2426 | HTML id | `cc-sim-test` | `<button class="cc-btn cc-btn-primary" id="cc-sim-test">Run Simulated Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2426 | Button | `<button class="cc-btn cc-btn-primary" id="cc-sim-test">Run Simulated Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2432 | HTML id | `cc-export-logs` | `<a class="cc-btn" id="cc-export-logs" href="/nut-ui/api/export-logs">Export Logs</a>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2432 | API/fetch reference | `<a class="cc-btn" id="cc-export-logs" href="/nut-ui/api/export-logs">Export Logs</a>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2445 | HTML id | `cc-action-output` | `<div class="cc-output" id="cc-action-output">No action has been run from this page yet.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2448 | HTML id | `cc-advanced-live-test-card` | `<div class="cc-live-locked-card" id="cc-advanced-live-test-card">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2484 | HTML id | `cc-real-test-phase` | `<select class="cc-select" id="cc-real-test-phase">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2497 | HTML id | `cc-live-test-notes` | `<button class="cc-btn" id="cc-live-test-notes">Show Safety Notes</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2497 | Button | `<button class="cc-btn" id="cc-live-test-notes">Show Safety Notes</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2498 | HTML id | `cc-real-test-run` | `<button class="cc-btn cc-btn-danger" id="cc-real-test-run" title="Requires Real Test passphrase. Use fake password to prove lockout, or real passphrase during approved live test.">Run Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2498 | Button | `<button class="cc-btn cc-btn-danger" id="cc-real-test-run" title="Requires Real Test passphrase. Use fake password to prove lockout, or real passphrase during approved live test.">Run Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2507 | JavaScript function | `escapeHtml` | `function escapeHtml(value) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2516 | JavaScript function | `getQuotedValue` | `function getQuotedValue(text, key) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2526 | JavaScript function | `parseEventLine` | `function parseEventLine(line) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2566 | JavaScript function | `loadControlCenterEvents` | `async function loadControlCenterEvents() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2577 | API/fetch reference | `const resp = await fetch("/nut-ui/api/power-events", { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2648 | JavaScript function | `updateControlCenterClock` | `function updateControlCenterClock() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2666 | JavaScript function | `rotateControlCenterFact` | `function rotateControlCenterFact() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2673 | JavaScript function | `setControlCenterOutput` | `function setControlCenterOutput(title, payload, isError = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2689 | JavaScript function | `ccApiJson` | `async function ccApiJson(url, options = {}) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2690 | API/fetch reference | `const res = await fetch(url, options);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2713 | JavaScript function | `ccGet` | `function ccGet(id) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2717 | JavaScript function | `setControlCenterStatus` | `function setControlCenterStatus(message, busy = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2730 | JavaScript function | `setControlCenterMeta` | `function setControlCenterMeta(data, status) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2750 | JavaScript function | `setConfigLoaderStatus` | `function setConfigLoaderStatus(message, isError = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2757 | JavaScript function | `extractConfigContent` | `function extractConfigContent(data) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2766 | JavaScript function | `loadControlCenterConfig` | `async function loadControlCenterConfig(configId) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2779 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId) + "/content");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2808 | JavaScript function | `loadControlCenterReference` | `async function loadControlCenterReference(refId) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2822 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(refId) + "/content-ref");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2847 | JavaScript function | `validateControlCenterConfig` | `async function validateControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2859 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2876 | JavaScript function | `saveControlCenterConfig` | `async function saveControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2899 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2918 | JavaScript function | `revertControlCenterConfig` | `function revertControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2937 | JavaScript function | `setButtonRunning` | `function setButtonRunning(buttonId, running, runningText = "Working...") {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2956 | JavaScript function | `classifyUpsStatus` | `function classifyUpsStatus(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 2987 | JavaScript function | `updateUpsStatusBarColor` | `function updateUpsStatusBarColor(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3005 | JavaScript function | `promptControlCenterRealTestPassphrase` | `function promptControlCenterRealTestPassphrase(phase) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3047 | Event listener | `cancel.addEventListener("click", onCancel);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3048 | Event listener | `submit.addEventListener("click", onSubmit);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3049 | Event listener | `input.addEventListener("keydown", onKeydown);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3055 | JavaScript function | `runControlCenterRealTest` | `async function runControlCenterRealTest() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3075 | API/fetch reference | `const response = await fetch("/nut-ui/api/test/real", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3101 | JavaScript function | `showControlCenterRealTestNotes` | `function showControlCenterRealTestNotes() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3103 | API/fetch reference | `backend_endpoint: "/nut-ui/api/test/real",` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3112 | JavaScript function | `runControlCenterBackup` | `async function runControlCenterBackup() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3117 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/backup", { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3126 | JavaScript function | `openRestoreOptionsModal` | `function openRestoreOptionsModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3134 | JavaScript function | `closeRestoreOptionsModal` | `function closeRestoreOptionsModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3142 | JavaScript function | `syncBackupRepoFromGithub` | `async function syncBackupRepoFromGithub() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3150 | API/fetch reference | `const branchData = await ccApiJson("/nut-ui/api/restore/branches");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3178 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3191 | JavaScript function | `runRestoreDryRunPreview` | `async function runRestoreDryRunPreview(category) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3199 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/live-dry-run", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3212 | JavaScript function | `openSelectedRestoreModal` | `function openSelectedRestoreModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3221 | JavaScript function | `closeSelectedRestoreModal` | `function closeSelectedRestoreModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3232 | JavaScript function | `openSelectedRestoreConfirmModal` | `function openSelectedRestoreConfirmModal(itemId, label) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3268 | JavaScript function | `closeSelectedRestoreConfirmModal` | `function closeSelectedRestoreConfirmModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3276 | JavaScript function | `runSelectedFileLiveRestore` | `async function runSelectedFileLiveRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3314 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/selected-file-live", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3329 | JavaScript function | `openLabSelectedRestoreScreen` | `function openLabSelectedRestoreScreen() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3339 | JavaScript function | `closeLabSelectedRestoreScreen` | `function closeLabSelectedRestoreScreen() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3347 | JavaScript function | `selectLabRestoreItem` | `function selectLabRestoreItem(itemId, label) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3361 | JavaScript function | `runLabSelectedRestore` | `async function runLabSelectedRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3381 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/selected-file-live", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3393 | JavaScript function | `runControlCenterRestore` | `async function runControlCenterRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3397 | JavaScript function | `sampleAllUpsLoadsForGraph` | `async function sampleAllUpsLoadsForGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3410 | JavaScript function | `preloadLoadGraphHistory` | `async function preloadLoadGraphHistory() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3422 | JavaScript function | `drawLoadGraph` | `function drawLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3498 | JavaScript function | `openLoadGraph` | `function openLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3510 | JavaScript function | `closeLoadGraph` | `function closeLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3517 | JavaScript function | `loadControlCenterRackMap` | `async function loadControlCenterRackMap() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3521 | API/fetch reference | `const res = await fetch("/ups-rack-map.txt?v=" + Date.now(), { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3542 | JavaScript function | `rackStatusClass` | `function rackStatusClass(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3549 | JavaScript function | `loadControlCenterRackOverview` | `async function loadControlCenterRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3591 | Event listener | `row.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3605 | JavaScript function | `openRackOverview` | `async function openRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3611 | JavaScript function | `closeRackOverview` | `function closeRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3618 | JavaScript function | `updatePontiacWeather` | `async function updatePontiacWeather() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3631 | API/fetch reference | `const response = await fetch(url, { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3650 | JavaScript function | `refreshControlCenterAll` | `async function refreshControlCenterAll() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3669 | JavaScript function | `secondsToReadable` | `function secondsToReadable(seconds) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3678 | JavaScript function | `pickValue` | `function pickValue(data, keys, suffix = "") {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3687 | JavaScript function | `formatPercent` | `function formatPercent(value) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3694 | JavaScript function | `setUpsText` | `function setUpsText(id, value) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3699 | JavaScript function | `fetchControlCenterUps` | `async function fetchControlCenterUps(upsName) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3700 | API/fetch reference | `const resp = await fetch("/cgi-bin/nut/upsjson.sh?ups=" + encodeURIComponent(upsName) + "&_=" + Date.now(), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3707 | JavaScript function | `renderControlCenterUpsPicker` | `function renderControlCenterUpsPicker() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3712 | Button | `<button class="cc-ups-choice ${upsName === ccSelectedUps ? "selected" : ""}" data-ups="${upsName}">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3718 | Event listener | `button.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3732 | JavaScript function | `autoCycleControlCenterUPS` | `function autoCycleControlCenterUPS() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3747 | JavaScript function | `loadControlCenterUPS` | `async function loadControlCenterUPS() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3801 | JavaScript function | `runControlCenterSimulatedTest` | `async function runControlCenterSimulatedTest() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3813 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/test/simulate", { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3825 | JavaScript function | `showControlCenterLiveTestNotes` | `function showControlCenterLiveTestNotes() {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3833 | Event listener | `document.addEventListener("DOMContentLoaded", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3836 | Event listener | `refreshAllButton.addEventListener("click", refreshControlCenterAll);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3841 | Event listener | `refreshEventsButton.addEventListener("click", loadControlCenterEvents);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3846 | Event listener | `upsRefreshButton.addEventListener("click", loadControlCenterUPS);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3852 | Event listener | `selectedUpsCard.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3862 | Event listener | `upsLoadCard.addEventListener("click", openLoadGraph);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3867 | Event listener | `closeLoadGraphButton.addEventListener("click", closeLoadGraph);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3872 | Event listener | `loadGraphModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3879 | Event listener | `rackOverviewButton.addEventListener("click", openRackOverview);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3884 | Event listener | `closeRackOverviewButton.addEventListener("click", closeRackOverview);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3889 | Event listener | `rackOverviewModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3896 | Event listener | `configSelect.addEventListener("change", async (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3903 | Event listener | `referenceSelect.addEventListener("change", async (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3910 | Event listener | `loadButton.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3917 | Event listener | `validateButton.addEventListener("click", validateControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3922 | Event listener | `saveButton.addEventListener("click", saveControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3927 | Event listener | `revertButton.addEventListener("click", revertControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3936 | Event listener | `realTestButton.addEventListener("click", runControlCenterRealTest);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3941 | Event listener | `realTestNotesButton.addEventListener("click", showControlCenterRealTestNotes);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3949 | Event listener | `openConfigButton.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3955 | Event listener | `closeConfigButton.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3961 | Event listener | `configModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3969 | JavaScript function | `showControlCenterTab` | `function showControlCenterTab(sectionId) {` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3980 | Event listener | `link.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 3996 | Event listener | `backupButton.addEventListener("click", runControlCenterBackup);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4001 | Event listener | `restoreButton.addEventListener("click", runControlCenterRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4006 | Event listener | `labOpenSelectedRestore.addEventListener("click", openLabSelectedRestoreScreen);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4011 | Event listener | `labSelectedRestoreBack.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4018 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4028 | Event listener | `labRunSelectedRestore.addEventListener("click", runLabSelectedRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4034 | Event listener | `restoreModalClose.addEventListener("click", closeRestoreOptionsModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4039 | Event listener | `restoreModalOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4047 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4058 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4067 | Event listener | `selectedRestoreModalClose.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4075 | Event listener | `selectedRestoreModalOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4083 | Event listener | `button.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4102 | Event listener | `selectedRestoreConfirmClose.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4110 | Event listener | `selectedRestoreConfirmCancel.addEventListener("click", closeSelectedRestoreConfirmModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4115 | Event listener | `selectedRestoreConfirmRun.addEventListener("click", runSelectedFileLiveRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4120 | Event listener | `selectedRestoreConfirmOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4129 | Event listener | `simTestButton.addEventListener("click", runControlCenterSimulatedTest);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4134 | Event listener | `realTestPlaceholder.addEventListener("click", showControlCenterLiveTestNotes);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4155 | HTML id | `cc-load-graph-modal` | `<div class="cc-modal-backdrop" id="cc-load-graph-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4159 | HTML id | `cc-load-graph-title` | `<div class="cc-modal-title" id="cc-load-graph-title">UPS Load History</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4160 | HTML id | `cc-load-graph-subtitle` | `<div class="cc-modal-note" id="cc-load-graph-subtitle">Rolling in-browser load history for selected UPS.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4162 | HTML id | `cc-close-load-graph` | `<button class="cc-btn" id="cc-close-load-graph">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4162 | Button | `<button class="cc-btn" id="cc-close-load-graph">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4164 | HTML id | `cc-load-graph-canvas` | `<canvas class="cc-load-graph" id="cc-load-graph-canvas" width="900" height="320"></canvas>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4171 | HTML id | `cc-rack-overview-modal` | `<div class="cc-modal-backdrop" id="cc-rack-overview-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4178 | HTML id | `cc-close-rack-overview` | `<button class="cc-btn" id="cc-close-rack-overview">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4178 | Button | `<button class="cc-btn" id="cc-close-rack-overview">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4194 | HTML id | `cc-rack-table-body` | `<tbody id="cc-rack-table-body">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4202 | HTML id | `cc-real-test-passphrase-overlay` | `<div class="cc-passphrase-overlay" id="cc-real-test-passphrase-overlay" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4205 | HTML id | `cc-real-test-passphrase-warning` | `<div class="cc-passphrase-warning" id="cc-real-test-passphrase-warning">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4208 | HTML id | `cc-real-test-passphrase-input` | `<input class="cc-passphrase-input" id="cc-real-test-passphrase-input" type="password" autocomplete="off" placeholder="Real Test passphrase">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4210 | HTML id | `cc-real-test-passphrase-cancel` | `<button class="cc-btn" id="cc-real-test-passphrase-cancel">Cancel</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4210 | Button | `<button class="cc-btn" id="cc-real-test-passphrase-cancel">Cancel</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4211 | HTML id | `cc-real-test-passphrase-submit` | `<button class="cc-btn cc-btn-danger" id="cc-real-test-passphrase-submit">Run Real Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4211 | Button | `<button class="cc-btn cc-btn-danger" id="cc-real-test-passphrase-submit">Run Real Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4216 | HTML id | `cc-config-management-modal` | `<div class="cc-modal-backdrop" id="cc-config-management-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4223 | HTML id | `cc-close-config-management` | `<button class="cc-btn" id="cc-close-config-management">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4223 | Button | `<button class="cc-btn" id="cc-close-config-management">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4235 | HTML id | `cc-restore-modal-overlay` | `<div class="cc-restore-modal-overlay" id="cc-restore-modal-overlay" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4239 | HTML id | `cc-restore-modal-title` | `<div class="cc-restore-modal-title" id="cc-restore-modal-title">Restore from GitHub Options</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4244 | HTML id | `cc-restore-modal-close` | `<button class="cc-btn" type="button" id="cc-restore-modal-close">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4244 | Button | `<button class="cc-btn" type="button" id="cc-restore-modal-close">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4248 | Button | `<button class="cc-restore-option" type="button" data-restore-action="sync-repo">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4253 | Button | `<button class="cc-restore-option" type="button" data-restore-dry-run="all">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4258 | HTML id | `cc-lab-open-selected-restore` | `<button class="cc-restore-option" type="button" id="cc-lab-open-selected-restore">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4258 | Button | `<button class="cc-restore-option" type="button" id="cc-lab-open-selected-restore">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4268 | HTML id | `cc-lab-selected-restore-screen` | `<div class="cc-restore-modal-overlay" id="cc-lab-selected-restore-screen" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4272 | HTML id | `cc-lab-selected-restore-title` | `<div class="cc-restore-modal-title" id="cc-lab-selected-restore-title">Restore Selected File</div>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4277 | HTML id | `cc-lab-selected-restore-back` | `<button class="cc-btn" type="button" id="cc-lab-selected-restore-back">Back</button>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4277 | Button | `<button class="cc-btn" type="button" id="cc-lab-selected-restore-back">Back</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4288 | HTML id | `cc-lab-restore-item-dropdown` | `<select id="cc-lab-restore-item-dropdown" class="cc-input" style="width:100%; margin-top:.45rem;">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4317 | Button | `<button class="cc-btn" type="button"` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4330 | HTML id | `cc-lab-restore-confirm-panel` | `<div class="cc-card" id="cc-lab-restore-confirm-panel" style="display:none; margin-top:1rem;">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4332 | HTML id | `cc-lab-restore-confirm-title` | `<h3 id="cc-lab-restore-confirm-title" style="margin:.35rem 0 .5rem;">Selected item</h3>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4333 | HTML id | `cc-lab-restore-confirm-id` | `<p id="cc-lab-restore-confirm-id" style="color:rgba(255,255,255,.66); margin-top:0;"></p>` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4337 | HTML id | `cc-lab-restore-confirm-input` | `id="cc-lab-restore-confirm-input"` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4351 | HTML id | `cc-lab-run-selected-restore` | `<button class="cc-btn cc-btn-danger" type="button" id="cc-lab-run-selected-restore">` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4351 | Button | `<button class="cc-btn cc-btn-danger" type="button" id="cc-lab-run-selected-restore">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4361 | Event listener | `document.addEventListener("DOMContentLoaded", function () {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4367 | Event listener | `openButton.addEventListener("click", function () {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2816 | HTML id | `nut-production-top-banner` | `<div id="nut-production-top-banner" aria-live="polite">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2820 | HTML id | `nut-prod-mode` | `<span id="nut-prod-mode" class="nut-prod-mode armed">PROTECTING</span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2821 | HTML id | `nut-prod-ups` | `<span class="nut-prod-detail">UPS: <strong id="nut-prod-ups">--/--</strong></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2824 | HTML id | `nut-prod-btn-protecting` | `<button type="button" class="nut-prod-btn" id="nut-prod-btn-protecting">Protecting</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2824 | Button | `<button type="button" class="nut-prod-btn" id="nut-prod-btn-protecting">Protecting</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2825 | HTML id | `nut-prod-btn-standby` | `<button type="button" class="nut-prod-btn warn" id="nut-prod-btn-standby">Standby</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2825 | Button | `<button type="button" class="nut-prod-btn warn" id="nut-prod-btn-standby">Standby</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2826 | HTML id | `nut-prod-btn-off` | `<button type="button" class="nut-prod-btn danger" id="nut-prod-btn-off">Off</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2826 | Button | `<button type="button" class="nut-prod-btn danger" id="nut-prod-btn-off">Off</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2827 | HTML id | `nut-prod-mode-fields` | `<span class="nut-prod-mode-fields" id="nut-prod-mode-fields">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2828 | HTML id | `nut-prod-live-actions` | `<span class="nut-prod-mode-field">Live protection action: <strong id="nut-prod-live-actions">--</strong></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2829 | HTML id | `nut-prod-maintenance-mode` | `<span class="nut-prod-mode-field">Maintenance mode: <strong id="nut-prod-maintenance-mode">--</strong></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2830 | HTML id | `nut-prod-monitor` | `<span class="nut-prod-mode-field">Monitor: <strong id="nut-prod-monitor">--</strong></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2831 | HTML id | `nut-prod-emails` | `<span class="nut-prod-mode-field">Emails: <strong id="nut-prod-emails">--</strong></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2834 | HTML id | `nut-prod-controls-note` | `<span id="nut-prod-controls-note" style="display:none"></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2837 | HTML id | `cc-backup-github` | `<button class="cc-btn cc-btn-primary nut-prod-action-btn" id="cc-backup-github">Backup</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2837 | Button | `<button class="cc-btn cc-btn-primary nut-prod-action-btn" id="cc-backup-github">Backup</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2838 | HTML id | `cc-refresh-all` | `<button class="cc-btn nut-prod-action-btn" id="cc-refresh-all">Refresh</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2838 | Button | `<button class="cc-btn nut-prod-action-btn" id="cc-refresh-all">Refresh</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2839 | HTML id | `cc-restore-github` | `<button class="cc-btn nut-prod-action-btn" id="cc-restore-github">Restore</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2839 | Button | `<button class="cc-btn nut-prod-action-btn" id="cc-restore-github">Restore</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2844 | HTML id | `cc-clock-time` | `<strong id="cc-clock-time">--:--:--</strong>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2846 | HTML id | `cc-clock-date` | `<span id="cc-clock-date">Loading date...</span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2847 | HTML id | `cc-pontiac-weather` | `<span id="cc-pontiac-weather">Pontiac: loading temp...</span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2848 | HTML id | `cc-refresh-countdown` | `<span id="cc-refresh-countdown">Refresh countdown: 35s</span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2849 | HTML id | `nut-prod-updated` | `<span class="nut-prod-muted" id="nut-prod-updated" title="Last protection status update">Updated</span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2856 | HTML id | `nut-production-confirm-modal` | `<div id="nut-production-confirm-modal" role="dialog" aria-modal="true" aria-labelledby="nut-prod-confirm-title">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2858 | HTML id | `nut-prod-confirm-title` | `<div class="nut-prod-confirm-title" id="nut-prod-confirm-title">Confirm Protecting Mode</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2865 | HTML id | `nut-prod-confirm-cancel` | `<button type="button" class="nut-prod-confirm-cancel" id="nut-prod-confirm-cancel">Cancel</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2865 | Button | `<button type="button" class="nut-prod-confirm-cancel" id="nut-prod-confirm-cancel">Cancel</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2866 | HTML id | `nut-prod-confirm-protect` | `<button type="button" class="nut-prod-confirm-protect" id="nut-prod-confirm-protect">Confirm Protecting</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2866 | Button | `<button type="button" class="nut-prod-confirm-protect" id="nut-prod-confirm-protect">Confirm Protecting</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2873 | JavaScript function | `refreshNutProductionBanner` | `async function refreshNutProductionBanner() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2883 | API/fetch reference | `const response = await fetch('/nut-state/production-mode.json?ts=' + Date.now(), { cache: 'no-store' });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2941 | JavaScript function | `updateNutModeStatusFields` | `function updateNutModeStatusFields(mode) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2996 | JavaScript function | `updateNutProductionButtons` | `function updateNutProductionButtons(mode) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3018 | JavaScript function | `setNutProductionMode` | `async function setNutProductionMode(mode) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3024 | API/fetch reference | `let response = await fetch('/nut-ui/api/production-mode', {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3031 | API/fetch reference | `response = await fetch('/api/production-mode', {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3053 | JavaScript function | `openProtectingConfirmModal` | `function openProtectingConfirmModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3058 | JavaScript function | `closeProtectingConfirmModal` | `function closeProtectingConfirmModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3063 | JavaScript function | `wireNutProductionControls` | `function wireNutProductionControls() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3071 | Event listener | `if (protecting) protecting.addEventListener('click', openProtectingConfirmModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3072 | Event listener | `if (standby) standby.addEventListener('click', () => setNutProductionMode('standby'));` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3073 | Event listener | `if (off) off.addEventListener('click', () => setNutProductionMode('off'));` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3075 | Event listener | `if (cancel) cancel.addEventListener('click', closeProtectingConfirmModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3077 | Event listener | `confirm.addEventListener('click', async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3084 | Event listener | `modal.addEventListener('click', (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3090 | Event listener | `document.addEventListener('DOMContentLoaded', refreshNutProductionBanner);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3091 | Event listener | `document.addEventListener('DOMContentLoaded', wireNutProductionControls);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3118 | HTML id | `cc-health-text` | `<span class="cc-status-pill"><span class="cc-dot"></span><span id="cc-health-text">Loading</span></span>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3125 | HTML id | `cc-selected-ups` | `<div class="cc-metric-value" id="cc-selected-ups">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3130 | HTML id | `cc-latest-event-type` | `<div class="cc-metric-value" id="cc-latest-event-type">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3131 | HTML id | `cc-latest-event-time` | `<div class="cc-metric-note" id="cc-latest-event-time">Waiting for event feed.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3151 | HTML id | `cc-monitoring-section` | `<div class="cc-card cc-wide cc-tab-panel active" id="cc-monitoring-section">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3155 | HTML id | `cc-refresh-ups` | `<button class="cc-btn" id="cc-refresh-ups">Refresh UPS</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3155 | Button | `<button class="cc-btn" id="cc-refresh-ups">Refresh UPS</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3161 | HTML id | `cc-ups-status-bar` | `<div class="cc-ups-status-bar" id="cc-ups-status-bar">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3163 | HTML id | `cc-ups-status-main` | `<div class="cc-ups-status-main" id="cc-ups-status-main">Loading UPS status...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3164 | HTML id | `cc-ups-status-sub` | `<div class="cc-ups-status-sub" id="cc-ups-status-sub">Waiting for NUT data.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3166 | HTML id | `cc-ups-status-pill` | `<div class="cc-status-pill"><span class="cc-dot"></span><span id="cc-ups-status-pill">Checking</span></div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3169 | HTML id | `cc-ups-metrics` | `<div class="cc-metrics" id="cc-ups-metrics">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3170 | HTML id | `cc-selected-ups-card` | `<div class="cc-metric cc-ups-pick-card" id="cc-selected-ups-card" title="Click to choose UPS">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3172 | HTML id | `cc-ups-name` | `<div class="cc-metric-value" id="cc-ups-name">Loading</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3173 | HTML id | `cc-ups-model` | `<div class="cc-metric-note" id="cc-ups-model">Click to choose UPS.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3177 | HTML id | `cc-ups-charge` | `<div class="cc-metric-value" id="cc-ups-charge">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3180 | HTML id | `cc-ups-load-card` | `<div class="cc-metric cc-load-graph-click" id="cc-ups-load-card" title="Click to open load graph">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3182 | HTML id | `cc-ups-load` | `<div class="cc-metric-value" id="cc-ups-load">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3187 | HTML id | `cc-ups-runtime` | `<div class="cc-metric-value" id="cc-ups-runtime">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3192 | HTML id | `cc-ups-input` | `<div class="cc-metric-value" id="cc-ups-input">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3197 | HTML id | `cc-ups-output` | `<div class="cc-metric-value" id="cc-ups-output">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3202 | HTML id | `cc-ups-status` | `<div class="cc-metric-value" id="cc-ups-status">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3207 | HTML id | `cc-ups-refresh` | `<div class="cc-metric-value" id="cc-ups-refresh">--</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3212 | HTML id | `cc-ups-picker` | `<div class="cc-ups-picker" id="cc-ups-picker"></div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3213 | HTML id | `cc-picker-actions` | `<div class="cc-picker-actions" id="cc-picker-actions">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3214 | HTML id | `cc-rack-overview-button` | `<button class="cc-btn" id="cc-rack-overview-button">UPS Rack Overview</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3214 | Button | `<button class="cc-btn" id="cc-rack-overview-button">UPS Rack Overview</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3224 | HTML id | `cc-random-fact` | `<div class="cc-random-fact" id="cc-random-fact">Loading UPS fact...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3235 | HTML id | `cc-events-section` | `<div class="cc-card cc-wide cc-tab-panel" id="cc-events-section">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3239 | HTML id | `cc-refresh-events-2` | `<button class="cc-btn" id="cc-refresh-events-2">Refresh Event Log</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3239 | Button | `<button class="cc-btn" id="cc-refresh-events-2">Refresh Event Log</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3246 | HTML id | `cc-config-section` | `<div class="cc-card cc-wide cc-config-launch-card cc-tab-panel" id="cc-config-section">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3262 | HTML id | `cc-open-config-management` | `<button class="cc-btn cc-btn-primary" id="cc-open-config-management">Open Configuration Management</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3262 | Button | `<button class="cc-btn cc-btn-primary" id="cc-open-config-management">Open Configuration Management</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3267 | HTML id | `cc-event-summary` | `<div class="cc-section-subtitle" id="cc-event-summary">Loading latest event summary...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3268 | HTML id | `cc-event-box` | `<div class="cc-event-box" id="cc-event-box">Loading Power / Boot Event Log...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3273 | HTML id | `cc-config-section` | `<div class="cc-card cc-wide cc-tab-panel" id="cc-config-section">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3279 | HTML id | `cc-config-inline-status` | `<div class="cc-mini" id="cc-config-inline-status" style="margin-bottom:14px;">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3281 | HTML id | `cc-config-loader-status` | `<div class="v" id="cc-config-loader-status">Waiting to load selected config...</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3288 | HTML id | `config-select` | `<select class="cc-select" id="config-select">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3297 | HTML id | `reference-select` | `<select class="cc-select" id="reference-select">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3307 | HTML id | `meta-path` | `<div class="v" id="meta-path">-</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3312 | HTML id | `meta-type` | `<div class="v" id="meta-type">-</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3317 | HTML id | `meta-status` | `<div class="v" id="meta-status">Ready</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3324 | HTML id | `editor-title` | `<div class="cc-pane-title" id="editor-title">Config Editor</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3325 | HTML id | `editor-subtitle` | `<div class="cc-pane-subtitle" id="editor-subtitle">Select a live config to load, validate, save, or revert.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3328 | HTML id | `btn-load` | `<button class="cc-btn" id="btn-load">Reload</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3328 | Button | `<button class="cc-btn" id="btn-load">Reload</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3329 | HTML id | `btn-validate` | `<button class="cc-btn cc-btn-warn" id="btn-validate">Validate</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3329 | Button | `<button class="cc-btn cc-btn-warn" id="btn-validate">Validate</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3330 | HTML id | `btn-save` | `<button class="cc-btn cc-btn-primary" id="btn-save" title="Save validated changes to the selected live config">Save</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3330 | Button | `<button class="cc-btn cc-btn-primary" id="btn-save" title="Save validated changes to the selected live config">Save</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3331 | HTML id | `btn-revert` | `<button class="cc-btn cc-btn-danger" id="btn-revert">Revert</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3331 | Button | `<button class="cc-btn cc-btn-danger" id="btn-revert">Revert</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3343 | HTML id | `config-editor` | `<textarea class="cc-editor" id="config-editor" spellcheck="false"></textarea>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3353 | HTML id | `reference-viewer` | `<textarea class="cc-editor" id="reference-viewer" spellcheck="false" readonly></textarea>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3363 | HTML id | `cc-tests-logs-live-section` | `<section class="cc-card cc-danger-zone cc-tab-panel" id="cc-tests-logs-live-section">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3375 | HTML id | `cc-sim-test` | `<button class="cc-btn cc-btn-primary" id="cc-sim-test">Run Simulated Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3375 | Button | `<button class="cc-btn cc-btn-primary" id="cc-sim-test">Run Simulated Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3381 | HTML id | `cc-export-logs` | `<a class="cc-btn" id="cc-export-logs" href="/nut-ui/api/export-logs">Export Logs</a>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3381 | API/fetch reference | `<a class="cc-btn" id="cc-export-logs" href="/nut-ui/api/export-logs">Export Logs</a>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3395 | HTML id | `cc-output-copy` | `<button type="button" class="cc-btn" id="cc-output-copy" title="Selects and copies the full action output log" onclick="return ccCopyFullActionOutput(event);" style="outline:none;">Copy Full Output</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3395 | Button | `<button type="button" class="cc-btn" id="cc-output-copy" title="Selects and copies the full action output log" onclick="return ccCopyFullActionOutput(event);" style="outline:none;">Copy Full Output</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3397 | HTML id | `cc-action-output` | `<div class="cc-output" id="cc-action-output">No action has been run from this page yet.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3400 | HTML id | `cc-advanced-live-test-card` | `<div class="cc-live-locked-card" id="cc-advanced-live-test-card">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3436 | HTML id | `cc-real-test-phase` | `<select class="cc-select" id="cc-real-test-phase">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3449 | HTML id | `cc-live-test-notes` | `<button class="cc-btn" id="cc-live-test-notes">Show Safety Notes</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3449 | Button | `<button class="cc-btn" id="cc-live-test-notes">Show Safety Notes</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3450 | HTML id | `cc-real-test-run` | `<button class="cc-btn cc-btn-danger" id="cc-real-test-run" title="Requires Real Test passphrase. Use fake password to prove lockout, or real passphrase during approved live test.">Run Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3450 | Button | `<button class="cc-btn cc-btn-danger" id="cc-real-test-run" title="Requires Real Test passphrase. Use fake password to prove lockout, or real passphrase during approved live test.">Run Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3459 | JavaScript function | `escapeHtml` | `function escapeHtml(value) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3468 | JavaScript function | `getQuotedValue` | `function getQuotedValue(text, key) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3478 | JavaScript function | `formatNutMonitorMessage` | `function formatNutMonitorMessage(text) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3491 | JavaScript function | `parseEventLine` | `function parseEventLine(line) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3568 | JavaScript function | `loadControlCenterEvents` | `async function loadControlCenterEvents() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3579 | API/fetch reference | `const resp = await fetch("/nut-ui/api/power-events", { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3650 | JavaScript function | `updateControlCenterClock` | `function updateControlCenterClock() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3668 | JavaScript function | `rotateControlCenterFact` | `function rotateControlCenterFact() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3675 | JavaScript function | `ccEscapeHtml` | `function ccEscapeHtml(value) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3684 | JavaScript function | `ccSectionHtml` | `function ccSectionHtml(label, value, open = true) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3696 | JavaScript function | `ccLineHtml` | `function ccLineHtml(label, value) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3701 | JavaScript function | `ccWeatherFlashColor` | `function ccWeatherFlashColor() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3718 | JavaScript function | `ccFlashCopyButton` | `function ccFlashCopyButton(button, message) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3732 | JavaScript function | `applyFlash` | `function applyFlash() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3764 | JavaScript function | `ccSelectActionOutput` | `function ccSelectActionOutput(output) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3773 | JavaScript function | `ccCopyTextFallback` | `function ccCopyTextFallback(text) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3795 | JavaScript function | `ccCopyFullActionOutput` | `function ccCopyFullActionOutput(event) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3833 | JavaScript function | `setControlCenterOutput` | `function setControlCenterOutput(title, payload, isError = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3882 | JavaScript function | `ccApiJson` | `async function ccApiJson(url, options = {}) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3883 | API/fetch reference | `const res = await fetch(url, options);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3906 | JavaScript function | `ccGet` | `function ccGet(id) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3910 | JavaScript function | `setControlCenterStatus` | `function setControlCenterStatus(message, busy = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3923 | JavaScript function | `setControlCenterMeta` | `function setControlCenterMeta(data, status) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3943 | JavaScript function | `setConfigLoaderStatus` | `function setConfigLoaderStatus(message, isError = false) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3950 | JavaScript function | `extractConfigContent` | `function extractConfigContent(data) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3959 | JavaScript function | `loadControlCenterConfig` | `async function loadControlCenterConfig(configId) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 3972 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId) + "/content");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4001 | JavaScript function | `loadControlCenterReference` | `async function loadControlCenterReference(refId) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4015 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(refId) + "/content-ref");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4040 | JavaScript function | `validateControlCenterConfig` | `async function validateControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4052 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4070 | JavaScript function | `maskDbShutdownPasswordEditor` | `function maskDbShutdownPasswordEditor() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4108 | JavaScript function | `buildConfigContentForSave` | `function buildConfigContentForSave(configId, editorValue) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4122 | JavaScript function | `saveControlCenterConfig` | `async function saveControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4145 | API/fetch reference | `const data = await ccApiJson(CC_BASE + "/api/config/" + encodeURIComponent(configId), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4169 | JavaScript function | `revertControlCenterConfig` | `function revertControlCenterConfig() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4188 | JavaScript function | `setButtonRunning` | `function setButtonRunning(buttonId, running, runningText = "Working...") {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4207 | JavaScript function | `classifyUpsStatus` | `function classifyUpsStatus(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4238 | JavaScript function | `updateUpsStatusBarColor` | `function updateUpsStatusBarColor(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4256 | JavaScript function | `promptControlCenterRealTestPassphrase` | `function promptControlCenterRealTestPassphrase(phase) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4298 | Event listener | `cancel.addEventListener("click", onCancel);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4299 | Event listener | `submit.addEventListener("click", onSubmit);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4300 | Event listener | `input.addEventListener("keydown", onKeydown);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4306 | JavaScript function | `runControlCenterRealTest` | `async function runControlCenterRealTest() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4326 | API/fetch reference | `const response = await fetch("/nut-ui/api/test/real", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4352 | JavaScript function | `showControlCenterRealTestNotes` | `function showControlCenterRealTestNotes() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4354 | API/fetch reference | `backend_endpoint: "/nut-ui/api/test/real",` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4363 | JavaScript function | `runControlCenterBackup` | `async function runControlCenterBackup() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4368 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/backup", { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4377 | JavaScript function | `openRestoreOptionsModal` | `function openRestoreOptionsModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4385 | JavaScript function | `closeRestoreOptionsModal` | `function closeRestoreOptionsModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4393 | JavaScript function | `syncBackupRepoFromGithub` | `async function syncBackupRepoFromGithub() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4401 | API/fetch reference | `const branchData = await ccApiJson("/nut-ui/api/restore/branches");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4429 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4442 | JavaScript function | `runRestoreDryRunPreview` | `async function runRestoreDryRunPreview(category) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4450 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/live-dry-run", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4463 | JavaScript function | `openSelectedRestoreModal` | `function openSelectedRestoreModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4472 | JavaScript function | `closeSelectedRestoreModal` | `function closeSelectedRestoreModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4483 | JavaScript function | `openSelectedRestoreConfirmModal` | `function openSelectedRestoreConfirmModal(itemId, label) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4519 | JavaScript function | `closeSelectedRestoreConfirmModal` | `function closeSelectedRestoreConfirmModal() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4527 | JavaScript function | `runSelectedFileLiveRestore` | `async function runSelectedFileLiveRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4565 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/selected-file-live", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4580 | JavaScript function | `loadLabRestoreTargets` | `async function loadLabRestoreTargets() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4591 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/targets");` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4650 | JavaScript function | `openLabSelectedRestoreScreen` | `function openLabSelectedRestoreScreen() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4662 | JavaScript function | `closeLabSelectedRestoreScreen` | `function closeLabSelectedRestoreScreen() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4670 | JavaScript function | `selectLabRestoreItem` | `function selectLabRestoreItem(itemId, label) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4684 | JavaScript function | `runLabSelectedRestore` | `async function runLabSelectedRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4704 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/restore/selected-file-live", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4716 | JavaScript function | `runControlCenterRestore` | `async function runControlCenterRestore() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4720 | JavaScript function | `sampleAllUpsLoadsForGraph` | `async function sampleAllUpsLoadsForGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4733 | JavaScript function | `preloadLoadGraphHistory` | `async function preloadLoadGraphHistory() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4745 | JavaScript function | `addLoadHistorySample` | `function addLoadHistorySample(upsName, rawLoadValue) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4760 | JavaScript function | `drawLoadGraph` | `function drawLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4836 | JavaScript function | `openLoadGraph` | `function openLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4848 | JavaScript function | `closeLoadGraph` | `function closeLoadGraph() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4859 | JavaScript function | `ccCanLocatorIdentify` | `function ccCanLocatorIdentify(upsName) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4863 | JavaScript function | `runUpsLocatorIdentify` | `async function runUpsLocatorIdentify(upsName, buttonEl = null) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4887 | API/fetch reference | `const response = await fetch(CC_BASE + "/api/ups-locator-identify", {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4923 | JavaScript function | `loadControlCenterRackMap` | `async function loadControlCenterRackMap() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4927 | API/fetch reference | `const res = await fetch("/ups-rack-map.txt?v=" + Date.now(), { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4948 | JavaScript function | `rackStatusClass` | `function rackStatusClass(statusText) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 4955 | JavaScript function | `loadControlCenterRackOverview` | `async function loadControlCenterRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5002 | Event listener | `button.addEventListener("click", async (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5010 | Event listener | `row.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5024 | JavaScript function | `openRackOverview` | `async function openRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5030 | JavaScript function | `closeRackOverview` | `function closeRackOverview() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5037 | JavaScript function | `updatePontiacWeather` | `async function updatePontiacWeather() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5050 | API/fetch reference | `const response = await fetch(url, { cache: "no-store" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5069 | JavaScript function | `refreshControlCenterAll` | `async function refreshControlCenterAll() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5087 | JavaScript function | `secondsToReadable` | `function secondsToReadable(seconds) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5096 | JavaScript function | `pickValue` | `function pickValue(data, keys, suffix = "") {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5105 | JavaScript function | `formatPercent` | `function formatPercent(value) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5112 | JavaScript function | `setUpsText` | `function setUpsText(id, value) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5117 | JavaScript function | `fetchControlCenterUps` | `async function fetchControlCenterUps(upsName) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5118 | API/fetch reference | `const resp = await fetch("/cgi-bin/nut/upsjson.sh?ups=" + encodeURIComponent(upsName) + "&_=" + Date.now(), {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5125 | JavaScript function | `renderControlCenterUpsPicker` | `function renderControlCenterUpsPicker() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5130 | Button | `<button class="cc-ups-choice ${upsName === ccSelectedUps ? "selected" : ""}" data-ups="${upsName}">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5136 | Event listener | `button.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5150 | JavaScript function | `autoCycleControlCenterUPS` | `function autoCycleControlCenterUPS() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5165 | JavaScript function | `loadControlCenterUPS` | `async function loadControlCenterUPS() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5223 | JavaScript function | `runControlCenterSimulatedTest` | `async function runControlCenterSimulatedTest() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5235 | API/fetch reference | `const data = await ccApiJson("/nut-ui/api/test/simulate", { method: "POST" });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5247 | JavaScript function | `showControlCenterLiveTestNotes` | `function showControlCenterLiveTestNotes() {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5255 | Event listener | `document.addEventListener("DOMContentLoaded", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5258 | Event listener | `refreshAllButton.addEventListener("click", function () {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5265 | Event listener | `refreshEventsButton.addEventListener("click", loadControlCenterEvents);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5270 | Event listener | `upsRefreshButton.addEventListener("click", loadControlCenterUPS);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5276 | Event listener | `selectedUpsCard.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5286 | Event listener | `upsLoadCard.addEventListener("click", openLoadGraph);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5291 | Event listener | `closeLoadGraphButton.addEventListener("click", closeLoadGraph);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5296 | Event listener | `loadGraphModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5303 | Event listener | `rackOverviewButton.addEventListener("click", openRackOverview);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5308 | Event listener | `closeRackOverviewButton.addEventListener("click", closeRackOverview);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5313 | Event listener | `rackOverviewModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5320 | Event listener | `configSelect.addEventListener("change", async (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5327 | Event listener | `referenceSelect.addEventListener("change", async (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5334 | Event listener | `loadButton.addEventListener("click", async () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5341 | Event listener | `validateButton.addEventListener("click", validateControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5346 | Event listener | `saveButton.addEventListener("click", saveControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5351 | Event listener | `configEditor.addEventListener("input", maskDbShutdownPasswordEditor);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5356 | Event listener | `revertButton.addEventListener("click", revertControlCenterConfig);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5365 | Event listener | `realTestButton.addEventListener("click", runControlCenterRealTest);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5370 | Event listener | `realTestNotesButton.addEventListener("click", showControlCenterRealTestNotes);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5378 | Event listener | `openConfigButton.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5384 | Event listener | `closeConfigButton.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5390 | Event listener | `configModal.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5398 | JavaScript function | `showControlCenterTab` | `function showControlCenterTab(sectionId) {` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5409 | Event listener | `link.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5425 | Event listener | `backupButton.addEventListener("click", runControlCenterBackup);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5430 | Event listener | `restoreButton.addEventListener("click", runControlCenterRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5435 | Event listener | `labOpenSelectedRestore.addEventListener("click", openLabSelectedRestoreScreen);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5440 | Event listener | `labSelectedRestoreBack.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5447 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5457 | Event listener | `labRunSelectedRestore.addEventListener("click", runLabSelectedRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5463 | Event listener | `restoreModalClose.addEventListener("click", closeRestoreOptionsModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5468 | Event listener | `restoreModalOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5476 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5487 | Event listener | `button.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5496 | Event listener | `selectedRestoreModalClose.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5504 | Event listener | `selectedRestoreModalOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5512 | Event listener | `button.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5531 | Event listener | `selectedRestoreConfirmClose.addEventListener("click", () => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5539 | Event listener | `selectedRestoreConfirmCancel.addEventListener("click", closeSelectedRestoreConfirmModal);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5544 | Event listener | `selectedRestoreConfirmRun.addEventListener("click", runSelectedFileLiveRestore);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5549 | Event listener | `selectedRestoreConfirmOverlay.addEventListener("click", (event) => {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5558 | Event listener | `simTestButton.addEventListener("click", runControlCenterSimulatedTest);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5563 | Event listener | `realTestPlaceholder.addEventListener("click", showControlCenterLiveTestNotes);` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5586 | HTML id | `cc-load-graph-modal` | `<div class="cc-modal-backdrop" id="cc-load-graph-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5590 | HTML id | `cc-load-graph-title` | `<div class="cc-modal-title" id="cc-load-graph-title">UPS Load History</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5591 | HTML id | `cc-load-graph-subtitle` | `<div class="cc-modal-note" id="cc-load-graph-subtitle">Rolling in-browser load history for selected UPS.</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5593 | HTML id | `cc-close-load-graph` | `<button class="cc-btn" id="cc-close-load-graph">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5593 | Button | `<button class="cc-btn" id="cc-close-load-graph">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5595 | HTML id | `cc-load-graph-canvas` | `<canvas class="cc-load-graph" id="cc-load-graph-canvas" width="900" height="320"></canvas>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5602 | HTML id | `cc-rack-overview-modal` | `<div class="cc-modal-backdrop" id="cc-rack-overview-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5609 | HTML id | `cc-close-rack-overview` | `<button class="cc-btn" id="cc-close-rack-overview">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5609 | Button | `<button class="cc-btn" id="cc-close-rack-overview">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5626 | HTML id | `cc-rack-table-body` | `<tbody id="cc-rack-table-body">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5634 | HTML id | `cc-real-test-passphrase-overlay` | `<div class="cc-passphrase-overlay" id="cc-real-test-passphrase-overlay" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5637 | HTML id | `cc-real-test-passphrase-warning` | `<div class="cc-passphrase-warning" id="cc-real-test-passphrase-warning">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5640 | HTML id | `cc-real-test-passphrase-input` | `<input class="cc-passphrase-input" id="cc-real-test-passphrase-input" type="password" autocomplete="off" placeholder="Real Test passphrase">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5642 | HTML id | `cc-real-test-passphrase-cancel` | `<button class="cc-btn" id="cc-real-test-passphrase-cancel">Cancel</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5642 | Button | `<button class="cc-btn" id="cc-real-test-passphrase-cancel">Cancel</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5643 | HTML id | `cc-real-test-passphrase-submit` | `<button class="cc-btn cc-btn-danger" id="cc-real-test-passphrase-submit">Run Real Test</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5643 | Button | `<button class="cc-btn cc-btn-danger" id="cc-real-test-passphrase-submit">Run Real Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5648 | HTML id | `cc-config-management-modal` | `<div class="cc-modal-backdrop" id="cc-config-management-modal" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5655 | HTML id | `cc-close-config-management` | `<button class="cc-btn" id="cc-close-config-management">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5655 | Button | `<button class="cc-btn" id="cc-close-config-management">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5667 | HTML id | `cc-restore-modal-overlay` | `<div class="cc-restore-modal-overlay" id="cc-restore-modal-overlay" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5671 | HTML id | `cc-restore-modal-title` | `<div class="cc-restore-modal-title" id="cc-restore-modal-title">Restore from GitHub Options</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5676 | HTML id | `cc-restore-modal-close` | `<button class="cc-btn" type="button" id="cc-restore-modal-close">Close</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5676 | Button | `<button class="cc-btn" type="button" id="cc-restore-modal-close">Close</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5680 | Button | `<button class="cc-restore-option" type="button" data-restore-action="sync-repo">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5685 | Button | `<button class="cc-restore-option" type="button" data-restore-dry-run="all">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5690 | HTML id | `cc-lab-open-selected-restore` | `<button class="cc-restore-option" type="button" id="cc-lab-open-selected-restore">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5690 | Button | `<button class="cc-restore-option" type="button" id="cc-lab-open-selected-restore">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5700 | HTML id | `cc-lab-selected-restore-screen` | `<div class="cc-restore-modal-overlay" id="cc-lab-selected-restore-screen" aria-hidden="true">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5704 | HTML id | `cc-lab-selected-restore-title` | `<div class="cc-restore-modal-title" id="cc-lab-selected-restore-title">Restore Selected File</div>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5709 | HTML id | `cc-lab-selected-restore-back` | `<button class="cc-btn" type="button" id="cc-lab-selected-restore-back">Back</button>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5709 | Button | `<button class="cc-btn" type="button" id="cc-lab-selected-restore-back">Back</button>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5720 | HTML id | `cc-lab-restore-item-dropdown` | `<select id="cc-lab-restore-item-dropdown" class="cc-input" style="width:100%; margin-top:.45rem;">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5725 | Button | `<button class="cc-btn" type="button"` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5738 | HTML id | `cc-lab-restore-confirm-panel` | `<div class="cc-card" id="cc-lab-restore-confirm-panel" style="display:none; margin-top:1rem;">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5740 | HTML id | `cc-lab-restore-confirm-title` | `<h3 id="cc-lab-restore-confirm-title" style="margin:.35rem 0 .5rem;">Selected item</h3>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5741 | HTML id | `cc-lab-restore-confirm-id` | `<p id="cc-lab-restore-confirm-id" style="color:rgba(255,255,255,.66); margin-top:0;"></p>` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5745 | HTML id | `cc-lab-restore-confirm-input` | `id="cc-lab-restore-confirm-input"` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5759 | HTML id | `cc-lab-run-selected-restore` | `<button class="cc-btn cc-btn-danger" type="button" id="cc-lab-run-selected-restore">` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5759 | Button | `<button class="cc-btn cc-btn-danger" type="button" id="cc-lab-run-selected-restore">` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5769 | Event listener | `document.addEventListener("DOMContentLoaded", function () {` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 5775 | Event listener | `openButton.addEventListener("click", function () {` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 11 | HTML id | `toast-wrap` | `<div class="nutui-toast-wrap" id="toast-wrap"></div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 21 | HTML id | `btn-sim-test` | `<button class="nutui-btn nutui-btn-secondary" id="btn-sim-test">Simulated Test</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 21 | Button | `<button class="nutui-btn nutui-btn-secondary" id="btn-sim-test">Simulated Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 22 | HTML id | `btn-real-test` | `<button class="nutui-btn nutui-btn-warn" id="btn-real-test">Real Test</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 22 | Button | `<button class="nutui-btn nutui-btn-warn" id="btn-real-test">Real Test</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 23 | HTML id | `btn-backup-github` | `<button class="nutui-btn nutui-btn-primary" id="btn-backup-github">Backup All to GitHub</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 23 | Button | `<button class="nutui-btn nutui-btn-primary" id="btn-backup-github">Backup All to GitHub</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 24 | HTML id | `btn-restore-github` | `<button class="nutui-btn nutui-btn-secondary" id="btn-restore-github">Restore from GitHub</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 24 | Button | `<button class="nutui-btn nutui-btn-secondary" id="btn-restore-github">Restore from GitHub</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 29 | HTML id | `top-status` | `<div class="nutui-statusbar" id="top-status">` |
| `opt/nut-orchestrator-ui/templates/index.html` | 30 | HTML id | `top-spinner` | `<span class="nutui-spinner" id="top-spinner"></span>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 31 | HTML id | `top-status-text` | `<span id="top-status-text">Loading approved configs...</span>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 37 | HTML id | `config-select` | `<select class="nutui-select" id="config-select">` |
| `opt/nut-orchestrator-ui/templates/index.html` | 46 | HTML id | `reference-select` | `<select class="nutui-select" id="reference-select">` |
| `opt/nut-orchestrator-ui/templates/index.html` | 56 | HTML id | `meta-path` | `<div class="v" id="meta-path">-</div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 60 | HTML id | `meta-type` | `<div class="v" id="meta-type">-</div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 64 | HTML id | `meta-status` | `<div class="v" id="meta-status">Ready</div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 74 | HTML id | `editor-title` | `<div class="nutui-pane-title" id="editor-title">Config Editor</div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 75 | HTML id | `editor-subtitle` | `<div class="nutui-pane-subtitle" id="editor-subtitle">Select a live config to load and edit its current server content.</div>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 78 | HTML id | `btn-load` | `<button class="nutui-btn nutui-btn-secondary" id="btn-load">Reload</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 78 | Button | `<button class="nutui-btn nutui-btn-secondary" id="btn-load">Reload</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 79 | HTML id | `btn-validate` | `<button class="nutui-btn nutui-btn-warn" id="btn-validate">Validate</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 79 | Button | `<button class="nutui-btn nutui-btn-warn" id="btn-validate">Validate</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 80 | HTML id | `btn-save` | `<button class="nutui-btn nutui-btn-primary" id="btn-save">Save</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 80 | Button | `<button class="nutui-btn nutui-btn-primary" id="btn-save">Save</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 81 | HTML id | `btn-revert` | `<button class="nutui-btn nutui-btn-danger" id="btn-revert">Revert</button>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 81 | Button | `<button class="nutui-btn nutui-btn-danger" id="btn-revert">Revert</button>` | `` |
| `opt/nut-orchestrator-ui/templates/index.html` | 85 | HTML id | `config-editor` | `<textarea class="nutui-editor" id="config-editor" spellcheck="false"></textarea>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 102 | HTML id | `reference-viewer` | `<textarea class="nutui-editor" id="reference-viewer" spellcheck="false" readonly></textarea>` |
| `opt/nut-orchestrator-ui/templates/index.html` | 108 | HTML id | `action-output` | `<div class="nutui-output" id="action-output"></div>` |
| `var/www/html/index.html` | 212 | HTML id | `about` | `<div id="about"></div>` |
| `var/www/html/index.html` | 238 | HTML id | `changes` | `<div id="changes"></div>` |
| `var/www/html/index.html` | 321 | HTML id | `docroot` | `<div id="docroot"></div>` |
| `var/www/html/index.html` | 342 | HTML id | `bugs` | `<div id="bugs"></div>` |
| `var/www/html/nutserver-dashboard.html` | 279 | HTML id | `deviceModel` | `<div class="subtle" id="deviceModel">Loading UPS model...</div>` |
| `var/www/html/nutserver-dashboard.html` | 283 | HTML id | `clock` | `<div id="clock">--:--:--</div>` |
| `var/www/html/nutserver-dashboard.html` | 284 | HTML id | `dateLine` | `<div id="dateLine">Loading date...</div>` |
| `var/www/html/nutserver-dashboard.html` | 285 | HTML id | `countdown` | `<div class="refresh-note">Refresh countdown: <span id="countdown">30</span>s</div>` |
| `var/www/html/nutserver-dashboard.html` | 289 | HTML id | `statusBox` | `<div id="statusBox" class="alert-box alert-ok">Loading...</div>` |
| `var/www/html/nutserver-dashboard.html` | 294 | HTML id | `selectedUpsLabel` | `<div class="big-value" id="selectedUpsLabel">ups1</div>` |
| `var/www/html/nutserver-dashboard.html` | 300 | HTML id | `batteryCharge` | `<div class="big-value" id="batteryCharge">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 305 | HTML id | `upsLoad` | `<div class="big-value" id="upsLoad">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 310 | HTML id | `runtime` | `<div class="big-value" id="runtime">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 315 | HTML id | `tempF` | `<div class="big-value" id="tempF">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 320 | HTML id | `inputVoltage` | `<div class="big-value" id="inputVoltage">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 325 | HTML id | `outputVoltage` | `<div class="big-value" id="outputVoltage">--</div>` |
| `var/www/html/nutserver-dashboard.html` | 333 | HTML id | `loadChart` | `<canvas id="loadChart" width="900" height="280"></canvas>` |
| `var/www/html/nutserver-dashboard.html` | 338 | HTML id | `triviaBox` | `<div id="triviaBox" style="font-size:15px; line-height:1.6;">Loading trivia...</div>` |
| `var/www/html/nutserver-dashboard.html` | 348 | HTML id | `lastBootSummary` | `<div id="lastBootSummary" style="font-size:15px; margin-bottom:10px;">Loading boot event summary...</div>` |
| `var/www/html/nutserver-dashboard.html` | 349 | HTML id | `outageLogBox` | `<div id="outageLogBox" style="font-size:14px; line-height:1.5; max-height:220px; overflow-y:auto; white-space:pre-line;">` |
| `var/www/html/nutserver-dashboard.html` | 370 | HTML id | `upsTableBody` | `<tbody id="upsTableBody">` |
| `var/www/html/nutserver-dashboard.html` | 373 | HTML id | `tblRack-ups1` | `<td id="tblRack-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 374 | HTML id | `tblModel-ups1` | `<td id="tblModel-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 375 | HTML id | `tblStatus-ups1` | `<td id="tblStatus-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 376 | HTML id | `tblBattery-ups1` | `<td id="tblBattery-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 377 | HTML id | `tblLoad-ups1` | `<td id="tblLoad-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 378 | HTML id | `tblVoltage-ups1` | `<td id="tblVoltage-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 382 | HTML id | `tblRack-ups2` | `<td id="tblRack-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 383 | HTML id | `tblModel-ups2` | `<td id="tblModel-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 384 | HTML id | `tblStatus-ups2` | `<td id="tblStatus-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 385 | HTML id | `tblBattery-ups2` | `<td id="tblBattery-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 386 | HTML id | `tblLoad-ups2` | `<td id="tblLoad-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 387 | HTML id | `tblVoltage-ups2` | `<td id="tblVoltage-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 391 | HTML id | `tblRack-ups3` | `<td id="tblRack-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 392 | HTML id | `tblModel-ups3` | `<td id="tblModel-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 393 | HTML id | `tblStatus-ups3` | `<td id="tblStatus-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 394 | HTML id | `tblBattery-ups3` | `<td id="tblBattery-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 395 | HTML id | `tblLoad-ups3` | `<td id="tblLoad-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 396 | HTML id | `tblVoltage-ups3` | `<td id="tblVoltage-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 400 | HTML id | `tblRack-ups4` | `<td id="tblRack-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 401 | HTML id | `tblModel-ups4` | `<td id="tblModel-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 402 | HTML id | `tblStatus-ups4` | `<td id="tblStatus-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 403 | HTML id | `tblBattery-ups4` | `<td id="tblBattery-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 404 | HTML id | `tblLoad-ups4` | `<td id="tblLoad-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 405 | HTML id | `tblVoltage-ups4` | `<td id="tblVoltage-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 409 | HTML id | `tblRack-ups5` | `<td id="tblRack-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 410 | HTML id | `tblModel-ups5` | `<td id="tblModel-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 411 | HTML id | `tblStatus-ups5` | `<td id="tblStatus-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 412 | HTML id | `tblBattery-ups5` | `<td id="tblBattery-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 413 | HTML id | `tblLoad-ups5` | `<td id="tblLoad-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 414 | HTML id | `tblVoltage-ups5` | `<td id="tblVoltage-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 418 | HTML id | `tblRack-ups6` | `<td id="tblRack-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 419 | HTML id | `tblModel-ups6` | `<td id="tblModel-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 420 | HTML id | `tblStatus-ups6` | `<td id="tblStatus-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 421 | HTML id | `tblBattery-ups6` | `<td id="tblBattery-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 422 | HTML id | `tblLoad-ups6` | `<td id="tblLoad-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 423 | HTML id | `tblVoltage-ups6` | `<td id="tblVoltage-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 427 | HTML id | `tblRack-ups7` | `<td id="tblRack-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 428 | HTML id | `tblModel-ups7` | `<td id="tblModel-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 429 | HTML id | `tblStatus-ups7` | `<td id="tblStatus-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 430 | HTML id | `tblBattery-ups7` | `<td id="tblBattery-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 431 | HTML id | `tblLoad-ups7` | `<td id="tblLoad-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 432 | HTML id | `tblVoltage-ups7` | `<td id="tblVoltage-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 436 | HTML id | `tblRack-ups8` | `<td id="tblRack-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 437 | HTML id | `tblModel-ups8` | `<td id="tblModel-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 438 | HTML id | `tblStatus-ups8` | `<td id="tblStatus-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 439 | HTML id | `tblBattery-ups8` | `<td id="tblBattery-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 440 | HTML id | `tblLoad-ups8` | `<td id="tblLoad-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 441 | HTML id | `tblVoltage-ups8` | `<td id="tblVoltage-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 445 | HTML id | `tblRack-ups9` | `<td id="tblRack-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 446 | HTML id | `tblModel-ups9` | `<td id="tblModel-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 447 | HTML id | `tblStatus-ups9` | `<td id="tblStatus-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 448 | HTML id | `tblBattery-ups9` | `<td id="tblBattery-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 449 | HTML id | `tblLoad-ups9` | `<td id="tblLoad-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 450 | HTML id | `tblVoltage-ups9` | `<td id="tblVoltage-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.html` | 489 | JavaScript function | `secondsToReadable` | `function secondsToReadable(sec) {` |
| `var/www/html/nutserver-dashboard.html` | 497 | JavaScript function | `updateClock` | `function updateClock() {` |
| `var/www/html/nutserver-dashboard.html` | 515 | JavaScript function | `reorderUpsRows` | `function reorderUpsRows() {` |
| `var/www/html/nutserver-dashboard.html` | 523 | JavaScript function | `loadRackMap` | `async function loadRackMap() {` |
| `var/www/html/nutserver-dashboard.html` | 525 | API/fetch reference | `const res = await fetch("ups-rack-map.txt?v=" + Date.now(), { cache: "no-store" });` | `` |
| `var/www/html/nutserver-dashboard.html` | 543 | JavaScript function | `drawChart` | `function drawChart() {` |
| `var/www/html/nutserver-dashboard.html` | 585 | JavaScript function | `updateTrivia` | `function updateTrivia() {` |
| `var/www/html/nutserver-dashboard.html` | 590 | JavaScript function | `mapDisplayStatus` | `function mapDisplayStatus(statusRaw) {` |
| `var/www/html/nutserver-dashboard.html` | 606 | JavaScript function | `markUpsOffline` | `function markUpsOffline(upsName) {` |
| `var/www/html/nutserver-dashboard.html` | 639 | JavaScript function | `applySelectedUPSDetails` | `function applySelectedUPSDetails() {` |
| `var/www/html/nutserver-dashboard.html` | 707 | JavaScript function | `setSelectedRowVisual` | `function setSelectedRowVisual() {` |
| `var/www/html/nutserver-dashboard.html` | 716 | JavaScript function | `updateTableRow` | `function updateTableRow(upsName, data) {` |
| `var/www/html/nutserver-dashboard.html` | 742 | JavaScript function | `fetchUpsData` | `async function fetchUpsData(upsName) {` |
| `var/www/html/nutserver-dashboard.html` | 744 | API/fetch reference | `const resp = await fetch("/cgi-bin/nut/upsjson.sh?ups=" + encodeURIComponent(upsName) + "&_=" + Date.now());` | `` |
| `var/www/html/nutserver-dashboard.html` | 771 | JavaScript function | `refreshAllUPS` | `function refreshAllUPS() {` |
| `var/www/html/nutserver-dashboard.html` | 775 | JavaScript function | `tickCountdown` | `function tickCountdown() {` |
| `var/www/html/nutserver-dashboard.html` | 787 | JavaScript function | `initRowSelection` | `function initRowSelection() {` |
| `var/www/html/nutserver-dashboard.html` | 789 | Event listener | `row.addEventListener("click", () => {` | `` |
| `var/www/html/nutserver-dashboard.html` | 800 | JavaScript function | `loadOutageLog` | `async function loadOutageLog() {` |
| `var/www/html/nutserver-dashboard.html` | 802 | API/fetch reference | `const resp = await fetch("nut-outage-log.json?v=" + Date.now(), { cache: "no-store" });` | `` |
| `var/www/html/nutserver-dashboard.html` | 838 | JavaScript function | `autoCycleSelectedUPS` | `function autoCycleSelectedUPS() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 325 | HTML id | `deviceModel` | `<div class="subtle" id="deviceModel">Loading UPS model...</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 329 | HTML id | `clock` | `<div id="clock">--:--:--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 330 | HTML id | `dateLine` | `<div id="dateLine">Loading date...</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 331 | HTML id | `countdown` | `<div class="refresh-note">Refresh countdown: <span id="countdown">30</span>s</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 335 | HTML id | `statusBox` | `<div id="statusBox" class="alert-box alert-ok">Loading...</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 340 | HTML id | `selectedUpsLabel` | `<div class="big-value" id="selectedUpsLabel">ups1</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 346 | HTML id | `batteryCharge` | `<div class="big-value" id="batteryCharge">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 351 | HTML id | `upsLoad` | `<div class="big-value" id="upsLoad">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 356 | HTML id | `runtime` | `<div class="big-value" id="runtime">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 361 | HTML id | `tempF` | `<div class="big-value" id="tempF">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 366 | HTML id | `inputVoltage` | `<div class="big-value" id="inputVoltage">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 371 | HTML id | `outputVoltage` | `<div class="big-value" id="outputVoltage">--</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 379 | HTML id | `loadChart` | `<canvas id="loadChart" width="900" height="280"></canvas>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 385 | HTML id | `nut-ui-trivia-launcher` | `<div id="nut-ui-trivia-launcher" style="margin: 14px 0 18px 0;">` |
| `var/www/html/nutserver-dashboard.priority1.html` | 392 | HTML id | `triviaBox` | `<div id="triviaBox" style="font-size:15px; line-height:1.6;">Loading trivia...</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 402 | HTML id | `lastBootSummary` | `<div id="lastBootSummary" style="font-size:15px; margin-bottom:10px;">Loading boot event summary...</div>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 403 | HTML id | `outageLogBox` | `<div id="outageLogBox" style="font-size:14px; line-height:1.5; max-height:220px; overflow-y:auto; white-space:pre-line;">` |
| `var/www/html/nutserver-dashboard.priority1.html` | 424 | HTML id | `upsTableBody` | `<tbody id="upsTableBody">` |
| `var/www/html/nutserver-dashboard.priority1.html` | 427 | HTML id | `tblRack-ups1` | `<td id="tblRack-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 428 | HTML id | `tblModel-ups1` | `<td id="tblModel-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 429 | HTML id | `tblStatus-ups1` | `<td id="tblStatus-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 430 | HTML id | `tblBattery-ups1` | `<td id="tblBattery-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 431 | HTML id | `tblLoad-ups1` | `<td id="tblLoad-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 432 | HTML id | `tblVoltage-ups1` | `<td id="tblVoltage-ups1">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 436 | HTML id | `tblRack-ups2` | `<td id="tblRack-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 437 | HTML id | `tblModel-ups2` | `<td id="tblModel-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 438 | HTML id | `tblStatus-ups2` | `<td id="tblStatus-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 439 | HTML id | `tblBattery-ups2` | `<td id="tblBattery-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 440 | HTML id | `tblLoad-ups2` | `<td id="tblLoad-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 441 | HTML id | `tblVoltage-ups2` | `<td id="tblVoltage-ups2">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 445 | HTML id | `tblRack-ups3` | `<td id="tblRack-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 446 | HTML id | `tblModel-ups3` | `<td id="tblModel-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 447 | HTML id | `tblStatus-ups3` | `<td id="tblStatus-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 448 | HTML id | `tblBattery-ups3` | `<td id="tblBattery-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 449 | HTML id | `tblLoad-ups3` | `<td id="tblLoad-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 450 | HTML id | `tblVoltage-ups3` | `<td id="tblVoltage-ups3">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 454 | HTML id | `tblRack-ups4` | `<td id="tblRack-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 455 | HTML id | `tblModel-ups4` | `<td id="tblModel-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 456 | HTML id | `tblStatus-ups4` | `<td id="tblStatus-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 457 | HTML id | `tblBattery-ups4` | `<td id="tblBattery-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 458 | HTML id | `tblLoad-ups4` | `<td id="tblLoad-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 459 | HTML id | `tblVoltage-ups4` | `<td id="tblVoltage-ups4">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 463 | HTML id | `tblRack-ups5` | `<td id="tblRack-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 464 | HTML id | `tblModel-ups5` | `<td id="tblModel-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 465 | HTML id | `tblStatus-ups5` | `<td id="tblStatus-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 466 | HTML id | `tblBattery-ups5` | `<td id="tblBattery-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 467 | HTML id | `tblLoad-ups5` | `<td id="tblLoad-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 468 | HTML id | `tblVoltage-ups5` | `<td id="tblVoltage-ups5">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 472 | HTML id | `tblRack-ups6` | `<td id="tblRack-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 473 | HTML id | `tblModel-ups6` | `<td id="tblModel-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 474 | HTML id | `tblStatus-ups6` | `<td id="tblStatus-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 475 | HTML id | `tblBattery-ups6` | `<td id="tblBattery-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 476 | HTML id | `tblLoad-ups6` | `<td id="tblLoad-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 477 | HTML id | `tblVoltage-ups6` | `<td id="tblVoltage-ups6">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 481 | HTML id | `tblRack-ups7` | `<td id="tblRack-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 482 | HTML id | `tblModel-ups7` | `<td id="tblModel-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 483 | HTML id | `tblStatus-ups7` | `<td id="tblStatus-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 484 | HTML id | `tblBattery-ups7` | `<td id="tblBattery-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 485 | HTML id | `tblLoad-ups7` | `<td id="tblLoad-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 486 | HTML id | `tblVoltage-ups7` | `<td id="tblVoltage-ups7">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 490 | HTML id | `tblRack-ups8` | `<td id="tblRack-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 491 | HTML id | `tblModel-ups8` | `<td id="tblModel-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 492 | HTML id | `tblStatus-ups8` | `<td id="tblStatus-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 493 | HTML id | `tblBattery-ups8` | `<td id="tblBattery-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 494 | HTML id | `tblLoad-ups8` | `<td id="tblLoad-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 495 | HTML id | `tblVoltage-ups8` | `<td id="tblVoltage-ups8">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 499 | HTML id | `tblRack-ups9` | `<td id="tblRack-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 500 | HTML id | `tblModel-ups9` | `<td id="tblModel-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 501 | HTML id | `tblStatus-ups9` | `<td id="tblStatus-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 502 | HTML id | `tblBattery-ups9` | `<td id="tblBattery-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 503 | HTML id | `tblLoad-ups9` | `<td id="tblLoad-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 504 | HTML id | `tblVoltage-ups9` | `<td id="tblVoltage-ups9">--</td>` |
| `var/www/html/nutserver-dashboard.priority1.html` | 543 | JavaScript function | `secondsToReadable` | `function secondsToReadable(sec) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 551 | JavaScript function | `updateClock` | `function updateClock() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 569 | JavaScript function | `reorderUpsRows` | `function reorderUpsRows() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 577 | JavaScript function | `loadRackMap` | `async function loadRackMap() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 579 | API/fetch reference | `const res = await fetch("ups-rack-map.txt?v=" + Date.now(), { cache: "no-store" });` | `` |
| `var/www/html/nutserver-dashboard.priority1.html` | 597 | JavaScript function | `drawChart` | `function drawChart() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 639 | JavaScript function | `updateTrivia` | `function updateTrivia() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 644 | JavaScript function | `mapDisplayStatus` | `function mapDisplayStatus(statusRaw) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 660 | JavaScript function | `markUpsOffline` | `function markUpsOffline(upsName) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 693 | JavaScript function | `applySelectedUPSDetails` | `function applySelectedUPSDetails() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 761 | JavaScript function | `setSelectedRowVisual` | `function setSelectedRowVisual() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 770 | JavaScript function | `updateTableRow` | `function updateTableRow(upsName, data) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 796 | JavaScript function | `fetchUpsData` | `async function fetchUpsData(upsName) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 798 | API/fetch reference | `const resp = await fetch("/cgi-bin/nut/upsjson.sh?ups=" + encodeURIComponent(upsName) + "&_=" + Date.now());` | `` |
| `var/www/html/nutserver-dashboard.priority1.html` | 825 | JavaScript function | `refreshAllUPS` | `function refreshAllUPS() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 829 | JavaScript function | `tickCountdown` | `function tickCountdown() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 841 | JavaScript function | `initRowSelection` | `function initRowSelection() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 843 | Event listener | `row.addEventListener("click", () => {` | `` |
| `var/www/html/nutserver-dashboard.priority1.html` | 854 | JavaScript function | `loadOutageLog` | `async function loadOutageLog() {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 856 | API/fetch reference | `const resp = await fetch("nut-power-events.json?v=" + Date.now(), { cache: "no-store" });` | `` |
| `var/www/html/nutserver-dashboard.priority1.html` | 898 | JavaScript function | `parseLine` | `function parseLine(line) {` |
| `var/www/html/nutserver-dashboard.priority1.html` | 985 | JavaScript function | `autoCycleSelectedUPS` | `function autoCycleSelectedUPS() {` |

---

## 10. Every Shell Script and Shell Function

This section is generated from `/tmp/nut-architecture-inventory/05_shell_scripts_functions.tsv`.

It includes:

- Main orchestrator script
- Shutdown wrappers
- Backup helpers
- Restore helpers
- Email helpers
- Protection mode helpers
- APC IDF monitor scripts
- Shell functions inside those scripts

Use this section when trying to find where a shell workflow starts, what helper script owns a function, or which wrapper is responsible for a target action.

| File | Line | Type | Name | Code / context |
|---|---:|---|---|---|
| `usr/local/bin/nut-orchestrator.sh` | 1 | Script file | `nut-orchestrator.sh` | `` |
| `usr/local/bin/nut-orchestrator.sh` | 15 | Shell function | `ts` | `ts() {` |
| `usr/local/bin/nut-orchestrator.sh` | 19 | Shell function | `log_line` | `log_line() {` |
| `usr/local/bin/nut-orchestrator.sh` | 31 | Shell function | `write_state` | `write_state() {` |
| `usr/local/bin/nut-orchestrator.sh` | 62 | Shell function | `production_mode_allows_commit` | `production_mode_allows_commit() {` |
| `usr/local/bin/nut-orchestrator.sh` | 92 | Shell function | `run_phase2_power_restore_abort` | `run_phase2_power_restore_abort() {` |
| `usr/local/bin/nut-orchestrator.sh` | 119 | Shell function | `commit_placeholder` | `commit_placeholder() {` |
| `usr/local/bin/nut-orchestrator.sh` | 278 | Shell function | `email_ups_from_reason` | `email_ups_from_reason() {` |
| `usr/local/bin/nut-orchestrator.sh` | 282 | Shell function | `email_mark_outage_start` | `email_mark_outage_start() {` |
| `usr/local/bin/nut-orchestrator.sh` | 288 | Shell function | `email_duration_for_ups` | `email_duration_for_ups() {` |
| `usr/local/bin/nut-orchestrator.sh` | 318 | Shell function | `email_context_for_type` | `email_context_for_type() {` |
| `usr/local/bin/nut-orchestrator.sh` | 366 | Shell function | `send_outage_email` | `send_outage_email() {` |
| `usr/local/bin/nut-test-logic.sh` | 1 | Script file | `nut-test-logic.sh` | `` |
| `usr/local/sbin/__pycache__/nut-production-statuscpython-312.pyc` | 1 | Script file | `nut-production-statuscpython-312.pyc` | `` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 1 | Script file | `nut-apc-idf-event-monitor.sh` | `` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 14 | Shell function | `timestamp` | `timestamp() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 18 | Shell function | `log_event` | `log_event() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 25 | Shell function | `publish_events` | `publish_events() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 31 | Shell function | `safe_name` | `safe_name() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 35 | Shell function | `sanitize_log_field` | `sanitize_log_field() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 39 | Shell function | `init_paths` | `init_paths() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 45 | Shell function | `load_credentials` | `load_credentials() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 62 | Shell function | `read_count` | `read_count() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 71 | Shell function | `write_count` | `write_count() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 78 | Shell function | `record_failure` | `record_failure() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 96 | Shell function | `record_success` | `record_success() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 118 | Shell function | `try_logout` | `try_logout() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 131 | Shell function | `fetch_apc_event_txt` | `fetch_apc_event_txt() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 236 | Shell function | `extract_relevant_events` | `extract_relevant_events() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 269 | Shell function | `event_severity_for_message` | `event_severity_for_message() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 285 | Shell function | `get_snmp_community_candidate` | `get_snmp_community_candidate() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 297 | Shell function | `idf_current_status_message` | `idf_current_status_message() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 317 | Shell function | `log_current_power_state` | `log_current_power_state() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 358 | Shell function | `monitor_target` | `monitor_target() {` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 452 | Shell function | `main` | `main() {` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | 1 | Script file | `nut-blueiris-shutdown.sh` | `` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | 13 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | 17 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | 21 | Shell function | `classify_target` | `classify_target() {` |
| `usr/local/sbin/nut-boot-event-log.sh` | 1 | Script file | `nut-boot-event-log.sh` | `` |
| `usr/local/sbin/nut-classify-shutdown-result` | 1 | Script file | `nut-classify-shutdown-result` | `` |
| `usr/local/sbin/nut-classify-target-shutdown` | 1 | Script file | `nut-classify-target-shutdown` | `` |
| `usr/local/sbin/nut-db-shutdown.sh` | 1 | Script file | `nut-db-shutdown.sh` | `` |
| `usr/local/sbin/nut-db-shutdown.sh` | 16 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 20 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 24 | Shell function | `get_live_actions_allowed` | `get_live_actions_allowed() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 33 | Shell function | `load_db_config` | `load_db_config() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 53 | Shell function | `validate_common_config` | `validate_common_config() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 86 | Shell function | `resolve_target_host` | `resolve_target_host() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 106 | Shell function | `run_telnet_shutdown` | `run_telnet_shutdown() {` |
| `usr/local/sbin/nut-db-shutdown.sh` | 179 | Shell function | `run_ssh_shutdown` | `run_ssh_shutdown() {` |
| `usr/local/sbin/nut-email-alert-test-send` | 1 | Script file | `nut-email-alert-test-send` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 9 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` | 1 | Script file | `nut-esxi-ssh-readonly-preflight.sh` | `` |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` | 21 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` | 25 | Shell function | `run_readonly` | `run_readonly() {` |
| `usr/local/sbin/nut-export-test-logs` | 1 | Script file | `nut-export-test-logs` | `` |
| `usr/local/sbin/nut-fix-sockets.sh` | 1 | Script file | `nut-fix-sockets.sh` | `` |
| `usr/local/sbin/nut-get-power-events-json` | 1 | Script file | `nut-get-power-events-json` | `` |
| `usr/local/sbin/nut-get-verification-target` | 1 | Script file | `nut-get-verification-target` | `` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 1 | Script file | `nut-hypervisor-ssh-readonly-preflight.sh` | `` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 15 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 29 | Shell function | `run_ssh_readonly` | `run_ssh_readonly() {` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 57 | Shell function | `run_esxi_host` | `run_esxi_host() {` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 67 | Shell function | `run_proxmox_host` | `run_proxmox_host() {` |
| `usr/local/sbin/nut-inventory-configs.sh` | 1 | Script file | `nut-inventory-configs.sh` | `` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 1 | Script file | `nut-lansweeper-shutdown.sh` | `` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 15 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 19 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 23 | Shell function | `power_event` | `power_event() {` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 29 | Shell function | `publish_power_events` | `publish_power_events() {` |
| `usr/local/sbin/nut-local-final-shutdown.sh` | 1 | Script file | `nut-local-final-shutdown.sh` | `` |
| `usr/local/sbin/nut-local-final-shutdown.sh` | 11 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-local-final-shutdown.sh` | 15 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-local-final-shutdown.sh` | 19 | Shell function | `power_event` | `power_event() {` |
| `usr/local/sbin/nut-netapp-halt.sh` | 1 | Script file | `nut-netapp-halt.sh` | `` |
| `usr/local/sbin/nut-netapp-halt.sh` | 9 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-netapp-halt.sh` | 13 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-netapp-halt.sh` | 17 | Shell function | `classify_name` | `classify_name() {` |
| `usr/local/sbin/nut-netapp-halt.sh` | 31 | Shell function | `power_classification` | `power_classification() {` |
| `usr/local/sbin/nut-power-event-log` | 1 | Script file | `nut-power-event-log` | `` |
| `usr/local/sbin/nut-production-mode` | 1 | Script file | `nut-production-mode` | `` |
| `usr/local/sbin/nut-production-mode` | 11 | Shell function | `set_hypervisor_fallback_enabled` | `set_hypervisor_fallback_enabled() {` |
| `usr/local/sbin/nut-production-mode` | 56 | Shell function | `unit_exists` | `unit_exists() {` |
| `usr/local/sbin/nut-production-mode` | 61 | Shell function | `mode_label` | `mode_label() {` |
| `usr/local/sbin/nut-production-mode` | 72 | Shell function | `current_configured_mode` | `current_configured_mode() {` |
| `usr/local/sbin/nut-production-mode` | 80 | Shell function | `log_mode_change_event` | `log_mode_change_event() {` |
| `usr/local/sbin/nut-production-mode` | 101 | Shell function | `ensure_monitoring_active` | `ensure_monitoring_active() {` |
| `usr/local/sbin/nut-production-mode` | 122 | Shell function | `ensure_monitoring_stopped` | `ensure_monitoring_stopped() {` |
| `usr/local/sbin/nut-production-mode` | 140 | Shell function | `write_mode` | `write_mode() {` |
| `usr/local/sbin/nut-production-status` | 1 | Script file | `nut-production-status` | `` |
| `usr/local/sbin/nut-publish-power-events-json` | 1 | Script file | `nut-publish-power-events-json` | `` |
| `usr/local/sbin/nut-rebuild-msmtp-from-email-config` | 1 | Script file | `nut-rebuild-msmtp-from-email-config` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 1 | Script file | `nut-run-backup-and-push.sh` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 19 | Shell function | `run_git` | `run_git() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 27 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 31 | Shell function | `require_cmd` | `require_cmd() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 38 | Shell function | `repo_has_changes` | `repo_has_changes() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 54 | Shell function | `fail_if_repo_has_secrets` | `fail_if_repo_has_secrets() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 86 | Shell function | `commit_pending_repo_changes_before_pull` | `commit_pending_repo_changes_before_pull() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 110 | Shell function | `copy_text_file` | `copy_text_file() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 127 | Shell function | `copy_executable_file` | `copy_executable_file() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 143 | Shell function | `copy_sanitized_config_file` | `copy_sanitized_config_file() {` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 163 | Shell function | `main` | `main() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 1 | Script file | `nut-sync-live-to-repo-for-backup` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 16 | Shell function | `is_secret_path` | `is_secret_path() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 34 | Shell function | `is_temp_artifact` | `is_temp_artifact() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 49 | Shell function | `repo_relative_path` | `repo_relative_path() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 54 | Shell function | `copy_file` | `copy_file() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 78 | Shell function | `copy_exec` | `copy_exec() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 102 | Shell function | `sanitize_config_file` | `sanitize_config_file() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 127 | Shell function | `sync_registry_managed_files` | `sync_registry_managed_files() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 180 | Shell function | `sync_directory_safe_files` | `sync_directory_safe_files() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 211 | Shell function | `sync_glob_execs` | `sync_glob_execs() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 225 | Shell function | `sync_glob_files` | `sync_glob_files() {` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 262 | Shell function | `sanitize_upsmon_file` | `sanitize_upsmon_file() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 1 | Script file | `nut-synology-shutdown.sh` | `` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 9 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 13 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 17 | Shell function | `power_classification` | `power_classification() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 35 | Shell function | `require_config` | `require_config() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 52 | Shell function | `dsm_login` | `dsm_login() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 64 | Shell function | `extract_sid` | `extract_sid() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 68 | Shell function | `dsm_logout` | `dsm_logout() {` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 85 | Shell function | `dsm_shutdown` | `dsm_shutdown() {` |
| `usr/local/sbin/nut-ui-apply-config` | 1 | Script file | `nut-ui-apply-config` | `` |
| `usr/local/sbin/nut-ui-apply-config` | 10 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-ui-backup-now` | 1 | Script file | `nut-ui-backup-now` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 1 | Script file | `nut-ui-live-restore-dry-run` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 16 | Shell function | `fail` | `fail() {` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 23 | Shell function | `print_menu` | `print_menu() {` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 63 | Shell function | `emit_item` | `emit_item() {` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 93 | Shell function | `emit_all_items` | `emit_all_items() {` |
| `usr/local/sbin/nut-ui-live-restore-selected` | 1 | Script file | `nut-ui-live-restore-selected` | `` |
| `usr/local/sbin/nut-ui-live-restore-selected` | 15 | Shell function | `fail` | `fail() {` |
| `usr/local/sbin/nut-ui-live-restore-selected-dry-run` | 1 | Script file | `nut-ui-live-restore-selected-dry-run` | `` |
| `usr/local/sbin/nut-ui-live-restore-selected-dry-run` | 8 | Shell function | `fail` | `fail() {` |
| `usr/local/sbin/nut-ui-read-config` | 1 | Script file | `nut-ui-read-config` | `` |
| `usr/local/sbin/nut-ui-read-config` | 7 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-ui-read-config` | 29 | Shell function | `redact_secret_lines` | `redact_secret_lines() {` |
| `usr/local/sbin/nut-ui-read-reference` | 1 | Script file | `nut-ui-read-reference` | `` |
| `usr/local/sbin/nut-ui-read-reference` | 7 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-ui-restore-github` | 1 | Script file | `nut-ui-restore-github` | `` |
| `usr/local/sbin/nut-ui-restore-github` | 25 | Shell function | `run_git` | `run_git() {` |
| `usr/local/sbin/nut-ui-restore-github` | 32 | Shell function | `fail` | `fail() {` |
| `usr/local/sbin/nut-ui-restore-github` | 37 | Shell function | `normalize_branch` | `normalize_branch() {` |
| `usr/local/sbin/nut-ui-restore-github` | 43 | Shell function | `validate_branch_name` | `validate_branch_name() {` |
| `usr/local/sbin/nut-ui-restore-github` | 59 | Shell function | `ensure_repo` | `ensure_repo() {` |
| `usr/local/sbin/nut-ui-restore-github` | 63 | Shell function | `fetch_remote` | `fetch_remote() {` |
| `usr/local/sbin/nut-ui-restore-github` | 68 | Shell function | `branch_exists` | `branch_exists() {` |
| `usr/local/sbin/nut-ui-restore-github` | 73 | Shell function | `list_branches` | `list_branches() {` |
| `usr/local/sbin/nut-ui-rollback` | 1 | Script file | `nut-ui-rollback` | `` |
| `usr/local/sbin/nut-ui-rollback` | 9 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-ui-run-real-test-approved` | 1 | Script file | `nut-ui-run-real-test-approved` | `` |
| `usr/local/sbin/nut-ui-run-test` | 1 | Script file | `nut-ui-run-test` | `` |
| `usr/local/sbin/nut-ui-run-test` | 18 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-ui-run-test` | 22 | Shell function | `log_line` | `log_line() {` |
| `usr/local/sbin/nut-ui-run-test` | 26 | Shell function | `power_event` | `power_event() {` |
| `usr/local/sbin/nut-ui-run-test` | 30 | Shell function | `pass` | `pass() {` |
| `usr/local/sbin/nut-ui-run-test` | 35 | Shell function | `fail` | `fail() {` |
| `usr/local/sbin/nut-ui-run-test` | 40 | Shell function | `check_file` | `check_file() {` |
| `usr/local/sbin/nut-ui-run-test` | 51 | Shell function | `check_exec` | `check_exec() {` |
| `usr/local/sbin/nut-ui-run-test` | 62 | Shell function | `validate_managed_configs` | `validate_managed_configs() {` |
| `usr/local/sbin/nut-ui-run-test` | 84 | Shell function | `run_sim_wrapper` | `run_sim_wrapper() {` |
| `usr/local/sbin/nut-ui-run-test` | 114 | Shell function | `run_real_wrapper` | `run_real_wrapper() {` |
| `usr/local/sbin/nut-ui-run-test` | 145 | Shell function | `run_prechecks` | `run_prechecks() {` |
| `usr/local/sbin/nut-ui-run-test` | 172 | Shell function | `run_simulate` | `run_simulate() {` |
| `usr/local/sbin/nut-ui-run-test` | 227 | Shell function | `verify_lansweeper_nut_runtime_access` | `verify_lansweeper_nut_runtime_access() {` |
| `usr/local/sbin/nut-ui-run-test` | 266 | Shell function | `run_real` | `run_real() {` |
| `usr/local/sbin/nut-ui-run-test` | 312 | Shell function | `phase2_cancel` | `phase2_cancel() {` |
| `usr/local/sbin/nut-ups-locator-beep.sh` | 1 | Script file | `nut-ups-locator-beep.sh` | `` |
| `usr/local/sbin/nut-ups-locator-beep.sh` | 72 | Shell function | `run_upscmd` | `run_upscmd() {` |
| `usr/local/sbin/nut-verify-target-down.sh` | 1 | Script file | `nut-verify-target-down.sh` | `` |
| `usr/local/sbin/nut-verify-target-down.sh` | 13 | Shell function | `usage` | `usage() {` |
| `usr/local/sbin/nut-verify-target-down.sh` | 17 | Shell function | `log_line` | `log_line() {` |
| `usr/local/sbin/nut-vmware-export-inventory.sh` | 1 | Script file | `nut-vmware-export-inventory.sh` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 1 | Script file | `nut-vmware-hybrid-dry-run-plan.py` | `` |
| `usr/local/sbin/nut-vmware-readonly-placement.py` | 1 | Script file | `nut-vmware-readonly-placement.py` | `` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 1 | Script file | `nut-vmware-shutdown.sh` | `` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 9 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 13 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 17 | Shell function | `power_classification` | `power_classification() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 87 | Shell function | `require_python` | `require_python() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 93 | Shell function | `run_wave_sim` | `run_wave_sim() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 107 | Shell function | `simulate_shutdown_domain` | `simulate_shutdown_domain() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 130 | Shell function | `vc_api_login` | `vc_api_login() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 153 | Shell function | `vmware_map_lookup` | `vmware_map_lookup() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 176 | Shell function | `vc_api_get_vm_id` | `vc_api_get_vm_id() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 201 | Shell function | `vc_api_guest_shutdown` | `vc_api_guest_shutdown() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 238 | Shell function | `vc_api_detect_vcsa_host` | `vc_api_detect_vcsa_host() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 297 | Shell function | `shutdown_vm_list` | `shutdown_vm_list() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 341 | Shell function | `shutdown_esxi_hosts` | `shutdown_esxi_hosts() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 438 | Shell function | `real_shutdown_domain` | `real_shutdown_domain() {` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 505 | Shell function | `real_detect_vcsa_host` | `real_detect_vcsa_host() {` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 1 | Script file | `nut-vmware-tools-status-report.py` | `` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 1 | Script file | `nut-voip-shutdown.sh` | `` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 10 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 14 | Shell function | `log` | `log() {` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 18 | Shell function | `power_classification` | `power_classification() {` |
| `usr/local/sbin/phase2-power-restore-abort` | 1 | Script file | `phase2-power-restore-abort` | `` |
| `usr/local/sbin/phase2-power-restore-abort` | 8 | Shell function | `ts` | `ts() {` |
| `usr/local/sbin/phase2-power-restore-abort` | 12 | Shell function | `log_all` | `log_all() {` |
| `usr/local/sbin/rollback-remote-access.sh` | 1 | Script file | `rollback-remote-access.sh` | `` |
| `usr/local/sbin/start-x11vnc.sh` | 1 | Script file | `start-x11vnc.sh` | `` |

---

## 11. Config / Service / Log / Mode References

This section is generated from `/tmp/nut-architecture-inventory/06_config_service_log_refs.tsv`.

It includes references to:

- systemd services and timers
- NUT config files
- log files
- event logs
- production mode state
- live-action safety flags
- ESXi fallback flags
- dashboard and Control Center event paths

Use this section when trying to find where a service, log path, mode flag, event file, or NUT config reference appears in the repo.

| File | Line | Type | Name | Reference |
|---|---:|---|---|---|
| `.gitignore` | 58 | Reference | `etc/nut/ups.conf` | `` |
| `docs/ROLLBACK.md` | 26 | Reference | `sudo systemctl stop nut-monitor` | `` |
| `docs/ROLLBACK.md` | 27 | Reference | `sudo systemctl stop nut-server` | `` |
| `docs/nut_backup_inventory.md` | 10 | Reference | `- /etc/nut/upsmon.conf (sanitized)` | `` |
| `docs/nut_backup_inventory.md` | 11 | Reference | `- /etc/nut/upssched.conf` | `` |
| `docs/nut_backup_inventory.md` | 15 | Reference | `- /etc/systemd/system/nut-boot-event-log.service` | `` |
| `docs/nut_backup_inventory.md` | 16 | Reference | `- /etc/systemd/system/nut-fix-sockets.service` | `` |
| `docs/nut_backup_inventory.md` | 17 | Reference | `- /etc/systemd/system/nut-monitor.service.d/override.conf` | `` |
| `docs/nut_backup_inventory.md` | 18 | Reference | `- /etc/systemd/system/tigervnc-backup.service` | `` |
| `docs/nut_backup_inventory.md` | 19 | Reference | `- /etc/systemd/system/x11vnc.service` | `` |
| `docs/nut_backup_inventory.md` | 20 | Reference | `- /etc/systemd/system/nut-driver@.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 21 | Reference | `- /etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 22 | Reference | `- /etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 23 | Reference | `- /etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 24 | Reference | `- /etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 25 | Reference | `- /etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 26 | Reference | `- /etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 27 | Reference | `- /etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 28 | Reference | `- /etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 29 | Reference | `- /etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 30 | Reference | `- /etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 31 | Reference | `- /etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 32 | Reference | `- /etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 33 | Reference | `- /etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 34 | Reference | `- /etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 35 | Reference | `- /etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 36 | Reference | `- /etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 37 | Reference | `- /etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated-checksum.conf` | `` |
| `docs/nut_backup_inventory.md` | 38 | Reference | `- /etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf` | `` |
| `docs/nut_backup_inventory.md` | 49 | Reference | `- /etc/nut/ups.conf` | `` |
| `etc/nut/config.d/nut-orchestrator.conf` | 8 | Reference | `log_dir=/var/log/nut-orchestrator-ui` | `` |
| `etc/nut/config.d/nut-orchestrator.conf.template` | 12 | Reference | `log_dir=/var/log/nut-orchestrator-ui` | `` |
| `etc/nut/config.d/shutdown-verification-targets.conf` | 24 | Reference | `VOIP\|192.168.1.14\|300\|\|/usr/local/sbin/nut-voip-shutdown.sh\|Ubuntu PBX server; SSH root shutdown using systemctl poweroff; ping verification` | `` |
| `etc/nut/config.d/vmware-vm-map.conf` | 7 | Reference | `# /var/log/nut-vmware-inventory/vcenter-inventory-20260512-141229.json` | `` |
| `etc/nut/production-mode.conf` | 10 | Reference | `# off = live actions blocked; monitoring/logging timers, daily email reports, and nut-monitor.service are stopped` | `` |
| `etc/nut/restore/restore-targets.json.template` | 43 | Reference | `"name": "upsmon.conf",` | `` |
| `etc/nut/restore/restore-targets.json.template` | 44 | Reference | `"live_path": "/etc/nut/upsmon.conf",` | `` |
| `etc/nut/restore/restore-targets.json.template` | 45 | Reference | `"repo_source": "/opt/nut-admin/repo-template/etc/nut/upsmon.conf",` | `` |
| `etc/nut/restore/restore-targets.json.template` | 57 | Reference | `"name": "upssched.conf",` | `` |
| `etc/nut/restore/restore-targets.json.template` | 58 | Reference | `"live_path": "/etc/nut/upssched.conf",` | `` |
| `etc/nut/restore/restore-targets.json.template` | 59 | Reference | `"repo_source": "/opt/nut-admin/repo-template/etc/nut/upssched.conf",` | `` |
| `etc/systemd/system/nut-apc-idf-event-monitor.timer` | 9 | Reference | `Unit=nut-apc-idf-event-monitor.service` | `` |
| `etc/systemd/system/nut-boot-event-log.service` | 4 | Reference | `After=network-online.target apache2.service` | `` |
| `etc/systemd/system/nut-daily-health-email.timer` | 9 | Reference | `Unit=nut-daily-health-email.service` | `` |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=systemd-udev.service systemd-udev-settle.service` | `` |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf` | 6 | Reference | `Wants=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf` | 7 | Reference | `After=network-online.target systemd-resolved.service ifplugd.service` | `` |
| `etc/systemd/system/nut-fix-sockets.service` | 4 | Reference | `After=nut-server.service` | `` |
| `etc/systemd/system/nut-fix-sockets.service` | 5 | Reference | `Wants=nut-server.service` | `` |
| `etc/systemd/system/nut-orchestrator-ui.service` | 19 | Reference | `ReadWritePaths=/var/log/nut-orchestrator-ui /var/lib/nut-orchestrator-ui` | `` |
| `etc/systemd/system/nut-power-events-refresh.service` | 4 | Reference | `After=nut-monitor.service apache2.service` | `` |
| `etc/systemd/system/nut-power-events-refresh.service` | 5 | Reference | `Wants=apache2.service` | `` |
| `etc/systemd/system/nut-power-events-refresh.timer` | 9 | Reference | `Unit=nut-power-events-refresh.service` | `` |
| `etc/systemd/system/x11vnc.service` | 4 | Reference | `After=display-manager.service network.target` | `` |
| `etc/systemd/system/x11vnc.service` | 5 | Reference | `Wants=display-manager.service` | `` |
| `opt/nut-orchestrator-ui/app.py` | 853 | Reference | `export_dir = "/var/log/nut-orchestrator-ui/exports"` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 5 | Reference | `"name": "ups.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 6 | Reference | `"path": "/etc/nut/ups.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 33 | Reference | `"name": "upsmon.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 34 | Reference | `"path": "/etc/nut/upsmon.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 47 | Reference | `"name": "upssched.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 48 | Reference | `"path": "/etc/nut/upssched.conf",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 381 | Reference | `"name": "ups.conf.generated (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 382 | Reference | `"path": "/opt/nut-auto/output/ups.conf.generated",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 393 | Reference | `"name": "ups.conf.backup (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 394 | Reference | `"path": "/etc/nut/ups.conf.backup",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 399 | Reference | `"name": "ups.conf.working-2ups (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 400 | Reference | `"path": "/etc/nut/ups.conf.working-2ups",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 405 | Reference | `"name": "ups.conf.working-3ups (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 406 | Reference | `"path": "/etc/nut/ups.conf.working-3ups",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 411 | Reference | `"name": "upsmon.conf.pre-orchestrator (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 412 | Reference | `"path": "/etc/nut/upsmon.conf.pre-orchestrator",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 417 | Reference | `"name": "upssched.conf.pre-orchestrator (reference)",` | `` |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | 418 | Reference | `"path": "/etc/nut/upssched.conf.pre-orchestrator",` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 5 | Reference | `ups_conf: { id: "ups_conf", label: "ups.conf" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 7 | Reference | `upsmon_conf: { id: "upsmon_conf", label: "upsmon.conf" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 8 | Reference | `upssched_conf: { id: "upssched_conf", label: "upssched.conf" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 19 | Reference | `ups_conf_generated_ref: { id: "ups_conf_generated_ref", path: "/opt/nut-auto/output/ups.conf.generated" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 21 | Reference | `ups_conf_backup_ref: { id: "ups_conf_backup_ref", path: "/etc/nut/ups.conf.backup" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 22 | Reference | `ups_conf_working_2ups_ref: { id: "ups_conf_working_2ups_ref", path: "/etc/nut/ups.conf.working-2ups" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 23 | Reference | `ups_conf_working_3ups_ref: { id: "ups_conf_working_3ups_ref", path: "/etc/nut/ups.conf.working-3ups" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 24 | Reference | `upsmon_pre_orchestrator_ref: { id: "upsmon_pre_orchestrator_ref", path: "/etc/nut/upsmon.conf.pre-orchestrator" },` | `` |
| `opt/nut-orchestrator-ui/static/app.js` | 25 | Reference | `upssched_pre_orchestrator_ref: { id: "upssched_pre_orchestrator_ref", path: "/etc/nut/upssched.conf.pre-orchestrator" },` | `` |
| `opt/nut-orchestrator-ui/static/nut-ui-theme.css` | 1039 | Reference | `/* ===== Make ups.conf and Reference Viewer headers align cleanly ===== */` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4290 | Reference | `<option value="ups_conf" disabled>ups.conf — /etc/nut/ups.conf — blocked: missing GitHub-backed repo source</option>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4292 | Reference | `<option value="upsmon_conf" data-label="upsmon.conf">upsmon.conf — /etc/nut/upsmon.conf</option>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center-restore-lab.html` | 4293 | Reference | `<option value="upssched_conf" data-label="upssched.conf">upssched.conf — /etc/nut/upssched.conf</option>` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2883 | Reference | `const response = await fetch('/nut-state/production-mode.json?ts=' + Date.now(), { cache: 'no-store' });` | `` |
| `opt/nut-orchestrator-ui/templates/control-center.html` | 2889 | Reference | `// Source fields confirmed from /nut-state/production-mode.json:` | `` |
| `usr/local/bin/nut-orchestrator.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-orchestrator.log"` | `` |
| `usr/local/bin/nut-orchestrator.sh` | 7 | Reference | `EVENT_LOG="/var/www/html/nut-state/events.log"` | `` |
| `usr/local/bin/nut-orchestrator.sh` | 8 | Reference | `UI_POWER_LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/bin/nut-test-logic.sh` | 7 | Reference | `LOG_FILE="/var/log/nut-test-logic.log"` | `` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 6 | Reference | `LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/sbin/nut-apc-idf-event-monitor.sh` | 294 | Reference | `' /etc/nut/ups.conf 2>/dev/null` | `` |
| `usr/local/sbin/nut-blueiris-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-blueiris-shutdown.log"` | `` |
| `usr/local/sbin/nut-db-shutdown.sh` | 7 | Reference | `LOG_FILE="/var/log/nut-db-shutdown.log"` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 7 | Reference | `LOG="/var/log/nut-orchestrator-ui/ui-actions.log"` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 85 | Reference | `log_path = Path("/var/log/nut-orchestrator-ui/ui-actions.log")` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 154 | Reference | `m = re.search(r'"allow_live_actions"\s*:\s*"([^"]+)"', txt)` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 240 | Reference | `with open("/etc/nut/ups.conf", "r", encoding="utf-8", errors="replace") as f:` | `` |
| `usr/local/sbin/nut-email-alert-test-send` | 385 | Reference | `log = Path("/var/log/nut-orchestrator-ui/power-events.log")` | `` |
| `usr/local/sbin/nut-esxi-ssh-readonly-preflight.sh` | 5 | Reference | `OUT_DIR="/var/log/nut-vmware-inventory"` | `` |
| `usr/local/sbin/nut-export-test-logs` | 6 | Reference | `EXPORT_ROOT="/var/log/nut-orchestrator-ui/exports"` | `` |
| `usr/local/sbin/nut-export-test-logs` | 57 | Reference | `cp -a /var/log/nut-orchestrator-ui/*.log "$EXPORT_DIR/logs/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 61 | Reference | `/var/log/nut-vmware-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 62 | Reference | `/var/log/nut-netapp-halt.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 63 | Reference | `/var/log/nut-synology-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 64 | Reference | `/var/log/nut-lansweeper-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 65 | Reference | `/var/log/nut-voip-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 66 | Reference | `/var/log/nut-db-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 67 | Reference | `/var/log/nut-blueiris-shutdown.log \` | `` |
| `usr/local/sbin/nut-export-test-logs` | 70 | Reference | `cp -a /var/log/apache2/access.log "$EXPORT_DIR/apache/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 71 | Reference | `cp -a /var/log/apache2/error.log "$EXPORT_DIR/apache/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 72 | Reference | `cp -a /var/log/apache2/access.log.1 "$EXPORT_DIR/apache/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 73 | Reference | `cp -a /var/log/apache2/error.log.1 "$EXPORT_DIR/apache/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 75 | Reference | `journalctl -u nut-server.service --since "7 days ago" --no-pager > "$EXPORT_DIR/system/nut-server.journal.txt" 2>&1 \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 76 | Reference | `journalctl -u nut-monitor.service --since "7 days ago" --no-pager > "$EXPORT_DIR/system/nut-monitor.journal.txt" 2>&1 \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 77 | Reference | `journalctl -u nut-orchestrator-ui.service --since "7 days ago" --no-pager > "$EXPORT_DIR/system/nut-orchestrator-ui.journal.txt" 2>&1 \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 78 | Reference | `journalctl -u apache2.service --since "7 days ago" --no-pager > "$EXPORT_DIR/system/apache2.journal.txt" 2>&1 \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 80 | Reference | `systemctl status nut-server.service nut-monitor.service nut-orchestrator-ui.service apache2.service --no-pager -l > "$EXPORT_DIR/system/service-status.txt" 2>&1 \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 93 | Reference | `cp -a /etc/nut/ups.conf "$EXPORT_DIR/configs/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 95 | Reference | `cp -a /etc/nut/upsmon.conf "$EXPORT_DIR/configs/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-export-test-logs` | 96 | Reference | `cp -a /etc/nut/upssched.conf "$EXPORT_DIR/configs/" 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/nut-get-power-events-json` | 10 | Reference | `LOG = Path("/var/log/nut-orchestrator-ui/power-events.log")` | `` |
| `usr/local/sbin/nut-hypervisor-ssh-readonly-preflight.sh` | 6 | Reference | `OUT_DIR="/var/log/nut-vmware-inventory"` | `` |
| `usr/local/sbin/nut-inventory-configs.sh` | 6 | Reference | `OUT="/var/log/nut-orchestrator-ui/config-inventory-$(date +%Y%m%d-%H%M%S).txt"` | `` |
| `usr/local/sbin/nut-inventory-configs.sh` | 27 | Reference | `echo "/etc/nut/upsmon.conf = approved live file"` | `` |
| `usr/local/sbin/nut-inventory-configs.sh` | 28 | Reference | `echo "/etc/nut/upssched.conf = approved live file"` | `` |
| `usr/local/sbin/nut-lansweeper-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-lansweeper-shutdown.log"` | `` |
| `usr/local/sbin/nut-local-final-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-local-final-shutdown.log"` | `` |
| `usr/local/sbin/nut-netapp-halt.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-netapp-halt.log"` | `` |
| `usr/local/sbin/nut-power-event-log` | 5 | Reference | `EVENT_LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/sbin/nut-production-mode` | 7 | Reference | `LOG_FILE="/var/log/nut-production-mode.log"` | `` |
| `usr/local/sbin/nut-production-mode` | 8 | Reference | `POWER_EVENT_LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/sbin/nut-production-mode` | 49 | Reference | `"nut-monitor.service"` | `` |
| `usr/local/sbin/nut-production-mode` | 50 | Reference | `"nut-apc-idf-event-monitor.timer"` | `` |
| `usr/local/sbin/nut-production-mode` | 51 | Reference | `"nut-apc-idf-event-monitor.service"` | `` |
| `usr/local/sbin/nut-production-mode` | 52 | Reference | `"nut-power-events-refresh.timer"` | `` |
| `usr/local/sbin/nut-production-mode` | 53 | Reference | `"nut-power-events-refresh.service"` | `` |
| `usr/local/sbin/nut-production-mode` | 58 | Reference | `systemctl list-unit-files "$unit" >/dev/null 2>&1` | `` |
| `usr/local/sbin/nut-production-mode` | 107 | Reference | `*.timer)` | `` |
| `usr/local/sbin/nut-production-mode` | 108 | Reference | `systemctl start "$unit"` | `` |
| `usr/local/sbin/nut-production-mode` | 110 | Reference | `nut-monitor.service)` | `` |
| `usr/local/sbin/nut-production-mode` | 111 | Reference | `systemctl start "$unit"` | `` |
| `usr/local/sbin/nut-production-mode` | 126 | Reference | `for unit in nut-apc-idf-event-monitor.service nut-power-events-refresh.service nut-daily-health-email.service nut-monitor.service; do` | `` |
| `usr/local/sbin/nut-production-mode` | 128 | Reference | `systemctl stop "$unit" \|\| true` | `` |
| `usr/local/sbin/nut-production-mode` | 132 | Reference | `for unit in nut-apc-idf-event-monitor.timer nut-power-events-refresh.timer nut-daily-health-email.timer; do` | `` |
| `usr/local/sbin/nut-production-mode` | 134 | Reference | `systemctl stop "$unit" \|\| true` | `` |
| `usr/local/sbin/nut-production-mode` | 163 | Reference | `# off = live actions blocked; monitoring/logging timers, daily email reports, and nut-monitor.service are stopped` | `` |
| `usr/local/sbin/nut-production-mode` | 200 | Reference | `"$STATUS_CMD" \| grep -E '"mode"\|"mode_label"\|"nut_monitor"\|"ups_total"\|"ups_online"\|"esxi_ssh_fallback_enabled"\|"allow_live_actions"\|"allow_esxi_ssh_fallback"' \|\| true` | `` |
| `usr/local/sbin/nut-production-status` | 11 | Reference | `JSON_OUT = STATE_DIR / "production-mode.json"` | `` |
| `usr/local/sbin/nut-production-status` | 12 | Reference | `TEXT_OUT = pathlib.Path("/var/log/nut-production-mode-status.txt")` | `` |
| `usr/local/sbin/nut-production-status` | 44 | Reference | `def systemctl_active(service):` | `` |
| `usr/local/sbin/nut-production-status` | 45 | Reference | `rc, out, err = run(["systemctl", "is-active", service])` | `` |
| `usr/local/sbin/nut-production-status` | 75 | Reference | `nut_server = systemctl_active("nut-server.service")` | `` |
| `usr/local/sbin/nut-production-status` | 76 | Reference | `nut_monitor = systemctl_active("nut-monitor.service")` | `` |
| `usr/local/sbin/nut-production-status` | 77 | Reference | `nut_ui = systemctl_active("nut-orchestrator-ui.service")` | `` |
| `usr/local/sbin/nut-production-status` | 105 | Reference | `"allow_live_actions": mode_data.get("NUT_ALLOW_LIVE_ACTIONS", "unknown"),` | `` |
| `usr/local/sbin/nut-production-status` | 106 | Reference | `"allow_esxi_ssh_fallback": mode_data.get("NUT_ALLOW_ESXI_SSH_FALLBACK", "unknown"),` | `` |
| `usr/local/sbin/nut-production-status` | 120 | Reference | `f"allow_live_actions={payload['allow_live_actions']}",` | `` |
| `usr/local/sbin/nut-rebuild-msmtp-from-email-config` | 8 | Reference | `LOG="/var/log/nut-orchestrator-ui/ui-actions.log"` | `` |
| `usr/local/sbin/nut-rebuild-msmtp-from-email-config` | 72 | Reference | `"logfile /var/log/msmtp.log",` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 7 | Reference | `LOG_FILE="/var/log/nut-orchestrator-ui/backup.log"` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 206 | Reference | `copy_text_file /etc/systemd/system/nut-orchestrator-ui.service ./etc/systemd/system/nut-orchestrator-ui.service 644` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 207 | Reference | `copy_text_file /etc/systemd/system/nut-power-events-refresh.service ./etc/systemd/system/nut-power-events-refresh.service 644` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 208 | Reference | `copy_text_file /etc/systemd/system/nut-power-events-refresh.timer ./etc/systemd/system/nut-power-events-refresh.timer 644` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 209 | Reference | `copy_text_file /etc/systemd/system/nut-apc-idf-event-monitor.service ./etc/systemd/system/nut-apc-idf-event-monitor.service 644` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 210 | Reference | `copy_text_file /etc/systemd/system/nut-apc-idf-event-monitor.timer ./etc/systemd/system/nut-apc-idf-event-monitor.timer 644` | `` |
| `usr/local/sbin/nut-run-backup-and-push.sh` | 239 | Reference | `copy_text_file /etc/nut/ups.conf ./etc/nut/ups.conf 640` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 259 | Reference | `copy_file /etc/nut/ups.conf etc/nut/ups.conf` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 310 | Reference | `sanitize_upsmon_file /etc/nut/upsmon.conf etc/nut/upsmon.conf 0644` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 311 | Reference | `copy_file /etc/nut/upssched.conf etc/nut/upssched.conf` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 333 | Reference | `sync_glob_files "/etc/systemd/system/nut-*.service" etc/systemd/system` | `` |
| `usr/local/sbin/nut-sync-live-to-repo-for-backup` | 334 | Reference | `sync_glob_files "/etc/systemd/system/nut-*.timer" etc/systemd/system` | `` |
| `usr/local/sbin/nut-synology-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-synology-shutdown.log"` | `` |
| `usr/local/sbin/nut-ui-apply-config` | 8 | Reference | `LOG_FILE="/var/log/nut-orchestrator-ui/ui-actions.log"` | `` |
| `usr/local/sbin/nut-ui-backup-now` | 6 | Reference | `LOG_FILE="/var/log/nut-orchestrator-ui/backup.log"` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 143 | Reference | `emit_item "systemd" "etc/systemd/system/nut-orchestrator-ui.service" "/etc/systemd/system/nut-orchestrator-ui.service"` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 144 | Reference | `emit_item "systemd" "etc/systemd/system/nut-power-events-refresh.service" "/etc/systemd/system/nut-power-events-refresh.service"` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 145 | Reference | `emit_item "systemd" "etc/systemd/system/nut-power-events-refresh.timer" "/etc/systemd/system/nut-power-events-refresh.timer"` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 146 | Reference | `emit_item "systemd" "etc/systemd/system/nut-apc-idf-event-monitor.service" "/etc/systemd/system/nut-apc-idf-event-monitor.service"` | `` |
| `usr/local/sbin/nut-ui-live-restore-dry-run` | 147 | Reference | `emit_item "systemd" "etc/systemd/system/nut-apc-idf-event-monitor.timer" "/etc/systemd/system/nut-apc-idf-event-monitor.timer"` | `` |
| `usr/local/sbin/nut-ui-rollback` | 6 | Reference | `LOG_FILE="/var/log/nut-orchestrator-ui/ui-actions.log"` | `` |
| `usr/local/sbin/nut-ui-run-test` | 5 | Reference | `LOG_FILE="/var/log/nut-orchestrator-ui/tests.log"` | `` |
| `usr/local/sbin/nut-ui-run-test` | 6 | Reference | `POWER_EVENT_LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/sbin/nut-ui-run-test` | 230 | Reference | `local log="/var/log/nut-lansweeper-shutdown.log"` | `` |
| `usr/local/sbin/nut-ui-run-test` | 387 | Reference | `if grep -q "PHASE2_POWER_RESTORE_ABORT_RESULT ups3 rc=0" /var/log/nut-orchestrator.log 2>/dev/null; then` | `` |
| `usr/local/sbin/nut-verify-target-down.sh` | 10 | Reference | `LOG_FILE="/var/log/nut-orchestrator.log"` | `` |
| `usr/local/sbin/nut-vmware-export-inventory.sh` | 7 | Reference | `OUT_DIR="/var/log/nut-vmware-inventory"` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 8 | Reference | `TOOLS_REPORT = Path("/var/log/nut-vmware-inventory/vmware-tools-status-latest.json")` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 9 | Reference | `INVENTORY_DIR = Path("/var/log/nut-vmware-inventory")` | `` |
| `usr/local/sbin/nut-vmware-hybrid-dry-run-plan.py` | 10 | Reference | `OUT_DIR = Path("/var/log/nut-vmware-inventory")` | `` |
| `usr/local/sbin/nut-vmware-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-vmware-shutdown.log"` | `` |
| `usr/local/sbin/nut-vmware-tools-status-report.py` | 47 | Reference | `DEFAULT_OUT_DIR = "/var/log/nut-vmware-inventory"` | `` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 5 | Reference | `LOG_FILE="/var/log/nut-voip-shutdown.log"` | `` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 36 | Reference | `CMD_PREVIEW="ssh -o BatchMode=yes -o ConnectTimeout=10 ${USER_NAME}@${HOST} \"sudo /usr/bin/systemctl poweroff\""` | `` |
| `usr/local/sbin/nut-voip-shutdown.sh` | 79 | Reference | `ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER_NAME}@${HOST}" "sudo /usr/bin/systemctl poweroff" >> "$LOG_FILE" 2>&1` | `` |
| `usr/local/sbin/phase2-power-restore-abort` | 4 | Reference | `LOG_FILE="/var/log/nut-orchestrator.log"` | `` |
| `usr/local/sbin/phase2-power-restore-abort` | 5 | Reference | `EVENT_LOG="/var/www/html/nut-state/events.log"` | `` |
| `usr/local/sbin/phase2-power-restore-abort` | 6 | Reference | `UI_POWER_LOG="/var/log/nut-orchestrator-ui/power-events.log"` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 27 | Reference | `sudo systemctl stop tigervnc-backup.service 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 28 | Reference | `sudo systemctl stop x11vnc.service 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 29 | Reference | `sudo systemctl stop xrdp 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 30 | Reference | `sudo systemctl stop xrdp-sesman 2>/dev/null \|\| true` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 43 | Reference | `if [ -f "${BASE}/etc/systemd/system/tigervnc-backup.service" ]; then` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 44 | Reference | `echo "[INFO] Restoring tigervnc-backup.service"` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 45 | Reference | `sudo cp -a "${BASE}/etc/systemd/system/tigervnc-backup.service" /etc/systemd/system/tigervnc-backup.service` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 48 | Reference | `if [ -f "${BASE}/etc/systemd/system/x11vnc.service" ]; then` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 49 | Reference | `echo "[INFO] Restoring x11vnc.service"` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 50 | Reference | `sudo cp -a "${BASE}/etc/systemd/system/x11vnc.service" /etc/systemd/system/x11vnc.service` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 52 | Reference | `sudo rm -f /etc/systemd/system/x11vnc.service` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 83 | Reference | `sudo systemctl daemon-reload` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 86 | Reference | `sudo systemctl enable xrdp xrdp-sesman tigervnc-backup.service >/dev/null 2>&1 \|\| true` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 89 | Reference | `sudo systemctl restart xrdp` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 90 | Reference | `sudo systemctl restart xrdp-sesman` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 91 | Reference | `sudo systemctl restart tigervnc-backup.service` | `` |
| `usr/local/sbin/rollback-remote-access.sh` | 99 | Reference | `sudo systemctl status xrdp xrdp-sesman tigervnc-backup.service --no-pager -l \|\| true` | `` |
| `var/www/html/index.html` | 309 | Reference | `start/stop the service use <tt>systemctl start apache2</tt> and` | `` |
| `var/www/html/index.html` | 310 | Reference | `<tt>systemctl stop apache2</tt>, and use <tt>systemctl status apache2</tt>` | `` |

---

## 12. Restart / Reload Map

Use this section before changing files so the correct service is restarted and unrelated services are not touched.

| Changed item | Required action |
|---|---|
| `opt/nut-orchestrator-ui/app.py` | Restart `nut-orchestrator-ui.service` |
| `opt/nut-orchestrator-ui/templates/*.html` | Restart `nut-orchestrator-ui.service`, then press Ctrl+F5 in the browser |
| `opt/nut-orchestrator-ui/static/*` | Press Ctrl+F5 in the browser; restart UI service if behavior does not update |
| `opt/nut-orchestrator-ui/lib/config_registry.json` | Restart `nut-orchestrator-ui.service` |
| Apache config | Reload Apache with `sudo systemctl reload apache2`; restart only if reload fails |
| NUT config files | Restart or reload only the affected NUT service after review |
| systemd unit or timer | Run `sudo systemctl daemon-reload`, then restart the affected unit or timer |
| shell wrapper/helper script | Usually no service restart; verify syntax, permissions, ownership, and behavior |
| protection mode helper | Verify with `sudo /usr/local/sbin/nut-production-status` |
| email helper or email config | Send a controlled test email only when approved |
| dashboard static HTML | Browser refresh; Apache reload only if Apache config changed |
| sudoers rule | Validate syntax before relying on it |

---

## 13. Troubleshooting Index

Use this section when something breaks and you need the first place to look.

| Symptom | First places to check |
|---|---|
| Control Center does not load | `nut-orchestrator-ui.service`, Apache `/nut-ui/` route, `app.py`, template syntax |
| Button does nothing | Browser console, button ID, event listener, JavaScript function, Flask route |
| API returns 500/error | Flask route in `app.py`, helper script output, sudoers rule, service journal |
| Mutating action blocked | Check NUT Protection Mode; Protecting should block dangerous changes |
| Backup misses files | `nut-ui-backup-now`, `nut-run-backup-and-push.sh`, `nut-sync-live-to-repo-for-backup`, Git status |
| Restore risk unclear | Use dry-run or selected restore helpers before live restore |
| Export Logs incomplete | `/api/export-logs`, `nut-export-test-logs`, included log paths |
| Dashboard event missing | `events.log`, `power-events.log`, `/api/power-events`, `nut-monitor` journal |
| Power event visible in dashboard but not UI | Compare dashboard static JS, Control Center API, and shared event feed |
| Email missing | `nut-email-alert-test-send`, orchestrator email context, SMTP config, email timer |
| OFF still monitoring | Treat as incorrect; OFF should stop monitoring/logging/email/live actions |
| Standby allows live action | Treat as incorrect; Standby should block live protection actions |
| Protecting allows config changes | Treat as incorrect; mutating UI/backend routes should be blocked |
| Shutdown wrapper fails | Check wrapper executable permissions, config readability, credential access, and log writability |
| VMware fallback did not run | Check `allow_esxi_ssh_fallback`; fallback should stay disabled unless approved |
| Browser UI stale | Press Ctrl+F5 after UI/template/static changes |
| Copy Full Output stops working | Check `cc-output-copy`, `cc-action-output`, `ccCopyFullActionOutput()`, browser console |
| Weather/temp button flash stops working | Check `cc-pontiac-weather` and `ccWeatherFlashColor()` |
| Secret appears in output | Stop, redact, and rotate the exposed secret |

---

## 14. Git and Backup Workflow

Expected backup branch:

```text
origin/backup-sanitized-initial
```

Before committing:

1. Confirm NUT mode and safety state.
2. Confirm affected services are active.
3. Confirm only intended files changed.
4. Stage only intended files.
5. Commit with a clear message.
6. Push to the backup branch.
7. Fetch and confirm local and remote commit IDs match.
8. Confirm the working tree is clean.

Do not commit unrelated local changes unless they are intentionally part of the task.

---

## 15. Secret Handling Rules

Never expose:

- Passwords
- SMTP secrets
- SSH keys
- API tokens
- KeePass entries
- vCenter credentials
- ESXi credentials
- UPS credentials
- Synology credentials
- NetApp credentials
- Windows credentials
- Files ending in or acting like `.pass`, `.creds`, `.secret`, `.token`, or equivalent secret stores

When showing config, logs, screenshots, command output, or AI chat text:

1. Mask secret values.
2. Prefer key names and file paths over values.
3. If a secret is exposed, treat it as compromised and recommend rotation.
4. Never ask the user to paste passwords into chat.

---

## 16. AI Chat Handoff Instructions

When starting a new AI chat:

1. Share this `architecture.md` file first.
2. Tell the AI to follow this architecture file.
3. Ask the AI to perform read-only audits before changing anything.
4. Keep work to one or two steps at a time.
5. Require explicit PASS/FAIL validation.
6. Do not move to the next task until the current task is complete.
7. Keep NUT in Standby while making changes unless explicitly required.
8. Do not run live shutdown actions without explicit approval.
9. Do not paste secrets.
10. Do not assume OFF mode still monitors anything.
11. Do not enable ESXi SSH fallback unless explicitly approved.
12. Update this file when architecture, paths, features, routes, functions, or safety rules change.

---

## 17. Runbook Placement

Recommended runbook section:

```text
00 - NUT Server Architecture and AI Handoff Reference
```

Recommended document title:

```text
NUT Server Architecture and Complete Feature Map
```

This document should be reviewed before:

- Troubleshooting
- Live testing
- UI changes
- Backend changes
- Wrapper changes
- Email changes
- Backup/restore work
- Runbook updates
- Starting a new AI chat for this project

---

## 18. Maintenance Rule for This File

Update this document whenever any of the following change:

- File paths
- Service names
- URLs
- Protection mode behavior
- UI buttons
- API routes
- Flask functions
- JavaScript functions
- Shell scripts
- Wrapper scripts
- Config files
- Log paths
- Backup/restore behavior
- Email behavior
- Safety gates
- Runbook expectations

If this file and the actual repo disagree, audit the repo and update this file.

