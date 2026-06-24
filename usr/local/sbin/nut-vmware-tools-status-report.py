#!/usr/bin/env python3
# Copyright (c) 2026 T3CHNRD. All rights reserved.
import argparse
import configparser
import csv
import json
import os
import ssl
import sys
import socket
from datetime import datetime
from pathlib import Path

# Python 3.12 compatibility shim for older pyVmomi/pyVim code paths.
# This restores ssl.wrap_socket only for libraries that still expect it.
if not hasattr(ssl, "wrap_socket"):
    def _compat_wrap_socket(sock, keyfile=None, certfile=None, server_side=False,
                            cert_reqs=ssl.CERT_NONE, ssl_version=ssl.PROTOCOL_TLS,
                            ca_certs=None, do_handshake_on_connect=True,
                            suppress_ragged_eofs=True, ciphers=None):
        context = ssl.SSLContext(ssl_version)
        context.verify_mode = cert_reqs
        if ca_certs:
            context.load_verify_locations(ca_certs)
        if certfile:
            context.load_cert_chain(certfile, keyfile)
        if ciphers:
            context.set_ciphers(ciphers)
        return context.wrap_socket(
            sock,
            server_side=server_side,
            do_handshake_on_connect=do_handshake_on_connect,
            suppress_ragged_eofs=suppress_ragged_eofs
        )
    ssl.wrap_socket = _compat_wrap_socket

try:
    from pyVim.connect import SmartConnect, Disconnect
    from pyVmomi import vim
except Exception as e:
    print(f"ERROR: failed to import pyVmomi/pyVim: {e}", file=sys.stderr)
    sys.exit(2)


DEFAULT_MAIN_CONF = "/etc/nut/nut-orchestrator.conf"
DEFAULT_PASS_FILE = "/etc/nut/vcenter.pass"
DEFAULT_OUT_DIR = "/var/log/nut-vmware-inventory"


def load_config(path):
    values = {}
    if not os.path.exists(path):
        return values

    # This config has historically been shell-style, so parse simple KEY=VALUE lines.
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            values[key] = val
    return values


def get_password(config, pass_file):
    if os.path.exists(pass_file) and os.path.getsize(pass_file) > 0:
        return Path(pass_file).read_text(encoding="utf-8", errors="replace").strip()
    return (
        config.get("VCENTER_PASSWORD")
        or config.get("VMWARE_PASSWORD")
        or config.get("VCENTER_PASS")
        or ""
    )


def get_config_value(config, *names):
    for name in names:
        if name in config and config[name]:
            return config[name]
    return ""


def walk_vms(content):
    view = content.viewManager.CreateContainerView(
        content.rootFolder, [vim.VirtualMachine], True
    )
    try:
        for vm in view.view:
            yield vm
    finally:
        view.Destroy()


def safe_get(obj, attr, default=None):
    try:
        return getattr(obj, attr, default)
    except Exception:
        return default


def main():
    parser = argparse.ArgumentParser(description="Read-only VMware Tools status report")
    parser.add_argument("--config", default=DEFAULT_MAIN_CONF)
    parser.add_argument("--pass-file", default=DEFAULT_PASS_FILE)
    parser.add_argument("--out-dir", default=DEFAULT_OUT_DIR)
    parser.add_argument("--json-only", action="store_true")
    args = parser.parse_args()

    config = load_config(args.config)

    server = get_config_value(config, "VCENTER_SERVER", "VMWARE_VCENTER", "VCENTER_HOST")
    username = get_config_value(config, "VCENTER_USERNAME", "VMWARE_USERNAME", "VCENTER_USER")
    password = get_password(config, args.pass_file)

    if not server or not username or not password:
        print("ERROR: missing vCenter server, username, or password", file=sys.stderr)
        print(f"server_present={bool(server)} username_present={bool(username)} password_present={bool(password)}", file=sys.stderr)
        sys.exit(2)

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    json_path = out_dir / f"vmware-tools-status-{stamp}.json"
    csv_path = out_dir / f"vmware-tools-status-{stamp}.csv"
    latest_json = out_dir / "vmware-tools-status-latest.json"
    latest_csv = out_dir / "vmware-tools-status-latest.csv"

    context = ssl._create_unverified_context()

    si = SmartConnect(host=server, user=username, pwd=password, sslContext=context)
    try:
        content = si.RetrieveContent()
        rows = []

        for vm in sorted(walk_vms(content), key=lambda x: x.name.lower()):
            runtime = safe_get(vm, "runtime")
            guest = safe_get(vm, "guest")
            summary = safe_get(vm, "summary")

            host_name = ""
            try:
                if runtime and runtime.host:
                    host_name = runtime.host.name
            except Exception:
                host_name = ""

            power_state = str(safe_get(runtime, "powerState", ""))

            tools_running = ""
            tools_version_status = ""
            tools_version_status2 = ""
            tools_version = ""
            guest_ops_ready = ""
            guest_state = ""
            guest_full_name = ""
            ip_address = ""

            if guest:
                tools_running = str(safe_get(guest, "toolsRunningStatus", ""))
                tools_version_status = str(safe_get(guest, "toolsVersionStatus", ""))
                tools_version_status2 = str(safe_get(guest, "toolsVersionStatus2", ""))
                tools_version = str(safe_get(guest, "toolsVersion", ""))
                guest_ops_ready = str(safe_get(guest, "guestOperationsReady", ""))
                guest_state = str(safe_get(guest, "guestState", ""))
                guest_full_name = str(safe_get(guest, "guestFullName", ""))
                ip_address = str(safe_get(guest, "ipAddress", ""))

            if power_state == "poweredOff":
                shutdown_readiness = "POWERED_OFF"
            elif tools_running == "guestToolsRunning":
                shutdown_readiness = "LIKELY_GUEST_SHUTDOWN_READY"
            elif tools_running:
                shutdown_readiness = "TOOLS_NOT_RUNNING_OR_UNKNOWN"
            else:
                shutdown_readiness = "NO_TOOLS_STATUS_REPORTED"

            rows.append({
                "name": vm.name,
                "power_state": power_state,
                "host_name": host_name,
                "tools_running_status": tools_running,
                "tools_version_status": tools_version_status,
                "tools_version_status2": tools_version_status2,
                "tools_version": tools_version,
                "guest_operations_ready": guest_ops_ready,
                "guest_state": guest_state,
                "guest_full_name": guest_full_name,
                "ip_address": ip_address,
                "shutdown_readiness": shutdown_readiness,
            })

        payload = {
            "generated_at": datetime.now().isoformat(timespec="seconds"),
            "source": "pyVmomi read-only vim.VirtualMachine.guest report",
            "vcenter": server,
            "vm_count": len(rows),
            "summary": {
                "powered_on": sum(1 for r in rows if r["power_state"] == "poweredOn"),
                "powered_off": sum(1 for r in rows if r["power_state"] == "poweredOff"),
                "guest_tools_running": sum(1 for r in rows if r["tools_running_status"] == "guestToolsRunning"),
                "guest_shutdown_ready": sum(1 for r in rows if r["shutdown_readiness"] == "LIKELY_GUEST_SHUTDOWN_READY"),
                "tools_not_running_or_unknown": sum(1 for r in rows if r["shutdown_readiness"] in ("TOOLS_NOT_RUNNING_OR_UNKNOWN", "NO_TOOLS_STATUS_REPORTED")),
            },
            "vms": rows,
        }

        json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        latest_json.write_text(json.dumps(payload, indent=2), encoding="utf-8")

        with csv_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else [
                "name", "power_state", "host_name", "tools_running_status",
                "tools_version_status", "tools_version_status2", "tools_version",
                "guest_operations_ready", "guest_state", "guest_full_name",
                "ip_address", "shutdown_readiness"
            ])
            writer.writeheader()
            writer.writerows(rows)

        latest_csv.write_text(csv_path.read_text(encoding="utf-8"), encoding="utf-8")

        if args.json_only:
            print(json.dumps(payload, indent=2))
        else:
            print(f"PASS: wrote {json_path}")
            print(f"PASS: wrote {csv_path}")
            print(f"vm_count={payload['vm_count']}")
            print(f"powered_on={payload['summary']['powered_on']}")
            print(f"guest_tools_running={payload['summary']['guest_tools_running']}")
            print(f"guest_shutdown_ready={payload['summary']['guest_shutdown_ready']}")
            print(f"tools_not_running_or_unknown={payload['summary']['tools_not_running_or_unknown']}")

    finally:
        Disconnect(si)


if __name__ == "__main__":
    main()
