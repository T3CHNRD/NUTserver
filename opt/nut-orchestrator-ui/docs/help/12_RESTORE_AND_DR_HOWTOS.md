# Restore and Disaster Recovery - Complete Operator How-Tos

## Purpose

Use Restore and Disaster Recovery procedures when recovering NUT configuration or rebuilding the NUT server.

Restore operations are higher risk than Backup operations because they can replace working configuration.

---


## Restore Levels - Know Which Operation You Are Running

The Restore area contains several different recovery operations.

They do not all have the same scope or risk.

### Level 1 - Repository Rollback / Repository Sync

Repository operations update or select the local backup-repository content.

Examples include:

- syncing the backup repository from GitHub
- selecting an approved branch or backup snapshot
- reviewing historical sanitized repository content

This level does **not** automatically replace live NUT system files.

Use it when you need to obtain or inspect the recovery source before deciding whether a live restore is required.

For backup source and sanitization behavior, see [Backup](11_BACKUP_HOWTOS.md).

### Level 2 - Selected-File Live Restore

Selected-file live restore replaces one explicitly approved live file or restore item.

The workflow should include:

1. selecting the exact approved restore item
2. reviewing the restore source
3. running preview/dry-run when available
4. creating a pre-restore backup
5. requiring the displayed confirmation
6. restoring only the selected approved item
7. validating configuration syntax and affected service behavior
8. using rollback if validation fails

This operation can change a working production system.

Use [Configuration](09_CONFIGURATION_HOWTOS.md) to validate restored configuration and [Logs](16_LOGS_HOWTOS.md) to review restore/service output.

### Level 3 - Full Managed-System Rollback

A full managed-system rollback restores the managed NUT application/configuration environment from an approved backup source.

This is broader than restoring one file.

Depending on the approved restore scope, it may affect:

- NUT application code
- Control Center files
- NUT configuration
- orchestration configuration
- systemd-managed NUT service definitions
- wrapper scripts
- Help/runbook content
- other managed files included in the backup set

Before applying a full managed-system rollback:

1. identify the exact branch/snapshot/source
2. run the available preflight/preview
3. review every proposed changed file
4. create the required pre-restore backup
5. confirm that secret files will be preserved or recreated securely
6. confirm the server is in the required safe operating state
7. use the exact confirmation required by the Restore workflow
8. apply only the approved rollback
9. validate configuration syntax
10. restart only services required by the restore
11. verify Control Center and NUT service health
12. verify protected-system integrations non-destructively
13. use automatic/manual rollback if validation fails

For protected-system validation, see [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md) and [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md).

### Full Managed-System Rollback Is Not Bare-Metal Disaster Recovery

A full managed-system rollback assumes there is already a working operating system/server environment capable of running the restore workflow.

It is **not** the same as rebuilding a completely lost Ubuntu server from scratch.

Bare-metal / replacement-server disaster recovery starts with a fresh supported Ubuntu system and then reconstructs the NUT environment from the sanitized backup plus separately restored credentials/secrets.

Search phrases:

- repository rollback
- selected file restore
- full restore
- full managed system rollback
- restore whole NUT system
- what does full restore change
- bare metal restore
- disaster recovery rebuild

---

## Critical Production Safety Rule

DO NOT run the disaster-recovery --apply restore against the fully working production NUT server.

The final end-to-end disaster-recovery rebuild test must be performed on an isolated disposable Ubuntu 24.04 VM or spare machine.

The production NUT server should remain untouched while validating whether the sanitized backup can rebuild the environment.

---

## How to Use the Restore Button Safely

1. Open the NUT Control Center and review the applicable [Protection Mode](02_PROTECTION_MODES.md) before performing any live restore.
2. Click Restore.
3. Read the restore warning completely.
4. Identify what restore category or scope is being requested.
5. Run the available dry-run/preview first and compare the proposed configuration changes with [Configuration](09_CONFIGURATION_HOWTOS.md).
6. Review every proposed change.
7. Stop if the preview includes unexpected files or settings.
8. Only use an apply operation when the target and scope have been explicitly approved.

Do not use Restore experimentally on the production server.

Search phrases:

- restore NUT
- restore backup
- restore configuration
- use restore button
- undo NUT server changes

---

## How to Sync the Backup Repository from GitHub

The Restore menu includes **Sync backup repo from GitHub**.

This action updates the local backup-repository copy used by the NUT server.

It does **not** restore files into the live NUT system.

### Procedure

1. Open the NUT Control Center.
2. Click **Restore**.
3. Select **Sync backup repo from GitHub**.
4. Review the available backup branches.
5. Select the intended approved branch.
6. Read the confirmation carefully.
7. Confirm only if updating the local backup-repository copy is intended.
8. Review Action Output when the sync finishes using [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md) if additional investigation is needed.

### Expected Result

The local backup-repository copy is updated from the selected GitHub branch.

Live NUT system files are not restored by this action.

Search phrases:

- sync backup repo
- sync repo from GitHub
- update backup repository
- download GitHub backup
- refresh backup repo

---

## How to Run a Restore Dry-Run

A restore dry-run is the preferred first step because it shows intended changes without applying them.

1. Open Restore.
2. Select the intended restore category.
3. Choose the dry-run or preview action.
4. Wait for the preview to finish.
5. Read the full output.
6. Confirm which files would change.
7. Confirm which files would not change.
8. Confirm secret files are not unexpectedly replaced; use [Security](18_SECURITY_HOWTOS.md) and [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md) for credential handling.
9. Stop if anything is unclear.

Expected result:

The preview reports what would be restored without applying the restore.

Search phrases:

- restore dry run
- preview restore
- test restore without changing anything
- what will restore change

---

## How to Restore One Approved Selected File

The Restore menu includes **Live restore selected file**.

This is a live restore operation. Unlike repository sync or restore preview, it can replace a selected live file.

Use it only when the exact file and restore source have been reviewed and the restore has been approved.

### Procedure

1. Open the NUT Control Center.
2. Click **Restore**.
3. Select **Live restore selected file**.
4. Choose one approved restore item from the displayed list.
5. Confirm that the selected item is exactly the file intended for restoration.
6. Use the dry-run/preview first when applicable.
7. Review the confirmation screen.
8. Type the exact confirmation phrase shown by the Control Center.
9. Click **Restore Selected File** only when the live restore is approved.
10. Review the complete Action Output.
11. Validate the restored file using [Configuration](09_CONFIGURATION_HOWTOS.md), then verify the affected service or feature using [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md) and [Logs](16_LOGS_HOWTOS.md).

The restore workflow creates a pre-restore backup before the selected live file is replaced.

Blocked or non-approved entries must not be bypassed.

### Expected Result

Only the explicitly selected approved restore item is processed by the selected-file restore workflow.

### Production Safety

This is **not** equivalent to repository sync or dry-run.

- Repository sync does not restore live system files.
- Dry-run/preview does not copy files.
- Selected-file live restore can change a live system file.

Do not use selected-file live restore experimentally on a working production system.

Search phrases:

- restore selected file
- selected restore
- restore one file
- live restore selected file
- restore individual file
- restore approved file

---

## How to Rebuild NUT After a Server Failure

The recovery goal is to prove that a fresh system can be rebuilt from the sanitized backup plus separately restored secrets.

Use an isolated Ubuntu 24.04 VM or spare system for the validation rebuild.

High-level sequence:

1. Build a fresh supported Ubuntu system.
2. Keep it isolated from production automation.
3. Obtain the approved sanitized GitHub backup.
4. Follow the repository bootstrap/recovery instructions.
5. Restore safe configuration and application code.
6. Recreate secret files through the secure credential process.
7. Validate ownership and permissions.
8. Validate application syntax/configuration.
9. Start only the required test services.
10. Verify the Control Center.
11. Verify NUT configuration without controlling production systems.
12. Run safe simulated tests.
13. Document all missing reconstruction steps.

The DR project is not considered complete until a fresh rebuild succeeds without depending on undocumented production-only knowledge.

Search phrases:

- rebuild NUT server
- disaster recovery
- NUT server died
- restore NUT from GitHub
- build replacement NUT server

---

## How to Roll Back a Bad Change

Use the smallest rollback appropriate to the change.

Possible rollback sources include:

- Control Center Revert
- timestamped local pre-change backups
- sanitized Git history
- approved restore functionality

Procedure:

1. Identify exactly what changed.
2. Stop making additional unrelated changes.
3. Determine the last known-good version.
4. Prefer the smallest targeted rollback. Use selected-file restore rather than a full managed-system rollback when one approved file is sufficient.
5. Validate the restored configuration.
6. Restart only the affected service when required.
7. Verify normal operation.

Do not restore the entire server merely to undo one configuration line.

---

## How to Verify a Recovery

Verify recovery in layers:

1. Required files exist.
2. Ownership and permissions are correct.
3. Configuration syntax passes.
4. Required services start.
5. Control Center loads.
6. Monitoring works in the intended mode.
7. Notification configuration is present.
8. Protected-system integrations pass non-destructive validation using [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md).
9. Supported [Simulated Tests](10_TESTS_AND_LOGS_HOWTOS.md) pass.

Live shutdown testing is separate and requires explicit approval.

---

## Production-Hours Safety

SAFE:

- reading restore documentation
- reviewing backups
- restore dry-run/preview
- rebuilding on an isolated disposable system

HIGH RISK / DO NOT RUN WITHOUT APPROVAL:

- applying Restore to production
- replacing production configuration
- reconnecting an unverified DR server to production automation
- performing live protected-system shutdown tests

---

## Monitoring Impact

A dry-run should not alter monitoring.

A live applied restore can change monitoring configuration and therefore requires careful validation.

## Notification Impact

A restore may alter notification settings if those files are included in the selected restore scope.

## Shutdown-Protection Impact

A restore can change timers, targets, credentials, wrappers, or orchestration behavior.

Therefore, shutdown protection must be revalidated after an applied restore.

---

## Security Rules

- Do not restore secrets from GitHub because secrets should not be stored there.
- Restore credentials through the approved process in [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).
- Verify secret-file ownership and permissions.
- Never publish recovered passwords in documentation or logs.

