# NUT Project Backlog

This is the known backlog from the documentation review, not a percentage-complete assessment of the entire project.

| Task | Current evidence and next action |
| --- | --- |
| Documentation release | Reconciled Word/Help content is prepared; finish visual review, original-source reconciliation and final publication checks. |
| Help search | Exact title should rank first; broad terms should return relevant related topics. Deferred until documentation work is closed. |
| Observium final order | No Observium action in reviewed final path. Implement only as a separately approved behavior change; credentials and tests remain work. |
| VMware T04 and ESXi fallback | Source includes gated paths. Reconcile development/deployment state and arrange separately approved validation. Do not enable gates just for documentation. |
| Third V240 | Confirm intended identity before deferred operational validation. |
| Maintenance and protection | Documented suppression is per UPS; unreadable state does not suppress. Review whether that failure behavior meets the operator's requirements as a separate design decision. |
| Restore coverage | Resolve DB username catalog entry with no source and review current full-restore policy. No live restore test was performed. |
| Service and timer health | Recheck earlier failed APC-monitor and stale timer findings; earlier observations are not proof of today's state. |
| Configuration cleanup | Review config.d/nut-orchestrator.conf, approved-targets.yml and dashboard-ui.json across all consumers. No removal authorized. |
| Active maps | Preserve shutdown-verification-targets.conf and vmware-vm-map.conf; active readers were found. |
| VOIP identity | Confirm SSH identity/config/agent path without exposing key contents. |
| Email recovery | Confirm generated msmtp consumer and required recovery steps; config rollback does not rebuild it. |
| Credential verification | Document/implement approved non-shutdown checks where none exist. Do not use shutdown wrappers to test passwords. |
| KDE and XRDP recovery | Previously deferred recovery check remains separate from documentation production. |
| Safe test suite | Implement the isolated plan with mocked actions and no production network access. |

No cleanup deletion, operational improvement or live test is performed by the documentation installer.
