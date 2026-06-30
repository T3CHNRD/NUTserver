# Copyright (c) 2026 T3CHNRD. All rights reserved.
from flask import send_file, Flask, render_template, request, jsonify
import json
import os
import subprocess
import tempfile
from pathlib import Path
import time

APP_ROOT = Path("/opt/nut-orchestrator-ui")
REGISTRY_PATH = APP_ROOT / "lib" / "config_registry.json"

app = Flask(__name__)


def load_registry():
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_config_by_id(config_id):
    registry = load_registry()
    for item in registry["editable_configs"]:
        if item["id"] == config_id:
            return item
    return None


def is_allowed_file(item):
    path = item["path"]
    basename = os.path.basename(path)

    blocked_patterns = load_registry().get("blocked_patterns", [])
    for pattern in blocked_patterns:
        if pattern in basename:
            return False

    allowed_extensions = item.get("allowed_extensions", [])
    return any(path.endswith(ext) for ext in allowed_extensions)


@app.route("/")
def index():
    registry = load_registry()
    editable_configs = registry.get("editable_configs", [])
    reference_configs = registry.get("reference_configs", [])
    return render_template(
        "index.html",
        editable_configs=editable_configs,
        reference_configs=reference_configs
    )



@app.route("/control-center")
def control_center():
    registry = load_registry()
    editable_configs = registry.get("editable_configs", [])
    reference_configs = registry.get("reference_configs", [])
    return render_template(
        "control-center.html",
        editable_configs=editable_configs,
        reference_configs=reference_configs
    )



@app.route("/control-center-restore-lab")
def control_center_restore_lab():
    return render_template("control-center-restore-lab.html")

@app.route("/healthz")
def healthz():
    return jsonify({"ok": True})


# =========================
# CONFIG READ (REFERENCE)
# =========================
@app.route("/api/config/<reference_id>/content-ref", methods=["GET"])
def get_reference_content(reference_id):
    registry = load_registry()
    ref_item = None

    for item in registry.get("reference_configs", []):
        if item["id"] == reference_id:
            ref_item = item
            break

    if not ref_item:
        return jsonify({"ok": False, "error": "Reference is not approved for viewing"}), 403

    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-read-reference", reference_id]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    if result.returncode != 0:
        return jsonify({
            "ok": False,
            "error": result.stderr or result.stdout or "Failed to read reference"
        }), 500

    return jsonify({
        "ok": True,
        "id": ref_item["id"],
        "name": ref_item["name"],
        "path": ref_item["path"],
        "type": ref_item["type"],
        "content": redact_secret_config_lines(result.stdout)
    })



# =========================
# CONFIG SECRET LINE REDACTION
# =========================
SECRET_KEY_MARKERS = ("PASS", "PASSWORD", "SECRET", "TOKEN", "HYPERVISOR_SSH_KEY", "PRIVATE_KEY", "CREDENTIAL")
SECRET_PLACEHOLDERS = {
    "[REDACTED]",
    "\"[REDACTED]\"",
    "'[REDACTED]'",
    "********",
    "\"********\"",
    "'********'",
}


def is_secret_config_line(line):
    line = str(line or "")
    if "=" not in line:
        return False
    key = line.split("=", 1)[0].strip().upper()
    return any(marker in key for marker in SECRET_KEY_MARKERS)


def redact_secret_config_lines(content):
    out = []
    source = str(content or "")
    for line in source.splitlines():
        if is_secret_config_line(line):
            key = line.split("=", 1)[0].strip()
            out.append(f'{key}="********"')
        else:
            out.append(line)
    return "\n".join(out) + ("\n" if source.endswith("\n") else "")


def preserve_existing_secret_config_lines(config_id, submitted_content):
    item = get_config_by_id(config_id)
    if not item:
        return submitted_content

    target_path = Path(item["path"])
    if not target_path.exists():
        return submitted_content

    existing = {}
    for line in target_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if is_secret_config_line(line) and "=" in line:
            key, value = line.split("=", 1)
            existing[key.strip()] = value

    out = []
    source = str(submitted_content or "")
    for line in source.splitlines():
        if is_secret_config_line(line) and "=" in line:
            key, value = line.split("=", 1)
            clean_key = key.strip()
            clean_value = value.strip()
            if clean_key in existing and clean_value in SECRET_PLACEHOLDERS:
                out.append(f"{clean_key}={existing[clean_key]}")
                continue
        out.append(line)

    return "\n".join(out) + ("\n" if source.endswith("\n") else "")

# =========================
# CONFIG READ (EDITABLE)
# =========================
@app.route("/api/config/<config_id>/content", methods=["GET"])
def get_config_content(config_id):
    item = get_config_by_id(config_id)

    if not item or not is_allowed_file(item):
        return jsonify({"ok": False, "error": "Config is not approved for viewing"}), 403

    if item.get("sensitive") is True:
        target_path = Path(item["path"])
        configured = target_path.exists() and target_path.stat().st_size > 0
        return jsonify({
            "ok": True,
            "id": item["id"],
            "name": item["name"],
            "path": item["path"],
            "type": item["type"],
            "sensitive": True,
            "password_configured": configured,
            "content": "********" if configured else ""
        })

    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-read-config", config_id]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    if result.returncode != 0:
        return jsonify({
            "ok": False,
            "error": result.stderr or result.stdout or "Failed to read config"
        }), 500

    return jsonify({
        "ok": True,
        "id": item["id"],
        "name": item["name"],
        "path": item["path"],
        "type": item["type"],
        "content": redact_secret_config_lines(result.stdout)
    })


# =========================
# CONFIG UPDATE
# =========================
@app.route("/api/config/<config_id>", methods=["POST"])
def update_config(config_id):
    item = get_config_by_id(config_id)

    if not item or not is_allowed_file(item):
        return jsonify({"ok": False, "error": "Config is not approved for editing"}), 403

    payload = request.get_json(force=True)
    content = payload.get("content", "")
    mode = payload.get("mode", "dry-run")

    if item.get("sensitive") is True and content.strip() == "********":
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": "Sensitive config was not changed because the masked placeholder was submitted. Replace ******** with the real new value before applying.",
            "returncode": 2
        }), 400

    content = preserve_existing_secret_config_lines(config_id, content)

    with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8") as tf:
        tf.write(content)
        staged = tf.name

    try:
        cmd = [
            "/usr/bin/sudo",
            "/usr/local/sbin/nut-ui-apply-config",
            config_id,
            staged,
            mode
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)

        return jsonify({
            "ok": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        })

    finally:
        try:
            os.unlink(staged)
        except FileNotFoundError:
            pass


# =========================
# TEST RUNNER
# =========================
@app.route("/api/test/<mode>", methods=["POST"])
def run_test(mode):
    if mode not in ("simulate", "real"):
        return jsonify({"ok": False, "error": "Invalid mode"}), 400

    if mode == "real":
        payload = request.get_json(silent=True) or {}
        supplied = payload.get("passphrase", "")

        hash_path = Path("/etc/nut/real-test-passphrase.sha256")
        if not hash_path.exists():
            return jsonify({
                "ok": False,
                "error": "Real Test passphrase hash is not configured"
            }), 500

        import hashlib
        expected_hash = hash_path.read_text(encoding="utf-8").strip()
        supplied_hash = hashlib.sha256(supplied.encode("utf-8")).hexdigest()

        if supplied_hash != expected_hash:
            return jsonify({
                "ok": False,
                "stdout": "",
                "stderr": "Real Test blocked: invalid passphrase",
                "output": "Real Test blocked: invalid passphrase",
                "returncode": 403
            }), 403

        phase = payload.get("phase", "phase1-lansweeper")
        allowed_phases = {
            "phase1-lansweeper",
            "phase2-power-restore-abort",
            "phase3-full",
        }

        if phase not in allowed_phases:
            return jsonify({
                "ok": False,
                "stdout": "",
                "stderr": f"Real Test blocked: invalid phase {phase}",
                "output": f"Real Test blocked: invalid phase {phase}",
                "returncode": 400
            }), 400

        cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-run-real-test-approved", phase]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
    else:
        cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-run-test", "simulate"]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    return jsonify({
        "ok": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })



# =========================
# BACKUP
# =========================
@app.route("/api/backup", methods=["POST"])
def backup_now():
    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-backup-now"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)

    return jsonify({
        "ok": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode
    })


# =========================
# RESTORE FROM GITHUB
# =========================
@app.route("/api/restore/branches", methods=["GET"])
def restore_branches():
    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-restore-github", "--list"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    branches = [
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip() and not line.startswith("Fetching ")
    ]

    return jsonify({
        "ok": result.returncode == 0,
        "branches": branches,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })


@app.route("/api/restore", methods=["POST"])
def restore_now():
    payload = request.get_json(silent=True) or {}
    branch = str(payload.get("branch") or "backup-sanitized-initial").strip()

    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-restore-github", branch]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)

    return jsonify({
        "ok": result.returncode == 0,
        "branch": branch,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })


@app.route("/api/restore/live-dry-run", methods=["POST"])
def restore_live_dry_run():
    payload = request.get_json(silent=True) or {}
    category = str(payload.get("category") or "all").strip()

    allowed = {
        "all",
        "ui",
        "nut-configs",
        "scripts",
        "vmware-hypervisor",
        "systemd",
    }

    if category not in allowed:
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Invalid restore dry-run category: {category}",
            "output": f"Invalid restore dry-run category: {category}",
            "returncode": 400,
        }), 400

    cmd = [
        "/usr/bin/sudo",
        "/usr/local/sbin/nut-ui-live-restore-dry-run",
        "dry-run",
        category,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    return jsonify({
        "ok": result.returncode == 0,
        "category": category,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })


RESTORE_TARGET_CATALOG = "/etc/nut/restore/restore-targets.json"


def load_restore_targets():
    targets = []

    # Built-in safe probe remains available even if the catalog is missing.
    targets.append({
        "id": "restore_test_probe",
        "name": "Safe test probe",
        "live_path": "/etc/nut/restore-live-test-probe.txt",
        "repo_source": "/opt/nut-admin/repo-template/etc/nut/restore-live-test-probe.txt",
        "repo_source_exists": True,
        "live_exists": True,
        "sensitive": False,
        "restore_enabled": True,
        "blocked_reason": "",
    })

    try:
        with open(RESTORE_TARGET_CATALOG, "r", encoding="utf-8") as f:
            data = json.load(f)
        for item in data.get("targets", []):
            if isinstance(item, dict) and item.get("id"):
                targets.append(item)
    except Exception:
        pass

    return targets


@app.route("/api/restore/targets", methods=["GET"])
def restore_targets():
    targets = load_restore_targets()

    safe_targets = []
    for item in targets:
        safe_targets.append({
            "id": item.get("id", ""),
            "name": item.get("name", item.get("id", "")),
            "live_path": item.get("live_path", ""),
            "repo_source_exists": bool(item.get("repo_source_exists", False)),
            "live_exists": bool(item.get("live_exists", False)),
            "sensitive": bool(item.get("sensitive", False)),
            "restore_enabled": bool(item.get("restore_enabled", False)),
            "blocked_reason": item.get("blocked_reason", ""),
        })

    return jsonify({
        "ok": True,
        "targets": safe_targets,
        "returncode": 0,
    })


@app.route("/api/restore/selected-file-live", methods=["POST"])
def restore_selected_file_live():
    payload = request.get_json(silent=True) or {}
    item_id = str(payload.get("item_id") or "").strip()
    confirmation = str(payload.get("confirmation") or "").strip()

    required_confirmation = "RESTORE SELECTED FILE"

    targets = load_restore_targets()
    target = next((item for item in targets if item.get("id") == item_id), None)

    if not target:
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Invalid selected restore item id: {item_id}",
            "output": f"Invalid selected restore item id: {item_id}",
            "returncode": 400,
        }), 400

    if bool(target.get("sensitive", False)):
        reason = target.get("blocked_reason") or "sensitive restore target is blocked"
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Selected restore item is blocked: {reason}",
            "output": f"Selected restore item is blocked: {reason}",
            "returncode": 403,
        }), 403

    if not bool(target.get("restore_enabled", False)):
        reason = target.get("blocked_reason") or "restore target is not enabled"
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Selected restore item is blocked: {reason}",
            "output": f"Selected restore item is blocked: {reason}",
            "returncode": 403,
        }), 403

    if not bool(target.get("repo_source_exists", False)):
        reason = target.get("blocked_reason") or "missing GitHub-backed repo source"
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Selected restore item is blocked: {reason}",
            "output": f"Selected restore item is blocked: {reason}",
            "returncode": 403,
        }), 403

    if confirmation != required_confirmation:
        return jsonify({
            "ok": False,
            "stdout": "",
            "stderr": f"Live selected-file restore requires exact confirmation phrase: {required_confirmation}",
            "output": f"Live selected-file restore requires exact confirmation phrase: {required_confirmation}",
            "returncode": 403,
        }), 403

    cmd = [
        "/usr/bin/sudo",
        "/usr/local/sbin/nut-ui-live-restore-selected",
        "live",
        item_id,
        confirmation,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    return jsonify({
        "ok": result.returncode == 0,
        "item_id": item_id,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })


# =========================
# POWER EVENTS (NEW)
# =========================
@app.route("/api/power-events", methods=["GET"])
def power_events():
    result = subprocess.run(
        ["/usr/bin/sudo", "/usr/local/sbin/nut-get-power-events-json"],
        capture_output=True,
        text=True,
        timeout=10,
    )

    return result.stdout, 200, {"Content-Type": "application/json"}


# =========================
# ROLLBACK
# =========================





@app.route("/api/power-events-table", methods=["GET"])
def power_events_table():
    import json
    import re

    def parse_line(raw_line):
        raw = str(raw_line).strip()
        timestamp = ""
        msg = raw

        m = re.match(r"^\[([^\]]+)\]\s*(.*)$", raw)
        if m:
            timestamp = m.group(1)
            msg = m.group(2)

        def qval(name):
            q = re.search(rf'{name}="([^"]*)"', msg)
            return q.group(1) if q else ""

        target = qval("target")
        action = qval("action")
        result = qval("result")

        mode = ""
        status = ""
        event = "event"
        summary = ""

        upper = msg.upper()

        if "SIMULATED" in upper or "DRY-RUN" in upper:
            mode = "SIMULATED / DRY-RUN"
        if "REAL TEST" in upper or "MODE: REAL" in upper:
            mode = "REAL"
        if "BLOCKED" in upper:
            mode = "BLOCKED"
            event = "shutdown blocked"
        if "RUNNING" in upper or "START" in upper:
            if not mode:
                mode = "RUNNING"

        if "PASS" in upper or "SUCCESS" in upper:
            status = "PASS"
        elif "FAIL" in upper or "ERROR" in upper:
            status = "FAIL"
        elif "WARN" in upper:
            status = "WARN"

        if "SUMMARY" in upper:
            event = "test summary"
            summary = msg
        elif "POWER RESTORE" in upper or "ONLINE" in upper or "UTILITY POWER RETURNS" in upper:
            event = "power restored"
        elif "POWER OUTAGE" in upper or "ON BATTERY" in upper or " ONBATT" in upper or " OB" in upper:
            event = "power outage"
        elif "BATTERY IS LOW" in upper or "LOW BATTERY" in upper or " LB" in upper:
            event = "UPS battery low / replacement check"
        elif "SHUTDOWN" in upper and ("TRIGGER" in upper or "START" in upper or "REQUEST" in upper):
            event = "shutdown triggered"
        elif "ABORT" in upper or "STOPPED" in upper or "CANCEL" in upper:
            event = "shutdown stopped"
        elif "REAL TEST REQUESTED" in upper:
            event = "real test requested"
        elif "SIMULATED TEST START" in upper:
            event = "simulated test started"
        elif "TARGET:" in upper and not target:
            target = msg.split("TARGET:", 1)[1].strip()
            event = "target"
        elif "ACTION:" in upper and not action:
            action = msg.split("ACTION:", 1)[1].strip()
            event = "action"
        elif "MODE:" in upper and not mode:
            mode = msg.split("MODE:", 1)[1].strip()
            event = "mode"

        if not result:
            result = msg

        return {
            "timestamp": timestamp,
            "event": event,
            "target": target,
            "mode": mode,
            "action": action,
            "status": status,
            "result": result,
            "summary": summary,
            "raw": raw,
        }

    try:
        result = subprocess.run(
            ["/usr/bin/sudo", "/usr/local/sbin/nut-get-power-events-json"],
            capture_output=True,
            text=True,
            timeout=30,
            check=True,
        )

        raw_events = json.loads(result.stdout or "[]")
        lines = []

        for item in raw_events[-300:]:
            if isinstance(item, dict):
                lines.append(item.get("line", ""))
            else:
                lines.append(str(item))

        return jsonify({"ok": True, "events": [parse_line(line) for line in lines]})
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc), "events": []}), 500

@app.route("/api/export-logs", methods=["GET"])
def export_logs():
    try:
        export_dir = "/var/log/nut-orchestrator-ui/exports"
        max_age_seconds = 300

        newest_archive = None
        newest_mtime = 0

        if os.path.isdir(export_dir):
            for name in os.listdir(export_dir):
                if not name.startswith("nut-full-log-export-") or not name.endswith(".tar.gz"):
                    continue
                candidate = os.path.join(export_dir, name)
                try:
                    st = os.stat(candidate)
                except OSError:
                    continue
                if not os.path.isfile(candidate):
                    continue
                if st.st_mtime > newest_mtime:
                    newest_archive = candidate
                    newest_mtime = st.st_mtime

        now = time.time()
        if newest_archive and newest_mtime and (now - newest_mtime) <= max_age_seconds:
            archive_path = newest_archive
        else:
            result = subprocess.run(
                ["/usr/bin/sudo", "/usr/local/sbin/nut-export-test-logs"],
                capture_output=True,
                text=True,
                timeout=120,
                check=True,
            )
            archive_path = result.stdout.strip().splitlines()[-1]

        return send_file(
            archive_path,
            as_attachment=True,
            download_name=os.path.basename(archive_path),
            mimetype="application/gzip",
            max_age=0,
        )
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc)}), 500


@app.route("/api/rollback/<config_id>", methods=["POST"])
def rollback(config_id):
    item = get_config_by_id(config_id)

    if not item or not is_allowed_file(item):
        return jsonify({"ok": False, "error": "Config is not approved for rollback"}), 403

    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-rollback", config_id]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)

    return jsonify({
        "ok": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode
    })




@app.post("/api/production-mode")
def api_production_mode():
    """Set NUT production mode from Control Center.

    User-facing modes:
    - protecting -> /usr/local/sbin/nut-production-mode protecting
    - standby    -> /usr/local/sbin/nut-production-mode standby
    - off        -> /usr/local/sbin/nut-production-mode off

    This API does not directly send shutdown, poweroff, reboot,
    maintenance-mode, or VM power commands.
    """
    data = request.get_json(silent=True) or {}
    requested_mode = str(data.get("mode", "")).strip().lower()

    allowed_map = {
        "protecting": "protecting",
        "protect": "protecting",
        "armed": "protecting",
        "arm": "protecting",

        "standby": "standby",
        "standby_for_maintenance": "standby",
        "standby-for-maintenance": "standby",
        "maintenance": "standby",
        "disarmed": "standby",
        "disarm": "standby",

        "off": "off",
    }

    command_mode = allowed_map.get(requested_mode)
    if not command_mode:
        return jsonify({
            "ok": False,
            "error": "Invalid production mode request.",
            "requested_mode": requested_mode,
        }), 400

    proc = subprocess.run(
        ["/usr/bin/sudo", "/usr/local/sbin/nut-production-mode", command_mode],
        text=True,
        capture_output=True,
        timeout=30,
    )

    status_proc = subprocess.run(
        ["/usr/bin/sudo", "/usr/local/sbin/nut-production-status"],
        text=True,
        capture_output=True,
        timeout=30,
    )

    return jsonify({
        "ok": proc.returncode == 0,
        "requested_mode": requested_mode,
        "command_mode": command_mode,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "status_stdout": status_proc.stdout,
        "status_stderr": status_proc.stderr,
    }), (200 if proc.returncode == 0 else 409)


@app.post("/api/ups-locator-identify")
@app.post("/api/ups-locator-beep")
def api_ups_locator_identify():
    """Run a safe read-only Find UPS identify/status action.

    This API only permits known UPS names and fixed short pulse values.
    It calls /usr/local/sbin/nut-ups-locator-beep.sh directly because the script is read-only.
    It does not send shutdown, reboot, poweroff, outlet, battery-test,
    maintenance-mode, or VM power commands.
    """
    data = request.get_json(silent=True) or {}

    ups_name = str(data.get("ups", "")).strip().lower()

    allowed_ups = {"ups1", "ups2", "ups3", "ups4", "ups5", "ups6", "ups7", "ups8", "ups9"}
    if ups_name not in allowed_ups:
        return jsonify({
            "ok": False,
            "error": "Find UPS is available for ups1 through ups9.",
            "requested_ups": ups_name,
        }), 400

    # Keep this fixed and short from the web UI.
    pulse_count = "3"
    pulse_on_seconds = "1"
    pulse_off_seconds = "1"

    cmd = [
        "/usr/local/sbin/nut-ups-locator-beep.sh",
        ups_name,
        pulse_count,
        pulse_on_seconds,
        pulse_off_seconds,
    ]

    proc = subprocess.run(
        cmd,
        text=True,
        capture_output=True,
        timeout=30,
    )

    return jsonify({
        "ok": proc.returncode == 0,
        "action": "find-ups",
        "ups": ups_name,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }), (200 if proc.returncode == 0 else 409)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5080)
