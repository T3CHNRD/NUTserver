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

1. <INTERNAL_IP>   Exchange
2. <INTERNAL_IP>  SQL
3. <INTERNAL_IP>  VMware Assistant
4. <INTERNAL_IP>   AD / SDC1
5. <INTERNAL_IP>   Web build
6. <INTERNAL_IP>   Web prod
7. <INTERNAL_IP>  Maintenance VM
8. <INTERNAL_IP>  Parkview
9. <INTERNAL_IP>  ActiveIQ
10. <INTERNAL_IP> Oracle DB
11. <INTERNAL_IP>  VOIP

### Wave 2 — ESXi / vCenter

12. <INTERNAL_IP>
13. <INTERNAL_IP>
14. <INTERNAL_IP>
15. <INTERNAL_IP> (vCenter)

### Wave 3 — Physical Hosts

16. <INTERNAL_IP>
17. <INTERNAL_IP>
18. <INTERNAL_IP>

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
→ Lansweeper ONLY (<INTERNAL_IP>)

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
