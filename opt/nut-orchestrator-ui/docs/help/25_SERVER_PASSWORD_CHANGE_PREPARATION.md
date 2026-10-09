# Preparing for a Server Password Change

Base revision 2026-10-08 | Evidence update 2026-10-09

Use this checklist before changing an account used by shutdown automation. It prepares the change; it does not supply the still-unverified per-server editing or activation commands.

## 1 Identify the account

Record the server, the account being changed and whether shutdown automation uses that account. A personal login password may be unrelated. Record the account role without writing down the password.

## 2 Identify every affected script

Find the active credential source and all scripts that read it. The current reference scan points both Blue Iris and Lansweeper at /etc/nut/lansweeper.creds. Review both before editing. The vCenter reference is /etc/nut/vcenter.pass; Synology references /etc/nut/synology-api.conf; DB references /etc/nut/db-shutdown.conf. These references still require confirmation of the exact fields read.

## 3 Prepare the change and recovery steps

Before proceeding, establish the exact setting, whether any generated file or cached value must be refreshed, a non-shutdown authentication check, and a recovery plan coordinated with the remote account. Do not restore an old local password if the remote account no longer accepts it.

## 4 Keep secrets out of documentation

Enter passwords only through the approved credential process. Do not copy them into Help, Word documents, screenshots or reports. Do not run a shutdown script just to test a password.

Verification: this is a preparation checklist based on the current reference findings. The exact password-change procedures remain an open item in the Documentation Verification Gaps topic.
