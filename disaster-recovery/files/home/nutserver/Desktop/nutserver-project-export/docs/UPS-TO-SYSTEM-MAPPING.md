# UPS to System Mapping

## Purpose
This document maps each UPS to the systems it protects so shutdown timing can be based on actual runtime limits.

## Source
This mapping is based on the `UPS` column in:
- `master_shutdown_startup_schedule.xlsx`

## Runtime Reference
- ups1 / UPS_Test = 2h 6m
- ups2 = 30m
- ups3 = 27m
- ups4 / UPS 3_3 = 34m
- ups5 / Rack 4_3 = 26m
- ups6 = 19h 2m
- ups7 = 18m
- ups8 = 15m
- ups9 = 37m

## Mapping Table

### ups1 / UPS_Test
- Runtime: 2h 6m
- Connection: Network / SNMP
- Protected systems:
  - TBD
- Notes:
  - Friendly name: UPS_Test
  - No confirmed systems mapped from the current spreadsheet yet

### ups2
- Runtime: 30m
- Connection: USB
- Protected systems:
  - Blue Iris | Physical | Windows Server 2012 R2 Standard | 192.168.1.25 | Shutdown order 1
  - Observium | Physical | Ubuntu 20.04.5 | 192.168.3.230 | Shutdown order 1
- Notes:
  - Short-runtime UPS
  - Non-critical apps only in current sheet

### ups3
- Runtime: 27m
- Connection: USB
- Protected systems:
  - TBD
- Notes:
  - No confirmed systems mapped from the current spreadsheet yet

### ups4 / UPS 3_3
- Runtime: 34m
- Connection: Network / SNMP
- Protected systems:
  - TBD
- Notes:
  - Friendly name: UPS 3_3
  - No confirmed systems mapped from the current spreadsheet yet

### ups5 / Rack 4_3
- Runtime: 26m
- Connection: Network / SNMP
- Protected systems:
  - TBD
- Notes:
  - Friendly name: Rack 4_3
  - No confirmed systems mapped from the current spreadsheet yet

### ups6
- Runtime: 19h 2m
- Connection: Network / SNMP
- Protected systems:
  - PDC1 | Physical | Windows Server 2025 | 192.168.1.22 | Shutdown order 5 / Startup order 3
- Notes:
  - Long-runtime UPS
  - Protects a core identity server

### ups7
- Runtime: 18m
- Connection: Network / SNMP
- Protected systems:
  - DB01 | Physical | Solaris 10 | 192.168.1.9 | Shutdown order 5 / Startup order 3
  - DB02 | Physical | Solaris 10 | 192.168.1.11 | Shutdown order 5 / Startup order 3
- Notes:
  - Very short-runtime UPS
  - Protects critical database systems
  - High priority for shutdown timing design

### ups8
- Runtime: 15m
- Connection: USB
- Protected systems:
  - VOIP | Physical | Ubuntu 24.04 | 192.168.1.14 | Shutdown order 7 / Startup order 6
- Notes:
  - Shortest-runtime UPS
  - Must be treated as highest timing urgency

### ups9
- Runtime: 37m
- Connection: Network / SNMP
- Protected systems:
  - WebServer-1 | Physical | Ubuntu 20.04.5 | 192.168.1.20 | Shutdown order 1 / Startup order 6
  - Albl-Exch2019 | VM | Windows | 192.168.1.75 | Shutdown order 2 / Startup order 6
  - albl-SageSQL | VM | Windows | 192.168.1.150 | Shutdown order 2 / Startup order 5
  - alblvvsaa | VM | Linux | 192.168.99.86 | Shutdown order 2
  - ALBL-WSUS | VM | Down / powered off in sheet | 192.168.1.35 | Shutdown order 3
  - ALBL-ActiveIQ | VM | Linux | 192.168.99.88 | Shutdown order 3 / Startup order 4A
  - ALBL-ParkView-1 | VM | Linux | 192.168.99.92 | Shutdown order 3 / Startup order 4A
  - ALBL-VCSA | VM | Linux | 192.168.99.84 | Shutdown order 5a / Startup order 2A
  - ALBL-SDC1 | VM | Windows | IP not listed in sheet | Shutdown order 5 / Startup order 3
  - Alblvmhost01 | Physical | VMware ESXi 7.03 | 192.168.99.70 | Shutdown order 6 / Startup order 2
  - Alblvmhost02 | Physical | VMware ESXi 7.03 | 192.168.99.71 | Shutdown order 6 / Startup order 2
  - Alblvmhost03 | Physical | VMware ESXi 7.03 | 192.168.99.72 | Shutdown order 6 / Startup order 2
  - Alblnetapp01 | Physical | Storage | 192.168.99.20 | Shutdown order 6a / Startup order 1A
  - Alblnetapp02 | Physical | Storage | 192.168.99.30 | Shutdown order 6a / Startup order 1A
  - Albl-synology1 | Physical | Synology DSM | 192.168.1.250 | Shutdown order 6a / Startup order 1A
- Notes:
  - Main VMware / storage / application UPS in the current sheet
  - Even though runtime is longer than ups7/ups8, this UPS protects the largest and most critical shutdown set
  - This UPS will likely drive most clustered shutdown orchestration logic

### TBD / Unknown UPS assignment
- Protected systems:
  - ALBL-NUT Server | VM | Ubuntu 24.04 | 192.168.3.251 | Shutdown order 8 / Startup order 1
  - OEL-DB01 | VM | OS not listed in current rows | IP not listed in current rows | Shutdown order 4
- Notes:
  - These systems appear in the spreadsheet with no confirmed UPS assignment
  - The NUT server UPS assignment must be confirmed before final timing is trusted

## Notes
- This mapping is based on the spreadsheet UPS column and current planning inputs.
- Use the real NUT names from `ups.conf`.
- Do not guess. Only enter confirmed mappings.
- This mapping must be completed before final shutdown timing can be trusted.
- The shortest-runtime UPS-backed systems should be evaluated first.
- The largest orchestration set currently appears to be on `ups9`.

## Highest Priority UPS Units to Evaluate First
1. ups8 = 15m
2. ups7 = 18m
3. ups5 / Rack 4_3 = 26m
4. ups3 = 27m
5. ups2 = 30m
6. ups4 / UPS 3_3 = 34m
7. ups9 = 37m
8. ups1 / UPS_Test = 2h 6m
9. ups6 = 19h 2m

## Remaining Mapping Gaps
- ups1 / UPS_Test = not yet mapped
- ups3 = not yet mapped
- ups4 / UPS 3_3 = not yet mapped
- ups5 / Rack 4_3 = not yet mapped
- ALBL-NUT Server = UPS assignment still unknown
- OEL-DB01 = UPS assignment still unknown
