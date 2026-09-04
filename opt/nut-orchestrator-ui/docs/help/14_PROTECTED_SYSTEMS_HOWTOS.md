# Protected Systems - Complete Operator How-Tos

## Purpose

This section explains how to review, update, validate, and troubleshoot each system that NUT may control during a protected shutdown workflow.

Always prefer non-disruptive validation unless a live shutdown test has been explicitly approved.

---

## How to Work With Any Protected System Safely

Before changing any protected-system integration:

1. Identify the exact system.
2. Confirm its hostname and IP address.
3. Confirm which UPS physically powers it.
4. Confirm the logical NUT mapping.
5. Identify the shutdown wrapper used by NUT.
6. Identify the credential source without displaying the secret.
7. Back up the affected configuration.
8. Make only the intended change.
9. Validate authentication/connectivity non-destructively.
10. Review logs.
11. Do not run a live shutdown test unless explicitly approved.

---

## How to Update or Troubleshoot <DATABASE_SERVER_1> Shutdown Integration

Production <DATABASE_SERVER_1>:

- IP: <INTERNAL_IP>

Current integration reference:

- /usr/local/sbin/nut-db-shutdown.sh

Procedure:

1. Confirm you are working with <DATABASE_SERVER_1> and not <DATABASE_SERVER_2>.
2. Review the DB shutdown target/configuration.
3. Confirm the <DATABASE_SERVER_1> IP is correct.
4. Confirm the configured Telnet username reference.
5. Confirm the password reference without displaying it.
6. If the password changed, use [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).
7. Perform only the approved non-destructive authentication validation.
8. Review wrapper output/logs.

DO NOT perform a live shutdown of production <DATABASE_SERVER_1> as a routine test.

Search phrases:

- <DATABASE_SERVER_1> shutdown
- <DATABASE_SERVER_1> NUT
- DBO1 password
- <DATABASE_SERVER_1> shutdown failed
- update <DATABASE_SERVER_1> in NUT

---

## How to Update or Troubleshoot <DATABASE_SERVER_2> Shutdown Integration

Production <DATABASE_SERVER_2>:

- IP: <INTERNAL_IP>

Current integration reference:

- /usr/local/sbin/nut-db-shutdown.sh

Procedure:

1. Confirm you are working with <DATABASE_SERVER_2>.
2. Review the DB shutdown configuration.
3. Confirm the <DATABASE_SERVER_2> IP.
4. Confirm the username reference.
5. Confirm the password reference without exposing it.
6. Use non-destructive authentication validation.
7. Review wrapper output/logs.

DO NOT perform a live shutdown of production <DATABASE_SERVER_2> as a routine test.

Search phrases:

- <DATABASE_SERVER_2> shutdown
- <DATABASE_SERVER_2> NUT
- DBO2 password
- <DATABASE_SERVER_2> shutdown failed
- update <DATABASE_SERVER_2> in NUT

---

## How to Update or Troubleshoot the Sun Fire V240 Integration

The V24013 integration is a **future-use deployment path**. It is not currently part of the production rack shutdown mapping and should not be treated as a current production protected system.

Current planned production V240 address:

- <INTERNAL_IP>

Dedicated wrapper reference:

- /usr/local/sbin/nut-v24013-shutdown.sh

A separate temporary recovery/test address <INTERNAL_IP> has previously been used to validate the Solaris shutdown process.

That previous validation does not authorize future live shutdown tests automatically.

Procedure:

1. Confirm the physical V240 you intend to manage.
2. Confirm its current IP.
3. Confirm the wrapper target.
4. Confirm credentials without displaying them.
5. Confirm approved-target mapping.
6. Use non-disruptive verification whenever possible.
7. Never accidentally target production <DATABASE_SERVER_1> or <DATABASE_SERVER_2> while testing V240 logic.

Search phrases:

- V240 shutdown
- Sun Fire shutdown
- Solaris shutdown
- <INTERNAL_IP>
- V240 NUT

---


## VMware / vCenter / ESXi Shutdown Architecture

The primary VMware shutdown method is the approved **vCenter API** path.

An **ESXi SSH fallback** also exists for supported failure scenarios, but it is gated by configuration, approval, outage confirmation, and fallback enablement.

The VMware wrapper:

1. processes configured VM shutdown phases
2. detects VCSA placement
3. shuts down VCSA at the appropriate point
4. proceeds to ESXi host shutdown
5. uses SSH fallback only when the required safety gates allow it

A successful shutdown command does not always prove the remote system has fully powered off. Command acceptance and independent power-state verification are separate concepts.

For current settings, review [Configuration](09_CONFIGURATION_HOWTOS.md).

For the wrapper implementation reference, see [nut-vmware-shutdown](REF_35_nut_vmware_shutdown.md).

For credential handling, use [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).

---

## How to Update or Troubleshoot VMware / vCenter Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-vmware-shutdown.sh

Procedure:

1. Confirm the correct vCenter target.
2. Confirm the account/credential reference.
3. If the vCenter password changed, use [Credential and Password Changes](18_CREDENTIAL_AND_PASSWORD_CHANGES.md).
4. Confirm VMware target configuration using [Configuration](09_CONFIGURATION_HOWTOS.md) and the [VMware shutdown wrapper reference](REF_35_nut_vmware_shutdown.md).
5. Validate connectivity/authentication without shutting down VMs.
6. Review the wrapper output.
7. Review the intended VM/host shutdown ordering.

Do not perform an ESXi or VM shutdown merely to test credentials.

Search phrases:

- VMware shutdown
- vCenter shutdown
- update vCenter password
- ESXi shutdown
- VM shutdown failed

---

## How to Update or Troubleshoot Synology Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-synology-shutdown.sh

Procedure:

1. Confirm the intended Synology system.
2. Confirm its address.
3. Confirm API credential reference.
4. Validate API connectivity without halting the NAS.
5. Review wrapper output.
6. Correct only the identified failure.

Search phrases:

- Synology shutdown
- NAS shutdown
- Synology password
- Synology API
- Synology NUT

---

## How to Update or Troubleshoot NetApp Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-netapp-halt.sh

Procedure:

1. Identify NetApp01 or NetApp02.
2. Confirm the target address.
3. Confirm the intended halt workflow.
4. Confirm authentication method.
5. Validate connectivity non-destructively.
6. Review wrapper output.
7. Do not halt production storage as a routine test.

Search phrases:

- NetApp shutdown
- NetApp halt
- NetApp01
- NetApp02
- storage shutdown

---

## How to Update or Troubleshoot Blue Iris Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-blueiris-shutdown.sh

Procedure:

1. Confirm the Blue Iris target system.
2. Confirm address and credentials.
3. Confirm target mapping.
4. Run supported non-destructive validation.
5. Review wrapper output.

Search phrases:

- Blue Iris shutdown
- camera server shutdown
- BlueIris NUT
- nut-blueiris-shutdown.sh
- Blue Iris shutdown script
- update Blue Iris shutdown

---

## How to Update or Troubleshoot Lansweeper Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-lansweeper-shutdown.sh

Procedure:

1. Confirm the Lansweeper target.
2. Confirm address and authentication method.
3. Confirm approved-target mapping.
4. Run supported non-disruptive validation.
5. Review wrapper output.

Search phrases:

- Lansweeper shutdown
- Lansweeper NUT
- Lansweeper server

---

## How to Update or Troubleshoot VoIP Shutdown

Current wrapper reference:

- /usr/local/sbin/nut-voip-shutdown.sh

Procedure:

1. Confirm the VoIP system target.
2. Confirm address and authentication.
3. Confirm UPS mapping.
4. Run non-disruptive validation.
5. Review wrapper output.

Search phrases:

- VoIP shutdown
- phone system shutdown
- VoIP NUT

---


## Automatic Shutdown Versus Alert-Only Equipment

Being physically powered by a UPS does not automatically mean NUT will issue a shutdown command to that device.

The current authoritative logical mapping is documented in [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).

That article identifies:

- automatic shutdown targets
- alert-only equipment
- timer values
- shutdown wrappers
- historical physical mappings that still need verification

Always verify both the physical UPS relationship and the current logical NUT action before changing a protected-system mapping.

---

## How to Change a Protected System IP Address

1. Verify the new IP is correct.
2. Search Help for change server IP.
3. Review approved-target configuration.
4. Review the associated wrapper configuration.
5. Review verification-target configuration.
6. Update all required references consistently.
7. Validate before saving.
8. Test connectivity without executing shutdown.

Do not assume the address exists in only one file.

---

## How to Change a Protected-System Password

Search Help for:

- <DATABASE_SERVER_1> password
- <DATABASE_SERVER_2> password
- vCenter password
- Synology password
- credential change

Use the Credential and Password Changes article.

Never paste the new password into Help, chat, screenshots, logs, or GitHub.

---

## How to Troubleshoot Authentication Failure

1. Confirm the target system.
2. Confirm network connectivity.
3. Confirm the username.
4. Confirm the secret file exists.
5. Confirm file ownership and permissions.
6. Confirm the remote account is not locked.
7. Run only the approved authentication validation.
8. Review sanitized logs.

Do not repeatedly retry a bad password if the target may lock the account.

---

## Production-Hours Safety

SAFE:

- read-only configuration review
- IP/mapping verification
- service/log review
- approved non-destructive authentication testing

HIGH RISK:

- changing production credentials
- changing target IPs
- changing UPS mappings
- changing shutdown commands

LIVE / DISRUPTIVE - DO NOT RUN WITHOUT APPROVAL:

- real <DATABASE_SERVER_1> shutdown
- real <DATABASE_SERVER_2> shutdown
- real VMware shutdown
- real Synology halt
- real NetApp halt
- any other production protected-system shutdown

---

## Monitoring Impact

Protected-system configuration normally does not change UPS monitoring directly.

## Notification Impact

Failed protected-system actions may generate failure/event notifications depending on current configuration.

## Shutdown-Protection Impact

Incorrect target information or credentials may prevent the protected system from shutting down during an actual outage.

---


## Reference Runbooks

- nut lansweeper shutdown
- nut synology shutdown
- nut voip shutdown
- nut db shutdown
- nut blueiris shutdown
- nut vmware shutdown
- nut netapp halt

---

## How to Determine Which UPS Protects a System

Use the current UPS inventory when determining the relationship between protected equipment and automatic NUT shutdown behavior:

[UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md)

The inventory distinguishes:

- physical or historically documented UPS association
- current automatic shutdown target
- alert-only equipment
- shutdown timer
- shutdown wrapper
- mappings that still require physical verification

Do not assume that equipment physically powered by a UPS is automatically shut down by NUT.
