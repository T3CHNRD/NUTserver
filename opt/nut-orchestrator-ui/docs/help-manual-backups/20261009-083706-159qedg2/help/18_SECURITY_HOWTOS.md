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



## Control Center Secret Masking

The Control Center must not expose stored passwords, tokens, or other protected credential values merely because an operator opens Configuration.

Sensitive configuration entries use protected/masked handling instead of displaying the raw stored secret.

### Masked Placeholder

The current configuration workflow uses the placeholder:

`********`

for protected values where applicable.

That placeholder represents a masked value. It is **not** the actual credential.

The backend specifically prevents the masked placeholder from being submitted as though it were a new sensitive value. This protects against accidentally replacing a working credential with the literal text `********`.

For the DB shutdown configuration, the browser-side save logic also preserves the masked display until an operator explicitly supplies a replacement password.

### What Masking Does

Masking:

- reduces accidental credential exposure in the Control Center
- prevents normal configuration viewing from displaying the raw secret
- helps protect screenshots and routine operator viewing
- prevents an unchanged masked placeholder from being treated as a real replacement credential

### What Masking Does NOT Mean

Masking does not mean:

- the credential is absent
- the credential can safely be committed to GitHub
- the underlying secret file can have weak permissions
- screenshots or command output no longer need review
- operators may bypass the approved credential-change workflow

Use [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md) when an actual credential must be changed.

Never copy raw credentials into Help documentation, tickets, screenshots, terminal transcripts, or repository content.

---

## File and Credential Permission Model

The NUT server uses different permission expectations for application code, ordinary Help content, NUT configuration, and credential/secret files.

### Current Observed Baseline

During the current live documentation audit, these non-secret paths were observed:

- `/opt/nut-orchestrator-ui` - owned by `root:root`, mode `755`
- `/opt/nut-orchestrator-ui/app.py` - owned by `root:root`, mode `644`
- `/opt/nut-orchestrator-ui/templates/control-center.html` - owned by `root:root`, mode `644`
- `/opt/nut-orchestrator-ui/docs/help` - owned by `root:root`, mode `755`
- `/etc/nut` - owned by `root:nut`, mode `755`
- `/usr/local/sbin` - owned by `root:root`, mode `755`

The Control Center Flask/Gunicorn service currently runs as `www-data`.

These values describe the observed baseline for the listed paths. They are **not** a blanket recommendation to assign those modes to every NUT file.

Credential and secret files require more restrictive permissions. Follow the credential-specific procedure in [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md#general-credential-change-procedure).

### Permission Safety Rules

- Do not make a credential file world-readable to solve an access problem.
- Preserve the existing owner, group, and restrictive mode when changing a credential.
- Keep secret files outside public/sanitized repository content.
- Do not change ownership recursively across `/etc/nut`, `/usr/local/sbin`, or the Control Center tree merely to solve one permission failure.
- Verify the exact service/wrapper execution context before changing permissions.
- Application code and Help files being readable does not mean credential files should use the same mode.

When a configuration Save, restore, or protected-system validation reports a permission problem, use [Configuration troubleshooting](09_CONFIGURATION_HOWTOS.md#troubleshooting) and [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md) rather than weakening access controls.

---

## Control Center Access-Control Model

The Control Center uses several layers of application-level safety controls.

### Approved Configuration and Reference Files

Configuration and reference access is allowlist-based.

The backend resolves requested configuration/reference IDs against its approved registry. Requests that are not approved are rejected rather than being allowed to read an arbitrary path.

Examples of current backend behavior include:

- unapproved reference view requests return HTTP `403`
- unapproved configuration view requests return HTTP `403`
- unapproved configuration edit requests return HTTP `403`
- unapproved rollback targets return HTTP `403`

See [Configuration](09_CONFIGURATION_HOWTOS.md) for the operator workflow.

### Sensitive Configuration Handling

Sensitive configurations are handled differently from ordinary editable configuration.

The Control Center does not treat the masked value `********` as a real replacement password. If that placeholder is submitted as though it were a changed sensitive value, the backend rejects the operation.

This prevents an unchanged masked display value from accidentally becoming the stored credential.

The Control Center also contains backend redaction/masking handling for sensitive configuration data. Operators must still avoid copying passwords, tokens, API secrets, or other credentials into Help articles, screenshots, tickets, or logs.

### High-Risk Operation Gates

Several higher-risk actions have additional controls beyond ordinary UI access.

Current examples include:

- approved Real Test phases are restricted to an allowed set
- Real Test requires its approved authorization/passphrase mechanism
- selected-file live restore requires a valid approved restore target
- a selected restore can be blocked when the target is not enabled
- a selected restore can be blocked when its expected repository source is unavailable
- selected-file live restore requires the exact confirmation phrase used by that workflow
- full managed-system restore requires its own exact confirmation phrase

These controls reduce accidental execution. They do not replace the operator safety procedures in [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md) and [Restore and Disaster Recovery](12_RESTORE_AND_DR_HOWTOS.md).

### Web / Reverse-Proxy Authentication Boundary

This section documents the access controls verified in the Control Center application itself.

The current documentation audit did **not** establish the complete implementation details of the external/front-door web authentication layer. Do not assume that absence of an authentication directive in one searched proxy path means the Control Center has no web authentication.

Application-level authorization and web-entry authentication are separate controls and should be verified independently before changing either one.

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
