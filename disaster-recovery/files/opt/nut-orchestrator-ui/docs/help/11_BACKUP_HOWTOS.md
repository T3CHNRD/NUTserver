# Backup - Complete Operator How-Tos

## Purpose

Use Backup when you need to preserve the current NUT server configuration, application code, documentation, and approved recoverable state. For how that backup is later used, see [Restore and Disaster Recovery](12_RESTORE_AND_DR_HOWTOS.md).

The production backup process is designed to create a sanitized backup suitable for the project GitHub repository while keeping passwords, tokens, and other secrets out of Git.

---

## How to Run Backup All from the Control Center

1. Open the NUT Control Center.
2. Click Backup.
3. Read the displayed backup information and warnings.
4. Click Backup All.
5. Allow the backup process to finish.
6. Read the complete Action Output.
7. Confirm the operation reports success.
8. Record the resulting commit identifier when shown.

Expected result:

- current approved NUT application/configuration content is synchronized into the sanitized repository
- secret material remains excluded
- a Git commit is created when there are changes
- the configured backup branch is pushed successfully

Search phrases:

- backup NUT
- backup all
- save NUT configuration
- GitHub backup
- make a NUT backup
- how do I back up the server

---

## How to Verify a Backup Completed Successfully

Do not treat clicking Backup as proof that the backup succeeded.

Verify all of the following:

1. Backup output reports success.
2. No sanitizer/security failure is reported.
3. Git reports a successful commit or no-change condition as appropriate.
4. The expected remote branch push succeeds.
5. No secret or credential file is reported as included.

Current project backup branch:

- origin/backup-sanitized-initial

Search phrases:

- did my backup work
- verify GitHub backup
- check NUT backup
- backup failed
- backup commit

---

## What the Sanitized Backup Is For

The sanitized backup exists so the NUT server can be reconstructed without placing live secrets into GitHub. For credential handling rules, see [Security](18_SECURITY_HOWTOS.md) and [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).

It should contain the code, safe configuration, documentation, scripts, and other approved recoverable files needed for disaster recovery.

It must not be treated as a raw image of the production server.

---

## What Must NOT Be Put in GitHub

Examples include:

- Telegram bot tokens
- SMTP passwords
- protected-system passwords
- API secrets
- raw credential files
- private access databases containing sensitive identifiers
- other files explicitly excluded by the sanitizer

If a secret is accidentally exposed in Git, treat it as compromised and rotate it.

---

## How to Check What Is Included in Backup

1. Review the backup manifest.
2. Review the sync/backup script configuration.
3. Review the sanitizer exclusions.
4. Check the staged Git changes before committing when performing manual maintenance.
5. Never add an excluded secret file merely because a recovery procedure needs it.

Credentials and other secrets must be recreated or restored through the approved secure process.

---

## Production-Hours Safety

Running the normal sanitized Backup operation is generally safe during production hours.

Backup should not:

- generate a UPS event
- change NUT mode
- initiate shutdown
- stop monitoring

However, always read backup output for unexpected errors.

---

## Troubleshooting Backup

If Backup reports failure:

1. Do not repeatedly run Backup without reading the first error.
2. Copy the complete sanitized Action Output.
3. Determine whether the failure occurred during sync, sanitizer validation, Git commit, or Git push.
4. Check disk space.
5. Check repository status.
6. Check network access to the configured Git remote if push failed.
7. Do not bypass the sanitizer to make the backup pass.

---

## Security Warning

Never solve a backup failure by adding credential files to Git.

