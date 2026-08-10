# NUT Server Project README

## Purpose
This document explains how the NUT server project works in the current environment, what design and implementation decisions have already been made, how UPS runtimes affect shutdown behavior, what wrappers and workflows already exist, and what still remains to be completed.

This is intended to be a practical support and handoff document.

---

## Current Project State
The NUT server project is **partially implemented and actively progressing**.

### What is already true
- Core NUT server is operational
- Dashboard is operational
- All 9 UPS entries are online
- Human-readable UPS status wording has been implemented
- Socket permission handling has been stabilized
- UPS recovery after reboot was corrected using serial-based identification for `ups2`
- `ups.conf` truncation issue was corrected
- `upsmon` / `upssched` event flow has been tested successfully
- Shutdown countdown and restore-power cancellation logic are working
- Known-good configuration and logs were frozen for rollback purposes
- Wrapper scripts now exist on the NUT server for several shutdown domains
- The orchestrator has been updated to call the real wrappers where available

### What is not fully complete yet
- Not all wrappers have been fully validated against live target systems
- VMware flow exists, but still needs safe validation and live testing
- NetApp flow exists, but still needs safe validation and live testing
- Lansweeper flow exists, but still needs Windows SSH validation
- Dashboard integration with all per-UPS state/history views is not yet fully finished
- Final controlled end-to-end outage testing has not yet been completed

---

## Current Project Document Set
The current working document set is:

- **HA Shutdown Plan**
- **HA Cluster Design Notes**
- **UPS to System Mapping**
- **Shutdown Orchestration Design**
- **implementation decision sheet**
- **UPS Shutdown Decision Table**
- **VMware Control Decision**
- **UPS Action Matrix**

These are the project’s current authoritative working docs.

---

## High-Level Shutdown Philosophy

### Shutdown model: outside-in
During a battery event, systems shut down from the outside in:

1. non-critical apps
2. business apps
3. cluster support
4. identity / core data
5. vCenter as the final VMware VM
6. ESXi hosts
7. storage
8. NUT server last

### Startup model: inside-out
After power returns, systems start in the opposite order:

1. NUT server
2. storage
3. ESXi hosts
4. identity / network dependencies
5. management systems
6. applications

### NUT server role
The NUT server is the **orchestrator**. Its job is to:

- monitor UPS state
- detect `ONBATT` and `ONLINE`
- start a UPS-specific countdown
- cancel shutdown if power returns before commit
- run shutdown workflows when countdown expires
- record event/state information
- update dashboard-facing state files
- eventually shut itself down last once its own UPS is finalized

---

## Core Operational Rule
The single most important operating rule is:

**Power return during the countdown cancels shutdown immediately.**  
**Power return after shutdown has already started may not save every system.**

This rule was chosen because the environment frequently experiences short 3–5 minute outages that recover quickly.

---

## Operational State Flow

### State 1 — Normal
- Utility power is present
- No shutdown countdown is active

### State 2 — On battery / pending
- A UPS goes `ONBATT`
- A UPS-specific countdown starts
- The event is logged
- No shutdown occurs yet

### State 3 — Power restored during countdown
- Utility power returns before the countdown expires
- Shutdown is canceled immediately
- `shutdown canceled / power restored` is logged
- Pending state clears
- Systems remain online

### State 4 — Shutdown committed
- Countdown expires while still on battery
- Shutdown actions begin for that UPS domain

### State 5 — Finalization
- LOWBATT or final-stage logic is reached
- Remaining shutdown steps complete
- Final orchestration finishes
- NUT server final action happens later once its own UPS is finalized

---

## UPS Runtime Reference
Current runtime reference:

- **ups8** = 15 minutes
- **ups7** = 18 minutes
- **ups5 / Rack 4_3** = 26 minutes
- **ups3** = 27 minutes
- **ups2** = 30 minutes
- **ups4 / UPS 3_3** = 34 minutes
- **ups9** = 37 minutes
- **ups1 / UPS_Test** = 2h 6m
- **ups6** = 19h 2m

### Runtime tiers
#### Tier 1 — Critical shortest runtime
- ups8 = 15m
- ups7 = 18m

#### Tier 2 — High urgency
- ups5 / Rack 4_3 = 26m
- ups3 = 27m
- ups2 = 30m
- ups4 / UPS 3_3 = 34m

#### Tier 3 — Moderate urgency
- ups9 = 37m

#### Tier 4 — Long runtime
- ups1 / UPS_Test = 2h 6m

#### Tier 5 — Extended runtime
- ups6 = 19h 2m

---

## Approved Countdown / Timing Model

### ups8 — 15 minutes
- ONBATT detected immediately
- Cancelable countdown: 3 minutes
- If still on battery at 3 minutes: begin shutdown
- Target completion by 7–9 minutes elapsed
- Reserve target left: 4–6 minutes
- LOWBATT behavior: finalize immediately

### ups7 — 18 minutes
- ONBATT detected immediately
- Cancelable countdown: 4 minutes
- If still on battery at 4 minutes: begin shutdown
- Target completion by 9–10 minutes elapsed
- Reserve target left: 5–7 minutes
- LOWBATT behavior: finalize immediately

### ups2 — 30 minutes
- ONBATT detected immediately
- Cancelable countdown: 7 minutes
- If still on battery at 7 minutes: begin shutdown
- Target completion by 14–16 minutes elapsed
- Reserve target left: 10+ minutes

### ups9 — 37 minutes
- ONBATT detected immediately
- Cancelable countdown: 4 minutes
- If still on battery at 4 minutes: begin broader shutdown sequence
- Target completion by 20–25 minutes elapsed
- Reserve target left: 10–12 minutes

### ups6 — 19h 2m
- ONBATT detected immediately
- Cancelable countdown: 25 minutes
- If still on battery at 25 minutes: begin shutdown
- This UPS should not drive early site shutdown

### ups1 / ups3 / ups4 / ups5
- No fully committed automatic timing across the whole domain
- Mixed or partially approved domain behavior
- Unapproved items remain alert-only until finalized

---

## Current Per-UPS Domain Understanding

### ups2 domain
Current approved target:
- **Blue Iris**

Working assumption:
- **ALBL-NUT Server may eventually be placed on ups2**
- not final yet

### ups3 domain
Current mapped systems:
- Cisco 3850
- Video Server / Watchdog-type server
- Dell 1950

Current design status:
- mixed physical/support domain
- not fully automated yet

### ups4 / UPS 3_3 domain
Current mapped systems:
- Observium
- DB01
- DB02
- Cisco 3850
- Mail Gateway
- Rack 1 APC Surge Protector

Current design status:
- Observium = shutdown
- DB01 / DB02 = shutdown via Solaris wrapper path
- wider domain items remain alert-only unless explicitly approved

### ups5 / Rack 4_3 domain
Current mapped systems:
- PDC1
- OPC Server
- LTO-7 Tape Drive

Current design status:
- PDC1 = shutdown
- remaining items = alert-only unless explicitly approved

### ups6 domain
Current mapped systems:
- Lansweeper
- Cisco ASA 5508
- AT&T 4808 Router

Current approved behavior:
- Lansweeper = shutdown
- Cisco ASA 5508 = alert only
- AT&T router = alert only

### ups7 domain
Current mapped system:
- PDU Cabinet

Current design status:
- treat as infrastructure / alert-only domain unless later revised

### ups8 domain
Current mapped systems:
- VOIP
- VME Server
- Comcast 3909 R
- phone switch (Merlin)
- remote access

Current approved behavior:
- VOIP = shutdown
- VME Server = alert only
- Merlin = alert only
- Comcast router = alert only
- remote access = needs final confirmation if it remains shutdown-capable or alert-only in the final implementation

### ups9 domain
Current mapped systems:
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

Current approved behavior:
- broader VMware / storage shutdown domain
- main orchestration path for clustered VMware shutdown

### Unknown / unresolved domain
- ALBL-NUT Server = working assumption `ups2`, not fully final
- OEL-DB01 = unresolved / not part of the latest active implementation path

---

## Approved VMware Decisions

### Current platform
The current active virtualization platform is **VMware / vSphere**, orchestrated through **vCenter**.

### vCenter endpoint
Current configured vCenter endpoint:
- `192.168.99.84`

### VMware control method
Approved current method:
- **Primary** = vCenter API
- **PowerCLI fallback** = documented only, **not currently in active use**

### Host detection rule
The shutdown logic must **not** assume a fixed final host for vCenter.

Instead:
- dynamically detect which ESXi host is currently carrying `ALBL-VCSA`
- treat that host as the final compute host

### Future platform note
It is expected that VMware may eventually be replaced with **Proxmox**.  
This current shutdown design still targets **VMware/vCenter**, but future documentation and orchestration design should plan for a later Proxmox transition.

---

## Approved Storage Decisions

### Alblnetapp01
- management IP: `192.168.99.20`
- NUT-side wrapper: `/usr/local/sbin/nut-netapp-halt.sh`
- internal command over SSH: `system node halt ...`
- node name: `alblnetapp01`
- username: `admin`

### Alblnetapp02
- management IP: `192.168.99.30`
- NUT-side wrapper: `/usr/local/sbin/nut-netapp-halt.sh`
- internal command over SSH: `system node halt ...`
- node name: `alblnetapp02`
- username: `admin`

### Albl-synology1
- management IP: `192.168.1.250`
- NUT-side wrapper: `/usr/local/sbin/nut-synology-shutdown.sh`
- remote SSH user: `Admin`
- internal shutdown command: `sudo shutdown -P now`

---

## Settled Enough To Build Now — Wrapper / Command Map

### DB01
- wrapper: `/usr/local/sbin/nut-db-shutdown.sh`
- remote call: `ssh root@<DB01-IP> /usr/local/sbin/nut-db-shutdown.sh`
- internal command: Solaris shutdown path

### DB02
- wrapper: `/usr/local/sbin/nut-db-shutdown.sh`
- remote call: `ssh root@<DB02-IP> /usr/local/sbin/nut-db-shutdown.sh`
- internal command: Solaris shutdown path

### Blue Iris
- command path: `C:\Windows\System32\shutdown.exe`
- NUT-side wrapper: `/usr/local/sbin/nut-blueiris-shutdown.sh`

### VOIP
- wrapper: `/usr/local/sbin/nut-voip-shutdown.sh`
- remote SSH user: `root`
- internal command: `/usr/bin/systemctl poweroff`

### Alblnetapp01
- NUT-side wrapper: `/usr/local/sbin/nut-netapp-halt.sh`
- internal command over SSH: `system node halt ...`

### Alblnetapp02
- NUT-side wrapper: `/usr/local/sbin/nut-netapp-halt.sh`
- internal command over SSH: `system node halt ...`

### Albl-synology1
- NUT-side wrapper: `/usr/local/sbin/nut-synology-shutdown.sh`
- internal command: `sudo shutdown -P now`

### Lansweeper
- NUT-side wrapper: `/usr/local/sbin/nut-lansweeper-shutdown.sh`
- preferred remote method: Windows SSH with key-based auth
- Windows-side shutdown remains native `shutdown.exe`

### Merlin phone switch
- alert only
- no automatic wrapper

### Cisco ASA 5508
- alert only
- no automatic wrapper

### VME Server
- alert only
- no automatic wrapper

---

## Current Wrapper / Workflow Files on the NUT Server

The following workflow files now exist on the NUT server:

- `/usr/local/sbin/nut-db-shutdown.sh`
- `/usr/local/sbin/nut-blueiris-shutdown.sh`
- `/usr/local/sbin/nut-voip-shutdown.sh`
- `/usr/local/sbin/nut-synology-shutdown.sh`
- `/usr/local/sbin/nut-netapp-halt.sh`
- `/usr/local/sbin/nut-vmware-shutdown.sh`
- `/usr/local/sbin/nut-lansweeper-shutdown.sh`

The orchestrator has also been updated to call these wrappers where available.

---

## Dashboard Requirements
For each UPS, the dashboard should show:

### Normal
- UPS name
- current status
- estimated runtime
- no shutdown pending

### On battery / pending
- UPS is on battery
- countdown timer is active
- time remaining until shutdown begins
- planned action scope:
  - targeted shutdown
  - broader VMware shutdown
  - alert only

### Power restored / canceled
- show `shutdown canceled / power restored`
- show which UPS was affected
- clear countdown
- return to normal after logging

### Shutdown committed
- show shutdown in progress
- show which UPS triggered it
- show domain / action type
- optionally show current phase

### Finalized
- show shutdown completed or finalization reached
- keep event visible in log/history

### Required feature
- every UPS that goes ONBATT must show a countdown until shutdown starts

---

## Event Logging Requirements
For every UPS event, record at minimum:

### ONBATT
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

### Per-target action
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

### End summary
- UPS that triggered
- systems that began shutdown
- systems that stayed up
- whether shutdown was canceled or completed

---

## Important Current Notes

### Wrapper existence vs usability
A wrapper file existing does **not** guarantee the target system is fully ready.

The wrapper layer is now built, but some workflows still depend on:

- SSH access working
- correct usernames
- target permissions
- target-side services like OpenSSH being enabled
- safe validation testing

### Protected config
The shared orchestrator config file exists at:

- `/etc/nut/nut-orchestrator.conf`

It is root-readable only by design.

### VMware testing mode
`VCENTER_INSECURE="1"` means:
- ignore TLS certificate validation
- acceptable during testing
- not ideal for final production

---

## Current Remaining TODOs

### Lansweeper
- confirm OpenSSH Server is installed and enabled on the Windows 10 host
- confirm SSH key-based auth works from the NUT server
- confirm the Windows account can run `shutdown.exe` remotely

### ALBL-NUT Server
- final UPS assignment still not fully confirmed
- current working assumption = `ups2`

### Testing / cutover
- test wrappers individually
- test orchestrator commit actions manually
- restart and validate `nut-monitor` after wrapper/config validation
- wire dashboard fully to `/var/www/html/nut-state/*.json` and `events.log`
- run controlled end-to-end outage testing
- confirm rollback still works
- finalize support/runbook cleanup

### Future platform planning
- document that VMware is the current platform
- plan for future migration path to Proxmox

---

## Practical Summary
The most important current support facts are:

- the system uses **per-UPS countdowns**
- **power return during countdown cancels shutdown**
- VMware uses:
  - **vCenter API first**
  - **PowerCLI fallback documented only**
  - **dynamic ALBL-VCSA host detection**
- NetApp uses:
  - **SSH + `system node halt`**
- Synology uses:
  - **SSH + `sudo shutdown -P now`**
- Lansweeper is moving toward:
  - **Windows SSH + native shutdown**
- Cisco ASA, Merlin, and VME Server remain:
  - **alert only**
- wrapper files exist, but safe validation is still required before live cutover
