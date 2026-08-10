# UPS Inventory and Rack Mapping

## Purpose
This document records the full UPS inventory, friendly names, rack locations, connection methods, and live NUT entry names for the NUT server project.

## Important Note
- `/etc/nut/ups.conf` remains the live NUT device configuration file.
- This document is for documentation, planning, and shutdown-design reference.
- Do not replace `/etc/nut/ups.conf` with this document.
- Do not put shutdown logic directly into `/etc/nut/ups.conf`.

## Source References
- Live internal reference:
  - `config/ups.conf.reference`
- Sanitized documentation reference:
  - `config/ups.conf.sanitized`

## Full Inventory and Rack Mapping

### ups1
- NUT Name: `ups1`
- Model: APC Smart-UPS 1500
- Serial: AS1113130969
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.153
- Friendly Name: UPS_Test
- Location: Rack 1 - Network
- Notes: Converted from USB to Network/SNMP

### ups2
- NUT Name: `ups2`
- Model: APC Back-UPS RS 1500G
- Serial: 3B1237X19716
- Connection: USB
- Driver: `usbhid-ups`
- Location: Rack 2 - USB

### ups3
- NUT Name: `ups3`
- Model: APC Back-UPS XS 1200
- Serial: JB0527045561
- Connection: USB
- Driver: `usbhid-ups`
- Location: Rack 2 - USB

### ups4
- NUT Name: `ups4`
- Model: APC Smart-UPS 3000
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.152
- Friendly Name: UPS 3_3
- Location: MDF Rack 3

### ups5
- NUT Name: `ups5`
- Model: APC Smart-UPS 3000 XLM
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.150
- Friendly Name: Rack 4_3
- Location: MDF Rack 4

### ups6
- NUT Name: `ups6`
- Model: Tripp Lite SU3000RTXL3U
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.154
- Location: MDF Rack 5

### ups7
- NUT Name: `ups7`
- Model: Tripp Lite SU3000RTXL3U
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.151
- Location: MDF Rack 2

### ups8
- NUT Name: `ups8`
- Model: APC Back-UPS RS 1300G
- Serial: 4B1206P36742
- Connection: USB
- Driver: `usbhid-ups`
- Location: Rack 5 - USB

### ups9
- NUT Name: `ups9`
- Model: Tripp Lite SU5000RT4UHV
- Connection: Network / SNMP
- Driver: `snmp-ups`
- IP: 192.168.3.252
- Location: MDF Cabinet 1

## Design Use
This document should be used together with:
- `config/ups.conf.reference`
- `config/ups.conf.sanitized`
- `docs/UPS-RUNTIME-REFERENCE.md`
- `docs/UPS-TO-SYSTEM-MAPPING.md`
- `docs/UPS-RUNTIME-TIERS.md`

## Separation of Responsibilities
- `ups.conf` = live NUT device definitions
- inventory/rack mapping docs = planning and documentation
- shutdown logic files = orchestration design
- runtime mapping docs = battery-aware shutdown planning
