# NUT Server Emergency Cheat Sheet

## UI Access
- Orchestrator UI: http://<INTERNAL_IP>/nut-ui
- Priority Dashboard: http://<INTERNAL_IP>/nutserver-dashboard.priority1.html

## Emergency Restore from GitHub
1. Open the Orchestrator UI
2. Click "Restore from GitHub"
3. Confirm Action Output shows restore completed
4. Verify service:
   sudo systemctl restart nut-orchestrator-ui
   curl -s http://127.0.0.1:5080/healthz

Expected:
{"ok":true}

## Backup to GitHub
Use UI button: "Backup All to GitHub"

CLI verification:
cd /opt/nut-admin/repo-template
git status --short
git log -1 --oneline
git fetch origin
git log -1 --oneline origin/backup-sanitized-initial

## Real Test Safety
Real Test requires:
- UI passphrase
- Backend validation
- ALLOW_REAL_TEST=1
- Approved wrapper
- Phase selection

Phases:
1 = Lansweeper only
2 = Power restore abort test
3 = Full shutdown

## Logs
sudo tail -f /var/log/nut-orchestrator-ui/tests.log
sudo tail -f /var/log/nut-orchestrator-ui/power-events.log
sudo tail -f /var/log/nut-lansweeper-shutdown.log
