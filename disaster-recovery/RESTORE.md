# NUT Server Disaster Recovery

This directory is for rebuilding the NUT server after catastrophic loss.

It is separate from the Configuration-area restore feature.

## Recovery flow

1. Install Ubuntu 24.04 LTS.
2. Install Git.
3. Clone the NUTserver GitHub repository.
4. Check out the disaster-recovery backup branch.
5. Run:

       sudo ./disaster-recovery/restore-nut-server.sh --check

6. If the check passes, run:

       sudo ./disaster-recovery/restore-nut-server.sh --apply

7. Re-enter secrets locally as documented in:

       disaster-recovery/SECRETS-NOT-IN-GITHUB.md

8. Run:

       sudo ./disaster-recovery/verify-restored-server.sh

9. Resolve every FAIL.
10. Review every WARN.
11. Only after validation should Protecting mode be enabled.

## Important

The GitHub repository intentionally does not contain passwords, tokens,
private SSH keys, private certificate keys, or other production secrets.

The normal Configuration Restore feature remains a separate system for
restoring selected configuration on an existing NUT server.
