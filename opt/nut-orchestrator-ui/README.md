# NUT Orchestrator UI

Last Updated: 2026-04-21

## Purpose
The NUT Orchestrator UI is the internal administrative web interface for:
- editing approved live NUT/orchestrator config files
- viewing read-only reference files
- validating and saving approved changes
- running simulated and real tests
- launching the sanitized GitHub backup workflow

## Buttons and Functions

### Reload
Reloads the selected live file from the server into the editor.

### Validate
Runs dry-run validation against the current editor content.

### Save
Writes the approved edited content to the live managed file.

### Revert
Resets the editor back to the last loaded server content for that file.

### Simulated Test
Runs the safe dry-run test workflow.

### Real Test
Runs the actual configured backend test workflow.

### Backup All to GitHub
Runs the sanitized backup process for approved NUT UI/config/script files.

### Restore from GitHub
Currently placeholder only. Not yet implemented for production restore.

### Open Main Dashboard
Opens the main UPS monitoring dashboard.

### Action Output
Shows raw results for:
- load
- validate
- save
- revert
- simulated test
- real test
- backup
- errors

## Current Proven State
- Backup All to GitHub button works
- backend backup route works
- sanitized backup completes successfully
- no-change runs correctly report: No changes to commit
