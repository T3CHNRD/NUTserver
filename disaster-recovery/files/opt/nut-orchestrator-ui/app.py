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


@app.route("/api/maintenance-status", methods=["GET"])
def maintenance_status_api():
    """
    Return the current UPS-maintenance risk classification using the
    existing Daily UPS Health Report logic.

    Only these report sections are evaluated:
      - Weather / grid risk summary
      - Reasons / risk checks

    Priority:
      BLOCKER > CAUTION > CLEAR

    This endpoint performs a report preview only. It does not send email,
    change NUT mode, or execute protection actions.
    """
    try:
        result = subprocess.run(
            [
                "/usr/local/sbin/nut-email-alert-test-send",
                "--preview",
                "weekly",
            ],
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )

        if result.returncode != 0:
            return jsonify({
                "ok": False,
                "status": "caution",
                "status_label": "CAUTION",
                "reasons": [
                    "Health-report risk evaluation could not be completed."
                ],
            }), 200

        target_sections = {
            "Weather / grid risk summary:",
            "Reasons / risk checks:",
        }

        blockers = []
        cautions = []
        current_section = None

        for raw_line in result.stdout.splitlines():
            line = raw_line.strip()

            if line in target_sections:
                current_section = line
                continue

            # A new report heading ends the currently captured section.
            if (
                current_section is not None
                and line
                and line.endswith(":")
                and line not in target_sections
            ):
                current_section = None
                continue

            if current_section is None:
                continue

            if line.startswith("- BLOCKER:"):
                reason = line[len("- BLOCKER:"):].strip()
                if reason and reason not in blockers:
                    blockers.append(reason)

            elif line.startswith("- CAUTION:"):
                reason = line[len("- CAUTION:"):].strip()
                if reason and reason not in cautions:
                    cautions.append(reason)

        if blockers:
            status = "blocker"
            label = "BLOCKER"
            reasons = blockers + cautions

        elif cautions:
            status = "caution"
            label = "CAUTION"
            reasons = cautions

        else:
            status = "clear"
            label = "CLEAR"
            reasons = [
                "No maintenance blockers or cautions were reported."
            ]

        return jsonify({
            "ok": True,
            "status": status,
            "status_label": label,
            "blockers": blockers,
            "cautions": cautions,
            "reasons": reasons,
        })

    except Exception as exc:
        return jsonify({
            "ok": False,
            "status": "caution",
            "status_label": "CAUTION",
            "reasons": [
                "Maintenance risk status could not be evaluated."
            ],
            "error": str(exc),
        }), 200



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
SECRET_KEY_MARKERS = [REDACTED]
SECRET_PLACEHOLDERS = [REDACTED]
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


def get_current_protection_mode():
    """
    Return the current NUT protection mode from nut-production-status.

    Expected mode values:
    - armed     = PROTECTING
    - disarmed  = STANDBY FOR MAINTENANCE
    - off       = OFF
    """
    try:
        result = subprocess.run(
            ["/usr/bin/sudo", "/usr/local/sbin/nut-production-status"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            return ""
        data = json.loads(result.stdout or "{}")
        return str(data.get("mode", "")).strip().lower()
    except Exception:
        return ""


def block_if_protecting(action_name):
    """
    Block maintenance/config/test/restore actions while NUT is actively protecting.

    PROTECTING mode is for live outage protection only. Maintenance changes must be
    made from STANDBY FOR MAINTENANCE or OFF.
    """
    current_mode = get_current_protection_mode()
    normalized_action = str(action_name or "").strip().lower()

    # Creating a backup is safe in every mode. Backup does not change
    # monitoring, configuration, restore state, tests, or live actions.
    if normalized_action == "backup":
        return None

    if current_mode == "armed":
        return jsonify({
            "ok": False,
            "blocked": True,
            "mode": "PROTECTING",
            "action": action_name,
            "error": (
                "Blocked: NUT is in PROTECTING mode. "
                "Switch to STANDBY FOR MAINTENANCE before making UI, config, test, backup, or restore changes."
            ),
            "returncode": 423,
        }), 423
    return None



# BEGIN_PASSWORD_MASKING_OVERRIDE_20260707
# Centralized masking override for editable config files.
# Any password-like key must never be returned to the browser in clear text.

SECRET_KEYWORDS = [REDACTED]
    "PASSWORD",
    "PASS",
    "SECRET",
    "TOKEN",
    "API_KEY",
    "PRIVATE_KEY",
    "ACCESS_KEY",
)


def is_secret_config_line(line):
    raw = str(line or "")
    stripped = raw.strip()

    if not stripped or stripped.startswith("#") or "=" not in stripped:
        return False

    key = stripped.split("=", 1)[0].strip().upper()
    return any(keyword in key for keyword in SECRET_KEYWORDS)


def redact_secret_config_lines(content):
    out = []
    source = str(content or "")

    for line in source.splitlines():
        if is_secret_config_line(line) and "=" in line:
            key = line.split("=", 1)[0].strip()
            out.append(f"{key}=********")
        else:
            out.append(line)

    return chr(10).join(out) + (chr(10) if source.endswith(chr(10)) else "")


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
            clean_value = value.strip().strip('"').strip("'")

            if clean_key in existing and clean_value in SECRET_PLACEHOLDERS:
                out.append(f"{clean_key}={existing[clean_key]}")
                continue

        out.append(line)

    return chr(10).join(out) + (chr(10) if source.endswith(chr(10)) else "")

# END_PASSWORD_MASKING_OVERRIDE_20260707

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
            "password_configured": [REDACTED],
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
    blocked = block_if_protecting("config update")
    if blocked:
        return blocked

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

# =========================
# NOTIFICATION RECIPIENT MANAGEMENT
# =========================

EMAIL_ALERTS_CONF = Path(
    "/etc/nut/nut-email-alerts.conf"
)

TELEGRAM_ACCESS_DB = Path(
    "/var/lib/nut-telegram-alerts/access.json"
)


def _parse_shell_config(path):
    import shlex

    data = {}

    for raw in path.read_text(
        encoding="utf-8"
    ).splitlines():

        line = raw.strip()

        if (
            not line
            or line.startswith("#")
            or "=" not in line
        ):
            continue

        key, value = line.split(
            "=",
            1
        )

        key = key.strip()
        value = value.strip()

        try:
            parsed = shlex.split(
                value
            )

            value = (
                parsed[0]
                if parsed
                else ""
            )

        except Exception:
            value = value.strip(
                '"'
            ).strip(
                "'"
            )

        data[key] = value

    return data


def _email_recipients():
    if not EMAIL_ALERTS_CONF.exists():
        return []

    data = _parse_shell_config(
        EMAIL_ALERTS_CONF
    )

    raw = data.get(
        "EMAIL_RECIPIENTS",
        ""
    )

    seen = set()
    result = []

    for item in raw.split(","):
        address = item.strip()

        if not address:
            continue

        lowered = address.lower()

        if lowered in seen:
            continue

        seen.add(lowered)
        result.append(address)

    return result


def _valid_email(address):
    import re

    return bool(
        re.fullmatch(
            r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+"
            r"@"
            r"[A-Za-z0-9-]+"
            r"(?:\.[A-Za-z0-9-]+)+",
            address
        )
    )


def _write_email_recipients(recipients):
    import os
    import tempfile

    source = EMAIL_ALERTS_CONF.read_text(
        encoding="utf-8"
    )

    replacement = (
        'EMAIL_RECIPIENTS="'
        + ",".join(recipients)
        + '"'
    )

    lines = source.splitlines()
    output = []
    replaced = False

    for line in lines:
        if line.strip().startswith(
            "EMAIL_RECIPIENTS="
        ):
            output.append(
                replacement
            )
            replaced = True
        else:
            output.append(line)

    if not replaced:
        output.append(
            replacement
        )

    new_text = (
        "\n".join(output)
        + "\n"
    )

    stat = os.stat(
        EMAIL_ALERTS_CONF
    )

    fd, tmp = tempfile.mkstemp(
        prefix=".nut-email-alerts-",
        dir=str(
            EMAIL_ALERTS_CONF.parent
        ),
        text=True,
    )

    try:
        with os.fdopen(
            fd,
            "w",
            encoding="utf-8"
        ) as handle:
            handle.write(
                new_text
            )

        os.chmod(
            tmp,
            stat.st_mode & 0o777
        )

        try:
            os.chown(
                tmp,
                stat.st_uid,
                stat.st_gid
            )
        except PermissionError:
            pass

        os.replace(
            tmp,
            EMAIL_ALERTS_CONF
        )

    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def _telegram_recipient_view():
    """
    Return dashboard-safe Telegram recipient data.

    Raw chat IDs are intentionally not exposed by this API.
    """

    import json

    result = {
        "approved": [],
        "pending": [],
        "primary_admin_configured": False,
    }

    if not TELEGRAM_ACCESS_DB.exists():
        return result

    try:
        data = json.loads(
            TELEGRAM_ACCESS_DB.read_text(
                encoding="utf-8"
            )
        )

    except Exception:
        return result

    def safe_name(record):
        if not isinstance(
            record,
            dict
        ):
            return "Telegram User"

        for key in (
            "display_name",
            "name",
            "username",
            "first_name"
        ):
            value = record.get(
                key
            )

            if value:
                return str(value)

        return "Telegram User"

    # Support the existing access database without exposing
    # its private numeric identifiers. We intentionally make
    # this view tolerant of dict- or list-shaped stores.

    approved_candidates = []

    for key in (
        "approved",
        "users",
        "authorized"
    ):
        value = data.get(
            key
        ) if isinstance(data, dict) else None

        if isinstance(
            value,
            dict
        ):
            approved_candidates.extend(
                value.values()
            )

        elif isinstance(
            value,
            list
        ):
            approved_candidates.extend(
                value
            )

    pending_candidates = []

    if isinstance(
        data,
        dict
    ):
        value = data.get(
            "pending"
        )

        if isinstance(
            value,
            dict
        ):
            pending_candidates.extend(
                value.values()
            )

        elif isinstance(
            value,
            list
        ):
            pending_candidates.extend(
                value
            )

        primary = (
            data.get("primary_admin")
            or data.get("primary")
            or data.get("owner")
        )

        result[
            "primary_admin_configured"
        ] = bool(primary)

    for item in approved_candidates:
        if not isinstance(
            item,
            dict
        ):
            continue

        role = str(
            item.get(
                "role",
                "USER"
            )
        ).upper()

        result[
            "approved"
        ].append({
            "name":
                safe_name(item),
            "role":
                role,
            "primary":
                role in {
                    "PRIMARY",
                    "PRIMARY ADMIN",
                    "PRIMARY_ADMIN"
                }
        })

    for item in pending_candidates:
        if not isinstance(
            item,
            dict
        ):
            continue

        result[
            "pending"
        ].append({
            "name":
                safe_name(item)
        })

    return result


@app.route(
    "/api/notification-recipients",
    methods=["GET"]
)
def notification_recipients():
    import json
    import subprocess

    cmd = [
        "sudo",
        "-n",
        "/usr/local/sbin/nut-notification-recipients",
        "list",
    ]

    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=15,
    )

    if proc.returncode != 0:
        return jsonify({
            "ok": False,
            "error":
                "Unable to read notification recipients"
        }), 500

    try:
        data = json.loads(proc.stdout)

    except Exception:
        return jsonify({
            "ok": False,
            "error":
                "Recipient helper returned invalid data"
        }), 500

    return jsonify(data)


@app.route(
    "/api/notification-recipients/email",
    methods=["POST"]
)
def notification_email_recipient_change():
    import json
    import subprocess

    payload = request.get_json(
        silent=True
    ) or {}

    action = str(
        payload.get(
            "action",
            ""
        )
    ).strip().lower()

    address = str(
        payload.get(
            "email",
            ""
        )
    ).strip()

    if action == "add":
        helper_action = "email-add"

    elif action == "remove":
        helper_action = "email-remove"

    else:
        return jsonify({
            "ok": False,
            "error":
                "action must be add or remove"
        }), 400

    if not address:
        return jsonify({
            "ok": False,
            "error":
                "email address is required"
        }), 400

    cmd = [
        "sudo",
        "-n",
        "/usr/local/sbin/nut-notification-recipients",
        helper_action,
        address,
    ]

    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=15,
    )

    try:
        data = json.loads(
            proc.stdout
        )

    except Exception:
        return jsonify({
            "ok": False,
            "error":
                "Recipient helper returned invalid data"
        }), 500

    if proc.returncode != 0:
        status = 400

        if proc.returncode == 4:
            status = 409

        elif proc.returncode == 3:
            status = 404

        return jsonify(data), status

    return jsonify(data)



@app.route(
    "/api/notification-recipients/telegram",
    methods=["POST"]
)
def notification_telegram_recipient_change():
    import json
    import subprocess

    payload = request.get_json(
        silent=True
    ) or {}

    action = str(
        payload.get(
            "action",
            ""
        )
    ).strip().lower()

    name = str(
        payload.get(
            "name",
            ""
        )
    ).strip()

    if action == "approve":
        helper_action = (
            "telegram-approve"
        )

    elif action == "remove":
        helper_action = (
            "telegram-remove"
        )

    else:
        return jsonify({
            "ok": False,
            "error":
                "action must be approve or remove"
        }), 400

    if not name:
        return jsonify({
            "ok": False,
            "error":
                "Telegram recipient name is required"
        }), 400

    cmd = [
        "sudo",
        "-n",
        "/usr/local/sbin/nut-notification-recipients",
        helper_action,
        name,
    ]

    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=15,
    )

    try:
        data = json.loads(
            proc.stdout
        )

    except Exception:
        return jsonify({
            "ok": False,
            "error":
                "Recipient helper returned invalid data"
        }), 500

    if proc.returncode != 0:
        status = 400

        if proc.returncode == 4:
            status = 404

        elif proc.returncode == 5:
            status = 409

        elif proc.returncode == 6:
            status = 409

        return jsonify(data), status

    return jsonify(data)



@app.route(
    "/api/notification-controls",
    methods=["GET", "POST"]
)
def notification_controls_api():
    import json
    import subprocess

    helper = (
        "/usr/local/sbin/"
        "nut-notification-controls"
    )

    if request.method == "GET":
        cmd = [
            "sudo",
            "-n",
            helper,
            "list",
        ]

    else:
        payload = request.get_json(
            silent=True
        ) or {}

        key = str(
            payload.get(
                "key",
                ""
            )
        ).strip()

        value = payload.get(
            "value"
        )

        if not key:
            return jsonify({
                "ok": False,
                "error":
                    "control key is required"
            }), 400

        if not isinstance(
            value,
            bool
        ):
            return jsonify({
                "ok": False,
                "error":
                    "control value must be true or false"
            }), 400

        cmd = [
            "sudo",
            "-n",
            helper,
            "set",
            key,
            (
                "true"
                if value
                else "false"
            ),
        ]

    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=15,
    )

    try:
        data = json.loads(
            proc.stdout
        )

    except Exception:
        return jsonify({
            "ok": False,
            "error":
                "Notification helper returned invalid data"
        }), 500

    if proc.returncode != 0:
        return jsonify(data), 400

    return jsonify(data)


@app.route("/api/test/<mode>", methods=["POST"])
def run_test(mode):
    blocked = block_if_protecting("test run")
    if blocked:
        return blocked

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
    blocked = block_if_protecting("backup")
    if blocked:
        return blocked

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
    blocked = block_if_protecting("restore from github")
    if blocked:
        return blocked

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
    blocked = block_if_protecting("live restore dry run")
    if blocked:
        return blocked

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
    blocked = block_if_protecting("selected file live restore")
    if blocked:
        return blocked

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
# FULL MANAGED-SYSTEM RESTORE
# =========================

@app.route("/api/restore/full-status", methods=["GET"])
def restore_full_status():
    branch = str(
        request.args.get("branch")
        or "backup-sanitized-initial"
    ).strip()

    cmd = [
        "/usr/bin/sudo",
        "/usr/local/sbin/nut-ui-restore-status",
        branch,
    ]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=120,
    )

    if result.returncode != 0:
        return jsonify({
            "ok": False,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "output": result.stdout + result.stderr,
            "returncode": result.returncode,
        }), 500

    try:
        payload = json.loads(result.stdout)
    except Exception:
        return jsonify({
            "ok": False,
            "error": "Restore status helper returned invalid JSON",
            "output": result.stdout + result.stderr,
            "returncode": 500,
        }), 500

    payload["ok"] = True
    return jsonify(payload)


@app.route(
    "/api/restore/full-job/<job_id>",
    methods=["GET"]
)
def restore_full_job(job_id):
    import re

    if not re.fullmatch(
        r"[0-9]{8}-[0-9]{6}-[0-9]+",
        str(job_id or ""),
    ):
        return jsonify({
            "ok": False,
            "error": "Invalid restore job id",
            "returncode": 400,
        }), 400

    status_file = Path(
        "/var/lib/nut-orchestrator-ui/"
        f"restore-jobs/{job_id}.json"
    )

    if not status_file.is_file():
        return jsonify({
            "ok": False,
            "error": "Restore job status not found",
            "returncode": 404,
        }), 404

    try:
        data = json.loads(status_file.read_text())
    except Exception as exc:
        return jsonify({
            "ok": False,
            "error": f"Invalid restore job status: {exc}",
            "returncode": 500,
        }), 500

    data["ok"] = True
    return jsonify(data)



@app.route(
    "/api/restore/full-preflight",
    methods=["POST"]
)
def restore_full_preflight():
    payload = request.get_json(silent=True) or {}

    branch = str(
        payload.get("branch")
        or "backup-sanitized-initial"
    ).strip()

    cmd = [
        "/usr/bin/sudo",
        "/usr/local/sbin/nut-ui-full-managed-restore-preflight",
        branch,
    ]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=300,
    )

    return jsonify({
        "ok": result.returncode == 0,
        "branch": branch,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode,
        "live_restore_performed": False,
    })


@app.route(
    "/api/restore/full-live",
    methods=["POST"]
)
def restore_full_live():
    blocked = block_if_protecting(
        "full managed-system live restore"
    )

    if blocked:
        return blocked

    payload = request.get_json(silent=True) or {}

    branch = str(
        payload.get("branch")
        or "backup-sanitized-initial"
    ).strip()

    confirmation = str(
        payload.get("confirmation") or ""
    ).strip()

    required = "RESTORE FULL MANAGED SYSTEM"

    if confirmation != required:
        return jsonify({
            "ok": False,
            "error": (
                "Full managed-system restore requires "
                f"exact confirmation phrase: {required}"
            ),
            "returncode": 403,
        }), 403

    helper = Path(
        "/usr/local/sbin/"
        "nut-ui-full-managed-restore-live"
    )

    if not helper.is_file():
        return jsonify({
            "ok": False,
            "error": (
                "Full managed-system restore engine "
                "is not installed."
            ),
            "returncode": 503,
        }), 503

    result = subprocess.run(
        [
            "/usr/bin/sudo",
            str(helper),
            branch,
            confirmation,
        ],
        capture_output=True,
        text=True,
        timeout=900,
    )

    job_id = ""

    for line in result.stdout.splitlines():
        if line.startswith("job_id="):
            job_id = line.split("=", 1)[1].strip()
            break

    return jsonify({
        "ok": result.returncode == 0,
        "accepted": (
            result.returncode == 0
            and bool(job_id)
        ),
        "job_id": job_id,
        "branch": branch,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "output": result.stdout + result.stderr,
        "returncode": result.returncode,
    })



# =========================
# POWER EVENTS (NEW)
# =========================

HELP_DIR = Path("/opt/nut-orchestrator-ui/docs/help")

@app.route("/api/help/articles", methods=["GET"])
def help_articles():
    articles = []
    if HELP_DIR.is_dir():
        for path in sorted(HELP_DIR.glob("*.md")):
            articles.append({
                "file": path.name,
                "title": path.stem.replace("_", " ").title()
            })
    return jsonify({"ok": True, "articles": articles})


@app.route("/api/help/search", methods=["GET"])
def api_help_search():
    from flask import request
    import re

    def norm(s):
        s=(s or "").lower()
        s=s.replace("dbo1","db01").replace("dbo2","db02")
        s=re.sub(r"\bup\s+date\b","update",s)
        s=re.sub(r"\bcome\s+from\b","source",s)
        return s

    q=norm(request.args.get("q") or "")

    stop={
        "how","to","i","the","a","an","do","does","my",
        "is","are","in","on","for","of","can","what","where",
        "button","buttons","please"
    }

    aliases={
        "update":{"update","change","edit","modify","manage","add","remove"},
        "change":{"update","change","edit","modify","manage"},
        "edit":{"update","change","edit","modify","manage"},
        "recipient":{"recipient","recipients","address","addresses"},
        "recipients":{"recipient","recipients","address","addresses"},
        "email":{"email","emails"},
        "password":[REDACTED],
        "source":{"source","provider","origin"},
        "backup":{"backup","backups"},
        "restore":{"restore","recovery"},
    }

    words=[x for x in re.findall(r"[a-z0-9]+",q) if x not in stop]

    def terms(word):
        return aliases.get(word,{word})

    def concept_match(text,word):
        return any(t in text for t in terms(word))

    out=[]

    for f in sorted(HELP_DIR.glob("*.md")):
        body=f.read_text(errors="replace")
        hay=norm(f.name+" "+body)

        if not words or not all(concept_match(hay,w) for w in words):
            continue

        title=next(
            (x[2:].strip() for x in body.splitlines() if x.startswith("# ")),
            f.name
        )

        sections=re.split(r"(?m)(?=^#{2,6}\s+)",body)

        def secscore(sec):
            sn=norm(sec)
            head=next(
                (x for x in sec.splitlines() if re.match(r"^#{2,6}\s+",x)),
                ""
            )
            hn=norm(head)

            score=0

            # Natural-language intent boosts.
            # These only affect ranking; normal matching still returns
            # other relevant Help results.
            qn=q.strip()
            hn=norm(head)

            if qn in {
                "turn protection on",
                "enable protection",
                "enable shutdown protection",
                "arm nut"
            }:
                if "protecting mode" in hn and "put the nut server" in hn:
                    score+=500

            if qn in {
                "turn nut back on",
                "resume nut",
                "leave off mode",
                "restore monitoring"
            }:
                if "return from off to normal operation" in hn:
                    score+=500

            if qn in {
                "what should i check first",
                "start using dashboard",
                "how do i use nut"
            }:
                if "begin a normal nut control center operator session" in hn:
                    score+=500

            for w in words:
                ts=terms(w)

                if any(t in hn for t in ts):
                    score+=120

                hits=sum(sn.count(t) for t in ts)
                score+=min(hits,8)*4

                if any(t in norm(title+" "+f.name) for t in ts):
                    score+=20

            return score

        best=max(sections,key=secscore)

        anchor=next(
            (x.strip() for x in best.splitlines()
             if re.match(r"^#{2,6}\s+",x)),
            ""
        )

        section=re.sub(r"^#{2,6}\s+","",anchor).strip() or title

        ref=f.name.startswith("REF_")

        score=secscore(best)
        score+=(35 if not ref else -30)

        # Prefer the substantive Getting Started article over the index
        # for a direct getting-started search.
        if q.strip()=="getting started" and f.name=="01_GETTING_STARTED.md":
            score+=100

        if f.name=="00_HELP_INDEX.md":
            score-=140

        out.append({
            "file":f.name,
            "title":title,
            "type":"Reference Runbook" if ref else "Current How-To",
            "section":section,
            "anchor":anchor,
            "score":score
        })

    out.sort(key=lambda x:-x["score"])
    return jsonify({"ok":True,"query":q,"results":out[:8]})


@app.route("/api/help/article/<filename>", methods=["GET"])
def help_article(filename):
    if "/" in filename or "\\" in filename or not filename.endswith(".md"):
        return jsonify({"ok": False, "error": "Invalid help article name"}), 400

    path = HELP_DIR / filename

    try:
        resolved = path.resolve()
        help_root = HELP_DIR.resolve()
    except OSError:
        return jsonify({"ok": False, "error": "Unable to resolve help article"}), 500

    if resolved.parent != help_root:
        return jsonify({"ok": False, "error": "Invalid help article path"}), 400

    if not resolved.is_file():
        return jsonify({"ok": False, "error": "Help article not found"}), 404

    try:
        content = resolved.read_text(encoding="utf-8")
    except OSError:
        return jsonify({"ok": False, "error": "Unable to read help article"}), 500

    return jsonify({
        "ok": True,
        "file": resolved.name,
        "content": content
    })


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
    blocked = block_if_protecting("rollback")
    if blocked:
        return blocked

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
    blocked = block_if_protecting("ups locator")
    if blocked:
        return blocked

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
