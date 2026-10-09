# Changing the Synology Automation Password

Revision 2026-10-09. Procedure basis: wrapper source inspection; remote authentication was not tested.

## 1 When to use this procedure

Use this when the password for the account used by Synology shutdown automation changes. A change to an unrelated personal login does not require this update. Plan the local and remote changes together so automatic shutdown is not left using an invalid password during the change window.

## 2 Which file and field to change

File: `/etc/nut/synology-api.conf`

Password field: `SYNOLOGY_PASSWORD`

Username field, only if the account name changed: `SYNOLOGY_USERNAME`

The Synology wrapper reads this shell-format file on each invocation. It requires SYNOLOGY_BASE_URL, SYNOLOGY_USERNAME and SYNOLOGY_PASSWORD. Leave SYNOLOGY_LIVE_APPROVED unchanged; it is a separate live-shutdown gate.

For a password-only change, leave the username, domain or endpoint, target address, timers, shutdown commands and approval gates unchanged. The actual live file and remote account state must be checked by the operator; the evidence review inspected the wrapper copies.

## 3 Before you begin

Confirm there is no active outage or shutdown sequence and arrange an approved change window. Confirm the intended automation account with the system administrator. Record the existing file owner and mode without displaying its contents:

```bash
sudo stat -c '%U:%G %a %n' /etc/nut/synology-api.conf
```

Stop if the file is missing or the intended account cannot be established. Do not create an empty replacement or guess the fields.

## 4 Make a private recovery copy

The following is a proposed local backup location for this procedure, not a claim about the site's existing backup policy. Use the site's approved protected location instead if required. These commands create a root-only directory and copy the file without printing its contents:

```bash
sudo install -d -m 700 -o root -g root /root/nut-credential-backups
backup_file="/root/nut-credential-backups/synology-api.conf.$(date +%Y%m%d-%H%M%S)"
sudo cp -a -- /etc/nut/synology-api.conf "$backup_file"
```

Continue only if the backup succeeds. Keep the backup path for recovery and never include the backup contents in Help, tickets or Git.

## 5 Edit only the intended credential

Open the file in a privileged editor:

```bash
sudoedit /etc/nut/synology-api.conf
```

Change the existing SYNOLOGY_PASSWORD assignment. Change SYNOLOGY_USERNAME only if the automation account changed. Preserve the file's shell assignment format. Password punctuation must be quoted correctly for shell input; do not paste a password as a terminal command. If you are unsure how to represent a character safely, stop and have the administrator handle the edit without disclosing the password in chat.

If the expected assignment is absent, appears more than once, or is calculated from another source, stop and resolve that before editing. A sourced assignment replaces an inherited environment value; an omitted field could leave an inherited value in use.

## 6 Check the saved file

Run a syntax-only check with diagnostics suppressed so a malformed credential line cannot be echoed into the terminal:

```bash
if sudo bash -n /etc/nut/synology-api.conf >/dev/null 2>&1; then
    echo 'Shell syntax check passed'
else
    echo 'Check failed or could not run; stop and review the file privately'
fi
sudo stat -c '%U:%G %a %n' /etc/nut/synology-api.conf
```

Compare owner and mode with the values recorded before editing. Do not broaden permissions to solve an access error. A syntax pass does not prove that a password is correct or that authentication works. This syntax check reads the file without sourcing it.

## 7 When the change takes effect

The wrapper reads the file again on its next invocation. No wrapper restart is needed for it to reread the credential. Do not restart NUT services merely for this file reread, and do not invoke the wrapper to force activation.

## 8 Verify without shutting down the system

The inspected Synology wrapper logs in, obtains a session ID, then checks its simulation branch. That branch logs out and exits before the shutdown request, but it also updates local event/classification records. It is not a side-effect-free check, and the reviewed report does not establish an operator invocation that can safely be copied here. Do not guess simulation arguments or change the live approval gate. Obtain the reviewed verification invocation before using that path. A Configuration dry-run does not establish DSM authentication.

Record the syntax result and account coordination separately from authentication evidence. Do not mark the credential change fully verified solely because the file saved successfully.

## 9 Recover if the change is unsuccessful

Stop further tests to avoid account lockout. Recheck the intended account and assignment privately. If rollback is required, coordinate the remote account and the local file so they agree. Restoring an old local password does not undo a remote password change. For the shared RPC file, coordinate both destinations before rollback.

Use the recorded protected backup to recover only the intended settings through `sudoedit`, preserving any unrelated later changes. Restore the whole backup only after checking that no later edits would be lost. Repeat the syntax and permission checks. Do not use a shutdown action as recovery verification.

## 10 Evidence and limits

The sanitized source review cites nut-synology-shutdown.sh lines 6 and 35–49 for file loading and required fields; 52–66 for login/session handling; 96–121 for login before simulation; and 124–159 for the approval gate and shutdown call. The copied scripts matched their capture manifest. They were not compared again with the current production hashes during that review. Local backup/edit commands above are proposed operator steps and were not executed as part of documentation preparation. No credential values are included.
