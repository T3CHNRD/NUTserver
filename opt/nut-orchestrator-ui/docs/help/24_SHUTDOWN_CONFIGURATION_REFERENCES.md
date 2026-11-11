# Shutdown Script Configuration References

Base revision 2026-10-08 | Evidence update 2026-10-09

Use this map to find the configuration paths mentioned by shutdown scripts. These are references in script text, not proof of active reading, setting precedence or successful authentication.

## 1 Reference map

| Script or system | Referenced file |
| --- | --- |
| Main orchestrator | /etc/nut/production-mode.conf |
| VMware | /etc/nut/nut-orchestrator.conf |
| VMware | /etc/nut/vcenter.pass |
| VMware | /etc/nut/config.d/vmware-vm-map.conf |
| VMware | /etc/nut/hypervisors/hypervisor-ssh-fallback.conf |
| Synology | /etc/nut/synology-api.conf |
| NetApp | /etc/nut/nut-orchestrator.conf |
| DB | /etc/nut/db-shutdown.conf |
| DB | /etc/nut/production-mode.conf |
| Blue Iris | /etc/nut/lansweeper.creds |
| Lansweeper | /etc/nut/lansweeper.creds |

## 2 Shared files need special attention

Both Blue Iris and Lansweeper reference lansweeper.creds. Inspect both uses before changing that file. A shared path alone does not prove the scripts use the same account.

VMware and NetApp reference /etc/nut/nut-orchestrator.conf. Do not confuse this with /etc/nut/config.d/nut-orchestrator.conf; their precedence is not established.

## 3 References not found

No complete literal /etc/nut/ path was detected in the VOIP or local final shutdown wrapper. They may use constructed paths, another location or an indirect helper. This finding does not mean they use no configuration.

Verification: operator-supplied path-only scan of nine scripts received 2026-10-09; full-line comments were excluded. No script was executed.


## Loading confirmed by the broader source review

VMware and NetApp source `/etc/nut/nut-orchestrator.conf`. The main orchestrator reads `/etc/nut/production-mode.conf`. The verification-target helper reads `/etc/nut/config.d/shutdown-verification-targets.conf`, and VMware reads `/etc/nut/config.d/vmware-vm-map.conf`. These mapping files must not be treated as unused. No operational reader for the sibling `config.d/nut-orchestrator.conf` was found in the bounded source snapshot; this is a cleanup candidate, not removal approval. See [credential sources](34_PROTECTED_SYSTEM_CREDENTIALS.md).
