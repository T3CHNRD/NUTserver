# NUT Server Project - Open Items

## Items Still Needing Completion

### 1. Change DNS back / confirm DNS rollback status
- Confirm whether DNS was already changed back
- If not completed, change DNS back and document the final state
- If completed, mark this item as done in project documentation

### 2. Identify the ESXi host that normally runs the vCenter appliance during a shutdown event
- Current placeholder in config:
  - `CHANGE_ME_VCSA_LAST_HOST`
- Replace this with the actual ESXi host handling the vCenter appliance during the shutdown sequence
- This must be confirmed before coding real clustered host shutdown execution logic
- The host carrying vCenter at shutdown time must be treated as the final compute host

### 3. Finalize the test-server shutdown / abort behavior
- Shorten the battery-to-action delay to the exact timing you want
- Shorten the remote Windows shutdown delay to the exact timing you want
- Verify the remote abort happens reliably every time
- Decide whether to show a separate “power restored” message on the Windows test server after abort

### 4. Build the real shutdown logic
- Define the true shutdown master
- Decide which systems are NUT netclients
- Define which systems get software shutdown commands
- Define which systems only alert
- Confirm how the shutdown script will interact with VMware:
  - vCenter API
  - PowerCLI
  - govc
  - another approved method
- Define actual trigger timing:
  - ONBATT delay
  - LOWBATT action
  - communication-loss behavior
  - power-restore abort behavior
- Build runtime-aware shutdown timing based on actual UPS hold time
- Identify which systems are attached to each UPS
- Determine which UPS-backed systems require earliest shutdown because of shorter runtime
- Ensure final timing leaves enough battery buffer for graceful shutdown and NUT server final actions

### 5. Finalize shutdown and startup order
- Finalize physical host order
- Finalize VM host order
- Finalize VM order
- Finalize critical services order
- Build the dependency map
- Confirm startup order after power restore
- Confirm final clustered host shutdown order
- Confirm vCenter remains the last VM in the cluster to go down
- Confirm ESXi hosts shut down only after guest VMs are verified off
- Confirm storage shuts down after compute

### 6. Confirm storage shutdown method
- Decide whether storage shutdown will be:
  - manual
  - scripted
  - vendor-tool driven
- Document the chosen storage shutdown procedure before full automation is enabled

### 7. Productionize the remote shutdown wrapper(s)
- Standard shutdown wrapper for Windows hosts
- Standard abort wrapper for Windows hosts
- Logging and exit-code handling
- Host-specific config or mapping file
- Safer credential handling for production use

### 8. Add server shutdown visibility to the dashboard
- Indicate which servers are linked to which UPS
- Show pending shutdown state
- Show abort sent state
- Show shutdown in progress
- Show restored / canceled state

### 9. Prometheus exporter and monitoring integration
- Install Prometheus NUT exporter
- Add scrape config
- Test metrics
- Confirm labels / instance naming
- Document it

### 10. Alerting
- On Battery alert
- Low Battery alert
- Communication-loss alert
- Runtime threshold alert
- UPS offline alert
- Possibly host shutdown / abort alerting

### 11. Controlled power test and final validation
- Complete dry-run validation against the production order
- Validate order only at first
- Confirm timing, dependency order, and logging
- Complete lab or non-production shutdown test
- Test graceful VM shutdown
- Test host shutdown sequencing
- Confirm no step occurs out of order
- Perform one controlled production-style battery event
- Confirm timers
- Confirm shutdown commands
- Confirm abort behavior
- Confirm recovery / startup sequence
- Document exact results
- Validate shutdown timing against the shortest-runtime UPS units first
- Confirm timing still leaves safe battery reserve on the lowest-runtime circuits

### 12. Documentation
- Current known-good baseline document
- upsmon / upssched fix document
- Test-server shutdown validation document
- Backup and rollback document
- Shutdown logic design document
- Final runbook

### 13. Backup / rollback hardening
- Confirm current backup locations
- Confirm which files are the authoritative live versions
- Create one clean rollback procedure
- Document exact restore commands
- Document validation after rollback
- Document support procedure for future maintenance

### 14. BIOS / power recovery checks
- Confirm AC Power Recovery / Restore on AC Power Loss settings
- Confirm what happens after full loss and return
- Document host-specific behavior
