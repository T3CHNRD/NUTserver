# Save, Apply and Roll Back an Editable Configuration

**Use when:** changing a configuration through the Control Center editable-configuration workflow.

**Where:** the UI identifies a config by registry ID. `nut-ui-apply-config` reads the registry and validator files, then uses the registered target path, validator, owner, group and mode. The earlier registry inspection captured 26 entries and their validator names. The later source bundle establishes apply behavior but does not include validator implementations. Confirm the selected entry and its current metadata before editing.

**Procedure:**

1. Select the exact registry entry and inspect its displayed name, target path, validator and apply notes. Do not infer that every file in a backup or restore catalog is editable.
2. Make the smallest supported change. Use Validate/Dry Run first: helper validates staged content and exits before backup or write.
3. Apply only after the validator passes. The helper backs up the existing target, writes the staged file, and applies registered owner/group/mode. Email config additionally calls the msmtp rebuild helper.
4. Read the result as a file-apply result, not proof of activation. The helper contains no service reload/restart call. Determine the consumer’s activation requirement from its unit or documented mechanism before scheduling changes.
5. If needed, rollback selects the latest backup for the registry ID, copies it to the registered path and reapplies metadata. The rollback helper does not validate, regenerate email output or restart services. Follow with the appropriate non-disruptive file/consumer check.

**Expected result:** changed file matches the submitted content and registered metadata; relevant dependent generated files are rebuilt only where the helper explicitly does so.

**Recovery:** use the Control Center rollback path for the same config ID, then verify restored content and dependent behavior. If rollback itself fails, stop and use the protected backup directory via the system owner. Do not hand-copy a backup into a live target without approval.

**Source-confirmed vs tested:** behavior is established by text inspection of `/usr/local/sbin/nut-ui-apply-config` lines 17-148 and `nut-ui-rollback` lines 16-36. No UI submission or live save/rollback was performed. Registry metadata was captured separately; detailed validator implementation and current per-file metadata still require checking at change time.
