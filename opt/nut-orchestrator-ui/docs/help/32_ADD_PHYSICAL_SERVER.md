# Add a Physical Server to UPS Shutdown Orchestration

**Use when:** a new physical system powered by an already-monitored UPS must join the automated shutdown sequence.

**Where:** coordinate the target’s automation account with its wrapper configuration, the development-reviewed wrapper, and the matching UPS event branch in `/usr/local/bin/nut-orchestrator.sh`. A dashboard/approved-target entry alone does not wire an action.

This task requires a reviewed implementation change, not just filling in a dashboard row. An administrator should own the wrapper and event-handler changes below.

**Procedure:**

1. Identify the UPS event that owns the server and its required shutdown position. Record the target name, address, operating system, command protocol, credential source, timeout, independent down-verifier, and recovery owner.
2. Confirm whether an existing wrapper already supports the target class. If not, prepare a target-specific wrapper that uses protected credentials, explicit action gates, clear rejection detection, and a positive down verifier. Do not embed credentials in the wrapper.
3. Add the wrapper invocation to the correct event branch in the orchestrator. The captured source uses explicit wrapper calls; target registration by itself is not an orchestration change. Add event-level ordering and “do not continue on failed/unknown” handling.
4. Add/update target verification metadata only when the wrapper’s verifier consumes it. The staged source proves the shared verifier-map helper is used by some wrappers, but the map alone does not dispatch shutdown.
5. Use the project’s isolated test approach: mock command and verifier executables and assert target, order, failure and unknown handling. Do not invoke the wrapper or authenticate to the target as a documentation check.
6. Review the development diff, owner/mode, helper dependencies and active caller context. Production activation, credential agreement and any live test are separate operator-controlled steps.

**Expected result:** the event branch invokes the wrapper at the intended point and blocks later progression when required verification fails.

**Verification:** source review + fixture tests prove control flow only. The manual timer capture agrees with the source thresholds. No target shutdown was executed during documentation work.

**Recovery:** remove the development branch change from the candidate and retain the target out of the active orchestration until wrapper, credentials and verifier are corrected. Do not remove a required target silently.

**Evidence:** orchestrator `/usr/local/bin/nut-orchestrator.sh` lines 194-389 and event cases 608-880; example wrapper pattern `/usr/local/sbin/nut-db-shutdown.sh` lines 108-196.
