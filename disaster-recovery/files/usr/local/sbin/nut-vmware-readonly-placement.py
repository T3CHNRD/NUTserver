#!/usr/bin/env python3
# Copyright (c) 2026 T3CHNRD. All rights reserved.
import argparse
import json
import ssl
import sys
from pathlib import Path

# Compatibility shim for Ubuntu 24.04 Python 3.12 + apt pyVmomi 6.7.1.
if not hasattr(ssl, "wrap_socket"):
    def _compat_wrap_socket(sock, keyfile=None, certfile=None, server_side=False,
                            cert_reqs=ssl.CERT_NONE, ssl_version=ssl.PROTOCOL_TLS,
                            ca_certs=None, do_handshake_on_connect=True,
                            suppress_ragged_eofs=True, ciphers=None):
        context = ssl.SSLContext(ssl_version)
        context.check_hostname = False
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
            suppress_ragged_eofs=suppress_ragged_eofs,
        )

    ssl.wrap_socket = _compat_wrap_socket

from pyVim.connect import SmartConnect, Disconnect
from pyVmomi import vim


CONFIG_FILE = Path("/etc/nut/nut-orchestrator.conf")
PASS_FILE = [REDACTED]


def load_config():
    config = {}
    for line in CONFIG_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        config[key] = value.strip().strip('"')
    return config


def connect(config):
    server = config.get("VCENTER_SERVER", "")
    user = config.get("VCENTER_USERNAME", "")
    password = [REDACTED]

    if PASS_FILE.exists() and PASS_FILE.stat().st_size > 0:
        password = [REDACTED]

    if not server or not user or not password:
        raise SystemExit("ERROR missing VCENTER_SERVER, VCENTER_USERNAME, or VCENTER_PASSWORD")

    context = None
    if config.get("VCENTER_INSECURE", "1") == "1":
        context = ssl._create_unverified_context()

    return SmartConnect(host=server, user=user, pwd=password, sslContext=context)


def vm_record(vm):
    host = vm.runtime.host
    cluster = host.parent if host else None

    return {
        "name": vm.name,
        "vm_moref": vm._moId,
        "power_state": str(vm.runtime.powerState),
        "host_name": host.name if host else None,
        "host_moref": host._moId if host else None,
        "cluster_name": cluster.name if cluster else None,
    }


def main():
    parser = argparse.ArgumentParser(description="Read-only VMware VM placement inventory helper")
    parser.add_argument("--vm", help="Return placement for one VM by case-insensitive name")
    parser.add_argument("--all", action="store_true", help="Return placement for all VMs")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    if not args.vm and not args.all:
        parser.error("Use --vm NAME or --all")

    config = load_config()
    si = None

    try:
        si = connect(config)
        content = si.RetrieveContent()
        view = content.viewManager.CreateContainerView(
            content.rootFolder,
            [vim.VirtualMachine],
            True
        )

        records = []
        for vm in view.view:
            if args.all or vm.name.lower() == args.vm.lower():
                records.append(vm_record(vm))

        view.Destroy()

        if args.vm and not records:
            print(f"ERROR VM not found: {args.vm}", file=sys.stderr)
            return 2

        records.sort(key=lambda item: item["name"].lower())

        if args.json:
            print(json.dumps(records if args.all else records[0], indent=2, sort_keys=True))
        else:
            for item in records:
                print(
                    f'{item["name"]}|{item["vm_moref"]}|{item["power_state"]}|'
                    f'{item["host_name"]}|{item["host_moref"]}|{item["cluster_name"]}'
                )

        return 0

    finally:
        if si:
            Disconnect(si)


if __name__ == "__main__":
    sys.exit(main())
