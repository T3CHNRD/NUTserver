NUT test export created: 20260508-102630

Purpose:
Offline analysis bundle for NUT real-world test preparation and post-test troubleshooting.

Known scope:
VMWARE_SCOPE="vCenter guest shutdown only"
VMWARE_ESXI_HOST_SHUTDOWN=NOT_IMPLEMENTED"

Included:
- NUT orchestrator UI logs
- Power / Boot event log
- Shutdown wrapper logs
- NUT service journals
- Current service status
- UPS status snapshot
- NUT configs
- Active shutdown wrappers
- UI app/frontend snapshot

Do not assume this bundle proves live shutdown success.
Live shutdown remains unproven until test day.
