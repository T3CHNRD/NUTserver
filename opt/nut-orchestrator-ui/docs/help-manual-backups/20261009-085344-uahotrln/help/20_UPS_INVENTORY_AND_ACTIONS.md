# UPS Inventory and Automatic Actions

## Purpose

This article identifies what each UPS protects and, separately, what the NUT server is currently configured to shut down automatically.

Physical power connection and automatic NUT shutdown action are not the same thing.

A device may be physically powered by a UPS while being alert-only or having no automatic shutdown action.

Do not assume rack location alone proves what equipment is connected to a UPS.

---

## Current UPS Locations

| UPS | Location |
|---|---|
| UPS1 | Rack 1 - Network |
| UPS2 | Rack 2 - USB |
| UPS3 | Rack 2 - USB |
| UPS4 | Rack 3 - Network |
| UPS5 | Rack 4 - Network |
| UPS6 | Rack 5 - Network |
| UPS7 | Rack 2 - Network |
| UPS8 | Rack 5 - USB |
| UPS9 | MDF Cabinet 1 - Network |

---

## UPS1

### Current NUT Behavior

UPS1 is currently an alert-only UPS path.

NUT monitors ONBATT, ONLINE, LOWBATT, COMMBAD, and COMMOK events.

There is no automatic shutdown timer or production shutdown action assigned to UPS1.

### Physical Equipment

The current Help/source reconciliation does not yet contain a verified authoritative equipment list for UPS1.

Physical connections must be verified before documenting equipment as current.

Search phrases:

- what is on UPS1
- what is plugged into UPS1
- UPS1 shutdown
- UPS1 alert only

---

## UPS2

### Current NUT Behavior

UPS2 protects the Blue Iris shutdown domain.

ONBATT starts a 420-second shutdown timer.

If utility power returns before commit, ONLINE cancels the pending shutdown timer.

If the timer reaches commit while production shutdown actions are allowed, NUT invokes the Blue Iris shutdown wrapper.

### Automatic Shutdown Target

- Blue Iris

### Shutdown Wrapper

`/usr/local/sbin/nut-blueiris-shutdown.sh`

Search phrases:

- what is on UPS2
- what does UPS2 shut down
- Blue Iris UPS
- Blue Iris shutdown timer

---

## UPS3

### Known Physical / Historical Equipment Association

Recovered orchestration documentation identifies the UPS3 domain as:

- Cisco 3850 switch
- Video Server
- Dell PowerEdge 1950

These equipment associations describe the UPS3 power/domain documentation.

They do not mean that NUT currently shuts those devices down automatically.

### Current NUT Behavior

UPS3 is monitored by NUT.

ONBATT starts a 300-second timer.

UPS3 currently uses a validation-only commit path.

When the timer reaches commit, the orchestrator records that the Phase 2 UPS3 validation timer expired.

It does not currently issue production shutdown commands to the Cisco 3850, Video Server, or Dell 1950.

ONLINE before commit cancels the timer through the UPS3 power-restore-abort validation path.

### Important Distinction

UPS3 is not an empty UPS.

It has documented equipment associated with it, but its current automatic shutdown behavior is validation-only.

Search phrases:

- what is on UPS3
- what is plugged into UPS3
- Cisco 3850 UPS
- Video Server UPS
- Dell 1950 UPS
- UPS3 shutdown
- UPS3 validation
- why does UPS3 not shut anything down

---

## UPS4

### Current NUT Behavior

UPS4 is currently an alert-only UPS path.

There is no automatic shutdown timer or production shutdown action assigned to UPS4.

### Physical Equipment Reconciliation

Historical spreadsheet-derived documentation contains several UPS4 / UPS 3_3 equipment associations.

Those older mappings conflict with parts of the current live shutdown design and must not be treated as authoritative current physical wiring until they are physically reverified.

Search phrases:

- what is on UPS4
- UPS4 alert only
- UPS 3_3
- what does UPS4 shut down

---

## UPS5

### Current NUT Behavior

UPS5 is currently an alert-only UPS path.

There is no automatic shutdown timer or production shutdown action assigned to UPS5.

### Physical Equipment Reconciliation

Historical documentation associates UPS5 / Rack 4_3 with systems including PDC1, OPC Server, and an LTO-7 Tape Drive.

These are historical physical mappings and must be physically reverified before being treated as the current authoritative wiring.

Search phrases:

- what is on UPS5
- UPS5 alert only
- Rack 4 UPS
- what does UPS5 shut down

---

## UPS6

### Current NUT Behavior

UPS6 uses a 300-second shutdown timer.

### Automatic Shutdown Target

- Lansweeper

### Alert-Only Equipment

- Cisco ASA 5508
- AT&T router

The network equipment is intentionally not automatically shut down by the current orchestrator.

### Shutdown Wrapper

`/usr/local/sbin/nut-lansweeper-shutdown.sh`

Search phrases:

- what is on UPS6
- Lansweeper UPS
- Cisco ASA UPS
- firewall UPS
- router UPS
- UPS6 shutdown

---

## UPS7

### Current NUT Behavior

UPS7 uses a 240-second shutdown timer.

### Automatic Shutdown Targets

- DB01
- DB02

Both Solaris shutdown commands are attempted before post-shutdown verification begins.

The current shutdown integration uses the dedicated Solaris/Telnet DB shutdown wrapper.

### Shutdown Wrapper

`/usr/local/sbin/nut-db-shutdown.sh`

### Historical Mapping Warning

Some older spreadsheet-derived documents placed DB01 and DB02 under UPS4 / UPS 3_3.

That is not the current NUT shutdown mapping.

The current live orchestrator assigns DB01 and DB02 to UPS7.

Physical power wiring should still be independently verified before a live outage test.

Search phrases:

- what is on UPS7
- which UPS protects DB01
- which UPS protects DB02
- DB01 UPS
- DB02 UPS
- UPS7 shutdown

---

## UPS8

### Current NUT Behavior

UPS8 uses a 180-second shutdown timer.

### Automatic Shutdown Target

- VOIP server

### Alert-Only Equipment

- VME Server
- Merlin phone switch

Historical source material also lists additional equipment in the UPS8 domain. Those physical associations should be reconciled before being promoted to current authoritative status.

### Shutdown Wrapper

`/usr/local/sbin/nut-voip-shutdown.sh`

Search phrases:

- what is on UPS8
- VOIP UPS
- VME UPS
- Merlin UPS
- phone system UPS
- UPS8 shutdown

---

## UPS9

### Current NUT Behavior

UPS9 is the broader VMware/storage shutdown domain.

ONBATT starts a 360-second timer.

When shutdown commits, the current orchestration sequence is:

1. VMware shutdown domain
2. Synology
3. NetApp01
4. NetApp02
5. NUT server final shutdown

The NUT server is intentionally the final shutdown step so it remains available to coordinate and record the earlier shutdown actions.

### VMware Domain

The VMware wrapper handles the configured VM/VCSA/ESXi shutdown phases.

### Storage

After the VMware workflow:

- Synology shutdown is attempted
- NetApp01 halt is attempted
- NetApp02 halt is attempted

### Final System

The NUT server shutdown wrapper runs last.

### Shutdown Wrappers

- `/usr/local/sbin/nut-vmware-shutdown.sh`
- `/usr/local/sbin/nut-synology-shutdown.sh`
- `/usr/local/sbin/nut-netapp-halt.sh`
- `/usr/local/sbin/nut-local-final-shutdown.sh`

Search phrases:

- what is on UPS9
- what does UPS9 shut down
- VMware UPS
- ESXi UPS
- Synology UPS
- NetApp UPS
- why does NUT server shut down last
- UPS9 shutdown order

---

## Physical Connection Versus Automatic Shutdown

Always distinguish these two questions:

### What is physically plugged into this UPS?

This describes electrical power wiring.

NUT software cannot independently prove which power cord is plugged into which UPS.

Use current rack documentation and physical verification.

### What will NUT automatically shut down?

This is determined by:

- `upsmon`
- `upssched`
- the NUT orchestrator
- the production-mode safety gates
- UPS Maintenance Mode
- the individual shutdown wrappers

A physically connected device can intentionally be alert-only.

---

## Current Timer Summary

| UPS | Timer | Current Automatic Action |
|---|---:|---|
| UPS1 | None | Alert only |
| UPS2 | 420 seconds | Blue Iris |
| UPS3 | 300 seconds | Validation-only commit |
| UPS4 | None | Alert only |
| UPS5 | None | Alert only |
| UPS6 | 300 seconds | Lansweeper |
| UPS7 | 240 seconds | DB01 + DB02 |
| UPS8 | 180 seconds | VOIP |
| UPS9 | 360 seconds | VMware/storage/NUT sequence |

---

## Safety Rule

Do not intentionally create a real ONBATT condition merely to determine what a UPS controls.

Verify software mappings read-only and verify physical power wiring separately.

---

## Related Help

- Shutdown Orchestration
- Protected Systems
- Monitoring
- Events
- Tests and Logs
- Configuration
