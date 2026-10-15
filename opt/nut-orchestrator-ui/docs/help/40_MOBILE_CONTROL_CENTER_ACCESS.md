# Mobile Access to the NUT Control Center

Revision date: 2026-10-15

## Purpose

This article explains the currently supported way to open the NUT Control Center from a phone and the boundary around access from outside the company network.

## Current supported access

Internal mobile access over company Wi-Fi is working. The Control Center layout is responsive and can be used from a phone browser.

When the phone is connected to the company Wi-Fi, open the approved internal Control Center address:

`http://<INTERNAL_IP>/nut-ui/control-center`

This address is already listed in the Control Center overview and Help reference index. Continue to use the existing authentication and security controls. This article does not change or bypass them.

## Open the Control Center on a phone

1. Connect the phone to the normal company Wi-Fi network.
2. If you are unsure which network is the approved company Wi-Fi, confirm its name with your IT administrator. Do not assume a guest or public network can reach the Control Center.
3. Open the phone’s browser and enter the approved internal address shown above.
4. Sign in using the existing approved access method.
5. Confirm that the Control Center loads and that its tabs and content fit the phone display. The responsive layout is already verified; no separate mobile mode needs to be enabled.

## External and remote access policy

Access from outside the company network is **not implemented** and is not a supported procedure at this time. Do not expose the Control Center directly to the public Internet.

Do not:

- create a port forward to the Control Center;
- publish the web UI on a public address;
- bypass or weaken existing authentication or security controls;
- change firewall, DNS, proxy, tunnel, VPN, or network settings to enable phone access.

Any future external-access request requires separate operator approval and a separately reviewed secure design and implementation task. This article does not authorize or configure external access.

## Basic troubleshooting

If the page does not load while using the phone:

1. Confirm the phone is connected to the approved company Wi-Fi, rather than relying on cellular data.
2. Re-enter the approved internal address exactly as shown above.
3. Retry in the browser after confirming that the phone has joined the network successfully.
4. If it still fails, record the time, phone/browser, and whether another approved device on company Wi-Fi can open the Control Center. Give those details to the NUT/IT administrator.

Do not change network or firewall settings, try a public route, or disable security controls as a troubleshooting step.

## Expected result and verification

On company Wi-Fi, the approved internal address opens the same Control Center used from other supported internal devices, with a layout that fits the phone screen. This verifies internal access only. It does not establish or imply external access.

## Recovery and escalation

If phone access stops working, return to the approved internal Wi-Fi and address, then report the observed error to the administrator. Do not make infrastructure changes yourself. External access remains out of scope unless the operator separately approves a secure design and implementation task.
