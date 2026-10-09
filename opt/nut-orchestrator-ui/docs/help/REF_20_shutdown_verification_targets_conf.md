# Shutdown Verification Target Configuration

Path: `/etc/nut/config.d/shutdown-verification-targets.conf`

The reviewed `nut-get-verification-target` helper reads this file. It is actively used and is not an unused-file removal candidate. It supplies verification data to callers; it does not itself register a shutdown action. Preserve entries needed by current wrappers. Confirm the existing row format and all callers before adding or removing an entry.

See [Adding a physical server](32_ADD_PHYSICAL_SERVER.md) and [Project backlog](39_NUT_PROJECT_BACKLOG.md).
