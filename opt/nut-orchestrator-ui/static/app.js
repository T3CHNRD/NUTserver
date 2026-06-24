/* Copyright (c) 2026 T3CHNRD. All rights reserved. */
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

function normalizeActionOutputText(value) {
  if (value === null || value === undefined) return "";

  let text = typeof value === "string" ? value : JSON.stringify(value, null, 2);

  // Many backend responses arrive as JSON-escaped strings. Make them readable.
  text = text
    .replaceAll("\\r\\n", "\n")
    .replaceAll("\\n", "\n")
    .replaceAll("\\t", "  ");

  return text.trim();
}

function classifyActionOutput(text, payload) {
  const haystack = (text || "").toUpperCase();
  const rc = payload && typeof payload === "object" ? payload.returncode : undefined;

  if (rc !== undefined && Number(rc) !== 0) return "fail";
  if (haystack.includes("ERROR") || haystack.includes("FAILED") || haystack.includes("FATAL")) return "fail";
  if (haystack.includes("WARN") || haystack.includes("WARNING") || haystack.includes("BLOCKED")) return "warn";
  if ((payload && payload.ok === true) || haystack.includes(" PASS") || haystack.includes("SUCCESS")) return "pass";

  return "info";
}

function makeOutputSection(label, value) {
  const normalized = normalizeActionOutputText(value);
  if (!normalized) return "";

  return `
    <div class="nutui-output-section">
      <div class="nutui-output-section-title">${label}</div>
      <pre class="nutui-output-pre">${escapeHtml(normalized)}</pre>
    </div>
  `;
}

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function setOutput(title, payload) {
  const output = $("action-output");
  const isObject = payload && typeof payload === "object" && !Array.isArray(payload);

  let body = "";
  let combinedText = "";

  if (isObject) {
    const statusText = [
      payload.ok !== undefined ? `ok: ${payload.ok}` : "",
      payload.returncode !== undefined ? `returncode: ${payload.returncode}` : ""
    ].filter(Boolean).join(" | ");

    combinedText = [
      statusText,
      payload.stdout || "",
      payload.stderr || "",
      payload.output || ""
    ].join("\n");

    body += statusText
      ? `<div class="nutui-output-summary">${escapeHtml(statusText)}</div>`
      : "";

    body += makeOutputSection("Standard Output", payload.stdout || payload.output);
    body += makeOutputSection("Errors / Warnings", payload.stderr);

    const raw = JSON.stringify(payload, null, 2);
    body += `
      <details class="nutui-output-raw">
        <summary>Raw response</summary>
        <pre class="nutui-output-pre">${escapeHtml(normalizeActionOutputText(raw))}</pre>
      </details>
    `;
  } else {
    combinedText = normalizeActionOutputText(payload);
    body += makeOutputSection("Output", combinedText);
  }

  const classification = classifyActionOutput(combinedText, payload);

  output.classList.remove("nutui-output-pass", "nutui-output-warn", "nutui-output-fail", "nutui-output-info");
  output.classList.add(`nutui-output-${classification}`);

  output.innerHTML = `
    <div class="nutui-output-header">
      <span>${escapeHtml(title)}</span>
      <span class="nutui-output-badge">${classification.toUpperCase()}</span>
    </div>
    ${body || '<div class="nutui-output-empty">No output returned.</div>'}
  `;
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

  function promptRealTestPassphrase(phase) {
    return new Promise((resolve) => {
      const overlay = document.createElement("div");
      overlay.style.position = "fixed";
      overlay.style.inset = "0";
      overlay.style.background = "rgba(0,0,0,0.65)";
      overlay.style.zIndex = "9999";
      overlay.style.display = "flex";
      overlay.style.alignItems = "center";
      overlay.style.justifyContent = "center";

      const box = document.createElement("div");
      box.style.background = "#0b1220";
      box.style.color = "#ffffff";
      box.style.border = "1px solid #334155";
      box.style.borderRadius = "12px";
      box.style.padding = "20px";
      box.style.width = "min(520px, 92vw)";
      box.style.boxShadow = "0 20px 50px rgba(0,0,0,0.45)";

      const title = document.createElement("h2");
      title.textContent = "Real Test Warning";
      title.style.margin = "0 0 12px 0";

      const warning = document.createElement("p");
      warning.textContent = "Selected phase: " + phase + ". This may execute live shutdown commands. Enter the Real Test passphrase to continue.";
      warning.style.lineHeight = "1.45";

      const input = document.createElement("input");
      input.type = "password";
      input.autocomplete = "off";
      input.placeholder = "Real Test passphrase";
      input.style.width = "100%";
      input.style.boxSizing = "border-box";
      input.style.padding = "10px";
      input.style.margin = "12px 0";
      input.style.borderRadius = "8px";
      input.style.border = "1px solid #475569";
      input.style.background = "#020617";
      input.style.color = "#ffffff";

      const actions = document.createElement("div");
      actions.style.display = "flex";
      actions.style.gap = "10px";
      actions.style.justifyContent = "flex-end";

      const cancel = document.createElement("button");
      cancel.textContent = "Cancel";
      cancel.type = "button";

      const submit = document.createElement("button");
      submit.textContent = "Run Real Test";
      submit.type = "button";

      actions.appendChild(cancel);
      actions.appendChild(submit);

      box.appendChild(title);
      box.appendChild(warning);
      box.appendChild(input);
      box.appendChild(actions);
      overlay.appendChild(box);
      document.body.appendChild(overlay);

      const cleanup = (value) => {
        input.value = "";
        document.body.removeChild(overlay);
        resolve(value);
      };

      cancel.addEventListener("click", () => cleanup(""));
      submit.addEventListener("click", () => cleanup(input.value));

      input.addEventListener("keydown", (event) => {
        if (event.key === "Enter") cleanup(input.value);
        if (event.key === "Escape") cleanup("");
      });

      setTimeout(() => input.focus(), 0);
    });
  }

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

    const passphrase = await promptRealTestPassphrase(phase);

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




/* Power / Boot Event Log Panel - readable mirror of main dashboard source */
async function loadPowerBootEvents() {
  const targetId = "power-boot-event-log";
  let panel = document.getElementById(targetId);

  if (!panel) {
    const container = document.createElement("section");
    container.className = "nutui-card nutui-section nutui-power-log-card";

    const title = document.createElement("h2");
    title.textContent = "Power / Boot Event Log";
    title.className = "nutui-power-log-title";

    const note = document.createElement("div");
    note.textContent = "Readable view using the shared Dashboard/NUT UI power event feed: newest first, last 5 days only.";
    note.className = "nutui-power-log-note";

    const refresh = document.createElement("button");
    refresh.textContent = "Refresh Power / Boot Event Log";
    refresh.onclick = loadPowerBootEvents;
    refresh.className = "nutui-btn nutui-btn-secondary nutui-power-log-refresh";

    panel = document.createElement("div");
    panel.id = targetId;
    panel.className = "nutui-power-log-panel";

    container.appendChild(title);
    container.appendChild(note);
    container.appendChild(refresh);
    container.appendChild(panel);

    const main = document.querySelector(".nutui-main") || document.body;
    main.appendChild(container);
  }

  panel.textContent = "Loading Power / Boot Event Log...";

  try {
    const cacheBust = Date.now();
    const pageBase = window.location.pathname.endsWith("/")
      ? window.location.pathname
      : window.location.pathname.replace(/[^/]*$/, "");

    const candidates = [
      "/nut-power-events.json?v=" + cacheBust,
      "nut-power-events.json?v=" + cacheBust,
      pageBase + "nut-power-events.json?v=" + cacheBust,
      pageBase + "api/power-events?v=" + cacheBust,
      "api/power-events?v=" + cacheBust,
      "/api/power-events?v=" + cacheBust,
      "/nut-orchestrator-ui/api/power-events?v=" + cacheBust,
      "/orchestrator/api/power-events?v=" + cacheBust,
      "/nut/api/power-events?v=" + cacheBust
    ];

    let response = null;
    let lastStatus = "not attempted";

    for (const url of candidates) {
      try {
        const attempt = await fetch(url, { cache: "no-store" });
        lastStatus = `${url} -> HTTP ${attempt.status}`;
        if (attempt.ok) {
          response = attempt;
          break;
        }
      } catch (e) {
        lastStatus = `${url} -> ${e}`;
      }
    }

    if (!response) {
      throw new Error(`Power events API not reachable. Last attempt: ${lastStatus}`);
    }

    const data = await response.json();

    const rawLines = Array.isArray(data)
      ? data.map(item => {
          if (typeof item === "string") return item;
          return item.line || item.raw || "";
        })
      : [];

    const lines = rawLines.filter(line => String(line || "").trim() !== "").slice(-160);

    if (!lines.length) {
      panel.textContent = "No log entries found.";
      return;
    }

    const esc = (value) => String(value || "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;");

    function formatPowerEventResult(line) {
      const text = String(line || "");

      const upsMonitorMatch = text.match(/NUT_MONITOR_EVENT\s+.*UPS:\s+(ups[0-9]+)@localhost\s+\(primary\)\s+\(power value\s+([0-9]+)\)/i);
      if (upsMonitorMatch) {
        const upsName = upsMonitorMatch[1];
        const powerValue = upsMonitorMatch[2];
        return `UPS ${upsName} is being monitored by this NUT server. It counts as ${powerValue} UPS power source.`;
      }

      return text;
    }

    function parseLine(line) {
      const row = {
        timestamp: "",
        event: "",
        target: "",
        mode: "",
        action: "",
        status: "",
        result: formatPowerEventResult(line)
      };

      const ts = line.match(/^\[([^\]]+)\]\s*(.*)$/);
      let msg = line;
      if (ts) {
        row.timestamp = ts[1];
        msg = ts[2];
      }

      if (msg.startsWith("TARGET:")) {
        row.event = "Target";
        row.target = msg.replace("TARGET:", "").trim();
      } else if (msg.startsWith("MODE_CHANGE")) {
        row.event = "Mode change";
        row.mode = msg;
        row.status = "INFO";
      } else if (msg.startsWith("MODE:")) {
        row.event = "Mode";
        row.mode = msg.replace("MODE:", "").trim();
      } else if (msg.startsWith("ACTION:")) {
        row.event = "Action";
        row.action = msg.replace("ACTION:", "").trim();
      } else if (msg.includes("PASS")) {
        row.event = "Result";
        row.status = "PASS";
      } else if (msg.includes("FAIL") || msg.includes("ERROR")) {
        row.event = "Result";
        row.status = "FAIL";
      } else if (msg.includes("SUMMARY")) {
        row.event = "Summary";
      } else if (msg.toUpperCase().includes("REAL TEST BLOCKED")) {
        row.event = "Real test blocked";
        row.status = "FAIL";
      } else if (msg.toUpperCase().includes("POWER") || msg.toUpperCase().includes("BATTERY")) {
        row.event = "Power / battery event";
      } else {
        row.event = "Event";
      }

      return row;
    }

    const rows = lines.map(parseLine);

    panel.innerHTML = `
      <table style="width:100%; border-collapse:collapse; font-size:12px;">
        <thead>
          <tr>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Timestamp</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Event</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Target</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Mode</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Action</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">PASS / FAIL</th>
            <th style="border-bottom:1px solid #555; text-align:left; padding:5px;">Result text</th>
          </tr>
        </thead>
        <tbody>
          ${rows.map(row => `
            <tr>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.timestamp)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.event)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.target)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.mode)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.action)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.status)}</td>
              <td style="border-bottom:1px solid #222; padding:5px; vertical-align:top;">${esc(row.result)}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    panel.textContent = `ERROR loading Power / Boot Event Log: ${err}`;
  }
}

window.addEventListener("DOMContentLoaded", () => {
  loadPowerBootEvents();
  setInterval(loadPowerBootEvents, 900000);
});


/* Download All Logs button - added for NUT test evidence export */
function addDownloadAllLogsButton() {
  if (document.getElementById("btn-download-all-logs")) return;

  const btn = document.createElement("button");
  btn.id = "btn-download-all-logs";
  btn.textContent = "Download All Logs";
  btn.style.marginLeft = "0.5rem";
  btn.onclick = () => {
    window.location.href = `${BASE}/api/export-logs`;
  };

  const realBtn = document.getElementById("btn-real-test");
  if (realBtn && realBtn.parentNode) {
    realBtn.parentNode.insertBefore(btn, realBtn.nextSibling);
  } else {
    document.body.prepend(btn);
  }
}

window.addEventListener("DOMContentLoaded", () => {
  addDownloadAllLogsButton();
});
