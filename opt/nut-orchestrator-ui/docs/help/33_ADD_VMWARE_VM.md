# Add a VMware VM to Shutdown Orchestration

**Use when:** a guest must be included in the VMware shutdown waves.

**Where:** `/etc/nut/nut-orchestrator.conf` supplies VMware settings and phase arrays; `/etc/nut/config.d/vmware-vm-map.conf` is loaded as the identity map; `/etc/nut/vcenter.pass` is the wrapper’s password file. The Help source snapshot does not include their current contents.

The active VM map is read by the wrapper, but its exact current row format was not supplied. Have the VMware administrator establish that format before editing; the steps below identify the change process without guessing column order.

**Procedure:**

1. Confirm exact vCenter VM name and intended wave. Match the VM to the role using current vCenter read-only identity evidence before editing a mapping.
2. Add its exact identity to the appropriate phase collection and add the name-to-identity fields expected by the map reader. The map helper selects record columns for identity fields; its current data file is absent from the bundle, so use the existing local schema reference before editing and do not guess field order.
3. Preserve one row/entry per VM. Do not merge VMs or substitute a peer. Leave stored MoRef blank only where the approved dynamic exact-name path is designed for that target; the exact current schema is not staged.
4. Review ordering and ensure that required guests are independently checked POWERED_OFF before host progression. VCSA placement is handled through a separate detection path; do not add VCSA to a normal guest wave.
5. Use mocks/fixtures for map parsing, name ambiguity, stale identity, placement changes, and guest verification. Do not run the shutdown wrapper or call live vCenter during documentation work.

**Expected result:** the wrapper resolves exactly one intended VM and its phase includes it without replacing another target. Failure/unknown must block later progression.

**Verification:** the wrapper reads the main VMware config, map, and optional SSH fallback file at invocation; source review does not establish current rows or live credentials. A live test is separate and not performed.

**Recovery:** restore the previous mapping/config from the approved backup path; verify the target remains a required entry and remove the candidate from the phase only with operator approval.

**Evidence:** `nut-vmware-shutdown.sh` lines 41-89 (loaders and phase inputs), 158-180 (map lookup), 302-340 (guest handling), 443-507 (domain order and gates).
