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
  upssched_pre_orchestrator_ref: { id: "upssched_pre_orchestrator_ref", path: "/etc/nut/upssched.conf.pre-orchestrator" },
  nut_orchestrator_sh_ref: { id: "nut_orchestrator_sh_ref", path: "/usr/local/bin/nut-orchestrator.sh" }
};

const state = {
  currentId: "ups_conf",
  original: {}
};

function $(id) { return document.getElementById(id); }

function toast(message, type = "info") {
  // Toasts intentionally disabled to avoid upper-right flashing notifications.
  return;
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
  const btn = $("btn-backup-github");
  if (btn.dataset.running === "1") return;

  btn.dataset.running = "1";
  btn.disabled = true;
  setTopStatus("Running server backup to GitHub...", true);

  try {
    const data = await apiJson(`${BASE}/api/backup`, { method: "POST" });
    setTopStatus("Server backup completed.", false);
    setOutput("Backup All to GitHub", data);
  } catch (err) {
    setTopStatus("Server backup failed.", false);
    setOutput("Backup Error", String(err));
    toast("Server backup failed", "error");
  } finally {
    btn.dataset.running = "0";
    btn.disabled = false;
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
    const btn = $("btn-sim-test");
    if (btn.dataset.running === "1") return;

    btn.dataset.running = "1";
    setTopStatus("Running Simulated Test...", true);

    try {
      const data = await apiJson(`${BASE}/api/test/simulate`, { method: "POST" });

      setOutput(
        "Simulated Test",
        data.stdout || data.output || "No output returned."
      );

      if (data.ok) {
        setTopStatus("Simulated Test completed successfully.", false);
      } else {
        setTopStatus("Simulated Test failed.", false);
        toast("Simulated Test failed", "error");
      }
    } catch (err) {
      setOutput("Simulated Test", String(err));
      setTopStatus("Simulated Test failed.", false);
      toast("Simulated Test failed", "error");
    } finally {
      btn.dataset.running = "0";
    }
  });

  $("btn-real-test").addEventListener("click", async () => {
    const btn = $("btn-real-test");
    if (btn.dataset.running === "1") return;

    const phaseChoice = window.prompt(
      "REAL TEST PHASE SELECTION:\n\n" +
      "1 = Phase 1: Lansweeper only\n" +
      "2 = Phase 2: Power restore abort test\n" +
      "3 = Phase 3: Full shutdown\n\n" +
      "Enter 1, 2, or 3:"
    );

    const phaseMap = {
      "1": "phase1-lansweeper",
      "2": "phase2-power-restore-abort",
      "3": "phase3-full"
    };

    const phase = phaseMap[phaseChoice];

    if (!phase) {
      setOutput("Real Test", "Real Test cancelled. Invalid or missing phase selection.");
      setTopStatus("Real Test cancelled.", false);
      return;
    }

    const passphrase = window.prompt(
      "REAL TEST WARNING:\n\n" +
      "Selected phase: " + phase + "\n\n" +
      "This may execute live shutdown commands.\n" +
      "Enter the Real Test passphrase to continue:"
    );

    if (!passphrase) {
      setOutput("Real Test", "Real Test cancelled. No commands were run.");
      setTopStatus("Real Test cancelled.", false);
      return;
    }

    btn.dataset.running = "1";
    setTopStatus("Running Real Test " + phase + "...", true);

    try {
      const data = await apiJson(`${BASE}/api/test/real`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ passphrase, phase })
      });

      setOutput(
        "Real Test",
        data.output || data.stdout || data.stderr || "No output returned."
      );

      if (data.ok) {
        setTopStatus("Real Test completed successfully.", false);
      } else {
        setTopStatus("Real Test blocked or failed.", false);
        toast("Real Test blocked or failed", "error");
      }
    } catch (err) {
      setOutput("Real Test", String(err));
      setTopStatus("Real Test failed.", false);
      toast("Real Test failed", "error");
    } finally {
      btn.dataset.running = "0";
    }
  });

  $("btn-backup-github").addEventListener("click", async () => {
    await runServerBackup();
  });

  $("btn-restore-github").addEventListener("click", async () => {
    const btn = $("btn-restore-github");
    if (btn.dataset.running === "1") return;

    btn.dataset.running = "1";
    setTopStatus("Loading GitHub restore branches...", true);

    try {
      const branchData = await apiJson(`${BASE}/api/restore/branches`, { method: "GET" });

      if (!branchData.ok || !Array.isArray(branchData.branches) || branchData.branches.length === 0) {
        setOutput(
          "Restore from GitHub",
          branchData.output || "No restore branches were returned."
        );
        setTopStatus("Could not load restore branches.", false);
        toast("Could not load restore branches", "error");
        return;
      }

      const branchList = branchData.branches
        .map((branch, index) => `${index + 1}. ${branch}`)
        .join("\n");

      const selected = window.prompt(
        `Choose GitHub branch to restore from:\n\n${branchList}\n\nEnter a number or exact branch name. Leave blank to cancel:`,
        ""
      );

      if (selected === null) {
        setTopStatus("Restore cancelled.", false);
        return;
      }

      const trimmed = selected.trim();

      if (!trimmed) {
        setTopStatus("Restore cancelled.", false);
        return;
      }

      let branch = trimmed;

      if (/^[0-9]+$/.test(trimmed)) {
        const index = Number(trimmed) - 1;
        if (index < 0 || index >= branchData.branches.length) {
          setTopStatus("Invalid restore branch selection.", false);
          toast("Invalid branch selection", "error");
          return;
        }
        branch = branchData.branches[index];
      }

      const confirmed = window.confirm(
        `Restore local repo from GitHub branch:\n\n${branch}\n\nThis will back up the current repo state, fetch GitHub, and reset the local repo to origin/${branch}. Continue?`
      );

      if (!confirmed) {
        setTopStatus("Restore cancelled.", false);
        return;
      }

      setTopStatus(`Restoring from GitHub branch ${branch}...`, true);

      const data = await apiJson(`${BASE}/api/restore`, {
        method: "POST",
        body: JSON.stringify({ branch })
      });

      setOutput(
        "Restore from GitHub",
        data.output || `${data.stdout || ""}${data.stderr || ""}` || "No output returned."
      );

      if (data.ok) {
        setTopStatus(`Restore completed from ${branch}.`, false);
      } else {
        setTopStatus("Restore failed.", false);
        toast("Restore failed", "error");
      }
    } catch (err) {
      setOutput("Restore from GitHub", String(err));
      setTopStatus("Restore failed.", false);
      toast("Restore failed", "error");
    } finally {
      btn.dataset.running = "0";
    }
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  wireEvents();
  $("config-select").value = state.currentId;
  await loadConfig(state.currentId);
});

/* Power / Boot Event Log Panel - added for NUT real-test observability */
async function loadPowerBootEvents() {
  const targetId = "power-boot-event-log";
  let panel = document.getElementById(targetId);

  if (!panel) {
    const container = document.createElement("section");
    container.style.marginTop = "1rem";
    container.style.padding = "1rem";
    container.style.border = "1px solid #ccc";
    container.style.borderRadius = "8px";
    container.style.background = "#111";
    container.style.color = "#eee";

    const title = document.createElement("h2");
    title.textContent = "Power / Boot Event Log";
    title.style.marginTop = "0";

    const refresh = document.createElement("button");
    refresh.textContent = "Refresh Power / Boot Event Log";
    refresh.onclick = loadPowerBootEvents;
    refresh.style.marginBottom = "0.75rem";

    panel = document.createElement("pre");
    panel.id = targetId;
    panel.style.whiteSpace = "pre-wrap";
    panel.style.maxHeight = "360px";
    panel.style.overflow = "auto";
    panel.style.background = "#000";
    panel.style.color = "#0f0";
    panel.style.padding = "0.75rem";
    panel.style.borderRadius = "6px";

    container.appendChild(title);
    container.appendChild(refresh);
    container.appendChild(panel);
    document.body.appendChild(container);
  }

  panel.textContent = "Loading Power / Boot Event Log...";

  try {
    const response = await fetch("/api/power-events", { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const events = await response.json();
    const lines = events.map(item => item.line || JSON.stringify(item));
    panel.textContent = lines.slice(-250).join("\n") || "No power events found.";
  } catch (err) {
    panel.textContent = `ERROR loading Power / Boot Event Log: ${err}`;
  }
}

window.addEventListener("DOMContentLoaded", () => {
  loadPowerBootEvents();
  setInterval(loadPowerBootEvents, 30000);
});
