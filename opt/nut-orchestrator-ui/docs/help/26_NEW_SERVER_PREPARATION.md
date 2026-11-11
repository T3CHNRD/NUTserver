# Preparing to Add a Server

Base revision 2026-10-08 | Evidence update 2026-10-09

Use this checklist to gather the information needed to add a protected server. This is preparation guidance; target registration and activation steps still require inspection of the active scripts.

## 1 Record the server details

| Item | What to record |
| --- | --- |
| Server | Name and role |
| Power | Which UPS supplies it; verify physical wiring |
| Shutdown method | Supported and approved remote shutdown method |
| Automation account | Account role and secure credential location, without secret values |
| Dependencies | Systems that must stop before or after this server |
| Verification | A non-disruptive way to confirm identity and reachability |

## 2 Confirm how the target is selected

Establish whether the active handler reads a target list or contains explicit targets. Adding an entry to approved-targets.yml does not by itself prove that a shutdown action will run. Confirm the exact supported fields and action before making the entry.

## 3 Distinguish a server from a UPS

An ordinary server powered by an existing UPS is not a new UPS driver. For a VMware VM, establish how the active VMware script selects that VM and its shutdown phase. For a new physical UPS, driver and monitoring configuration must be reviewed separately.

## 4 Update the operating records

Once the implementation is approved and verified, update the relevant individual Word procedure, matching Help topic, system inventory and applicable backup/restore coverage together. Keep any deferred live test explicit.

Verification: this checklist does not claim that a new target has been configured or tested.


## Implementation evidence update — 2026-10-09

Revision date: 2026-10-09. Source review recorded; publication tracked separately.

A target list or verification-map entry does not by itself cause a shutdown. The orchestrator calls explicit wrappers in event-specific branches. For a physical server, confirm the UPS event and order, add or adapt the target wrapper, wire it into the correct orchestrator branch, add an independent verifier where supported, and test with command/verifier mocks. For a VMware guest, update the intended phase collection and identity map using the current verified vCenter identity; preserve separate targets and fail closed on ambiguous identity.

Do not copy credentials into Help. Protected account changes and production activation require the system owner. Source review is not a live shutdown test. See the new server procedure in the documentation package for the operator checklist.


## Implementation procedures

Continue with [Adding a physical server](32_ADD_PHYSICAL_SERVER.md) or [Adding a VMware VM](33_ADD_VMWARE_VM.md). The physical-server path needs explicit wrapper/event integration; the VMware map row format must be confirmed before editing.
