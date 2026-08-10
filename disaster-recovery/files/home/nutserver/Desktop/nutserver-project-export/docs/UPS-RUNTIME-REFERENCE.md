# UPS Runtime Reference

## Purpose
This document records the approximate battery runtime currently available on each UPS so the shutdown design can be based on actual available hold time.

## Current Runtime Reference

| UPS Name   | Approximate Runtime |
|------------|---------------------|
| UPS_test   | 2h 6m               |
| ups2       | 30m                 |
| ups3       | 27m                 |
| ups3_3     | 34m                 |
| Rack 4_3   | 26m                 |
| ups8       | 15m                 |
| ups6       | 19h 2m              |
| ups7       | 18m                 |
| ups9       | 37m                 |

## Immediate Design Impact
- A single shutdown timer should not be assumed to fit every UPS.
- Short-runtime UPS units must be treated as higher urgency.
- Any system attached to the shortest-runtime UPS units may need earlier action.
- Runtime-aware shutdown planning must be completed before final production timing is set.

## High-Urgency UPS Units
These UPS units have the least time available and must be considered first in timing design:
- ups8 = 15m
- ups7 = 18m
- ups3 = 27m
- Rack 4_3 = 26m
- ups2 = 30m
- ups3_3 = 34m
- ups9 = 37m

## Lower-Urgency / Longer Runtime Units
- UPS_test = 2h 6m
- ups6 = 19h 2m

## Notes
- These values should be treated as planning inputs, not guaranteed runtime.
- Actual runtime can change depending on load, battery health, and environmental conditions.
- Final ONBATT timing must leave enough buffer for graceful shutdown and NUT server final actions.
