# NUT Shutdown Flow Chart

## UPS Scope

All configured UPS units:
- ups1
- ups2
- ups3
- ups4
- ups5
- ups6
- ups7
- ups8
- ups9

Dashboard displays all UPS inventory entries.

Shutdown automation currently monitors and triggers shutdown logic for:
- ups2
- ups6
- ups7
- ups8
- ups9

Production decision:
- ups2, ups6, ups7, ups8, and ups9 are shutdown-trigger UPS units
- ups1, ups3, ups4, and ups5 remain dashboard/status monitoring only

---

## Shutdown Timer Rules

| UPS  | Timer | Purpose |
|------|------:|--------|
| ups8 | 180s  | VOIP / early timer |
| ups7 | 240s  | DB01 / DB02 timer |
| ups6 | 300s  | Lansweeper timer |
| ups9 | 360s  | VMware / NetApp / Synology timer |
| ups2 | 420s  | Blue Iris / final timer |

If power returns before timer expiration:
→ ONLINE event cancels shutdown

---

## Power Event Flow

Utility Power Loss
        |
        v
UPS → ONBATT
        |
        +--> ups8 → 3 min timer
        +--> ups7 → 4 min timer
        +--> ups6 → 5 min timer
        +--> ups9 → 6 min timer
        +--> ups2 → 7 min timer
        |
        v

If power returns:
        |
        v
Cancel timers → Abort shutdown → Log event

If timer expires:
        |
        v
/usr/local/bin/nut-orchestrator.sh
        |
        v
Begin shutdown sequence

---

## Shutdown Order

### Wave 1 — Applications / VMs

1. 192.168.1.75   Exchange
2. 192.168.1.150  SQL
3. 192.168.99.86  VMware Assistant
4. 192.168.1.23   AD / SDC1
5. 192.168.1.21   Web build
6. 192.168.1.20   Web prod
7. 192.168.3.250  Maintenance VM
8. 192.168.99.92  Parkview
9. 192.168.99.88  ActiveIQ
10. 192.168.1.230 Oracle DB
11. 192.168.1.14  VOIP

### Wave 2 — ESXi / vCenter

12. 192.168.99.70
13. 192.168.99.72
14. 192.168.99.71
15. 192.168.99.84 (vCenter)

### Wave 3 — Physical Hosts

16. 192.168.99.62
17. 192.168.99.61
18. 192.168.99.60

---

## Simulated Test Flow

Simulated Test Button
        |
        v
/api/test/simulate
        |
        v
nut-ui-run-test simulate
        |
        v
Validate configs
        |
        v
Run ALL wrappers with SIMULATE=1
        |
        v
NO shutdown executed
        |
        v
Log results

---

## Real Test Flow

Real Test Button
        |
        v
Select Phase (1 / 2 / 3)
        |
        v
Enter passphrase
        |
        v
Backend validates hash
        |
        v
nut-ui-run-real-test-approved
        |
        v
ALLOW_REAL_TEST=1
        |
        v
nut-ui-run-test real

---

## Real Test Phases

Phase 1:
→ Lansweeper ONLY (192.168.10.158)

Phase 2:
→ Simulated outage
→ Simulated restore
→ Abort shutdown

Phase 3:
→ Full shutdown sequence

---

## Logs

/var/log/nut-orchestrator-ui/tests.log  
/var/log/nut-orchestrator-ui/power-events.log  
/var/log/nut-lansweeper-shutdown.log  
/var/log/nut-vmware-shutdown.log  
