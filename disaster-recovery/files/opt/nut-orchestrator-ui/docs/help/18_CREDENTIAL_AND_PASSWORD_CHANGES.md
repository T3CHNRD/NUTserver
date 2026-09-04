# Credential and Password Changes - Complete How-To

## Purpose

Use this Help article when a password, username, API credential, or protected-system login used by NUT has changed.

Common examples include:

- DB01 Telnet password changed
- DB02 Telnet password changed
- database Telnet username changed
- vCenter password changed
- Synology API credentials changed

Credential changes must be handled carefully because some credentials are intentionally stored outside normal Git-backed configuration.

Never place an actual password, token, secret, or API key in Help documentation, screenshots, chat, email, or GitHub.

---

## General Credential Change Procedure

1. Confirm which protected system credential changed.
2. Identify the NUT configuration or secret file that stores that credential.
3. Back up the current credential file locally with root-only permissions.
4. Update the credential directly on the NUT server.
5. Preserve the existing owner and permissions.
6. Validate the related integration without causing a real UPS event.
7. Verify logs do not expose the credential.
8. Do not commit the credential file to GitHub.

---

## How to Update the DB01 Telnet Password Used by NUT

Use this procedure after the password for DB01 has changed.

DB01 production address:

- 192.168.1.9

### Step 1 - Open the Control Center Configuration area

1. Open the NUT Control Center.
2. Click Configuration.
3. Locate the DB Telnet password configuration/reference entry.

The Control Center should never display the actual saved password in normal Help documentation.

### Step 2 - Identify the live credential storage location

Current NUT DB shutdown integration uses the DB shutdown configuration and protected credential handling associated with:

- /etc/nut/db-shutdown.conf
- /usr/local/sbin/nut-db-shutdown.sh

The exact secret value must remain masked.

### Step 3 - Back up the current local credential configuration

Before changing anything, make a root-only backup of the applicable credential file.

Example backup naming convention:

- db-shutdown.conf.pre-password-change-YYYYMMDD-HHMMSS

Do not copy the credential value into the backup filename.

### Step 4 - Update the DB01 password

Update only the credential field used for DB01.

Do not change DB02 or other protected-system credentials unless those credentials also changed.

Do not paste the new password into chat while asking for assistance.

### Step 5 - Preserve permissions

After the change, verify the file still has the intended owner and restrictive permissions.

Do not make the credential file world-readable merely to fix a permission problem.

### Step 6 - Validate safely

Use the approved non-disruptive DB shutdown verification method.

Do NOT initiate a live shutdown of production DB01 merely to test the new password.

Production DB01 must not be used for a live shutdown test without explicit authorization.

### Step 7 - Review logs

Confirm the integration can authenticate without exposing the password in logs.

### Expected Result

The NUT DB shutdown integration can authenticate to DB01 using the new credential while production DB01 remains running.

### Search phrases

- I changed the DB01 password
- update DB01 password in NUT
- DBO1 password changed
- change database Telnet password
- DB01 login changed

---

## How to Update the DB02 Telnet Password Used by NUT

Use this procedure after the production DB02 Telnet password changes.

DB02 production address:

- 192.168.1.11

Follow the same safe process used for DB01:

1. Identify the DB02 credential field.
2. Make a root-only local backup.
3. Change only the DB02 credential.
4. Preserve file permissions.
5. Validate authentication non-destructively.
6. Never use production DB02 for an unapproved live shutdown test.

### Search phrases

- I changed the DB02 password
- update DB02 password in NUT
- DBO2 password changed
- DB02 Telnet login changed

---

## How to Update the Database Telnet Username

Use this if the login username itself changes rather than only the password.

1. Identify the DB Telnet username configuration used by the shutdown wrapper.
2. Back up the current configuration.
3. Replace only the intended username.
4. Preserve credential file permissions.
5. Validate authentication non-destructively.
6. Confirm both DB01 and DB02 behavior if the same username is shared.

Do not assume changing the username automatically updates the password.

---

## How to Update the vCenter Password Used by NUT

Use this after the vCenter account password changes.

The protected vCenter password is stored separately from ordinary editable configuration.

Current protected reference:

- /etc/nut/vcenter.pass

### Procedure

1. Confirm the vCenter password was intentionally changed.
2. Make a root-only backup of the current local password file.
3. Update the live vCenter password file without displaying the value in terminal history where avoidable.
4. Preserve restrictive ownership and permissions.
5. Use the approved non-disruptive VMware/vCenter validation method.
6. Do not start an ESXi or VM shutdown merely to validate the password.
7. Confirm the VMware wrapper can authenticate successfully.

### Search phrases

- changed vCenter password
- update VMware password in NUT
- vCenter credentials changed
- ESXi shutdown login changed

---

## How to Update Synology API Credentials Used by NUT

Current Synology API configuration reference:

- /etc/nut/synology-api.conf

### Procedure

1. Confirm which Synology credential changed.
2. Back up the current configuration locally.
3. Update only the required credential field.
4. Preserve restrictive permissions.
5. Validate API authentication without shutting down the Synology.
6. Review logs for authentication success or failure.

### Search phrases

- Synology password changed
- update Synology credentials
- NAS password changed
- Synology API login changed

---

## How to Verify a Credential Change Safely

Credential verification should prove authentication without performing the disruptive action the credential ultimately authorizes.

Examples:

- DB credential: [REDACTED]
- vCenter credential: [REDACTED]
- Synology credential: [REDACTED]

Use a live shutdown test only when the specific protected-system test has been formally approved.

---

## How to Undo a Credential Change

If the new credential does not work:

1. Confirm the new credential is correct on the protected system.
2. Review the NUT-side file for spelling or formatting mistakes.
3. If necessary, restore the local pre-change backup.
4. Preserve the correct permissions after restoration.
5. Repeat only the non-disruptive authentication test.

Do not repeatedly attempt authentication if the remote system may lock accounts after failed logins.

---

## Production-Hours Safety

Credential updates can usually be performed during production hours if the associated live shutdown action is not invoked.

Use extra caution with:

- DB01
- DB02
- VMware/vCenter
- Synology
- NetApp
- any credential used by automatic shutdown orchestration

A malformed credential can prevent the protected system from shutting down during a real outage.

---

## Monitoring Impact

Changing a protected-system shutdown credential should not normally disable UPS monitoring.

## Notification Impact

Credential changes generally do not alter notification settings.

## Shutdown-Protection Impact

An incorrect credential can cause the associated shutdown step to fail during a real outage.

For that reason, every credential change requires a safe authentication verification.

---

## Security Rules

- Never store raw passwords in Help.
- Never store raw passwords in GitHub.
- Never paste passwords into chat.
- Never reveal Telegram bot tokens.
- Never reveal SMTP passwords.
- Never expose raw Telegram chat IDs unnecessarily.
- Keep secret files root-owned and restrict permissions.
- Treat an accidentally exposed credential as compromised and rotate it.

---

## Related Help

- Configuration
- Protected Systems
- DB01 Shutdown Integration
- DB02 Shutdown Integration
- VMware/vCenter Shutdown Integration
- Synology Shutdown Integration
- Security
- Troubleshooting

## Technical References

- /etc/nut/db-shutdown.conf
- /usr/local/sbin/nut-db-shutdown.sh
- /etc/nut/vcenter.pass
- /etc/nut/synology-api.conf
- /usr/local/sbin/nut-vmware-shutdown.sh
- /usr/local/sbin/nut-synology-shutdown.sh
