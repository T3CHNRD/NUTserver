# Change Protected-System Credentials

**Use when:** changing a remote account password or API credential used by shutdown automation.

**General rule:** change the remote account and protected local credential source as a coordinated operation. The wrapper snapshots show these files are read on each invocation; no service restart is established for these wrappers. A successful file edit does not prove that the remote account accepts it.

| Target | Local source and exact fields | Shared dependency / behavior | Safe source-confirmed check |
|---|---|---|---|
| Blue Iris | `/etc/nut/lansweeper.creds`: `LANSWEEPER_DOMAIN`, `LANSWEEPER_USERNAME`, `LANSWEEPER_PASSWORD`; wrapper maps to `RPC_USERNAME`, `RPC_PASSWORD`. | Shared with Lansweeper. Both source the file each invocation. | No authentication-only check identified. Simulation exits before RPC call. |
| Lansweeper | Same file plus `LANSWEEPER_IP`. | Same local file as Blue Iris; confirm the remote account relationship rather than assuming it is identical. | No auth-only check; simulation exits before RPC. Target-down verification is after shutdown request, not auth-only. |
| Synology | `/etc/nut/synology-api.conf`: `SYNOLOGY_BASE_URL`, `SYNOLOGY_USERNAME`, `SYNOLOGY_PASSWORD`. | Wrapper login occurs before simulation exit; simulation logs out/records state and is not side-effect-free. | No separate authentication-only method established. Do not use shutdown wrapper as a password test. |
| VMware/vCenter | `/etc/nut/nut-orchestrator.conf` fields include `VCENTER_SERVER`, `VCENTER_USERNAME`, `VCENTER_INSECURE`; password in `/etc/nut/vcenter.pass`. | VMware shares main config with NetApp. Read on wrapper invocation. | Read-only placement/preflight tools exist in source, but their credential consumption and safe operational invocation require a separate approved runbook. |
| NetApp | `/etc/nut/nut-orchestrator.conf`: `NETAPP_USERNAME`, `NETAPP_PASSWORD`, host and node fields. | Same shared file as VMware. | Wrapper command is a halt action; no auth-only check established. |
| <DATABASE_SERVER_1>/<DATABASE_SERVER_2> | `/etc/nut/db-shutdown.conf`: per-target `<DATABASE_SERVER_1>_USERNAME`/`<DATABASE_SERVER_1>_PASSWORD`, `<DATABASE_SERVER_2>_USERNAME`/`<DATABASE_SERVER_2>_PASSWORD`, host, method and common timeout/command fields. | Common Telnet/Expect helper; source on each wrapper invocation. | No authentication-only helper established. Never test via shutdown wrapper. |
| VOIP | Wrapper host/user settings are present; no `/etc/nut` credential source found. SSH identity source is external to copied wrapper. | Account/key/agent dependencies need operator confirmation. | No auth-only check established. |
| Email | `/etc/nut/nut-email-alerts.conf` plus `/etc/nut/nut-email-alerts.secret`; apply triggers generated msmtp rebuild. | Generated msmtp config is a dependent artifact; exact active reader/reload semantics are unresolved. | The apply action is not a delivery test; do not send mail as part of this procedure. |

**Procedure:**

1. Confirm the credential owner, remote account, each local consumer, protected backup/recovery location and maintenance window. Do not expose values in tickets or chat.
2. Rotate the remote password with the system owner. Stage the new local value in the protected file using the established secure operator method. Preserve required owner/mode; values are not documented here.
3. For shared Blue Iris/Lansweeper credentials, coordinate both services’ remote account acceptance before declaring rotation complete.
4. Run only an existing authentication-only check if the owner has verified one is non-disruptive. The reviewed RPC wrappers do not provide one; Synology’s wrapper simulation logs in but also writes event state, so it is not a clean credential check. Do not invent a command.
5. Review protected logs for authentication status without copying secrets. If no safe check exists, mark verification deferred until an operator-controlled service-specific test is approved.

**Recovery:** if remote and local values disagree, use the system’s approved console/admin channel to restore agreement. Revert the local protected file from its approved backup or coordinate a remote reset; do not roll back only one side and assume recovery.

**Evidence:** Blue Iris lines 6-43, 98-123; Lansweeper 6, 35-59, 65-150; Synology 6, 43-59, 89-120, 124-179; VMware 41-48; NetApp 6, 57-107; DB 10, 35-114; VOIP 5-8, 56-96; email generator 5-18, 64.
