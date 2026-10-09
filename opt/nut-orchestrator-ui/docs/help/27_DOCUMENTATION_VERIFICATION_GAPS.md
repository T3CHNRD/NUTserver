# Documentation Verification Gaps

Base revision 2026-10-08 | Evidence update 2026-10-09

This register lists work that remains before the entire documentation set can be released as complete production instructions. Verified reference topics can be used within their stated scope; unresolved actions must not be presented as tested procedures.

## 1 Open items

| ID | Area | Completion requirement |
| --- | --- | --- |
| G01 | Configuration settings | Exact fields, active reads and precedence; include VOIP and final wrapper. |
| G02 | Password changes | Shared consumers, supported update method, activation and read-only check. |
| G03 | Shutdown flow | Timer handlers, maintenance suppression and current final order including Observium. |
| G04 | Save and restore | Actual validation, reload/restart, eligibility and recovery behavior. |
| G05 | Unused files | Broader consumer review before any removal. |
| G06 | Original documents | Complete individual revision and reconcile unique historical content. |
| G07 | Help publication | Publish matching articles and verify authenticated display, search and navigation. |
| G08 | Word layout | Render and inspect the individual documents before final production release. |

## 2 Configuration cleanup

Review /etc/nut/config.d/nut-orchestrator.conf, /etc/nut/config.d/approved-targets.yml and /etc/nut/config.d/shutdown-verification-targets.conf across application loaders, indirect helpers, services, scheduled jobs and recovery procedures. No file is confirmed unused by the nine-script scan.

For each confirmed unused file, add a removal task for the file and obsolete editor, restore, Help and Word references. Keep rollback material. No deletion is performed by this package.

## 3 Publication status

The previously reported 13-article server candidate was staged but not published. This individual-topic package adds separate articles and index links; it does not apply that earlier diff or claim its stale-article corrections are complete. A successful installer run still needs authenticated UI review.

## 4 Evidence dates

Base documentation revision is 2026-10-08. Timer, restore and path-reference evidence was received on 2026-10-09. Operational tests are separate from file inspection.
