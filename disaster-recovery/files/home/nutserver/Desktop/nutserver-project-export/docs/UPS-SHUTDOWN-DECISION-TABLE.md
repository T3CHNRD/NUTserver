# UPS Shutdown Decision Table

## Purpose
This document defines the approved first-pass shutdown decision logic per UPS before code is written.

---

## ups8
- Runtime: 15m
- Countdown before shutdown: 3m
- If power returns during countdown: cancel immediately
- Shutdown scope: targeted shutdown
- Graceful shutdown targets:
  - VOIP
  - VME Server
  - Merlin phone switch
- Alert only:
  - Comcast 3909 R
  - remote access
- LOWBATT behavior:
  - finalize immediately

---

## ups7
- Runtime: 18m
- Countdown before shutdown: 4m
- If power returns during countdown: cancel immediately
- Shutdown scope: targeted shutdown
- Graceful shutdown targets:
  - DB01
  - DB02
- Alert only:
  - PDU Cabinet
- LOWBATT behavior:
  - finalize immediately

---

## ups2
- Runtime: 30m
- Countdown before shutdown: 7m
- If power returns during countdown: cancel immediately
- Shutdown scope: targeted shutdown
- Graceful shutdown targets:
  - Blue Iris
- Alert only:
  - none currently approved
- LOWBATT behavior:
  - continue graceful path, then finalize if needed

---

## ups4 / UPS 3_3
- Runtime: 34m
- Countdown before shutdown: not finalized
- If power returns during countdown: cancel immediately
- Shutdown scope: alert only for now
- Graceful shutdown targets:
  - Observium remains listed here, but wider ups4 automation is not finalized
- Alert only:
  - all other ups4 devices until reconciliation is complete

---

## ups6
- Runtime: 19h 2m
- Countdown before shutdown: 25m
- If power returns during countdown: cancel immediately
- Shutdown scope: targeted shutdown
- Graceful shutdown targets:
  - Lansweeper
- Alert only:
  - Cisco Asa 5508
  - AT&T 4808 Router
- LOWBATT behavior:
  - finalize if still on battery after graceful path begins

---

## ups9
- Runtime: 37m
- Countdown before shutdown: 4m
- If power returns during countdown: cancel immediately
- Shutdown scope: broader VMware shutdown
- Graceful shutdown sequence:
  1. WebServer-1
  2. Albl-Exch2019
  3. albl-SageSQL
  4. alblvvsaa
  5. ALBL-WSUS
  6. ALBL-ActiveIQ
  7. ALBL-ParkView-1
  8. ALBL-SDC1
  9. ALBL-VCSA
  10. Alblvmhost01
  11. Alblvmhost02
  12. Alblvmhost03
  13. CHANGE_ME_VCSA_LAST_HOST
  14. Alblnetapp01
  15. Alblnetapp02
  16. Albl-synology1
- Alert only:
  - none currently approved
- LOWBATT behavior:
  - finalize remaining actions immediately

---

## ups1 / ups3 / ups5
- Shutdown scope: alert only for now
- Reason:
  - not finalized / under reconciliation
- Automatic shutdown:
  - not yet approved
