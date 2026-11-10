(function () {
  "use strict";

  const core = window.NutServerConnectionCore;
  const API_BASE = "/nut-ui";
  const root = document.getElementById("nut-server-connection-settings");
  if (!core || !root) return;

  const states = new Map();
  const cards = new WeakMap();

  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function render() {
    root.replaceChildren();
    const intro = element("p", "cc-section-subtitle",
      "Choose one managed server to show only its supported connection settings. Passwords are never shown; leave a password blank to keep it unchanged. Changes use the existing validation, backup, and access-control path.");
    root.append(intro);
    const label = element("label", "nut-connection-picker");
    label.htmlFor = "nut-managed-server-select";
    label.append(element("span", "cc-label", "Select Managed Server"));
    const select = document.createElement("select");
    select.id = "nut-managed-server-select";
    select.className = "cc-select";
    const placeholder = element("option", "", "Choose a managed server…");
    placeholder.value = "";
    select.append(placeholder);
    for (const server of core.MANAGED_SERVERS.filter(core.profileIsValid)) {
      const option = element("option", "", server.label);
      option.value = server.id;
      select.append(option);
    }
    label.append(select);
    root.append(label);
    const panel = element("div", "nut-connection-selected-panel");
    panel.id = "nut-connection-selected-panel";
    panel.setAttribute("aria-live", "polite");
    root.append(panel);
    const note = element("p", "cc-section-subtitle nut-connection-note",
      "Advanced Configuration remains available below for administrators. No verified connection-settings file is registered for VOIP, so no VOIP profile is offered.");
    root.append(note);
    select.addEventListener("change", () => renderProfile(select.value, panel));
  }

  function renderProfile(serverId, panel) {
    panel.replaceChildren();
    const server = core.serverById(serverId);
    if (!server) return;
    const title = element("div", "nut-connection-profile-heading");
    title.append(element("h3", "cc-pane-title", server.label));
    const help = element("a", "cc-help-internal-link nut-connection-help", "Help for this server");
    help.href = "#cc-help-section";
    help.dataset.helpFile = server.helpFile;
    help.dataset.helpAnchor = server.helpAnchor || "";
    help.addEventListener("click", event => {
      event.preventDefault();
      if (typeof window.ccOpenHelpArticle === "function") window.ccOpenHelpArticle(server.helpFile, server.helpAnchor || "");
    });
    title.append(help);
    panel.append(title);
    for (const section of server.sections) {
      const source = core.sourceById(section.sourceId);
      if (!source) continue;
      const card = element("article", "cc-card cc-wide nut-connection-source");
      card.dataset.configId = source.id;
      card.append(element("h4", "nut-connection-source-title", source.label));
      card.append(element("div", "cc-mini nut-connection-status", "Loading settings…"));
      if (section.note) card.append(element("p", "cc-section-subtitle nut-connection-section-note", section.note));
      const fields = core.fieldsForSection(section);
      const fieldset = element("fieldset", "nut-connection-system");
      fieldset.append(element("legend", "cc-label", server.label + " connection"));
      for (const field of fields) {
        const wrap = element("label", "nut-connection-field");
        wrap.append(element("span", "cc-label", field.label));
        const input = document.createElement("input");
        input.className = "cc-input";
        input.type = field.kind === "password" ? "password" : "text";
        input.autocomplete = field.kind === "password" ? "new-password" : "off";
        input.spellcheck = false;
        input.dataset.key = field.key;
        input.placeholder = field.kind === "password" ? "Leave blank to keep current" : "";
        wrap.append(input);
        fieldset.append(wrap);
      }
      card.append(fieldset);
      const actions = element("div", "cc-config-toolbar-actions");
      for (const [action, text, klass] of [["reload", "Reload", "cc-btn"], ["validate", "Validate", "cc-btn cc-btn-warn"], ["save", "Save settings", "cc-btn cc-btn-primary"]]) {
        const button = element("button", klass, text);
        button.type = "button";
        button.dataset.action = action;
        actions.append(button);
      }
      card.append(actions);
      panel.append(card);
      cards.set(card, { server, section, source });
      load(card);
    }
  }

  function status(card, message, isError = false) {
    const target = card.querySelector(".nut-connection-status");
    if (!target) return;
    target.textContent = message;
    target.dataset.error = isError ? "true" : "false";
  }

  async function request(sourceId, method, content, mode) {
    const url = `${API_BASE}/api/config/${encodeURIComponent(sourceId)}${method === "GET" ? "/content" : ""}`;
    const options = method === "GET" ? { method: "GET", credentials: "same-origin" } : {
      method: "POST", credentials: "same-origin",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content, mode })
    };
    const response = await fetch(url, options);
    let data = {};
    try { data = await response.json(); } catch (_) { /* don't render raw response bodies */ }
    if (!response.ok || data.ok === false) throw new Error("request rejected");
    return data;
  }

  async function load(card) {
    const meta = cards.get(card);
    if (!meta) return;
    const { source, section } = meta;
    status(card, "Loading settings…");
    try {
      const data = await request(source.id, "GET");
      const content = String(data.content || "");
      const inspected = core.inspectSource(source, content);
      if (inspected.error) throw new Error("A configured field is missing or duplicated: " + inspected.error);
      states.set(source.id, { content, values: inspected.values, path: data.path || "" });
      for (const input of card.querySelectorAll("input[data-key]")) {
        const field = core.fieldsForSection(section).find(item => item.key === input.dataset.key);
        input.value = field && field.kind === "password" ? "" : (inspected.values[input.dataset.key] || "");
      }
      card.querySelectorAll("input, button[data-action='validate'], button[data-action='save']").forEach(node => { node.disabled = false; });
      status(card, "Loaded. Passwords remain blank and masked; blank means unchanged.");
    } catch (error) {
      states.delete(source.id);
      card.querySelectorAll("input, button[data-action='validate'], button[data-action='save']").forEach(node => {
        if (node.dataset.action !== "reload") node.disabled = true;
      });
      status(card, "Settings could not be loaded safely. Ask an administrator to review this file and its active consumer.", true);
    }
  }

  function valuesFrom(card) {
    const values = {};
    for (const input of card.querySelectorAll("input[data-key]")) values[input.dataset.key] = input.value;
    return values;
  }

  async function validate(card) {
    const meta = cards.get(card);
    if (!meta) return;
    const { source, section } = meta;
    const state = states.get(source.id);
    if (!state) return status(card, "Reload settings before validating.", true);
    try {
      const result = await core.validateUpdates({
        source, sourceText: state.content, updates: valuesFrom(card),
        fetchImpl: (url, options) => fetch(url, options), baseUrl: API_BASE
      });
      status(card, result.unchanged ? "No changes to validate." : "Validation passed. Save to apply these settings.");
    } catch (_) {
      status(card, "Validation failed or a setting is ambiguous. No values were displayed; reload or ask an administrator.", true);
    }
  }

  async function save(card) {
    const meta = cards.get(card);
    if (!meta) return;
    const { source, section } = meta;
    const state = states.get(source.id);
    if (!state) return status(card, "Reload settings before saving.", true);
    const fields = core.fieldsForSection(section);
    const updates = valuesFrom(card);
    const changed = source.wholeFileSecret
      ? Boolean(updates.__FILE_SECRET__)
      : fields.some(field => field.kind === "password" ? Boolean(updates[field.key]) : updates[field.key] !== state.values[field.key]);
    if (!changed) return status(card, "No changes entered; existing settings were left untouched.");
    if (!window.confirm("Apply the entered settings for " + source.label + "? Passwords are not shown in this confirmation.")) return;
    try {
      const result = await core.saveUpdates({
        source, loadedText: state.content, updates,
        fetchImpl: (url, options) => fetch(url, options), baseUrl: API_BASE,
        confirmApply: () => true
      });
      card.querySelectorAll("input[type='password']").forEach(input => { input.value = ""; });
      if (result.saved) {
        status(card, "Settings saved. Reloading masked values…");
        await load(card);
      } else if (result.unchanged) {
        status(card, "No changes were applied.");
      } else if (result.cancelled) {
        status(card, "Save cancelled; no settings were applied.");
      }
    } catch (_) {
      status(card, "Save failed or settings changed since load. Reload and review before trying again.", true);
    }
  }

  render();
  root.addEventListener("click", event => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const card = button.closest(".nut-connection-source");
    if (!card) return;
    const action = button.dataset.action;
    if (action === "reload") load(card);
    if (action === "validate") validate(card);
    if (action === "save") save(card);
  });
})();
