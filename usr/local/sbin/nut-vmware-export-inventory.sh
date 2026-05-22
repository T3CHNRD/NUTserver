#!/bin/bash
set -u

CONFIG_FILE="/etc/nut/nut-orchestrator.conf"
VCENTER_PASS_FILE="/etc/nut/vcenter.pass"
OUT_DIR="/var/log/nut-vmware-inventory"
OUT_FILE="${OUT_DIR}/vcenter-inventory-$(date +%Y%m%d-%H%M%S).json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "ERROR config file missing: $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

if [ -s "$VCENTER_PASS_FILE" ]; then
  VCENTER_PASSWORD="$(tr -d '\r\n' < "$VCENTER_PASS_FILE")"
fi

mkdir -p "$OUT_DIR"

python3 - <<PY
import json
import sys
import requests
from datetime import datetime

server = "${VCENTER_SERVER:-}"
user = "${VCENTER_USERNAME:-}"
password = "${VCENTER_PASSWORD:-}"
verify = False if "${VCENTER_INSECURE:-1}" == "1" else True
out_file = "${OUT_FILE}"

if not server or not user or not password:
    print("ERROR: missing VCENTER_SERVER, VCENTER_USERNAME, or VCENTER_PASSWORD", file=sys.stderr)
    sys.exit(1)

session_url = f"https://{server}/rest/com/vmware/cis/session"

try:
    session_response = requests.post(
        session_url,
        auth=(user, password),
        verify=verify,
        timeout=20,
    )
    session_response.raise_for_status()
    session_id = session_response.json()["value"]
except Exception as exc:
    print(f"ERROR: vCenter login failed: {exc}", file=sys.stderr)
    sys.exit(1)

headers = {"vmware-api-session-id": session_id}

def get_json(path):
    url = f"https://{server}{path}"
    response = requests.get(url, headers=headers, verify=verify, timeout=30)
    response.raise_for_status()
    return response.json().get("value", [])

try:
    vm_list = get_json("/rest/vcenter/vm")
    host_list = get_json("/rest/vcenter/host")

    host_by_id = {
        item.get("host"): item
        for item in host_list
        if item.get("host")
    }

    placement_by_vm_id = {}
    placement_error = None
    try:
        import subprocess
        placement_cmd = [
            "/usr/local/sbin/nut-vmware-readonly-placement.py",
            "--all",
            "--json",
        ]
        placement_result = subprocess.run(
            placement_cmd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=90,
        )

        if placement_result.returncode == 0:
            placement_items = json.loads(placement_result.stdout)
            placement_by_vm_id = {
                item.get("vm_moref"): item
                for item in placement_items
                if item.get("vm_moref")
            }
        else:
            placement_error = placement_result.stderr.strip() or f"placement helper rc={placement_result.returncode}"
    except Exception as exc:
        placement_error = str(exc)

    inventory = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "vcenter_server": server,
        "source": "read-only vCenter REST API inventory export",
        "notes": [
            "This export uses read-only inventory endpoints after vCenter session login.",
            "It also merges read-only pyVmomi VM runtime placement when available.",
            "It does not call guest shutdown, poweroff, reboot, ESXi shutdown, or storage shutdown endpoints.",
        ],
        "placement_source": "pyVmomi read-only helper" if placement_by_vm_id else "unavailable",
        "placement_error": placement_error,
        "hosts": host_list,
        "vms": [],
    }

    for vm in vm_list:
        vm_id = vm.get("vm")
        detail = {}

        if vm_id:
            try:
                detail_response = requests.get(
                    f"https://{server}/rest/vcenter/vm/{vm_id}",
                    headers=headers,
                    verify=verify,
                    timeout=30,
                )
                detail_response.raise_for_status()
                detail = detail_response.json().get("value", {})
            except Exception as exc:
                detail = {"detail_error": str(exc)}

        host_id = detail.get("host")
        host_detail = host_by_id.get(host_id, {})
        placement = placement_by_vm_id.get(vm_id, {})

        resolved_host_id = placement.get("host_moref") or host_id
        resolved_host_name = placement.get("host_name") or host_detail.get("name")
        resolved_cluster_name = placement.get("cluster_name")

        inventory["vms"].append({
            "name": vm.get("name"),
            "vm": vm_id,
            "power_state": vm.get("power_state"),
            "cpu_count": vm.get("cpu_count"),
            "memory_size_MiB": vm.get("memory_size_MiB"),
            "host_id": resolved_host_id,
            "host_name": resolved_host_name,
            "cluster_name": resolved_cluster_name,
            "placement": placement,
            "detail": detail,
        })

    with open(out_file, "w", encoding="utf-8") as handle:
        json.dump(inventory, handle, indent=2, sort_keys=True)

    print(out_file)

except Exception as exc:
    print(f"ERROR: inventory export failed: {exc}", file=sys.stderr)
    sys.exit(1)
PY

RC="$?"

if [ "$RC" -ne 0 ]; then
  exit "$RC"
fi

chmod 640 "$OUT_FILE"
chown root:root "$OUT_FILE"

echo "Inventory written to: $OUT_FILE"
exit 0
