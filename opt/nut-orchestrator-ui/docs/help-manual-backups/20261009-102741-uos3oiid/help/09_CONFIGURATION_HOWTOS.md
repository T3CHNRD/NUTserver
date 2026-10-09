# Configuration - Complete Operator How-Tos

Revision date: 2026-10-08

## Purpose

Use this section when you need to review or change a NUT Control Center configuration.

Configuration changes can affect monitoring, notifications, shutdown timing, or protected systems.
Always understand the setting before saving it.

---

## Where Configuration Is Located

1. Open the NUT Control Center.
2. Click Configuration.
3. Select the configuration item you need to review or change.

Editable configuration items provide controls such as:

- Reload
- Validate
- Save
- Revert

In the captured main Control Center Configuration editor, Save is enabled for approved editable live configurations; Validate before saving. The separate Restore Lab uses a different interface and currently displays its dashboard-ui.json Save control as disabled. Do not generalize that Restore Lab restriction to the main Configuration editor.

Not every configuration has the same operational risk.

---


## How the Config Loader Works

The Control Center Config Loader is the operator interface for selecting approved configuration and reference items.

Opening or selecting an item does **not** itself save or apply a configuration change.

The loader works with the Control Center's approved configuration/reference registry. Files that are not approved by that registry are not intended to be exposed as arbitrary editable files.

Depending on the selected item, the Control Center may present:

- an approved editable configuration
- an approved read-only reference
- a sensitive configuration using protected/masked handling

After loading an editable configuration, use the documented procedures for [Validate](09_CONFIGURATION_HOWTOS.md#how-to-validate-a-configuration), [Save](09_CONFIGURATION_HOWTOS.md#how-to-save-a-configuration-change), and [Revert](09_CONFIGURATION_HOWTOS.md#how-to-revert-a-configuration-change).

Do not assume that seeing a file in the loader means it is safe to change during production hours. Review the file-specific guidance in the [Editable Live Config File Guide](09_CONFIGURATION_HOWTOS.md#editable-live-config-file-guide) first.

Sensitive values are handled separately as described in [Control Center Secret Masking](18_SECURITY_HOWTOS.md#control-center-secret-masking).

---

## How to Safely Review a Configuration

1. Open Configuration.
2. Select the configuration you need.
3. Read the description and safety information before editing.
4. Review the current contents.
5. Do not change anything if you are only investigating.

Reviewing a configuration is normally safe during production hours.

---

## How to Reload a Configuration

Use Reload when you want the editor to reread the currently saved configuration.

1. Open the desired configuration.
2. Click Reload.
3. Wait for the current saved configuration to reappear.
4. Confirm the editor shows the expected values.

Reload does not intentionally save new changes.

Use Reload when:

- another administrator changed the file
- the displayed contents may be stale
- you want to discard unsaved browser/editor changes

Search phrases:

- reload NUT config
- refresh configuration
- discard unsaved changes
- configuration looks stale

---

## How to Validate a Configuration

Always Validate before Save when the Control Center provides validation.

1. Make the intended configuration change.
2. Review the change carefully.
3. Click Validate.
4. Read the validation result.
5. Do not click Save if validation reports an error.
6. Correct the problem and Validate again.

Expected result:

The Control Center reports that the proposed configuration passes its configured validation checks.

Important:

A successful syntax validation does not automatically prove that every remote credential, IP address, or protected system is reachable.

Search phrases:

- validate NUT config
- check config before saving
- configuration syntax error
- is this NUT configuration valid

---

## How to Save a Configuration Change

1. Confirm you are editing the correct configuration.
2. Make only the intended change.
3. Click Validate.
4. Confirm validation succeeds.
5. Review the change one more time.
6. Click Save.
7. Read the save result.
8. Reload the configuration.
9. Confirm the intended value remains present.

If the configuration controls a protected system, notification, timer, or shutdown action, perform the appropriate non-disruptive verification afterward.

Do not generate a real outage merely to verify a saved configuration.

---

## How to Revert a Configuration Change

Use Revert when a saved configuration change must be rolled back using the Control Center-supported rollback mechanism.

1. Stop making additional changes.
2. Open the affected configuration.
3. Review the current value.
4. Click Revert.
5. Read any warning or confirmation.
6. Confirm the revert only if you intend to restore the previous version.
7. Reload the configuration.
8. Confirm the expected previous value has returned.
9. Validate the restored configuration.

If Revert is unavailable or does not restore the needed version, use the approved backup/rollback procedure rather than manually guessing the previous contents.

Search phrases:

- undo NUT config change
- revert configuration
- restore previous NUT setting
- I changed the wrong setting

---

## How to Change a UPS Shutdown Delay / Timer

UPS shutdown timers determine how long NUT waits after the relevant power condition before the configured shutdown workflow begins.

This is a HIGH-IMPACT configuration change.

Current documented timer baseline:

- UPS7: 240 seconds
- UPS2: 315 seconds
- UPS8: 180 seconds
- UPS6: 300 seconds
- UPS9: 360 seconds
- UPS3: 300 seconds

UPS1, UPS4, and UPS5 are currently documented as alert-only paths rather than timed shutdown paths.

### Procedure

1. Identify the UPS whose timer must change.
2. Confirm the reason for the change.
3. Confirm the new delay has been approved.
4. Open [Configuration](09_CONFIGURATION_HOWTOS.md).
5. Locate the configuration controlling UPS scheduling/timing in [Configuration](09_CONFIGURATION_HOWTOS.md), then review the [upssched.conf reference](REF_13_upssched_conf.md).
6. Review the existing timer and compare it with the current mapping in [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).
7. Change only the intended UPS timer.
8. Validate the configuration.
9. Do not Save if validation fails.
10. Save the approved change.
11. Reload and confirm the new value.
12. Verify the scheduling configuration non-destructively.

Technical areas associated with UPS event scheduling include:

- /etc/nut/upssched.conf
- /usr/sbin/upssched
- /usr/local/bin/nut-orchestrator.sh

Do NOT unplug a UPS or create a real ONBATT event merely to test a timer change.

Search phrases:

- change UPS shutdown time
- change UPS7 timer
- how long before NUT shuts down
- shutdown delay
- UPS timer
- increase shutdown timeout
- decrease shutdown timeout

---

## How to Add or Modify an Approved Shutdown Target

Approved targets define systems that NUT is permitted to act on as part of controlled shutdown orchestration.

This is a HIGH-IMPACT configuration change.

Current technical reference:

- approved-targets.yml

### Procedure

1. Identify the system being added or changed.
2. Confirm the hostname and IP address.
3. Confirm the system is supposed to be controlled by NUT.
4. Determine which UPS protects the system using [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).
5. Determine which shutdown wrapper/integration applies using [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md).
6. Confirm required credentials already exist using the approved process in [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).
7. Back up the current configuration.
8. Open the approved-target configuration and review the [approved-targets.yml reference](REF_18_approved_targets_yml.md).
9. Add or modify only the intended target.
10. Validate the configuration.
11. Review the target information carefully.
12. Save the approved change.
13. Reload and verify the target remains correct.
14. Perform only the approved non-disruptive integration verification.

Never perform an unapproved live shutdown to prove a newly added target.

Search phrases:

- add server to NUT
- add protected system
- change shutdown target
- approved targets
- change server IP in NUT
- move server to another UPS

---

## How to Change a Protected System IP Address

1. Identify every NUT configuration that references the old address.
2. Confirm the new address is correct.
3. Check the approved-target configuration using the [approved-targets.yml reference](REF_18_approved_targets_yml.md).
4. Check the associated shutdown wrapper configuration in [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md).
5. Check the verification-target configuration using the [shutdown verification targets reference](REF_20_shutdown_verification_targets_conf.md).
6. Update only the intended system.
7. Validate each changed configuration.
8. Save the approved changes.
9. Verify connectivity non-destructively.

Do not assume changing an IP in one file automatically changes every NUT integration.

---

## How to Change Which UPS Protects a System

Changing UPS-to-system mapping can change which outage causes a protected system to shut down.

1. Confirm the physical power connection first.
2. Identify the system.
3. Identify the old UPS mapping.
4. Confirm the new UPS mapping.
5. Review the current mapping in [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).
6. Update the approved configuration.
7. Validate.
8. Save.
9. Verify the logical mapping matches the physical power connection.

Do not change logical mapping merely because a system appears near a different UPS in the rack.

---

## Where to Change Passwords and Credentials

Not every credential used by the NUT environment is exposed as a normal field under Configuration -> EDITABLE LIVE CONFIG.

For DB01 and DB02 database shutdown access, use the dedicated **Credential and Password Changes** Help article instead of assuming the password is stored in a general Configuration form.

Use that article for searches and tasks such as:

- DB01 password
- DBO1 password
- update DB01 password
- DB02 password
- update DB02 password
- database Telnet password
- database Telnet username
- update username

The Configuration page should only be used for credential fields that are actually presented there as editable controls.

Never paste a live password into Help, logs, screenshots, tickets, GitHub, or other documentation.

Related Help:

- Credential and Password Changes - Complete How-To
- Protected Systems - Complete Operator How-Tos
- Security - Complete Operator How-Tos

## Editable Live Config File Guide

The Configuration area edits approved files from **Editable Live Config**. It is a file-level editor, not a separate form for every setting.

### ups.conf

Path: `/etc/nut/ups.conf`

Defines the configured UPS devices and their NUT driver/device settings.

Changes can affect whether a UPS is detected, monitored, or available to the rest of the NUT system. Validate changes carefully and verify UPS monitoring afterward without creating a real power event.

Search phrases:

- ups.conf
- UPS configuration
- UPS driver
- UPS device config
- configure UPS

### upsd.conf

Path: `/etc/nut/upsd.conf`

Controls the NUT server listener configuration. The current configuration includes the local NUT listener.

Search phrases:

- upsd.conf
- NUT listener
- NUT port
- UPS server listener

### upsmon.conf

Path: `/etc/nut/upsmon.conf`

Controls UPS monitoring behavior and participates directly in power-event handling.

Changes can affect monitoring and shutdown orchestration. Validate carefully and do not perform a live outage merely to test a change.

The currently captured directives are `SHUTDOWNCMD "/sbin/shutdown -h now"` and `POWERDOWNFLAG /etc/killpower`. FSD (Forced Shutdown) is separate from cancelable per-UPS timer workflows. Changing either directive requires a full upsmon stop/start; reload alone is insufficient. See [FSD / Forced Shutdown](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md#fsd-and-forced-shutdown-are-a-separate-path). Do not restart services as part of documentation review.

Search phrases:

- upsmon.conf
- UPS monitoring config
- monitoring configuration

### upssched.conf

Path: `/etc/nut/upssched.conf`

Controls scheduled UPS-event actions and timer behavior used by shutdown orchestration.

Changes can directly alter outage timing or cancellation behavior.

Search phrases:

- upssched.conf
- shutdown timer
- UPS timer
- power event timer

### nut.conf

Path: `/etc/nut/nut.conf`

Contains the NUT operating-mode configuration used by the installed NUT software.

Do not change the file merely to switch the Control Center between PROTECTING, STANDBY, and OFF; use the supported Protection Mode controls for those operational states.

Search phrases:

- nut.conf
- NUT mode config
- NUT operating mode

### hosts.conf

Path: `/etc/nut/hosts.conf`

Controls the UPS systems made available to NUT CGI/status components through `MONITOR` entries.

Changing a monitored host can affect which UPS is displayed or queried by those components.

Search phrases:

- hosts.conf
- MONITOR entry
- UPS host
- monitored UPS

### Dashboard UI Settings

Path: `/etc/nut/config.d/dashboard-ui.json`

Controls Control Center presentation options, including dashboard title, visibility of Simulated Test, Real Test and Backup controls, and Action Output line limits.

Validate JSON before saving. These settings affect the UI and do not themselves change UPS shutdown logic.

Search phrases:

- dashboard UI settings
- dashboard-ui.json
- hide test button
- show backup button
- output lines
- dashboard title

### Hypervisor SSH Fallback Config

Path: `/etc/nut/hypervisors/hypervisor-ssh-fallback.conf`

Prepares optional SSH fallback settings for supported hypervisors. The primary VMware shutdown path remains the approved vCenter path unless fallback is separately enabled, approved and tested.

This file contains settings for fallback enablement, shutdown methods, SSH-key reference, ESXi host information, delays, and future Proxmox wiring.

Do not enable SSH fallback or populate live host mappings experimentally. Changes can directly affect protected-system shutdown behavior.

Search phrases:

- hypervisor SSH fallback
- ESXi SSH fallback
- VMware fallback
- hypervisor-ssh-fallback.conf
- Proxmox fallback

### Main NUT Orchestrator

Path: `/usr/local/bin/nut-orchestrator.sh`

This is the primary shutdown-orchestration program. It coordinates approved protected-system actions after qualifying UPS events and timers.

Changes are high impact. Use Validate, preserve a backup, and verify through non-destructive testing before any approved live test.

Search phrases:

- nut-orchestrator.sh
- main orchestration
- shutdown orchestrator
- shutdown sequence

---

## Production-Hours Safety

Generally SAFE during production hours:

- viewing configuration
- Reload
- reviewing existing values
- running approved syntax validation

USE CAUTION:

- Save
- Revert
- notification configuration changes
- credential-related configuration changes

DO NOT CHANGE WITHOUT APPROVAL:

- UPS shutdown timers
- approved shutdown targets
- UPS-to-system mappings
- shutdown commands
- live-action permissions
- protected-system addresses used by shutdown orchestration

---

## Monitoring Impact

The impact depends on the configuration being edited.
Some files directly control NUT monitoring behavior.

## Notification Impact

Notification-related configuration changes can suppress or alter email and Telegram delivery.

## Shutdown-Protection Impact

Timer, target, mapping, credential, and shutdown-wrapper changes can directly affect shutdown protection.

---

## How to Verify a Configuration Change Without a Live Shutdown

1. Reload the saved configuration.
2. Confirm the intended value.
3. Run the supported validation.
4. Check the relevant service status.
5. Review the relevant logs using [Logs](16_LOGS_HOWTOS.md).
6. Use the supported [Simulated Test procedure](10_TESTS_AND_LOGS_HOWTOS.md) when that feature applies.
7. Use integration-specific authentication/connectivity validation when applicable.

Do not use Real Test unless a live/disruptive test has been specifically approved.

---

## Troubleshooting

If Validate fails:

1. Do not Save.
2. Read the reported error.
3. Compare the edited line with the previous configuration.
4. Correct only the error.
5. Validate again.

If Save fails:

1. Do not repeatedly click Save.
2. Record the error without exposing secrets.
3. Check the Control Center service journal using [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md).
4. Check file ownership and permissions.
5. Use Revert or the approved rollback method described in [Restore and Disaster Recovery](12_RESTORE_AND_DR_HOWTOS.md) if necessary.

If a protected-system verification fails after a successful Save:

1. Stop before performing a live test.
2. Recheck IP address, username, credential reference, and target mapping.
3. Review the associated shutdown wrapper logs.
4. Revert the change if the previous configuration was known-good.

---

## Security Rules

- Never paste passwords into configuration documentation.
- Never place credentials in Help articles.
- Never expose secret files through the Control Center.
- Never commit live passwords, Telegram tokens, SMTP passwords, or API secrets to GitHub.
- Preserve restrictive permissions on secret files.
- Treat accidentally exposed credentials as compromised.


## Choose the change before choosing the file

This section answers two practical questions: which file controls the thing you want to change, and what else must be checked before the change will work. A server plugged into a UPS does not automatically become an approved shutdown target. A credential file is useful only if the active wrapper actually reads it.

Evidence labels: CURRENT means a path, registry entry or behavior is supported by the captured server evidence S01–S06. STANDARD NUT means the version 2.8.1 manual defines a directive, but its local value may not have been captured. CHECK CONSUMER means the active script or configuration loader must be inspected before editing. These checks are particularly important for the two different nut-orchestrator.conf files.

| What changed | Start here | Other checks |
| --- | --- | --- |
| A physical server was added to an existing UPS | /etc/nut/config.d/approved-targets.yml, then the actual UPS handler/wrapper | Physical UPS mapping; supported shutdown method; secure credential store; verification target; order; backup and Help. Do not add an ordinary server to ups.conf. |
| A VM was added to VMware | Approved-target mapping and the active VMware wrapper; inspect /etc/nut/config.d/vmware-vm-map.conf | Confirm the VM identity and phase/exclusion rules. This map exists but its exact consumer/schema must be verified. No new UPS driver merely for a new VM. |
| A new UPS was installed | /etc/nut/ups.conf | Driver/device identity, monitoring in upsmon.conf, event routing in upssched.conf, orchestration, UI inventory and physical mapping. |
| A server account password changed | The credential source read by that server’s shutdown wrapper | Confirm this is the automation account, not an unrelated human account; check shared consumers and test authentication without shutdown. |
| The vCenter automation password changed | /etc/nut/vcenter.pass, after tracing the active consumer | Also inspect references to /etc/nut/vmware.creds and any fallback credential source; file existence does not prove which path is active. |
| A NUT monitoring account password changed | /etc/nut/upsd.users and every affected client MONITOR entry | This is NUT client authentication, not a protected server’s OS password. upsd.users is intentionally blocked from raw editor access. |
| The outage countdown needs changing | /etc/nut/upssched.conf | Inspect corresponding orchestrator countdown/state/notification text; keep all values aligned. Do not change timers for a password rotation. |
| A display label or notification setting changed | Relevant UI settings or notification control | A cosmetic mapping does not register an executable shutdown action. SMTP secrets are separate from ordinary email settings. |

## What you can change in each configuration entry

The entries below describe change categories, not blanket permission to edit. Use current syntax already supported by the consumer. The registry’s validator checks the configured validation function; it does not establish every allowed key or a safe value range. For custom files whose body/parser was not supplied, exact key names are deliberately not invented.

### ups.conf

File: /etc/nut/ups.conf

What it controls: Defines UPS devices and the driver used to communicate with each device. It does not list ordinary servers powered by those UPSes. [STANDARD NUT; current path S03]

What can be changed: A UPS section name, driver, port and optional desc; supported hardware-specific connection/identity options. Select options from the installed driver manual. Driver and port are required by standard NUT.

When to change it: Use for a new/replaced UPS, a driver/device connection change or a UPS description. Do not put a Windows/Linux server password here. Renaming a UPS can break monitoring and event references.

Apply and verify: Plan affected driver reconfiguration and verify the same physical UPS identity and current readings. The UI Save/restart behavior is not established; do not assume Save restarts a driver.

### upsd.conf

File: /etc/nut/upsd.conf

What it controls: Configures the NUT data server that makes UPS information available to clients. [STANDARD NUT; S03]

What can be changed: Standard directives include LISTEN address/port and MAXAGE for stale-data handling. Other transport/TLS settings require the installed manual and current network design.

When to change it: Use when NUT listening/network access changes, not merely when a server is plugged into a UPS. NUT users/passwords belong in upsd.users, not here.

Apply and verify: Verify intended client connectivity and ensure the service is not exposed beyond approved networks. Determine the activation method for the changed directive before applying.

### upsmon.conf

File: /etc/nut/upsmon.conf

What it controls: Controls what this host monitors, power-value shutdown decisions, notifications and local shutdown command. [S05; STANDARD NUT]

What can be changed: MONITOR entries specify UPS connection, power value, monitoring account and role. Other directives include MINSUPPLIES, NOTIFYCMD/NOTIFYFLAG and polling/synchronization settings. See the Shutdown Orchestration Help article for captured directives.

When to change it: Edit when monitored UPS relationships or NUT authentication change. A remotely commanded protected server is not automatically a new MONITOR line. MINSUPPLIES is not a server-count field.

Apply and verify: SHUTDOWNCMD and POWERDOWNFLAG require a full upsmon stop/start when changed. Other activation details need installed-manual/consumer verification. The current direct command bypass remains unresolved.

### upssched.conf

File: /etc/nut/upssched.conf

What it controls: Routes UPS events to the orchestrator and defines the current cancelable countdowns. [S05]

What can be changed: AT ONBATT START-TIMER delays in seconds; matching ONLINE CANCEL-TIMER; EXECUTE handler names; CMDSCRIPT, PIPEFN and LOCKFN wiring.

When to change it: For a timer change, inspect both START-TIMER and matching cancel route. For a new event/UPS, an EXECUTE name must have an implemented handler. Preserve UPS3 validation and UPS1/4/5 alert-only scope unless separately redesigned.

Apply and verify: Check syntax, handler spelling and state/notification timing together. Do not assume an existing running timer adopts an edited value; inspect timer state and use a controlled activation plan.

### nut.conf

File: /etc/nut/nut.conf

What it controls: Selects the host’s NUT service/deployment mode; packaging/startup integration consumes it. [STANDARD NUT; S03]

What can be changed: MODE supports none, standalone, netserver and netclient in standard NUT. The current captured registry does not establish this file’s live MODE value.

When to change it: Change only when changing NUT architecture/service role. Do not switch to netclient merely because another ordinary server was added to the room.

Apply and verify: Mode changes affect which NUT components start. Review package/service integration and dependent clients before an approved service change.

### hosts.conf

File: /etc/nut/hosts.conf

What it controls: Lists UPS monitoring targets and descriptions for standard NUT CGI pages such as upsstats, using MONITOR system description. It is not the server-room equipment inventory. [STANDARD NUT; S03]

What can be changed: UPS connection strings and display descriptions in the supported CGI syntax.

When to change it: Use if a standard CGI UPS list/label needs changing. Confirm whether the custom Control Center consumes this file before expecting its display to change.

Apply and verify: Verify the actual CGI consumer; this is not a shutdown action registration or credential rotation file.

### Live nut-orchestrator.conf

File: /etc/nut/nut-orchestrator.conf

What it controls: The live orchestration configuration path exposed by the registry. Full settings and precedence were not supplied. [S03; CHECK CONSUMER]

What can be changed: Only existing keys actually read by the active orchestrator/wrappers. Identify their meanings, types and precedence in the source before changing them.

When to change it: Inspect when target connection, approval or execution settings may live here. Do not assume every new target can be added here or that this file mirrors config.d.

Apply and verify: Trace the file load from /usr/local/bin/nut-orchestrator.sh and called wrappers. Confirm whether settings are read per invocation or cached; preserve actual permissions.

### config.d nut-orchestrator.conf

File: /etc/nut/config.d/nut-orchestrator.conf

What it controls: A separate config.d orchestration file. Similar names do not prove the same purpose or active precedence. [S03; CHECK CONSUMER]

What can be changed: Only parser-supported keys present in this file. Registry metadata alone cannot identify a supported target schema.

When to change it: Use only after identifying the caller. Do not update both orchestrator files blindly to keep them looking alike; one may override or serve a different consumer.

Apply and verify: Record the active read path and resolved setting. Verify the consumer, not just the saved text.

### Approved Targets

File: /etc/nut/config.d/approved-targets.yml

What it controls: The registry’s Approved Targets YAML. It is the first mapping to inspect when a protected system is added or removed. [S03; CHECK CONSUMER]

What can be changed: Target records and their supported fields, using the exact existing YAML schema. Candidate information includes identity and approved action scope; the actual key names were not captured.

When to change it: Adding a row does not prove that an UPS handler or test runner will execute it. Trace the target through the orchestrator and wrapper; verify all relevant allowlists.

Apply and verify: Use YAML validation, read back the parsed record and confirm selection by the actual consumer. Registry apply_mode local_or_ssh is not permission to run a remote shutdown.

### Dashboard UI Settings

File: /etc/nut/config.d/dashboard-ui.json

What it controls: Dashboard UI settings registered as JSON. Exact keys and defaults require the current UI loader. [S03; CHECK CONSUMER]

What can be changed: Only existing, consumer-supported display/behavior settings. Valid JSON is not proof that a key is recognized.

When to change it: Use for UI settings, not as a substitute for protected-target registration. A server label appearing in the UI does not establish shutdown coverage.

Apply and verify: Verify the intended screen after Save/readback. Reload/caching behavior needs current UI evidence.

### DB Shutdown Config

File: /etc/nut/db-shutdown.conf

What it controls: Shell-format DB Shutdown Config associated with the DB shutdown area. Detailed keys/consumer precedence were not captured. [S03; CHECK CONSUMER]

What can be changed: Supported non-secret connection/target settings only after reading nut-db-shutdown.sh and its config loads.

When to change it: For DB account rotation, inspect db-telnet.user and db-telnet.pass and any db-telnet.conf references; do not assume the password is stored in db-shutdown.conf.

Apply and verify: Because shell-format files may be sourced, treat edits as potentially executable input. Validate syntax and perform supported non-shutdown authentication checks.

### Hypervisor SSH Fallback Config

File: /etc/nut/hypervisors/hypervisor-ssh-fallback.conf

What it controls: Configuration for the hypervisor SSH fallback path. [S03]

What can be changed: Supported host/account/key-reference/fallback settings as defined by the current helper. Exact keys must be read from that implementation.

When to change it: Inspect for added/replaced ESXi hosts or changed SSH identities. A vCenter password rotation does not necessarily rotate SSH keys/accounts.

Apply and verify: Use the established read-only preflight after inspecting its supported inputs. Do not enable live fallback/host-action approval gates as an authentication test.

### vCenter Password

File: /etc/nut/vcenter.pass

What it controls: A sensitive password entry at /etc/nut/vcenter.pass, registered with type password. [S04]

What can be changed: The stored password value in the exact format expected by its consumer; no arbitrary configuration keys.

When to change it: For a vCenter password change, first confirm the active wrapper reads this file and whether other VMware/fallback consumers share the account.

Apply and verify: Use the secure credential workflow; never paste the value into output. Verify an authenticated read-only inventory query and current file permissions; no shutdown is needed.

### NUT Email Alert Settings

File: /etc/nut/nut-email-alerts.conf

What it controls: Shell-format NUT Email Alert Settings with dedicated validate_nut_email_alerts_conf validator. [S04]

What can be changed: Only supported mail/report settings in the live parser. Recipients/category controls may also be exposed by separate notification APIs.

When to change it: For SMTP password changes, inspect the separate nut-email-alerts.secret source and SMTP rebuild helper; do not place a secret in an ordinary setting without consumer evidence.

Apply and verify: Validate, read back and reconcile any generated SMTP configuration. Delivery testing sends a message and needs its own authorized scope.

### Synology API Config

File: /etc/nut/synology-api.conf

What it controls: Sensitive Synology API configuration. Historical evidence describes a DSM API shutdown path replacing old SSH. [S04; historical S09]

What can be changed: Consumer-supported API connection/account settings, including secret values only through the secure workflow. Exact key names and TLS policy require the current wrapper.

When to change it: Inspect for a DSM automation-account password, API endpoint or target change. Do not assume changing a personal DSM account affects the automation account.

Apply and verify: Validate using an approved non-shutdown API authentication/query/logout path after checking implementation; do not invoke the shutdown method to test login.

## Executable entries are code changes

Eleven of the 26 editable registry entries are executable scripts/helpers. They appear in the same selector but are not ordinary configuration files. Change them only when the implemented behavior must change; store routine credential rotations in the credential source they read. A generic text validator does not prove script correctness.

| Editable script | What a change means |
| --- | --- |
| nut-synology-shutdown.sh<br>/usr/local/sbin/nut-synology-shutdown.sh | Synology action/API workflow. Change for a new supported API/method or behavior; use Synology API Config for supported account/connection changes. |
| nut-voip-shutdown.sh<br>/usr/local/sbin/nut-voip-shutdown.sh | VOIP target action. Inspect current credential source and target identity; neither a new server nor a password change justifies guessing its variables. |
| nut-db-shutdown.sh<br>/usr/local/sbin/nut-db-shutdown.sh | DB01/DB02 action implementation. Existing DB settings/credential consumers must be traced before adding a third target. |
| nut-blueiris-shutdown.sh<br>/usr/local/sbin/nut-blueiris-shutdown.sh | Blue Iris action implementation. The 2026-10-09 scan found a reference to /etc/nut/lansweeper.creds. Lansweeper references the same file. Exact fields and active reading still require confirmation. |
| nut-ui-run-test<br>/usr/local/sbin/nut-ui-run-test | Simulation dispatch/validation. Update only if a newly supported target must be included in the test workflow; simulation is not target shutdown proof. |
| nut-ui-run-real-test-approved<br>/usr/local/sbin/nut-ui-run-real-test-approved | Real-test approval/dispatch. Preserve authorization gates; adding a target must not silently broaden an existing live test. |
| nut-lansweeper-shutdown.sh<br>/usr/local/sbin/nut-lansweeper-shutdown.sh | Lansweeper action. A lansweeper.creds file exists, but verify the active wrapper consumes it before rotation. |
| nut-vmware-shutdown.sh<br>/usr/local/sbin/nut-vmware-shutdown.sh | VMware guest/host shutdown sequencing and fallback. Target inventories, phases and credential sources must match its implementation. |
| nut-netapp-halt.sh<br>/usr/local/sbin/nut-netapp-halt.sh | NetApp halt workflow. A netapp.creds file exists; confirm consumer, account and per-node scope before changes. |
| nut-orchestrator.sh (main orchestration)<br>/usr/local/bin/nut-orchestrator.sh | UPS event handlers and wrapper call order. Adding a YAML target does not automatically create a handler. Required code changes belong in a separately reviewed implementation change. |
| nut-local-final-shutdown.sh<br>/usr/local/sbin/nut-local-final-shutdown.sh | Final local shutdown with explicit real-mode gates. Observium is still absent; do not insert a new server here merely to make it run last. |

## Files outside the editor that may also need attention

These paths exist in the captured inventory, but are not all editable registry entries. File existence is verified; the exact active consumer must still be traced before changing a value. Do not bypass the editor’s blocked-file protections by exposing secret contents elsewhere.

| Situation | Path to inspect | What to confirm |
| --- | --- | --- |
| Shutdown success checks | /etc/nut/config.d/shutdown-verification-targets.conf | Target identity/address and supported verification/timeout fields; a new action must also be verifiable. |
| VMware guest identity | /etc/nut/config.d/vmware-vm-map.conf | Whether the current VMware workflow loads it, expected identity format, phases and exclusions. |
| Lansweeper account | /etc/nut/lansweeper.creds | Current wrapper reference, file format and whether account is shared. |
| NetApp account | /etc/nut/netapp.creds | Current wrapper reference, node scope and all consumers sharing the account. |
| VMware account | /etc/nut/vmware.creds and /etc/nut/vcenter.pass | Which active paths use which source. Do not rotate one and assume both consumers changed. |
| DB automation account | /etc/nut/db-telnet.user; /etc/nut/db-telnet.pass; /etc/nut/db-telnet.conf | Username/password source and target scope used by the current DB wrapper. No secret values are shown. |
| SMTP authentication | /etc/nut/nut-email-alerts.secret | The active settings/rebuild/helper source, generated transport configuration and secret propagation. |
| NUT client authentication | /etc/nut/upsd.users | NUT accounts and privileges. Coordinate each affected client MONITOR credential. |
| Third V240 account | /etc/nut/secrets/v24013-shutdown.env | Correct intended target and consumer; live test remains deferred. |
| Telegram bot credentials | /etc/nut/secrets/telegram-alerts.env | Bot transport credential source, not a protected server password. |
| Restore coverage | /etc/nut/restore/restore-targets.json; /etc/nut/restore/full-managed-restore-policy.json | Whether a newly required non-secret file is included in supported recovery. No new target schema is inferred. |

Blue Iris and VOIP credential-source paths are not established by the provided registry. Inspect their active wrappers before selecting a secret file. A path named in an old document or an unused backup does not establish the current credential source.

## Example a new physical server on an existing UPS

Example: a new application server is installed on an already monitored UPS. The names and values below describe the workflow only; no production target, address, YAML key or shutdown command is invented.

1. Record physical identity, operating system, power feeds, UPS association, dependencies and whether automatic shutdown is actually required. An alert-only UPS does not become shutdown-enabled by adding equipment.

2. Decide the supported shutdown method and automation account with the system owner. Identify an existing suitable wrapper or the need for a new implementation; do not point an unrelated wrapper at the new server.

3. Inspect /etc/nut/config.d/approved-targets.yml and its actual loader. Add the target only using the verified schema and intended approval scope. Confirm that the consumer will select it.

4. Trace the affected UPS handler in /usr/local/bin/nut-orchestrator.sh. If the handler names targets explicitly, a reviewed code change is required to call the new target in the correct order; YAML alone is insufficient.

5. Configure the supported target settings in the file actually read by that wrapper. Establish credentials securely in its intended source. Do not duplicate passwords across unrelated config files.

6. Inspect /etc/nut/config.d/shutdown-verification-targets.conf and add the supported verification record if required. Confirm network dependencies so a lost switch is not mistaken for a confirmed shutdown.

7. Check whether adding the target changes shutdown duration enough to require a separate timer/dependency review. Do not change the UPS countdown automatically.

8. Update the physical inventory, supported UI display mapping, sanitized backup/restore coverage and Help action matrix. ups.conf normally remains unchanged because no new UPS was installed.

9. Run syntax/schema checks and supported non-disruptive connectivity/authentication/simulation checks. Confirm target identity, selection, order and unchanged existing targets.

10. Record the implementation status and leave real shutdown/recovery validation DEFERRED until the separately approved live test succeeds.

Rollback must cover the whole change set: target mapping, handler/wrapper, verification record and related display/backup changes. Removing only the YAML row may leave another explicit call active. Keep the current production configuration intact until the reviewed change can be applied and recovered coherently.

## Example a new VMware virtual machine

1. Confirm the VM’s current unique identity, owner, cluster placement and dependency order. A display name alone may be ambiguous.

2. Inspect the current VMware wrapper’s inventory and selection logic, then /etc/nut/config.d/vmware-vm-map.conf and Approved Targets where those files are actually consumed.

3. Add the VM using the supported identity/phase schema and confirm exclusions. Do not claim every discovered VM is automatically approved for shutdown.

4. Check guest shutdown readiness and the actual credentials/permissions used by the control path. A VM addition does not normally require editing UPS device definitions or changing the vCenter password.

5. Validate with supported read-only inventory and simulation; record the VM’s planned phase and preserve the deferred T04 live-validation status.

## Example a server password changed

First determine which password changed. A human login password may have no effect on automation if the wrapper uses a separate service account or SSH key. Conversely, one shared automation account may affect several wrappers. The correct file is the one loaded by the active consumer, not the file with the most familiar name.

1. Identify the changed account, affected server and wrapper. Confirm whether it uses a password, SSH key, API credential or a NUT monitoring account.

2. Trace the credential reference from the live wrapper/config loader without printing the secret. Record the file path, account scope and all consumers; use the table in 4.4 as starting points, not proof of active use.

3. Prepare a secure rotation/recovery plan with the account owner. Update the authoritative credential source using the expected format and preserve required ownership/permissions. Do not copy the value into documentation, chat, logs or a public backup.

4. Check for a generated configuration, cached credential or long-running process that must pick up the change. Perform only the activation established by its implementation; there is no universal NUT restart for target password changes.

5. Use a supported non-shutdown authentication/read-only query. Successful TCP reachability does not prove authentication, and authenticated login alone does not prove shutdown privileges.

6. Run the supported simulation/preflight to check the intended consumer and target selection. Do not use Real Test, FSD or a shutdown command merely to test the password.

7. Record the rotation date, credential-source path and successful checks without the value. Update documentation only if the source/account/method changed; do not document the new password.

Specific examples: a vCenter automation password may be in vcenter.pass, but inspect any vmware.creds/fallback consumers too. A Lansweeper automation password may use lansweeper.creds, subject to wrapper confirmation. For DB targets, inspect db-telnet.pass and db-telnet.user. For Synology, inspect the sensitive API configuration. For an upsd account, coordinate upsd.users with the affected client MONITOR entries. These are different authentication relationships.

Credential rollback is not simply restoring an old local file: the old secret may no longer be accepted by the remote system. Recovery must coordinate the remote account and each affected consumer securely. Never print the old or new value as proof.

## Apply verify and revert checklist

| Stage | Required result |
| --- | --- |
| Before editing | Exact consumer, target, file and supported syntax identified; rollback/recovery access retained. |
| Validate | Registry validator plus appropriate parser/syntax and target-selection checks pass. Generic text validation alone is insufficient. |
| Save and activate | Read back intended content and actual permissions; use the consumer-specific activation rule. |
| Verify | Supported non-destructive authentication, identity, mapping and simulation checks pass. Existing target coverage remains unchanged except for the intended change. |
| Record | Capture non-secret evidence, changed paths and remaining live-test status. No unsupported claim of end-to-end success. |
| Revert | Restore the coherent configuration/code set and repeat checks; credential recovery also needs remote account coordination. |

## Evidence and verification limits

CURRENT refers to the supplied server captures: S01 operating system, packages, services and file metadata; S02 routes and Help inventory; S03 UI controls and registry; S04 remaining registry and Help index; S05 shutdown wiring; S06 final shutdown wrapper. S09 denotes historical documentation and is lower authority. These labels do not mean that the live server was rechecked for this Help revision. CHECK CONSUMER means the active loader, supported keys or precedence remain to be verified.

The captured direct SHUTDOWNCMD is /sbin/shutdown -h now and bypasses nut-local-final-shutdown.sh. Observium final-order integration remains PARTIAL pending credentials. Authentication checks and live shutdown tests described here have not been performed as part of this documentation update.

## Standard NUT 2.8.1 references

- [ups.conf](https://networkupstools.org/historic/v2.8.1/docs/man/ups.conf.html)
- [upsd.conf](https://networkupstools.org/historic/v2.8.1/docs/man/upsd.conf.html)
- [upsmon.conf](https://networkupstools.org/historic/v2.8.1/docs/man/upsmon.conf.html)
- [nut.conf](https://networkupstools.org/historic/v2.8.1/docs/man/nut.conf.html)
- [hosts.conf](https://networkupstools.org/historic/v2.8.1/docs/man/hosts.conf.html)
- [upsd.users](https://networkupstools.org/historic/v2.8.1/docs/man/upsd.users.html)
