# Non Disruptive NUT Test Plan

## 1 Purpose

Use this plan to check the installation without deliberately changing protection, contacting protected systems for authentication, sending notifications or executing shutdown paths. These checks do not prove that a real outage sequence works.

## 2 Checks that can be planned as read only

- Inspect service and timer status, failed-unit names and timestamps. Do not start or stop units.
- Inspect file existence, ownership and modes. Do not print secrets or credential-bearing configuration lines.
- Review existing logs through a redacting reader; logs can contain sensitive values.
- Read known status and Help endpoints only after inspecting that route for writes or command execution. GET alone is not proof of a read-only operation.
- Check Help filenames, article links and Word/Help correspondence.
- Parse Python source as syntax without importing it. Run shell syntax checks on private copies without sourcing them, with diagnostics protected from secret exposure.

## 3 Isolated logic tests

Run tests in a disposable environment with production paths replaced by fixture paths, credentials replaced by fake values and network access blocked. Replace shutdown, SSH, RPC, API, notification, service-control and filesystem-changing dependencies with recording stubs. Assert the selected target, action order, rejection, failure and unknown-result behavior. Review the test harness before running it; merely setting SIMULATE is insufficient.

## 4 Actions outside this test plan

Do not invoke production wrappers, FSD, outage events, Save/Apply, rollback, restore, mode changes, service restarts, authentication or notifications. Full restore preflight writes staging and backups, so it is not a read-only test. Synology simulation logs in and writes local events. Blue Iris/Lansweeper simulation does not authenticate. No dry-run or simulation is accepted solely on its name.

## 5 Report results accurately

For each check record what was inspected, its time, evidence, pass/fail and limits. Separate source inspection, isolated tests, read-only runtime observations and separately authorized live tests. Stop at unexpected writes or contact attempts. This plan proposes checks; it does not claim any were executed.
