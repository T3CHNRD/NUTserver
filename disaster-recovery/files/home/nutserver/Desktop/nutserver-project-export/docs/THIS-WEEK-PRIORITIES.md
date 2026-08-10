# NUT Server Project - This Week Priorities

## Goal
Close out the next safe phase of the NUT server project without impacting production.

## This Week Priority Items

### Priority 1. Identify the ESXi host that normally runs the vCenter appliance during a shutdown event
- Replace:
  - `CHANGE_ME_VCSA_LAST_HOST`
- This must be confirmed before real clustered shutdown execution logic is written.

### Priority 2. Finalize the test-server shutdown / abort behavior
- Set the exact battery-to-action delay
- Set the exact remote Windows shutdown delay
- Verify abort works reliably every time
- Decide whether to show a separate “power restored” message

### Priority 3. Build the real shutdown logic design
- Define the true shutdown master
- Decide which systems are NUT netclients
- Decide which systems receive software shutdown commands
- Decide which systems only alert
- Define:
  - ONBATT delay
  - LOWBATT action
  - communication-loss behavior
  - power-restore abort behavior

### Priority 4. Finalize shutdown and startup order
- Finalize VM order
- Finalize host order
- Finalize critical services order
- Confirm dependency map
- Confirm startup order after power restore

### Priority 5. Complete safe validation
- Complete dry-run validation
- Complete lab or non-production shutdown testing
- Do not perform live production execution yet

## Not This Week Unless Time Allows
- Dashboard shutdown-state improvements
- Prometheus exporter integration
- Full alerting expansion
- BIOS/power recovery audits for every system
