# Configuration - Complete Operator How-Tos

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

Not every configuration has the same operational risk.

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
- UPS2: 420 seconds
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

