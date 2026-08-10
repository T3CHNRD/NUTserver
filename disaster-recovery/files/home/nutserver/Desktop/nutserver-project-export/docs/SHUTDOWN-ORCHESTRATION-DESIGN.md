# Shutdown Orchestration Design

## Purpose
This document defines the planned shutdown orchestration model for the NUT server project using the current UPS inventory, runtime information, VMware HA design constraints, the approved shutdown/startup philosophy, and the merged master shutdown/startup schedule.

## Core Design Model
- Shutdown model: outside-in
- Startup model: inside-out
- NUT server role: orchestrator
- Each UPS uses its own cancelable countdown before shutdown begins
- Power return during countdown cancels shutdown immediately
- vCenter: last VM in the VMware cluster
- ESXi hosts: shut down only after guest VMs are confirmed off
- Storage: shut down after compute
- NUT server: final system to shut down once its UPS assignment is finalized

## Source Inputs
This design uses:
- `config/ups.conf.reference`
- `config/ups.conf.sanitized`
- `docs/UPS-INVENTORY-AND-RACK-MAPPING.md`
- `docs/UPS-RUNTIME-REFERENCE.md`
- `docs/UPS-RUNTIME-TIERS.md`
- `docs/UPS-TO-SYSTEM-MAPPING.md`
- `docs/HA-CLUSTER-DESIGN.md`
- `docs/VMWARE-CONTROL-DECISION.md`
- `docs/OPEN-ITEMS.md`
- `master_merged_shutdown_startup_schedule_fixed.xlsx`

## Confirmed Architecture
- `/etc/nut/ups.conf` remains the live UPS device configuration
- UPS device definitions stay in NUT config
- Shutdown orchestration logic stays separate from `ups.conf`
- VMware production workloads are on HA-cluster nodes
- VMware Tools is installed on all servers
- Production shutdown control must be centralized from the physical NUT server
- NutClient-ESXi is not the production control method for HA-cluster nodes
- ESXi autostart/autoshutdown is not the production control method for HA-cluster nodes

## UPS Inventory Available to Orchestration
- ups1 / UPS_Test = 2h 6m
- ups2 = 30m
- ups3 = 27m
- ups4 / UPS 3_3 = 34m
- ups5 / Rack 4_3 = 26m
- ups6 = 19h 2m
- ups7 = 18m
- ups8 = 15m
- ups9 = 37m

## Runtime Tier Impact
### Tier 1 - Critical shortest runtime
- ups8 = 15m
- ups7 = 18m

### Tier 2 - High urgency
- ups5 / Rack 4_3 = 26m
- ups3 = 27m
- ups2 = 30m
- ups4 / UPS 3_3 = 34m

### Tier 3 - Moderate urgency
- ups9 = 37m

### Tier 4 - Long runtime
- ups1 / UPS_Test = 2h 6m

### Tier 5 - Extended runtime
- ups6 = 19h 2m

## Approved Per-UPS Shutdown Policy

### ups8 — 15 minutes runtime
**Protected systems**
- VOIP
- VME Server
- Merlin phone switch
- Comcast router
- remote access

**Approved behavior**
- Graceful shutdown:
  - VOIP
  - VME Server
  - Merlin phone switch
- Alert only:
  - Comcast router
  - remote access unless later confirmed as server-class

### ups7 — 18 minutes runtime
**Protected systems**
- DB01
- DB02
- PDU cabinet

**Approved behavior**
- Graceful shutdown:
  - DB01
  - DB02
- Alert only:
  - PDU cabinet

### ups2 — 30 minutes runtime
**Protected systems**
- Blue Iris
- Observium is not on ups2 in the merged sheet and should not be treated as an ups2 shutdown target

**Approved behavior**
- Graceful shutdown:
  - Blue Iris

### ups6 — 19h 2m runtime
**Protected systems**
- PDC1 is not on ups6 in the merged sheet and should not be treated as an ups6 shutdown target
- Lansweeper
- Cisco ASA 5508
- AT&T router

**Approved behavior**
- Graceful shutdown:
  - Lansweeper
- Alert only:
  - Cisco ASA 5508
  - AT&T router

### ups9 — 37 minutes runtime
**Protected systems**
- WebServer-1
- clustered VMware VMs
- vCenter
- ESXi hosts
- storage

**Approved behavior**
- Broader domain shutdown
- Main VMware orchestration path
- Sequence:
  1. Non-critical apps
  2. Business apps
  3. Cluster support
  4. Core identity/data
  5. ALBL-VCSA last VM
  6. ESXi hosts
  7. Storage
  8. NUT server last overall once its UPS is known

### ups1 / ups3 / ups4 / ups5
**Approved behavior for now**
- Alert only
- Not finalized for automatic shutdown
- Remain pending until mapping / duplicate-feed reconciliation is complete

## Approved First-Draft Timing Model

### ups8 — 15 minutes
- ONBATT detected: immediately
- Cancelable countdown before shutdown starts: 3 minutes
- If power returns during countdown: cancel immediately
- If still on battery at 3 minutes: begin graceful shutdown
- Target completion by: 7–9 minutes elapsed
- Reserve target left: 4–6 minutes
- LOWBATT behavior: finalize immediately

### ups7 — 18 minutes
- ONBATT detected: immediately
- Cancelable countdown before shutdown starts: 4 minutes
- If power returns during countdown: cancel immediately
- If still on battery at 4 minutes: begin graceful shutdown
- Target completion by: 9–10 minutes elapsed
- Reserve target left: 5–7 minutes
- LOWBATT behavior: finalize immediately

### ups2 — 30 minutes
- ONBATT detected: immediately
- Cancelable countdown before shutdown starts: 7 minutes
- If power returns during countdown: cancel immediately
- If still on battery at 7 minutes: begin graceful shutdown
- Target completion by: 14–16 minutes elapsed
- Reserve target left: 10+ minutes

### ups9 — 37 minutes
- ONBATT detected: immediately
- Cancelable countdown before shutdown starts: 4 minutes
- If power returns during countdown: cancel immediately
- If still on battery at 4 minutes: begin broader shutdown sequence
- Target completion by: 20–25 minutes elapsed
- Reserve target left: 10–12 minutes

### ups6 — 19h 2m
- ONBATT detected: immediately
- Cancelable countdown before shutdown starts: 25 minutes
- If power returns during countdown: cancel immediately
- If still on battery at 25 minutes: begin graceful shutdown
- This UPS should not drive early site shutdown

### ups1 / ups3 / ups4 / ups5
- No automatic timing committed yet
- Alert only / not finalized

## Approved Operational State Flow

### State 1 — Normal
- Utility power is present
- No shutdown countdown active

### State 2 — On battery / pending
- UPS goes ONBATT
- Start UPS-specific countdown timer
- Send alert / log event
- Do not shut anything down yet

### State 3 — Power restored during countdown
- Utility power returns before timer expires
- Cancel shutdown immediately
- Send “shutdown canceled / power restored” event
- Write cancellation to the log
- Clear pending state
- Remain online

### State 4 — Shutdown committed
- Timer expires and UPS is still on battery
- Begin graceful shutdown actions for that UPS domain
- Cancellation may no longer fully prevent shutdown once committed

### State 5 — Finalization
- LOWBATT or final stage reached
- Complete remaining shutdown steps
- Finish orchestration
- NUT server final action occurs later once its UPS design is finalized

### Practical Rule
- Power return during countdown cancels shutdown immediately
- Power return after shutdown has already started may not save every system

## Spreadsheet-Driven Shutdown Order Model

### Phase 1 - Non-Critical Apps
- Blue Iris | Physical | ups2 | Windows Server 2012 R2 Standard | 192.168.1.25
- Observium | Physical | ups4 / UPS 3_3 in merged sheet (`ups3_3`) | Ubuntu 20.04.5 | 192.168.3.230
- WebServer-1 | Physical | ups9 | Ubuntu 20.04.5 | 192.168.1.20

### Phase 2 - Business Apps
- Albl-Exch2019 | VM | ups9 | Windows | Host: Alblvmhost01 | 192.168.1.75
- albl-SageSQL | VM | ups9 | Windows | Host: Alblvmhost01 | 192.168.1.150
- alblvvsaa | VM | ups9 | Linux | Host: Alblvmhost01 | 192.168.99.86

### Phase 3 - Cluster Support
- ALBL-WSUS | VM | ups9 | Down / powered off in sheet | Host: Alblvmhost02 | 192.168.1.35
- ALBL-ActiveIQ | VM | ups9 | Linux | Host: Alblvmhost02 | 192.168.99.88
- ALBL-ParkView-1 | VM | ups9 | Linux | Host: Alblvmhost02 | 192.168.99.92

### Phase 4 - Data / Additional Core Workloads
- OEL-DB01 | VM | UPS not assigned in sheet | IP 192.168.1.9 | shutdown only

### Phase 5 - Core Identity
- PDC1 | Physical | ups5 / Rack 4_3 in merged sheet (`Rack4_4` treated as `Rack4_3`) | Windows Server 2025 | 192.168.1.22
- ALBL-SDC1 | VM | ups9 | Windows | Host: Alblvmhost03 | 192.168.99.120
- DB01 | Physical | ups4 / UPS 3_3 in merged sheet (`ups3_3`) | Solaris 10 | 192.168.1.9
- DB02 | Physical | ups4 / UPS 3_3 in merged sheet (`ups3_3`) | Solaris 10 | 192.168.1.11

### Phase 5a - Management / Final VM
- ALBL-VCSA | VM | ups9 | Linux | Host: Alblvmhost01 | 192.168.99.84

### Phase 6 - ESXi Hosts
- Alblvmhost01 | Physical | ups9 | VMware ESXi 7.03 | 192.168.99.70
- Alblvmhost02 | Physical | ups9 | VMware ESXi 7.03 | 192.168.99.71
- Alblvmhost03 | Physical | ups9 | VMware ESXi 7.03 | 192.168.99.72
- CHANGE_ME_VCSA_LAST_HOST | unresolved final compute host dependency

### Phase 6a - Storage
- Alblnetapp01 | Physical | ups9 | Storage | 192.168.99.20
- Alblnetapp02 | Physical | ups9 | Storage | 192.168.99.30
- Albl-synology1 | Physical | ups9 | Synology DSM | 192.168.1.250

### Phase 7 - Additional Physical / Site Systems
- VOIP | Physical | ups8 | Ubuntu 24.04 | 192.168.1.14
- Cisco 3850 | Switch | ups3 | no IP listed
- Video Server | Physical | ups3 | Ubuntu 24.04? | no IP listed
- Dell 1950 | Physical | ups3 | OS not listed | no IP listed
- PDU Cabinet | Physical | ups7 | device class not fully defined | no IP listed
- Cisco 3850 | Switch | ups4 / UPS 3_3 in sheet (`UPS3_3`) | no IP listed
- Mail Gateway | Physical | ups4 / UPS 3_3 | 192.168.3.67
- Rack 1 APC Surge Protector | Surge Protector | ups4 / UPS 3_3
- OPC Server | Physical | ups5 / Rack 4_3 in sheet (`Rack4_4` treated as `Rack4_3`) | 192.168.10.170
- LTO-7 Tape Drive | Tape Drive | ups5 / Rack 4_3 in sheet (`Rack4_4` treated as `Rack4_3`) | no IP listed
- Lansweeper | Physical | ups6 | Windows | 192.168.10.158
- Cisco Asa 5508 | Firewall | ups6 | iOS | 192.168.3.6
- AT&T 4808 Router | Router | ups6 | no IP listed
- VME Server | Physical | ups8 | OS not listed | no IP listed
- Comcast 3909 R | Router | ups8 | no IP listed
- phone switch (Merlin) | Physical | ups8 | unix 1.0 | no IP listed
- remote access | Type not listed | ups8 | no IP listed
- ALBL-NUT Server | VM | `tbd` | Ubuntu 24.04 | 192.168.3.251

## Spreadsheet-Driven Startup Order Model

### Phase 1 - NUT Server
- ALBL-NUT Server | VM | UPS assignment `tbd` in sheet | Ubuntu 24.04 | 192.168.3.251

### Phase 1A - Storage
- Alblnetapp01 | Physical | ups9 | 192.168.99.20
- Alblnetapp02 | Physical | ups9 | 192.168.99.30
- Albl-synology1 | Physical | ups9 | 192.168.1.250

### Phase 2 - ESXi Hosts
- Alblvmhost01 | Physical | ups9 | 192.168.99.70
- Alblvmhost02 | Physical | ups9 | 192.168.99.71
- Alblvmhost03 | Physical | ups9 | 192.168.99.72

### Phase 2A - Management
- ALBL-VCSA | VM | ups9 | Linux | Host: Alblvmhost01 | 192.168.99.84

### Phase 3 - Network / Identity
- DB01 | Physical | ups4 / UPS 3_3 in sheet (`ups3_3`) | Solaris 10 | 192.168.1.9
- DB02 | Physical | ups4 / UPS 3_3 in sheet (`ups3_3`) | Solaris 10 | 192.168.1.11
- PDC1 | Physical | ups5 / Rack 4_3 in sheet (`Rack4_4` treated as `Rack4_3`) | Windows Server 2025 | 192.168.1.22
- ALBL-SDC1 | VM | ups9 | Windows | Host: Alblvmhost03 | 192.168.99.120

### Phase 4A - Cluster Support
- ALBL-ActiveIQ | VM | ups9 | Linux | Host: Alblvmhost02 | 192.168.99.88
- ALBL-ParkView-1 | VM | ups9 | Linux | Host: Alblvmhost02 | 192.168.99.92

### Phase 5 - Data Tier
- OEL-DB01 | VM | UPS not assigned in sheet
- albl-SageSQL | VM | ups9 | Windows | Host: Alblvmhost01 | 192.168.1.150

### Phase 6 - Apps & Comms
- Albl-Exch2019 | VM | ups9 | Windows | Host: Alblvmhost01 | 192.168.1.75
- WebServer-1 | Physical | ups9 | Ubuntu 20.04.5 | 192.168.1.20
- VOIP | Physical | ups8 | Ubuntu 24.04 | 192.168.1.14

## UPS Event Domains Based on Spreadsheet Mapping

### ups2 domain
- Blue Iris

### ups3 domain
- Cisco 3850
- Video Server
- Dell 1950

### ups4 / UPS 3_3 domain
- Observium
- DB01
- DB02
- Cisco 3850
- Mail Gateway
- Rack 1 APC Surge Protector

### ups5 / Rack 4_3 domain
- PDC1
- OPC Server
- LTO-7 Tape Drive

### ups6 domain
- Lansweeper
- Cisco Asa 5508
- AT&T 4808 Router

### ups7 domain
- PDU Cabinet

### ups8 domain
- VOIP
- VME Server
- Comcast 3909 R
- phone switch (Merlin)
- remote access

### ups9 domain
- WebServer-1
- Albl-Exch2019
- albl-SageSQL
- alblvvsaa
- ALBL-WSUS
- ALBL-ActiveIQ
- ALBL-ParkView-1
- ALBL-VCSA
- ALBL-SDC1
- Alblvmhost01
- Alblvmhost02
- Alblvmhost03
- Alblnetapp01
- Alblnetapp02
- Albl-synology1

### Unknown / unresolved domain
- ALBL-NUT Server = `tbd`
- OEL-DB01 = no UPS listed

## Dashboard Requirements
For each UPS, the dashboard should show:

### Normal state
- UPS name
- current status
- estimated runtime
- no shutdown pending

### On battery / pending
- UPS is on battery
- countdown timer is active
- time remaining until shutdown begins
- planned action scope for that UPS:
  - Targeted shutdown
  - Broader VMware shutdown
  - Alert only

### Power restored / canceled
- show: shutdown canceled / power restored
- show which UPS was affected
- clear countdown
- return status to normal after logging the event

### Shutdown committed
- show shutdown in progress
- show which UPS triggered it
- show domain/action type
- optionally show current phase

### Finalized
- show shutdown completed or finalization reached
- keep event visible in log/history

### Required Feature
For each UPS that goes ONBATT, the dashboard must display a countdown showing how long remains until shutdown begins.

## Event Logging Requirements
For every UPS event, the log should record at minimum:

### ONBATT event
- timestamp
- UPS name
- runtime at event
- countdown duration selected

### Countdown started
- timestamp
- UPS name
- shutdown scope
- countdown time remaining

### Power restored / canceled
- timestamp
- UPS name
- message: shutdown canceled / power restored
- whether shutdown actions had not yet started

### Shutdown committed
- timestamp
- UPS name
- message: shutdown sequence started
- shutdown scope:
  - targeted
  - broader
  - alert only

### Per-system actions
For each target:
- timestamp
- UPS name
- target name
- target type
- action attempted
- result:
  - success
  - failed
  - skipped
  - not applicable

### End summary per UPS event
- UPS that triggered
- systems that began shutdown
- systems that stayed up
- whether there was:
  - shutdown canceled / power restored
  - or
  - shutdown completed

## Orchestration Rules
- Do not put shutdown logic in `/etc/nut/ups.conf`
- Do not assume one global battery timer fits every UPS
- Use the shortest-runtime UPS units to drive earliest shutdown planning
- Leave sufficient battery reserve for:
  - orderly guest shutdown
  - orderly host shutdown
  - storage shutdown
  - NUT server final action
- Abort logic must remain in place if utility power returns before final shutdown commitment
- Use the spreadsheet UPS column as the source of system-to-UPS grouping
- Do not finalize production thresholds until remaining unknown UPS assignments are resolved

## What the Spreadsheet UPS Column Now Defines
The `UPS` column in `master_merged_shutdown_startup_schedule_fixed.xlsx` now gives the project enough information to define:

1. which UPS event should affect which exact systems
2. which UPS-backed group should trigger which host/VM/application shutdown set
3. which systems belong to each protected UPS group
4. which UPS-backed groups are most urgent based on runtime

## What Still Requires Design Decisions
The spreadsheet UPS column does not by itself finalize:
1. exact per-group shutdown thresholds for VM, host, storage, and NUT completion for the still-unfinalized UPS domains
2. how to treat non-server infrastructure on UPS events:
   - Cisco switches
   - Cisco firewall
   - routers
   - surge protectors
   - tape drive
   - PDU cabinet

## What Is Already Decided
The reserve battery target before final shutdown commitment is already decided for the approved UPS domains:

- ups8: reserve target left 4–6 minutes
- ups7: reserve target left 5–7 minutes
- ups2: reserve target left 10+ minutes
- ups9: reserve target left 10–12 minutes
- ups6: delayed shutdown model already approved

The reserve target remains unfinalized only for:
- ups1
- ups3
- ups4 / UPS 3_3
- ups5 / Rack 4_3

## Current Blockers
- `CHANGE_ME_VCSA_LAST_HOST` still unresolved
- VMware control method still not fully selected
- storage shutdown method still needs to be finalized
- ALBL-NUT Server UPS assignment still unknown
- OEL-DB01 UPS assignment still unknown

## Updated Next Required Inputs
Before live shutdown orchestration can be safely coded:
1. confirm any remaining unknown UPS assignments
2. identify the final ESXi host that carries vCenter during shutdown
3. choose the VMware control method
4. confirm storage shutdown method
5. define final completion thresholds for the still-unfinalized UPS domains using:
   - UPS runtime
   - shutdown order
   - expected shutdown duration
   - desired safety reserve
