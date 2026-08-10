# UPS Runtime Tiers

## Purpose
This document groups UPS units by runtime urgency so shutdown planning can prioritize the shortest-runtime systems first.

## Tier Definitions

### Tier 1 - Critical / shortest runtime
These UPS units have the least time available and need the fastest shutdown planning:
- ups8 = 15m
- ups7 = 18m

### Tier 2 - High urgency
These UPS units still require aggressive timing:
- Rack 4_3 = 26m
- ups3 = 27m
- ups2 = 30m
- ups3_3 = 34m

### Tier 3 - Moderate urgency
These UPS units provide more buffer but still need planned shutdown timing:
- ups9 = 37m

### Tier 4 - Long runtime
These UPS units have substantially more runtime than the short-duration units:
- UPS_test = 2h 6m

### Tier 5 - Extended runtime
This UPS is in a separate class and should not drive the shortest shutdown timer:
- ups6 = 19h 2m

## Planning Notes
- Final shutdown timing should be based first on Tier 1 and Tier 2 UPS-backed systems.
- A single global battery timer may not be appropriate for all UPS-backed systems.
- Systems on the shortest-runtime UPS units must be evaluated first for graceful shutdown feasibility.
- The NUT server final shutdown must still leave enough battery reserve for clean completion.
