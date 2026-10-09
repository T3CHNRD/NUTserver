# Configuration Restore Catalog

Base revision 2026-10-08 | Evidence update 2026-10-09

Use this reference to understand which files the current restore catalog lists. It is not a restore execution procedure. Catalog flags describe recorded settings, not a successful restore test.

## 1 What the catalog says

There are 25 entries. Twenty are marked enabled, non-sensitive and backed by a repository source. DB Telnet Username is also enabled, but its source is marked missing. Four entries are disabled and marked sensitive.

## 2 Entry by entry

| Entry | Restore enabled | Source recorded available |
| --- | --- | --- |
| ups.conf | Yes | Yes |
| upsd.conf | Yes | Yes |
| upsmon.conf | No | Yes |
| upssched.conf | Yes | Yes |
| nut.conf | Yes | Yes |
| hosts.conf | Yes | Yes |
| Live nut-orchestrator.conf | Yes | Yes |
| config.d nut-orchestrator.conf | Yes | Yes |
| Approved Targets | Yes | Yes |
| Dashboard UI Settings | Yes | Yes |
| nut-synology-shutdown.sh | Yes | Yes |
| nut-voip-shutdown.sh | Yes | Yes |
| nut-db-shutdown.sh | Yes | Yes |
| nut-blueiris-shutdown.sh | Yes | Yes |
| nut-ui-run-test | Yes | Yes |
| nut-ui-run-real-test-approved | Yes | Yes |
| nut-lansweeper-shutdown.sh | Yes | Yes |
| nut-vmware-shutdown.sh | Yes | Yes |
| Hypervisor SSH Fallback Config | Yes | Yes |
| nut-netapp-halt.sh | Yes | Yes |
| nut-orchestrator.sh (main orchestration) | Yes | Yes |
| DB Telnet Username | Yes | No |
| DB Telnet Password | No | No |
| vCenter Password | No | No |
| NUT Email Alert Settings | No | Yes |

## 3 Before using restore

Confirm the intended file and the current backup source. Do not rely on the DB Telnet Username entry until its missing source is resolved. Do not assume the disabled entries can be restored through the ordinary selected-file workflow.

The catalog is /etc/nut/restore/restore-targets.json. It is separate from the 26-entry configuration editor registry. The earlier 21-item inventory included a test probe and was not the same list.

Verification: selected JSON fields supplied by the operator on 2026-10-09. File existence and source availability here are catalog values, not independent filesystem checks.
