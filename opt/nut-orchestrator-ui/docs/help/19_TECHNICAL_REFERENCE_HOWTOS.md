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

## Related Help

- Configuration
- Protected Systems
- Services and Timers
- Logs
- Security
