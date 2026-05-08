from flask import send_file, Flask, render_template, request, jsonify
import json
import os
import subprocess
import tempfile
from pathlib import Path

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
        "content": result.stdout
    })


# =========================
# CONFIG READ (EDITABLE)
# =========================
@app.route("/api/config/<config_id>/content", methods=["GET"])
def get_config_content(config_id):
    item = get_config_by_id(config_id)

    if not item or not is_allowed_file(item):
        return jsonify({"ok": False, "error": "Config is not approved for viewing"}), 403

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
        "content": result.stdout
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


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5080)
