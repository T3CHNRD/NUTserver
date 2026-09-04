# NUT Server Control Center

## Complete Source, Configuration, Documentation, and Disaster-Recovery Repository

This repository is the authoritative source and disaster-recovery repository
for the NUT Server environment.

Its purpose is not merely to hold a partial or selected backup.

The project goal is for GitHub to contain every current non-secret file and
every non-secret piece of information required to reproduce the working NUT
Server on a clean compatible Ubuntu system.

The intended recovery path is:

    Fresh Ubuntu 24.04
        |
        v
    Clone this GitHub repository
        |
        v
    Install required operating-system packages
        |
        v
    Restore NUT Server application, configuration and automation
        |
        v
    Re-enter intentionally excluded authentication secrets
        |
        v
    Validate the restored environment
        |
        v
    Place the server into service

The repository should therefore contain the current authoritative versions of:

- application source code
- web Control Center source
- HTML templates
- JavaScript and CSS
- Python code
- shell scripts
- shutdown wrappers
- orchestration logic
- NUT configuration
- Configuration-tab managed configuration
- systemd services
- systemd timers
- systemd paths
- systemd overrides and drop-ins
- Apache configuration
- sudoers configuration required by the application
- UPS definitions
- protected-system mappings
- shutdown verification configuration
- VMware / vCenter integration logic
- ESXi integration logic
- database shutdown integration
- Blue Iris integration
- Lansweeper integration
- Synology integration
- NetApp integration
- VOIP infrastructure integration
- V240 shutdown integration
- local NUT Server shutdown logic
- email notification logic
- Telegram notification logic
- weather and health-report logic
- maintenance workflows
- UPS identity checking
- backup implementation
- restore implementation
- disaster-recovery tooling
- deployment information
- package and platform requirements
- searchable Help documentation
- technical reference documentation
- recovery instructions
- secret templates and secret-recreation instructions

## Recovery Standard

The final standard for this repository is:

> If the production NUT Server disappeared today, GitHub contains every
> non-secret piece of information and every non-secret file needed to reproduce
> the current working NUT Server.

The project is not considered fully recoverable until that statement can be
answered YES.

## What "Sanitized" Means

This repository is comprehensive in scope, but authentication secrets must
never be committed.

Sanitization applies to secrets, not to the functionality or architecture of
the NUT Server.

The repository may contain the infrastructure information required to rebuild
the environment, including non-secret:

- host names
- IP addresses
- UPS mappings
- protected-system mappings
- shutdown target definitions
- service relationships
- orchestration rules
- VMware / ESXi configuration structure
- database target structure
- notification configuration structure

What must NOT be committed includes actual:

- passwords
- SMTP passwords
- API tokens
- Telegram bot tokens
- vCenter passwords
- Telnet passwords
- private SSH keys
- private certificate keys
- secret environment files
- recovery passphrases
- other authentication credentials

For every required secret-bearing component, the repository should instead
contain enough information to recreate it safely, such as:

- `.template` or `.example` files
- expected variable names
- expected path
- owner
- group
- permissions
- purpose
- instructions for supplying the secret after recovery

## NUT Server Control Center

The primary application is located on the running server at:

    /opt/nut-orchestrator-ui

Its repository representation is:

    opt/nut-orchestrator-ui/

The Control Center provides centralized access to:

- UPS monitoring
- operating modes
- power-event history
- tests and logs
- configuration management
- notification management
- UPS inventory
- maintenance operations
- backup
- restore
- searchable Help
- technical documentation

## Operating Modes and Safety

The NUT Server uses controlled operating modes including:

- OFF
- STANDBY
- PROTECTING

The system includes safety gates intended to prevent inappropriate mutating
operations while production protection is active.

A freshly restored server must start in a safe state.

A restore or rebuild must never automatically begin issuing production
shutdown commands merely because the software has been installed.

Production protection should only be enabled after the restored environment
has been validated.

## Protected Systems and Shutdown Orchestration

The repository contains the non-secret configuration and code necessary to
reproduce the protected-system shutdown architecture.

This includes integrations and workflows for systems such as:

- DB01
- DB02
- Sun Fire V240 systems
- VMware / ESXi
- vCenter
- Blue Iris
- Lansweeper
- Synology
- NetApp
- VOIP infrastructure
- local final NUT Server shutdown

Environment-specific non-secret target information required for proper
reconstruction belongs in this repository.

Authentication credentials used to reach those systems do not.

## Notifications and Health Reporting

The project includes:

- event-driven email notification
- Telegram notification
- Telegram command functionality
- Telegram heartbeat
- daily UPS health reporting
- weather integration
- maintenance-aware reporting
- critical power-event messaging
- restoration notifications

The code, schedules, templates and non-secret configuration for these systems
must be reproducible from GitHub.

## Help and Technical Documentation

The authoritative Help tree is:

    /opt/nut-orchestrator-ui/docs/help

The repository representation is:

    opt/nut-orchestrator-ui/docs/help/

The Help system includes operator How-Tos and technical reference articles
covering the Control Center, UPS configuration, notifications, maintenance,
shutdown orchestration, protected systems, configuration, backup, restore,
security and troubleshooting.

Current authoritative Help documentation belongs in GitHub.

Temporary editing copies and unreconciled historical source material do not
belong in the authoritative recovery tree.

## GitHub Backup Button

The Control Center Backup button is intended to perform a complete current
backup of the authoritative NUT Server source into GitHub.

The execution path is:

    Control Center Backup button
        |
        v
    Flask backup API
        |
        v
    /usr/local/sbin/nut-ui-backup-now
        |
        v
    /usr/local/sbin/nut-run-backup-and-push.sh
        |
        v
    /usr/local/sbin/nut-sync-live-to-repo-for-backup
        |
        v
    sanitized authoritative Git working tree
        |
        v
    git add
        |
        v
    git commit
        |
        v
    git push
        |
        v
    GitHub

The working repository on the production server is:

    /opt/nut-admin/repo-template

The GitHub backup branch is:

    backup-sanitized-initial

When the Backup button is used, the expected result is:

1. Current GitHub state is synchronized safely.
2. Current authoritative live NUT Server files are collected.
3. Current application source is copied.
4. Current scripts and wrappers are copied.
5. Current configuration is copied or safely sanitized.
6. Current Help documentation is copied.
7. Required Apache, systemd and sudoers configuration is copied.
8. Disaster-recovery information is refreshed.
9. Temporary development artifacts are excluded.
10. Authentication secrets are excluded.
11. Safe templates/documentation represent required secrets.
12. Git stages all resulting changes.
13. A new commit is created when changes exist.
14. The resulting commit is pushed to GitHub.

The goal is that clicking **Backup** is sufficient to capture all current
recoverable NUT Server changes without requiring the operator to remember
which individual files changed.

## Repository Structure

Important repository areas include:

    opt/nut-orchestrator-ui/
        Web application, UI code, libraries and documentation

    opt/nut-admin/
        Backup/inventory tooling required for repository maintenance

    usr/local/bin/
        Main orchestration scripts

    usr/local/sbin/
        NUT helper scripts, shutdown integrations, backup and restore tools

    etc/nut/
        NUT configuration and safe secret representations

    etc/systemd/system/
        Local NUT service, timer, path and override configuration

    etc/sudoers.d/
        NUT Control Center sudo policy

    etc/apache2/
        Apache configuration for the web application

    disaster-recovery/
        Full sanitized disaster-recovery information

    recovery/
        Rebuild metadata, platform information and recovery instructions

## Temporary and Historical Files

Development backup files are not authoritative source.

Files such as the following should not be part of the current recovery tree:

    *.pre-*
    *.before-*
    *.bak*
    *.backup
    *.candidate
    *.working-*
    *.final-before-*

Git history already provides version history for committed source code.

The recovery repository should represent the current authoritative system,
not a collection of old manual working copies.

## Rebuilding the Server

The target recovery platform is Ubuntu 24.04.

The final recovery process should be capable of:

1. Installing required packages.
2. Deploying the Control Center application.
3. Installing Python dependencies.
4. Installing NUT configuration.
5. Installing scripts and shutdown wrappers.
6. Installing systemd configuration.
7. Installing Apache configuration.
8. Installing required sudoers policy.
9. Restoring correct ownership and permissions.
10. Recreating service enablement.
11. Identifying every intentionally missing secret.
12. Validating configuration before activation.
13. Leaving the machine in a safe non-protecting state.
14. Allowing production protection only after operator approval.

## Final Disaster-Recovery Proof

Repository completeness alone is not the final proof.

The final validation is:

    Clean Ubuntu 24.04 machine
        +
    GitHub repository
        +
    manually supplied secrets
        =
    functional reconstructed NUT Server

Until that end-to-end reconstruction has been proven, the GitHub backup
should be considered comprehensive source/recovery work in progress rather
than a fully validated bare-metal recovery image.

## Security

This repository contains detailed internal infrastructure source,
configuration and topology information.

Even though passwords and authentication secrets are intentionally excluded,
the repository should be treated as sensitive internal infrastructure source
code and should have appropriately restricted access.

## Copyright

Copyright (c) 2026 T3CHNRD. All rights reserved.
