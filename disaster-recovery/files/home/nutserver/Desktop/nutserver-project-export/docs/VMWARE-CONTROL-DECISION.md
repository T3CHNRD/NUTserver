# VMware Control Decision for NUT Server Project

## Current State
- VMware Tools is confirmed installed on all servers.
- All production VMware workloads are on HA-cluster nodes.
- The physical NUT server remains the primary/orchestrator.
- Production shutdown logic must be centralized from the NUT server.
- Production execution is blocked until the vCenter host dependency is confirmed.

## Confirmed Design Direction
Because production workloads are on HA-cluster nodes:

- Do not use ESXi automatic VM startup/shutdown for production shutdown control
- Do not use NutClient-ESXi on production HA-cluster nodes
- Do not use host-local shutdown logic as the primary production method
- Use centralized orchestration from the physical NUT server

## VMware Control Options To Evaluate
The NUT server may control VMware through one of the following approved methods:

1. vCenter API
2. PowerCLI
3. govc
4. Another approved VMware-aware control method

## Current Recommendation
Recommended control model:

- NUT server detects the UPS battery event
- NUT server starts timer and orchestration logic
- NUT server centrally shuts down clustered VMs in defined order
- vCenter remains up until the rest of the clustered VMs are shut down
- vCenter is the last VM in the cluster to go down
- ESXi hosts shut down only after guest VMs are confirmed off
- The host carrying vCenter during the event is treated as the final compute host
- Storage shuts down after compute
- NUT server shuts down last

## Open Decision
The exact VMware control method is still not finalized.

### Decision still needed:
- Which control method will be used from the NUT server:
  - vCenter API
  - PowerCLI
  - govc
  - other approved method

### Blocking dependency:
- Identify which ESXi host normally carries the vCenter appliance during shutdown
- Replace:
  - `CHANGE_ME_VCSA_LAST_HOST`

## Status
- Design direction: confirmed
- Production execution method: not yet finalized
- Production execution: blocked pending vCenter host identification
