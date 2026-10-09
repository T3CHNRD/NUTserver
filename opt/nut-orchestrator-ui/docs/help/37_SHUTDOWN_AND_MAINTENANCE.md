# Shutdown Sequencing and UPS Maintenance Suppression

**Use when:** documenting a captured UPS event path, evaluating a maintenance session, or understanding the final local shutdown boundary.

**Normal orchestration:** the reviewed source contains event cases and configured delays: UPS7 240 seconds, UPS2 315, UPS8 180, UPS6 300, UPS9 360, UPS3 300. UPS1, UPS4 and UPS5 are alert-only in the captured handler. UPS3’s event path is a Phase 2 validation/abort helper, not evidence of a normal target shutdown wave. For UPS9, source order is VMware, Synology, NetApp01, NetApp02, then local final wrapper. <DATABASE_SERVER_1>/<DATABASE_SERVER_2> are sent before their independent verification/classification. These are source-inspected branches, not a live test.

**Maintenance:** COMMBAD/COMMOK handlers update maintenance state. Shutdown commit suppression is per UPS: the helper suppresses only when a matching UPS record is present in `active_sessions` with status `active` or `warning`. No matching record permits normal handling. Invalid/unreadable state yields an error; the orchestrator logs the error and does not suppress, so the ordinary mode gates and commit path continue. Maintenance is not a universal shutdown lock.

**Final shutdown:** the final wrapper requires its own simulation/live/approval checks and then calls the local OS shutdown command. No Observium call appears in the captured orchestrator or final wrapper. Observium-first ordering remains unimplemented in this path.

**Do not conflate:** per-UPS cancelable timers with upsmon FSD. Separate server evidence captured SHUTDOWNCMD as `/sbin/shutdown -h now` and POWERDOWNFLAG as `/etc/killpower`. The direct command bypasses the local final wrapper. The October 9 manual upssched capture confirms the six delays and matching ONLINE cancellation rules. Those cancellation rules apply to pending timers, not proof that FSD clears when utility power returns.

**Evidence:** `/usr/local/bin/nut-orchestrator.sh` lines 119-179, 194-389, 608-880; `/usr/local/sbin/nut-ups-maintenance-suppression-check` lines 21-46; `/usr/local/sbin/nut-local-final-shutdown.sh` lines 31-70.
