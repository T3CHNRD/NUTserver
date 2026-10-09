# Restore and Recovery Procedures

**Use when:** restoring selected managed files, recovering a prior editable configuration, or recovering the managed installation from the repository.

## Selected restore

Use the Restore Lab only after checking the selected item’s catalog eligibility and target path. Dry-run mode resolves the catalog item and prints a plan; it does not write. Live mode requires explicit confirmation, a restore-enabled item and allowed path checks. It backs up an existing destination before installing the selected repository source with catalog owner/group/mode. Catalog membership alone does not make an item eligible.

## Editable-config rollback

Use the UI rollback for an editable configuration ID. It selects the latest matching backup, restores the target and reapplies registered metadata. It does not restart or reload consumers, validate content or regenerate dependent files.

## Full managed restore

Treat preflight and live restore as separate operations. Preflight builds a restore plan, stages and validates candidate files, records metadata and creates a protected backup; it is not deployment. Live restore is policy/mode gated, preserves selected sensitive paths, captures current service states, stages and installs approved files, restarts only units that were active before the restore, validates activation, and attempts backup rollback on failure. The live helper is operational and must not be used as a documentation test.

**Expected result:** preflight provides a reviewable plan and backup evidence; a separately approved live restore reports activation validation or rollback status.

**Verification:** source inspection only. The separate manual catalog check captured 25 entries: 20 marked enabled with a source, one additional enabled DB username entry with no source, and four disabled sensitive entries. These are catalog fields, not a restore test. Full managed restore policy and present service states must be checked before a live restore.

**Recovery:** for selected restore, use the pre-restore target backup. For full restore, use the helper’s generated restore backup and inspect reported rollback status; if rollback is incomplete, stop and engage the administrator.

**Evidence:** `nut-ui-live-restore-selected` lines 17-172; `nut-ui-full-managed-restore-preflight` lines 295-475; `nut-ui-full-managed-restore-live` lines 627-898; `nut-ui-rollback` lines 16-36.
