# Security - Complete Operator How-Tos

## Purpose

This section explains how to protect passwords, tokens, credentials, and other sensitive NUT information.

---

## How to Verify Secrets Are Excluded From the Sanitized GitHub Backup

Perform this check before trusting a new or changed backup workflow.

1. Review the files staged by the sanitized backup process.
2. Review Git status before committing when performing manual validation.
3. Search staged/sanitized content for secret-key names.
4. Confirm known secret directories/files are excluded.
5. Confirm live Telegram token files are not tracked.
6. Confirm live credential/password files are not tracked.
7. Confirm private Telegram access-state data is not unintentionally tracked.
8. Stop the backup process if a live secret is detected.

Secret-name patterns to review include:

- PASSWORD
- PASS
- SMTP_PASSWORD
- SMTP_PASS
- SECRET
- TOKEN
- API_KEY
- BOT_TOKEN

Important:

A filename being absent from Git is not enough if the secret value was accidentally copied into another tracked file.

Search phrases:

- check GitHub for passwords
- secret audit
- sanitized backup
- verify no secrets in Git
- password in GitHub

---

## What to Do If a Secret Is Exposed

1. Stop publishing/sharing the exposed material.
2. Identify the affected credential.
3. Treat the exposed credential as compromised.
4. Rotate the credential.
5. Remove the secret from tracked/current documentation.
6. Re-run the sanitizer/security audit.

Do not simply mask the current display while leaving an exposed live credential valid.

---

## Credential Handling Rules

- Never paste passwords into Help.
- Never paste passwords into chat.
- Never commit passwords to GitHub.
- Never expose Telegram bot tokens.
- Never expose SMTP passwords.
- Mask secrets in screenshots and command output.
- Preserve restrictive permissions on secret files.

---

## Production-Hours Safety

Security audits are normally read-only and safe during production hours.

Credential rotation requires careful integration verification afterward.

---

## Related Help

- Credential and Password Changes
- Backup
- Restore and Disaster Recovery
- Configuration
- Logs

## Technical References

- sanitized Git repository
- backup sanitizer/exclusion configuration
- /etc/nut/secrets/
- /var/lib/nut-telegram-alerts/access.json
