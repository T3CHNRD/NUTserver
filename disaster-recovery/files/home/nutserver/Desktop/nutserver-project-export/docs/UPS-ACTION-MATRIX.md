# UPS Action Matrix

## Purpose
This document defines the exact first-pass action scope per UPS for the domains that are already approved for implementation.

---

## ups8
### Graceful shutdown targets
- VOIP
- VME Server
- Merlin phone switch

### Alert only
- Comcast 3909 R
- remote access

### Notes
- Shortest runtime UPS
- Highest urgency
- Shutdown starts after approved cancelable countdown expires

---

## ups7
### Graceful shutdown targets
- DB01
- DB02

### Alert only
- PDU Cabinet

### Notes
- Critical database UPS
- Shutdown starts after approved cancelable countdown expires

---

## ups2
### Graceful shutdown targets
- Blue Iris

### Alert only
- none currently approved

### Notes
- Observium is not on ups2
- ups2 currently applies to Blue Iris only

---

## ups4 / UPS 3_3
### Graceful shutdown targets
- Observium

### Alert only
- none currently approved

### Notes
- Observium is on ups3_3 in the spreadsheet
- In the NUT/environment naming, ups3_3 should be treated as ups4 / UPS 3_3
- Additional ups4 / UPS 3_3 devices remain under reconciliation and are not all approved for automatic shutdown yet

---

## ups6
### Graceful shutdown targets
- Lansweeper

### Alert only
- Cisco Asa 5508
- AT&T 4808 Router

### Notes
- Long-runtime UPS
- PDC1 is not being treated as an ups6 shutdown target in the corrected merged-sheet design

---

## ups9
### Graceful shutdown targets
#### Phase 1 - Non-Critical Apps
- WebServer-1

#### Phase 2 - Business Apps
- Albl-Exch2019
- albl-SageSQL
- alblvvsaa

#### Phase 3 - Cluster Support
- ALBL-WSUS
- ALBL-ActiveIQ
- ALBL-ParkView-1

#### Phase 4 - Core Identity / Data
- ALBL-SDC1

#### Phase 5 - Final VM
- ALBL-VCSA

#### Phase 6 - ESXi Hosts
- Alblvmhost01
- Alblvmhost02
- Alblvmhost03
- CHANGE_ME_VCSA_LAST_HOST

#### Phase 7 - Storage
- Alblnetapp01
- Alblnetapp02
- Albl-synology1

### Alert only
- none currently approved

### Notes
- Main VMware orchestration domain
- Broader shutdown path
- vCenter last VM
- Hosts after guest VMs
- Storage after compute
