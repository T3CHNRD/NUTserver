# Getting Started with the NUT Control Center

## Purpose

The NUT Control Center is the primary administrative and monitoring interface for the Network UPS Tools environment.

Use it to:

- Monitor all configured UPS units.
- Review battery charge, load, runtime, voltage, and UPS state.
- Review power and boot events.
- View current protection mode.
- Manage notification settings.
- Review and safely edit approved NUT configuration files.
- Run approved simulated tests.
- Export logs.
- Back up the NUT server configuration to the sanitized GitHub backup.
- Perform approved restore operations.
- Review maintenance and weather status.
- Review shutdown orchestration information.

The Control Center also provides access to advanced live-test and restore functions. Those functions must not be used casually.

---

## Production-Hours Safety

### SAFE DURING PRODUCTION HOURS

Normal read-only operations are safe, including:

1. Opening the Control Center.
2. Reviewing UPS status.
3. Selecting a UPS.
4. Reviewing battery, load, runtime, and voltage.
5. Reviewing the Power / Boot Event Log.
6. Reviewing Notification Settings.
7. Reviewing Configuration without saving changes.
8. Reviewing read-only reference files.
9. Exporting logs.
10. Using Refresh.
11. Reviewing Action Output.
12. Reviewing UPS Rack Overview.

### USE CAUTION

These operations make configuration or delivery changes:

- Changing notification settings.
- Adding or removing email recipients.
- Approving or removing Telegram recipients.
- Saving configuration changes.
- Changing NUT Protection Mode.
- Running Backup.
- Running Restore functions.

Follow the specific Help article before making these changes.

### LIVE / DISRUPTIVE

Do not perform live UPS, shutdown, or protected-system testing during production hours unless the test is specifically approved.

The Real Test feature can perform live actions.

Do not enter the real Real Test passphrase unless an approved live test is being intentionally performed.

---

## How to Begin a Normal NUT Control Center Operator Session

### Step 1 - Open the NUT Control Center

Open the NUT Control Center using the normal internal company access method.

Do not expose the administrative Control Center directly to the public Internet.

### Step 2 - Check NUT Protection Mode

At the top of the Control Center, locate the protection-mode controls.

The three modes are:

- PROTECTING
- STANDBY
- OFF

Before making changes, note the current mode.

Do not change the mode simply because you are reviewing the dashboard.

### Step 3 - Check Overall Health

Review the System Overview area.

Confirm:

- The health/status area does not show an unexpected failure.
- The expected number of UPS units is available.
- The latest event does not indicate an unresolved power problem.
- Weather and maintenance information is reasonable.
- The refresh countdown is updating.

### Step 4 - Review UPS Monitoring

Open the Monitoring tab.

Check the selected UPS for:

- UPS name
- model
- battery charge
- load
- runtime
- input voltage
- output voltage
- UPS status
- refresh age

Use the UPS selector to review another UPS when needed.

### Step 5 - Review Recent Events

Open the Events tab.

Review the Power / Boot Event Log for unexpected:

- ONBATT events
- ONLINE events
- communication failures
- shutdown activity
- boot activity
- maintenance-related activity

### Step 6 - Review Notifications if Needed

Open Configuration and locate Notification Settings.

Review:

- Daily Health Email
- Weather-Based Closing Thoughts
- Email Recipients
- Telegram Push Notifications
- Daily Health Push
- Critical Power Alerts
- Heartbeat
- Telegram Recipients
- Pending Telegram Access

Do not assume a child Telegram preference means delivery is active when the Telegram master switch is OFF.

### Step 7 - Use Refresh if Data Looks Stale

Use the main Refresh button or the section-specific refresh control.

Do not restart NUT services merely because the browser display looks stale.

Refresh the page or use the Control Center refresh functions first.

---

## How to Use the Main Refresh Button

The **Refresh** button at the top of the NUT Control Center reloads the entire Control Center page.

Use it when you want to refresh the overall dashboard, including the current information displayed by the page.

This is different from:

- **Refresh UPS**, which refreshes UPS monitoring data.
- **Refresh Event Log**, which refreshes the Power / Boot Event Log.

### Procedure

1. Click **Refresh** at the top of the Control Center.
2. Allow the page to reload.
3. Confirm the dashboard returns normally.
4. Recheck the information you wanted to refresh.

### Expected Result

The Control Center reloads and displays its current information.

Using the main Refresh button does not itself create a UPS event, change Protection Mode, or initiate a shutdown.

Search phrases:

- refresh button
- main refresh
- refresh dashboard
- reload dashboard
- update control center
- refresh everything

---

## Expected Normal Result

A normal operator session should typically show:

- NUT services healthy.
- Configured UPS units reachable.
- Current UPS information refreshing.
- No unexplained recent shutdown events.
- Protection mode matching intended operational state.
- Notification settings matching the intended delivery configuration.

---

## How to Determine Whether the NUT Server Is Healthy

Use this procedure for questions such as:

- is NUT working
- NUT health
- is everything okay
- check server health
- system status

### Step 1 - Review the System Overview

Open the NUT Control Center and review the System Overview.

Confirm there is no unexpected health failure or unresolved power condition.

### Step 2 - Check Protection Mode

Confirm the current mode is understood:

- PROTECTING means monitoring and normal automatic protection are available.
- STANDBY means monitoring remains active while live protected-system shutdown actions are blocked.
- OFF means operational monitoring, logging, scheduled health reporting, and live shutdown protection are intentionally stopped.

OFF can therefore be healthy only when OFF was intentionally selected.

### Step 3 - Check UPS Monitoring

Confirm configured UPS units are visible and current UPS information is refreshing.

Review the selected UPS for:

- UPS status
- battery charge
- load
- runtime
- input voltage
- output voltage
- refresh age

An unexpected communication failure, stale data condition, or unavailable UPS requires investigation.

### Step 4 - Review Recent Events

Open the Events area and check for unexplained:

- ONBATT events
- communication failures
- shutdown activity
- repeated service or monitoring failures

Normal historical events do not by themselves mean the server is unhealthy.

### Step 5 - Check the Backend Status if Needed

For an additional read-only check, run:

    sudo /usr/local/sbin/nut-production-status

Confirm the reported mode and monitoring state agree with what the Control Center shows.

When monitoring is expected to be active, the core services can also be checked with:

    systemctl is-active nut-server.service
    systemctl is-active nut-monitor.service
    systemctl is-active nut-orchestrator-ui.service

### Expected Result

A healthy normal operating state should show:

- the Control Center responding normally
- the intended Protection Mode
- monitoring active when the selected mode requires it
- configured UPS units reporting current information
- no unexplained active power or communication problem
- recent events consistent with actual conditions
- required services active when monitoring is expected

Do not create a real UPS event or perform a live shutdown merely to prove that the NUT server is healthy.


