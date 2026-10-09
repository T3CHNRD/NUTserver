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
