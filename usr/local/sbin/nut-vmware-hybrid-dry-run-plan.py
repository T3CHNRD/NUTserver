#!/usr/bin/env python3
# Copyright (c) 2026 T3CHNRD. All rights reserved.
import json
import sys
from pathlib import Path
from datetime import datetime

TOOLS_REPORT = Path("/var/log/nut-vmware-inventory/vmware-tools-status-latest.json")
INVENTORY_DIR = Path("/var/log/nut-vmware-inventory")
OUT_DIR = Path("/var/log/nut-vmware-inventory")

VCSA_NAME = "albl-vcsa"
ESXI_SHUTDOWN_REASON = "power outage"

DANGEROUS_WORDS = [
    "ShutdownGuest",
    "PowerOffVM",
    "PowerOnVM",
    "RebootGuest",
    "ResetVM",
    "SuspendVM",
    "MigrateVM",
    "EnterMaintenanceMode",
    "ExitMaintenanceMode",
    "ShutdownHost",
    "RebootHost",
    "esxcli system shutdown",
    "poweroff",
    "shutdown -h",
]


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def latest_inventory_json():
    candidates = sorted(
        p for p in INVENTORY_DIR.glob("vcenter-inventory-*.json")
        if p.is_file()
    )
    return candidates[-1] if candidates else None


def main():
    if not TOOLS_REPORT.exists():
        print(f"ERROR: missing tools report: {TOOLS_REPORT}", file=sys.stderr)
        sys.exit(2)

    inv_path = latest_inventory_json()
    if not inv_path:
        print("ERROR: no vcenter-inventory-*.json files found", file=sys.stderr)
        sys.exit(2)

    tools = load_json(TOOLS_REPORT)
    inventory = load_json(inv_path)

    vms = tools.get("vms", [])
    hosts = inventory.get("hosts", [])

    host_names = sorted({h.get("name") for h in hosts if h.get("name")})
    powered_on_vms = [vm for vm in vms if vm.get("power_state") == "poweredOn"]
    powered_off_vms = [vm for vm in vms if vm.get("power_state") == "poweredOff"]

    vcsa = None
    for vm in vms:
        if vm.get("name", "").lower() == VCSA_NAME.lower():
            vcsa = vm
            break

    non_vcsa_powered_on = [
        vm for vm in powered_on_vms
        if vm.get("name", "").lower() != VCSA_NAME.lower()
    ]

    tools_not_ready = [
        vm for vm in powered_on_vms
        if vm.get("shutdown_readiness") != "LIKELY_GUEST_SHUTDOWN_READY"
    ]

    plan = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "mode": "READ_ONLY_DRY_RUN",
        "safety": {
            "guest_shutdown_sent": False,
            "vm_poweroff_sent": False,
            "host_maintenance_mode_sent": False,
            "host_shutdown_sent": False,
            "esxi_ssh_commands_sent": False,
            "note": "This planner reads existing reports and generates intended order only."
        },
        "inputs": {
            "tools_report": str(TOOLS_REPORT),
            "inventory_report": str(inv_path),
        },
        "summary": {
            "hosts_found": len(host_names),
            "vm_count": len(vms),
            "powered_on": len(powered_on_vms),
            "powered_off": len(powered_off_vms),
            "tools_not_ready": len(tools_not_ready),
            "vcsa_name": VCSA_NAME,
            "vcsa_host": vcsa.get("host_name") if vcsa else None,
            "esxi_shutdown_reason": ESXI_SHUTDOWN_REASON,
        },
        "hosts": [],
        "vm_shutdown_verification_dry_run": [],
        "planned_order": [],
        "warnings": [],
    }

    if not vcsa:
        plan["warnings"].append("VCSA VM not found in tools report.")
    elif not vcsa.get("host_name"):
        plan["warnings"].append("VCSA host placement missing.")
    else:
        plan["planned_order"].append(
            f"Defer {VCSA_NAME} until after non-VCSA VM shutdown requests."
        )

    if tools_not_ready:
        for vm in tools_not_ready:
            plan["warnings"].append(
                f"Powered-on VM not guest-shutdown-ready: {vm.get('name')} "
                f"tools={vm.get('tools_running_status')} readiness={vm.get('shutdown_readiness')}"
            )

    for vm in sorted(non_vcsa_powered_on, key=lambda x: (x.get("host_name") or "", x.get("name") or "")):
        plan["vm_shutdown_verification_dry_run"].append({
            "vm": vm.get("name"),
            "host": vm.get("host_name"),
            "current_power_state": vm.get("power_state"),
            "tools_running_status": vm.get("tools_running_status"),
            "guest_operations_ready": vm.get("guest_operations_ready"),
            "future_live_action": "request_guest_shutdown_then_poll_power_state",
            "safe_dry_run_action_now": "read_only_no_shutdown_sent",
            "expected_verification_logic": "poll until poweredOff or timeout; classify PASS/WARN/FAIL/UNKNOWN",
        })

    if vcsa:
        plan["vm_shutdown_verification_dry_run"].append({
            "vm": vcsa.get("name"),
            "host": vcsa.get("host_name"),
            "current_power_state": vcsa.get("power_state"),
            "tools_running_status": vcsa.get("tools_running_status"),
            "guest_operations_ready": vcsa.get("guest_operations_ready"),
            "future_live_action": "request_guest_shutdown_late_then_poll_power_state",
            "safe_dry_run_action_now": "read_only_no_shutdown_sent",
            "expected_verification_logic": "defer until late; poll until poweredOff or timeout; classify PASS/WARN/FAIL/UNKNOWN",
        })

    for host in host_names:
        host_vms = [vm for vm in powered_on_vms if vm.get("host_name") == host]
        host_non_vcsa_vms = [vm for vm in host_vms if vm.get("name", "").lower() != VCSA_NAME.lower()]
        host_is_vcsa_host = bool(vcsa and vcsa.get("host_name") == host)

        plan["hosts"].append({
            "host": host,
            "is_vcsa_host": host_is_vcsa_host,
            "current_powered_on_vms": [vm.get("name") for vm in host_vms],
            "current_non_vcsa_powered_on_vms": [vm.get("name") for vm in host_non_vcsa_vms],
            "future_live_precheck": "confirm no unexpected running VMs remain before host shutdown",
            "future_maintenance_mode": "planned_but_not_executed_in_dry_run",
            "future_shutdown_command_template": f'esxcli system shutdown poweroff --delay=60 --reason="{ESXI_SHUTDOWN_REASON}"',
            "safe_dry_run_action_now": "no_ssh_no_maintenance_no_shutdown",
        })

    plan["planned_order"].extend([
        "1. Confirm vCenter inventory and VMware Tools status.",
        "2. Request guest shutdown for non-VCSA VMs by approved phase/order.",
        "3. Poll/read VM power states until poweredOff or timeout.",
        "4. Defer VCSA until late.",
        "5. Request guest shutdown for VCSA late.",
        "6. Poll/read VCSA power state until poweredOff or timeout.",
        "7. For each ESXi host, confirm no unexpected running VMs remain.",
        "8. Enter maintenance mode only during approved live workflow.",
        f'9. Power off ESXi hosts only during approved live workflow with reason "{ESXI_SHUTDOWN_REASON}".',
    ])

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    out = OUT_DIR / f"vmware-hybrid-dry-run-plan-{stamp}.json"
    latest = OUT_DIR / "vmware-hybrid-dry-run-plan-latest.json"

    out.write_text(json.dumps(plan, indent=2), encoding="utf-8")
    latest.write_text(json.dumps(plan, indent=2), encoding="utf-8")

    print(f"PASS: wrote {out}")
    print(f"PASS: wrote {latest}")
    print(f"hosts_found={plan['summary']['hosts_found']}")
    print(f"vm_count={plan['summary']['vm_count']}")
    print(f"powered_on={plan['summary']['powered_on']}")
    print(f"tools_not_ready={plan['summary']['tools_not_ready']}")
    print(f"vcsa_host={plan['summary']['vcsa_host']}")
    print(f'esxi_shutdown_reason="{ESXI_SHUTDOWN_REASON}"')
    print("SAFE: no VM shutdown, no host maintenance mode, no host shutdown, no SSH commands sent")


if __name__ == "__main__":
    main()
