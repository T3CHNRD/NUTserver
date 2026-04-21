# NUT Orchestrator UI

Last Updated: 2026-04-21

## Purpose
The NUT Orchestrator UI is the internal administrative web interface for:
- editing approved live NUT/orchestrator config files
- viewing read-only reference files
- validating and saving approved changes
- running simulated and real tests
- launching the sanitized GitHub backup workflow

## Main Page Areas

### Editable Live Config
Loads an approved live file into the main editor.

### Read-Only Reference File
Loads a comparison/reference file into the reference pane.

### Action Output
Shows the raw output of the most recent action:
- load
- validate
- save
- revert
- simulated test
- real test
- backup
- errors

## Buttons

### Reload
Reloads the selected live file from the server into the editor.

### Validate
Runs a dry-run validation of the current editor contents.

### Save
Writes the approved edited contents to the live managed file.

### Revert
Resets the editor to the last loaded live version of the file.

### Simulated Test
Runs the safe dry-run backend workflow.

### Real Test
Runs the actual configured backend workflow.

### Backup All to GitHub
Runs the sanitized backup workflow for approved NUT UI/config/script files.

### Restore from GitHub
Placeholder only right now. Not yet implemented for production restore.

### Open Main Dashboard
Opens the main UPS monitoring dashboard.

## Current Proven State
- UI backup button works
- backend backup route works
- sanitized GitHub backup completes successfully
- no-change runs correctly report: No changes to commit
