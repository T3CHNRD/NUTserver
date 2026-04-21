const BASE = "/nut-ui";

const CONFIGS = {
  ups_conf: { id: "ups_conf", label: "ups.conf" },
  upsd_conf: { id: "upsd_conf", label: "upsd.conf" },
  upsmon_conf: { id: "upsmon_conf", label: "upsmon.conf" },
  upssched_conf: { id: "upssched_conf", label: "upssched.conf" },
  nut_conf: { id: "nut_conf", label: "nut.conf" },
  hosts_conf: { id: "hosts_conf", label: "hosts.conf" },
  live_nut_orchestrator_conf: { id: "live_nut_orchestrator_conf", label: "Live nut-orchestrator.conf" },
  nut_orchestrator_conf: { id: "nut_orchestrator_conf", label: "config.d nut-orchestrator.conf" },
  approved_targets_yml: { id: "approved_targets_yml", label: "approved-targets.yml" },
  dashboard_ui_json: { id: "dashboard_ui_json", label: "dashboard-ui.json" }
};

const REFERENCES = {
  inventory_json_ref: { id: "inventory_json_ref", path: "/opt/nut-auto/output/inventory.json" },
  ups_conf_generated_ref: { id: "ups_conf_generated_ref", path: "/opt/nut-auto/output/ups.conf.generated" },
  proxmox_placeholder_ref: { id: "proxmox_placeholder_ref", path: "/etc/nut/nut-orchestrator.conf.pre-proxmox-placeholder-20260416-150741" },
  ups_conf_backup_ref: { id: "ups_conf_backup_ref", path: "/etc/nut/ups.conf.backup" },
  ups_conf_working_2ups_ref: { id: "ups_conf_working_2ups_ref", path: "/etc/nut/ups.conf.working-2ups" },
  ups_conf_working_3ups_ref: { id: "ups_conf_working_3ups_ref", path: "/etc/nut/ups.conf.working-3ups" },
  upsmon_pre_orchestrator_ref: { id: "upsmon_pre_orchestrator_ref", path: "/etc/nut/upsmon.conf.pre-orchestrator" },
  upssched_pre_orchestrator_ref: { id: "upssched_pre_orchestrator_ref", path: "/etc/nut/upssched.conf.pre-orchestrator" }
};

const state = {
  currentId: "ups_conf",
  original: {}
};

function $(id) { return document.getElementById(id); }

function toast(message, type = "info") {
  const wrap = $("toast-wrap");
  const el = document.createElement("div");
  el.className = `nutui-toast ${type}`;
  el.textContent = message;
  wrap.appendChild(el);
  setTimeout(() => el.remove(), 4000);
}

function setTopStatus(text, loading = false) {
  $("top-status-text").textContent = text;
  $("top-spinner").classList.toggle("nutui-hidden", !loading);
}

function setMeta(data, statusText = "Ready") {
  $("meta-path").textContent = data.path || "-";
  $("meta-type").textContent = (data.type || "-").toUpperCase();
  $("meta-status").textContent = statusText;
  $("editor-title").textContent = data.name || "Config Editor";
  $("editor-subtitle").textContent = data.path || "Select a live config to load and edit its current server content.";
}

function setOutput(title, payload) {
  const text = typeof payload === "string" ? payload : JSON.stringify(payload, null, 2);
  $("action-output").textContent = `=== ${title} ===\n\n${text}`;
}

async function apiJson(url, options = {}) {
  const res = await fetch(url, options);
  const contentType = res.headers.get("content-type") || "";
  const data = contentType.includes("application/json") ? await res.json() : await res.text();
  if (!res.ok) throw new Error(typeof data === "string" ? data : JSON.stringify(data, null, 2));
  return data;
}

async function loadConfig(configId) {
  state.currentId = configId;
  setTopStatus(`Loading ${configId} from server...`, true);

  try {
    const data = await apiJson(`${BASE}/api/config/${configId}/content`);
    $("config-editor").value = data.content || "";
    state.original[configId] = data.content || "";
    setMeta(data, "Loaded");
    setTopStatus(`${data.name} loaded from server.`, false);
    setOutput("Load", { ok: true, id: data.id, path: data.path, type: data.type });
  } catch (err) {
    setMeta({ path: "-", type: "-", name: "Config Editor" }, "Load failed");
    setTopStatus(`Failed to load ${configId}.`, false);
    setOutput("Load Error", String(err));
    toast(`Load failed: ${configId}`, "error");
  }
}

async function loadReference(refId) {
  if (!refId) {
    $("reference-viewer").value = "";
    return;
  }

  setTopStatus(`Loading reference file ${refId}...`, true);
  try {
    const data = await apiJson(`${BASE}/api/config/${refId}/content-ref`);
    $("reference-viewer").value = data.content || "";
    setTopStatus(`${data.name} loaded as read-only reference.`, false);
    setOutput("Reference Load", { ok: true, id: data.id, path: data.path, type: data.type });
  } catch (err) {
    $("reference-viewer").value = "";
    setTopStatus(`Failed to load reference file ${refId}.`, false);
    setOutput("Reference Load Error", String(err));
    toast(`Reference load failed: ${refId}`, "error");
  }
}

async function validateCurrent() {
  const configId = state.currentId;
  setTopStatus(`Validating ${configId}...`, true);
  try {
    const data = await apiJson(`${BASE}/api/config/${configId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: $("config-editor").value, mode: "dry-run" })
    });
    $("meta-status").textContent = "Validation OK";
    setTopStatus(`${configId} validated successfully.`, false);
    setOutput("Validate", data);
    toast("Validation successful", "success");
  } catch (err) {
    $("meta-status").textContent = "Validation failed";
    setTopStatus(`Validation failed for ${configId}.`, false);
    setOutput("Validate Error", String(err));
    toast("Validation failed", "error");
  }
}

async function saveCurrent() {
  const configId = state.currentId;
  if (!confirm(`Apply changes to ${configId}?`)) return;

  setTopStatus(`Saving ${configId}...`, true);
  try {
    const data = await apiJson(`${BASE}/api/config/${configId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: $("config-editor").value, mode: "apply" })
    });
    state.original[configId] = $("config-editor").value;
    $("meta-status").textContent = "Saved";
    setTopStatus(`${configId} saved successfully.`, false);
    setOutput("Save", data);
    toast("Save successful", "success");
  } catch (err) {
    $("meta-status").textContent = "Save failed";
    setTopStatus(`Save failed for ${configId}.`, false);
    setOutput("Save Error", String(err));
    toast("Save failed", "error");
  }
}

function revertCurrent() {
  const configId = state.currentId;
  $("config-editor").value = state.original[configId] || "";
  $("meta-status").textContent = "Reverted";
  setTopStatus(`${configId} reverted to last loaded state.`, false);
  setOutput("Revert", `Reverted ${configId}`);
  toast("Reverted editor content", "info");
}

async function runServerBackup() {
  setTopStatus("Running server backup to GitHub...", true);
  try {
    const data = await apiJson(`${BASE}/api/backup`, { method: "POST" });
    setTopStatus("Server backup completed.", false);
    setOutput("Backup All to GitHub", data);
  } catch (err) {
    setTopStatus("Server backup failed.", false);
    setOutput("Backup Error", String(err));
    toast("Server backup failed", "error");
  }
}

async function runTest(mode) {
  const label = mode === "simulate" ? "Simulated Test" : "Real Test";
  setTopStatus(`Running ${label}...`, true);
  try {
    const data = await apiJson(`${BASE}/api/test/${mode}`, { method: "POST" });
    setTopStatus(`${label} completed.`, false);
    setOutput(label, data);
    if (data && data.ok) toast(`${label} completed`, "success");
    else toast(`${label} reported errors`, "error");
  } catch (err) {
    setTopStatus(`${label} failed.`, false);
    setOutput(`${label} Error`, String(err));
    toast(`${label} failed`, "error");
  }
}

function wireEvents() {
  $("config-select").addEventListener("change", async (e) => {
    await loadConfig(e.target.value);
  });

  $("reference-select").addEventListener("change", async (e) => {
    await loadReference(e.target.value);
  });

  $("btn-load").addEventListener("click", async () => {
    await loadConfig(state.currentId);
  });

  $("btn-validate").addEventListener("click", async () => {
    await validateCurrent();
  });

  $("btn-save").addEventListener("click", async () => {
    await saveCurrent();
  });

  $("btn-revert").addEventListener("click", () => {
    revertCurrent();
  });

  $("btn-sim-test").addEventListener("click", async () => {
    await runTest("simulate");
  });

  $("btn-real-test").addEventListener("click", async () => {
    await runTest("real");
  });

  $("btn-backup-github").addEventListener("click", async () => {
    await runServerBackup();
  });

  $("btn-restore-github").addEventListener("click", () => {
    setOutput("Restore from GitHub", "Restore from GitHub is not wired yet in this pass.");
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  wireEvents();
  $("config-select").value = state.currentId;
  await loadConfig(state.currentId);
});
