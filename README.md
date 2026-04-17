# nut-server-backup

Sanitized backup of selected NUT server automation, service definitions, and safe configuration templates.

## Notes
- This repository intentionally excludes secrets, credentials, private keys, and environment-specific infrastructure details.
- Staged files are copied from the live server through a sanitizing filter.
- High-risk orchestration, credential, discovery, and infra-bearing files are intentionally excluded.

## Included
- Safe NUT config templates
- Safe systemd unit files
- Safe helper scripts

## Excluded
- Secrets and credential files
- Live infrastructure endpoints and host/IP details
- VMware, NetApp, Lansweeper, and other infra-specific shutdown logic
