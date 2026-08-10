# HA Cluster Design Notes for NUT Server Project

## Confirmed Facts
- VMware Tools has been verified as installed on all servers.
- All production VMware workloads are on HA-cluster nodes.
- The physical NUT server remains the primary/orchestrator.
- Shutdown model is outside-in.
- Startup model is inside-out.
- 60-second buffers are used between shutdown categories.

## Important Constraints
- Do not use ESXi automatic VM startup/shutdown for the production shutdown design.
- Do not use NutClient-ESXi on production HA-cluster nodes.
- Do not rely on host-local shutdown logic for clustered production hosts.
- Use centralized orchestration from the physical NUT server.

## Production Shutdown Control Model
1. NUT server detects ONBATT event and starts timer logic.
2. NUT server orchestrates clustered VM shutdown centrally.
3. vCenter remains up until all other clustered VMs are shut down.
4. vCenter is the last VM in the cluster to go down.
5. ESXi hosts are shut down only after guest VMs are confirmed off.
6. The host running vCenter during the event is treated as the final compute host.
7. Physical storage shuts down after compute.
8. NUT server shuts down last and then signals final UPS power-off if configured.

## Production Startup Control Model
1. NUT server powers on first after AC restore.
2. Storage powers on next.
3. ESXi hosts power on next.
4. Network and identity services come up next.
5. vCenter and management come up next.
6. Applications come up last.

## Coding Implication
The next script phase should use HA-aware orchestration methods such as:
- vcenter_vm
- vcenter_host
- storage_manual
- local_nut

The next script phase should not use:
- esxi_autostart
- nutclient_esxi_production
- direct host-local HA shutdown logic
