# NUT Server Backup Inventory

## GitHub Backup Branch
Repo: T3CHNRD/NUTserver
Branch: backup-sanitized-initial

### Included
- /etc/nut/apache-notes.txt
- /etc/nut/nut.conf
- /etc/nut/upsmon.conf (sanitized)
- /etc/nut/upssched.conf
- /etc/nut/upsset.conf
- /etc/nut/hosts.conf (sanitized)
- /etc/nut/upsd.conf
- /etc/systemd/system/nut-boot-event-log.service
- /etc/systemd/system/nut-fix-sockets.service
- /etc/systemd/system/nut-monitor.service.d/override.conf
- /etc/systemd/system/tigervnc-backup.service
- /etc/systemd/system/x11vnc.service
- /etc/systemd/system/nut-driver@.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups1.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups2.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups3.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups4.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups5.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups6.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups7.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups8.service.d/nut-driver-enumerator-generated.conf
- /etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated-checksum.conf
- /etc/systemd/system/nut-driver@ups9.service.d/nut-driver-enumerator-generated.conf
- /usr/local/sbin/nut-boot-event-log.sh
- /usr/local/sbin/nut-fix-sockets.sh
- /usr/local/sbin/rollback-remote-access.sh

## Protected Local Backup Only
Location: /opt/nut-admin/protected-backups

### Included
- /etc/nut/nut-orchestrator.conf
- /etc/nut/lansweeper.creds
- /etc/nut/ups.conf
- /etc/nut/upsd.users
- /usr/local/bin/nut-orchestrator.sh
- /usr/local/bin/nut-test-logic.sh
- /usr/local/sbin/nut-vmware-shutdown.sh
- /usr/local/sbin/nut-netapp-halt.sh
- /usr/local/sbin/nut-synology-shutdown.sh
- /usr/local/sbin/nut-lansweeper-shutdown.sh
- /usr/local/sbin/nut-voip-shutdown.sh
- /usr/local/sbin/nut-db-shutdown.sh
- /usr/local/sbin/nut-blueiris-shutdown.sh
- /usr/local/sbin/start-x11vnc.sh
- /opt/nut-auto/network-seeds.txt
- /opt/nut-auto/nut-auto-discover.sh
- /opt/nut-auto/output/inventory.json
- /opt/nut-auto/output/verified-ups-notes.txt
- /etc/xrdp/*
- /etc/X11/Xwrapper.config
- /home/nutserver/.vnc/*
- /home/nutserver/.config/autostart/*
- /home/rdpadmin/.xsession
- /home/nutserver/.xsession

## Pending Review
- Dashboard HTML/JS/CSS
- Milestone/progress/rollback docs
- Additional non-sensitive .conf files only after review/sanitization

## Dashboard Decision
### In GitHub
- /var/www/html/nutserver-dashboard.html
- /home/nutserver/Desktop/nutserver-project-export/docs/ROLLBACK.md

### Protected Local Backup Only
- /var/www/html/nutserver-dashboard.html.save
- /var/www/html/nutserver-dashboard.priority1.html
- /var/www/html/nutserver-dashboard.priority1.html.bak1
- /var/www/html/nutserver-dashboard.priority1.html.broken-layout
