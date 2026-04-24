from flask import Flask, render_template, request, jsonify
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

    content = result.stdout

    return jsonify({
        "ok": True,
        "id": item["id"],
        "name": item["name"],
        "path": item["path"],
        "type": item["type"],
        "content": content
    })

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
        cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-apply-config", config_id, staged, mode]
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

@app.route("/api/test/<mode>", methods=["POST"])
def run_test(mode):
    if mode not in ("simulate", "real"):
        return jsonify({"ok": False, "error": "Invalid mode"}), 400

    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-run-test", mode]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return jsonify({
        "ok": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode
    })

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


@app.route("/api/restore", methods=["POST"])
def restore_now():
    cmd = ["/usr/bin/sudo", "/usr/local/sbin/nut-ui-restore-github"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    return jsonify({
        "ok": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode
    })


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
