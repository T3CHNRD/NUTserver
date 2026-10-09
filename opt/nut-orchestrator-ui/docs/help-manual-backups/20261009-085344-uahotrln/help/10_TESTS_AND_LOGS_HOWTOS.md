# Tests and Logs - Complete Operator How-Tos

## Purpose

Use Tests & Logs to validate NUT behavior, review command output, and collect troubleshooting information.

The most important rule in this section is to distinguish a safe Simulated Test from an approved Real Test.

---

## Safety Levels

### SAFE DURING PRODUCTION HOURS

- Review previous test output
- Show Safety Notes
- Copy Full Output
- Export Logs
- Review logs
- Run an approved Simulated Test that does not execute live shutdown actions

### LIVE / DISRUPTIVE - DO NOT RUN WITHOUT APPROVAL

- Real Test
- Any test that executes a real protected-system shutdown command
- Any test that intentionally creates a UPS power event
- Any test that powers off DB01, DB02, VMware, storage, or another production system

---

## Where to Find Tests & Logs

1. Open the NUT Control Center.
2. Click Tests & Logs.

Depending on the selected test or feature, controls may include:

- Run Simulated Test
- Run Test
- Real Test
- Show Safety Notes
- Copy Full Output
- Export Logs
- test target selection
- action output

---

## How to Run a Safe Simulated Test

Use Simulated Test when you need to verify orchestration logic without intentionally shutting down protected equipment.

1. Open [Tests and Logs](10_TESTS_AND_LOGS_HOWTOS.md).
2. Locate the Simulated Test section.
3. Select the intended test or target if required.
4. Read any safety information displayed on the page.
5. Confirm the test is explicitly identified as simulated or non-live.
6. Click Run Simulated Test.
7. Wait for Action Output to complete.
8. Read the entire result.
9. Confirm no live shutdown action was executed.

Expected result:

- The test exercises supported validation/simulation logic.
- Output explains what NUT would do or what was validated.
- Production systems remain running.
- No real UPS event is required.

Search phrases:

- run simulated test
- safe NUT test
- test NUT without shutdown
- dry run shutdown
- test without powering anything off

---

## How to Understand Simulated Test Output

1. Read the output from top to bottom.
2. Identify the selected target or workflow.
3. Look for PASS, FAIL, WARN, SKIP, or similar result indicators.
4. Review any authentication or connectivity result.
5. Review the command NUT intended to validate.
6. Confirm the output explicitly indicates simulation/non-live behavior where applicable.
7. Investigate every FAIL using [Troubleshooting](17_TROUBLESHOOTING_HOWTOS.md) and the appropriate [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md) procedure before considering a Real Test.

Do not treat a partial PASS as proof that an entire shutdown sequence is ready.

Search phrases:

- what does simulated test output mean
- NUT test failed
- test result PASS FAIL
- action output meaning

---

## How to Show Safety Notes

1. Open Tests & Logs.
2. Locate the selected test.
3. Click Show Safety Notes.
4. Read the entire warning before running the test.

Safety Notes should explain whether the test is simulated, potentially live, or otherwise restricted.

If the safety notes are unclear, do not proceed with a live test.

---

## How to Copy Full Output

Use Copy Full Output when you need to preserve test results for troubleshooting, documentation, or review.

1. Run or open the relevant test result.
2. Wait until output is complete.
3. Click Copy Full Output.
4. Paste the output only into an approved location.
5. Review copied output using the rules in [Security](18_SECURITY_HOWTOS.md) before sharing it; never expose passwords, tokens, private keys, or other secrets.

Never paste unreviewed credential-bearing output into chat, email, tickets, or public documentation.

Search phrases:

- copy NUT output
- copy test results
- copy action output
- save test result

---

## How to Export Logs

1. Open Tests & Logs.
2. Click Export Logs.
3. Wait for the log package/download to be generated.
4. Save the resulting file to an approved location.
5. Confirm the downloaded file is not empty.
6. Review sensitive content using [Security](18_SECURITY_HOWTOS.md) before sending logs outside the IT team.

Expected result:

A downloadable log package is produced without changing NUT operation.

Search phrases:

- export NUT logs
- download logs
- get NUT logs
- save troubleshooting logs

---

## How to Find the Correct Log for a Problem

For the detailed log-purpose map, use [Logs](16_LOGS_HOWTOS.md).

Start with the component that failed.

Examples:

- Control Center/UI problem: nut-orchestrator-ui.service journal
- NUT monitoring problem: nut-monitor.service and NUT-related journal output
- NUT server communication problem: nut-server.service and NUT-related logs
- notification failure: notification/email/Telegram logs and related helper output
- protected-system shutdown integration: associated shutdown wrapper output/logs

Useful read-only command pattern:

    systemctl status SERVICE-NAME

Useful recent-journal pattern:

    journalctl -u SERVICE-NAME --since today

Do not paste secret values from logs into documentation or chat.

---

## How to Check the Control Center Service Log

Use this when the dashboard does not load, a button returns an error, or a Help/API action fails.

Read-only examples:

    systemctl status nut-orchestrator-ui.service

    journalctl -u nut-orchestrator-ui.service --since today

Expected result:

The service should normally report active/running.

---

## How to Check Core NUT Service Status

For the complete service/timer inventory and troubleshooting procedures, use [Services and Timers](15_SERVICES_AND_TIMERS_HOWTOS.md).

Use:

    systemctl is-active nut-server.service
    systemctl is-active nut-monitor.service
    systemctl is-active nut-orchestrator-ui.service

Expected normal result:

    active

for each service that should currently be running.

Remember: NUT mode OFF intentionally changes the operational state and must not be mistaken for a normal monitoring mode.

---

## How to Run an Approved Real Test

WARNING: A Real Test may execute actual protected-system actions.

Do not use this procedure casually.

Before a Real Test:

1. Confirm the exact target in [Protected Systems](14_PROTECTED_SYSTEMS_HOWTOS.md) and verify its UPS relationship in [UPS Inventory and Automatic Actions](20_UPS_INVENTORY_AND_ACTIONS.md).
2. Confirm the test has been explicitly approved.
3. Confirm production impact is understood, including the applicable [Shutdown Orchestration](13_SHUTDOWN_ORCHESTRATION_HOWTOS.md) behavior.
4. Confirm required stakeholders know the test is occurring.
5. Confirm recovery/access methods are available.
6. Review the test-specific runbook.
7. Review Show Safety Notes.
8. Confirm you are not accidentally targeting DB01, DB02, or another production system that is excluded from live testing.

When the Control Center requires a Real Test passphrase:

1. Read the warning.
2. Enter the approved confirmation/passphrase only when the live test is authorized.
3. Recheck the selected target before confirming.
4. Run the test.
5. Monitor Action Output continuously.
6. Verify the target behavior through the approved validation method.
7. Record the result.

DO NOT use a Real Test simply because a Simulated Test passed.

Search phrases:

- run real NUT test
- live shutdown test
- actual shutdown test
- real test passphrase
- test production shutdown

---

## DB01 and DB02 Real-Test Restriction

Production DB01 and DB02 must not be used for live shutdown testing unless separately and explicitly authorized.

Current production references:

- DB01: 192.168.1.9
- DB02: 192.168.1.11

Use non-destructive validation for these systems.

---

## V240 Shutdown Test Guidance

A separate Sun Fire V240 has previously been used to prove the Solaris shutdown process without using production DB01 or DB02 as live-test targets.

Do not repeat a live V240 test automatically just because the test path exists.
Always verify which physical server and IP are being targeted before any live action.

---

## How to Troubleshoot a Failed Simulated Test

1. Do not escalate directly to Real Test.
2. Copy the full test output.
3. Identify the first FAIL rather than only the final summary.
4. Check the associated configuration.
5. Check required credentials without displaying them.
6. Check network reachability where appropriate.
7. Check the associated wrapper/script.
8. Check relevant logs.
9. Correct only the verified problem.
10. Run the Simulated Test again.

Only consider live validation after the simulated/non-disruptive path is clean.

---

## How to Troubleshoot Export Logs

If Export Logs does not download:

1. Try the button once.
2. Do not repeatedly click it.
3. Check nut-orchestrator-ui.service.
4. Review the UI journal for the export request.
5. Confirm the browser did not block the download.
6. Confirm the generated package/path exists if the backend reports success.

---

## Production-Hours Safety

SAFE:

- Read-only log review
- service-status checks
- Export Logs
- Copy Full Output
- Show Safety Notes
- approved non-disruptive Simulated Tests

DO NOT RUN WITHOUT APPROVAL:

- Real Test
- real UPS power-event tests
- actual shutdown commands
- production DB01 or DB02 shutdown tests
- production storage/VMware shutdown tests

---

## Monitoring Impact

Read-only log review and output export do not normally affect monitoring.
Simulated tests should be designed not to interrupt monitoring.

## Notification Impact

Some tests may generate test-specific output or notifications depending on the selected workflow.
Never assume a test notification is equivalent to a real UPS event.

## Shutdown-Protection Impact

A Simulated Test should not execute real shutdown protection actions.
A Real Test may execute them and therefore requires explicit approval.

---

## Security Rules

- Review exported/copied logs for secrets before sharing.
- Never expose passwords or tokens.
- Never publish Real Test passphrases.
- Never publish protected credentials in Help.
- Do not weaken file permissions to make log access easier.

