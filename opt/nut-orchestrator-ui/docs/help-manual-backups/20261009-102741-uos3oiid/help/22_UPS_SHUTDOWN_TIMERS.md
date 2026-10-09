# UPS Shutdown Timers

Base revision 2026-10-08 | Evidence update 2026-10-09

Use this reference to check how long each configured UPS countdown waits. These timer declarations and matching cancellation rules were read from the server; no shutdown test was performed.

## 1 Current countdowns

| UPS | Seconds | Minutes |
| --- | --- | --- |
| UPS7 | 240 | 4 |
| UPS2 | 315 | 5 minutes 15 seconds |
| UPS8 | 180 | 3 |
| UPS6 | 300 | 5 |
| UPS9 | 360 | 6 |
| UPS3 | 300 | 5 |

## 2 When power returns

Each listed timer has a matching ONLINE rule that cancels its pending countdown when the UPS reports utility power has returned. This does not prove cancellation of an action already started or clearing of a separate forced-shutdown condition.

## 3 Where these settings live

The declarations are in /etc/nut/upssched.conf. The timer names are ups7-commit, ups2-commit, ups8-commit, ups6-commit, ups9-commit and ups3-commit. A timer name is not proof of the action it performs; check the corresponding handler before changing a countdown.

Verification: operator-supplied extraction, source lines 8–40, received 2026-10-09. This extraction does not establish all rules for UPS1, UPS4 or UPS5.
