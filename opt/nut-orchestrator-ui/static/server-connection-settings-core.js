(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  if (root) root.NutServerConnectionCore = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  const SOURCES = [
    {
      id: "live_nut_orchestrator_conf",
      label: "Shared NUT orchestrator settings",
      systems: [
        {
          name: "VMware / vCenter",
          fields: [
            { key: "VCENTER_SERVER", label: "vCenter address", kind: "text" },
            { key: "VCENTER_USERNAME", label: "vCenter username", kind: "text" }
          ],
          note: "The separate vCenter password is managed in its own protected file. VM identity mappings remain administrator configuration."
        },
        {
          name: "NetApp01 / NetApp02",
          fields: [
            { key: "NETAPP01_HOST", label: "NetApp01 management address", kind: "text" },
            { key: "NETAPP01_NODE_A", label: "NetApp01 node A address", kind: "text" },
            { key: "NETAPP01_NODE_B", label: "NetApp01 node B address", kind: "text" },
            { key: "NETAPP02_HOST", label: "NetApp02 management address", kind: "text" },
            { key: "NETAPP02_NODE_A", label: "NetApp02 node A address", kind: "text" },
            { key: "NETAPP02_NODE_B", label: "NetApp02 node B address", kind: "text" },
            { key: "NETAPP_USERNAME", label: "Shared NetApp username", kind: "text" },
            { key: "NETAPP_PASSWORD", label: "Shared NetApp password", kind: "password" }
          ],
          note: "The shared account applies to both arrays. Coordinate any account rotation with both systems."
        },
        {
          name: "Observium",
          editable: true,
          fields: [
            { key: "OBSERVIUM_HOST", label: "Observium address", kind: "text" },
            { key: "OBSERVIUM_USERNAME", label: "Observium username", kind: "text" },
            { key: "OBSERVIUM_PASSWORD", label: "Observium password", kind: "password" }
          ],
          note: "The wrapper uses these shared-config fields. Connect as the observium Linux account; leave password blank to retain the current value."
        }
      ]
    },
    {
      id: "lansweeper_creds",
      label: "Lansweeper and Blue Iris shared account",
      systems: [
        {
          name: "Lansweeper / Blue Iris",
          fields: [
            { key: "LANSWEEPER_IP", label: "Lansweeper address", kind: "text" },
            { key: "LANSWEEPER_DOMAIN", label: "Shared account domain", kind: "text" },
            { key: "LANSWEEPER_USERNAME", label: "Shared account username", kind: "text" },
            { key: "LANSWEEPER_PASSWORD", label: "Shared account password", kind: "password" },
            { key: "LANSWEEPER_METHOD", label: "Lansweeper connection method", kind: "text" }
          ],
          note: "Blue Iris and Lansweeper read the same credential file. A password change affects both consumers; coordinate the remote account change before saving."
        }
      ]
    },
    {
      id: "synology_api_conf",
      label: "Synology DSM API",
      systems: [
        {
          name: "Synology",
          fields: [
            { key: "SYNOLOGY_BASE_URL", label: "DSM API address", kind: "text" },
            { key: "SYNOLOGY_USERNAME", label: "DSM username", kind: "text" },
            { key: "SYNOLOGY_PASSWORD", label: "DSM password", kind: "password" }
          ],
          note: "The password remains masked. Blank password input means keep the existing password."
        }
      ]
    },
    {
      id: "db_shutdown_conf",
      label: "DB01 / DB02 Solaris connections",
      systems: [
        {
          name: "DB01",
          fields: [
            { key: "DB01_HOST", label: "DB01 address", kind: "text" },
            { key: "DB01_USERNAME", label: "DB01 username", kind: "text" },
            { key: "DB01_PASSWORD", label: "DB01 password", kind: "password" }
          ]
        },
        {
          name: "DB02",
          fields: [
            { key: "DB02_HOST", label: "DB02 address", kind: "text" },
            { key: "DB02_USERNAME", label: "DB02 username", kind: "text" },
            { key: "DB02_PASSWORD", label: "DB02 password", kind: "password" }
          ]
        }
      ]
    },
    {
      id: "vcenter_pass",
      label: "vCenter password",
      wholeFileSecret: true,
      systems: [
        {
          name: "VMware / vCenter",
          fields: [{ key: "__FILE_SECRET__", label: "vCenter password", kind: "password" }],
          note: "The current password is never loaded into the page. Leave blank to make no change."
        }
      ]
    }
  ];

  function allFields(source) {
    return source.systems.filter(system => system.editable !== false)
      .flatMap(system => system.fields.map(field => ({ ...field, system: system.name })));
  }

  function assignmentMatches(content, key) {
    const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp("^([\\t ]*(?:export[\\t ]+)?" + escaped + "[\\t ]*=)(.*?)(\\r?)$", "gm");
    const found = [];
    let match;
    while ((match = re.exec(String(content))) !== null) {
      found.push({ index: match.index, full: match[0], prefix: match[1], rhs: match[2], cr: match[3] });
    }
    return found;
  }

  function decodeShellScalar(rhs) {
    let value = String(rhs).trim();
    if (!value) return "";
    if (value[0] === "'" || value[0] === '"') {
      const q = value[0];
      if (value[value.length - 1] !== q) throw new Error("unsupported quoting");
      value = value.slice(1, -1);
      if (q === '"') value = value.replace(/\\([\\"$`])/g, "$1");
      else value = value.replace(/'\\''/g, "'");
    } else {
      const comment = value.search(/[\t ]+#/);
      if (comment >= 0) value = value.slice(0, comment).trimEnd();
      if (/[$`\\;]/.test(value)) throw new Error("unsupported shell expression");
    }
    if (/[\r\n\0]/.test(value)) throw new Error("multi-line value");
    return value;
  }

  function readAssignment(content, key) {
    const matches = assignmentMatches(content, key);
    if (matches.length !== 1) {
      throw new Error(matches.length === 0 ? "setting missing" : "duplicate setting");
    }
    return decodeShellScalar(matches[0].rhs);
  }

  function shellQuote(value) {
    const text = String(value);
    if (/[\r\n\0]/.test(text)) throw new Error("multi-line values are not allowed");
    return "'" + text.replace(/'/g, "'\\''") + "'";
  }

  function replaceAssignment(content, key, value) {
    const matches = assignmentMatches(content, key);
    if (matches.length !== 1) {
      throw new Error(matches.length === 0 ? "setting missing" : "duplicate setting");
    }
    const match = matches[0];
    const oldRhs = match.rhs;
    let comment = "";
    if (oldRhs[0] === "'" || oldRhs[0] === '"') {
      const q = oldRhs[0];
      let end = -1;
      for (let i = 1; i < oldRhs.length; i++) {
        if (oldRhs[i] === q && oldRhs[i - 1] !== "\\") end = i;
      }
      if (end < 0 || oldRhs.slice(end + 1).trim() && !/^\s+#/.test(oldRhs.slice(end + 1))) {
        throw new Error("unsupported assignment suffix");
      }
      comment = oldRhs.slice(end + 1);
    } else {
      const cm = oldRhs.match(/([\t ]+#.*)$/);
      if (cm) comment = cm[1];
    }
    const replacement = match.prefix + shellQuote(value) + comment + match.cr;
    return String(content).slice(0, match.index) + replacement + String(content).slice(match.index + match.full.length);
  }

  function inspectSource(source, content) {
    if (source.wholeFileSecret) return { values: { "__FILE_SECRET__": "" }, error: null };
    const values = {};
    for (const field of allFields(source)) {
      try {
        const value = readAssignment(content, field.key);
        values[field.key] = field.kind === "password" ? "" : value;
      } catch (error) {
        return { values, error: `${field.key}: ${error.message}` };
      }
    }
    return { values, error: null };
  }

  function buildUpdatedContent(source, currentContent, updates) {
    if (source.wholeFileSecret) {
      const value = String(updates.__FILE_SECRET__ || "");
      if (!value) return currentContent;
      if (/[\r\n\0]/.test(value)) throw new Error("multi-line values are not allowed");
      return value + "\n";
    }
    let result = String(currentContent);
    for (const field of allFields(source)) {
      const next = updates[field.key];
      if (next === undefined || next === null || next === "") continue;
      if (field.kind !== "password" && String(next) === readAssignment(result, field.key)) continue;
      result = replaceAssignment(result, field.key, next);
    }
    return result;
  }

  async function requestConfig(fetchImpl, baseUrl, sourceId, method, content, mode) {
    const url = `${baseUrl}/api/config/${encodeURIComponent(sourceId)}${method === "GET" ? "/content" : ""}`;
    const options = method === "GET" ? { method: "GET", credentials: "same-origin" } : {
      method: "POST", credentials: "same-origin",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content, mode })
    };
    const response = await fetchImpl(url, options);
    let data = {};
    try { data = await response.json(); } catch (_) { /* do not surface response bodies */ }
    if (!response.ok || data.ok === false) throw new Error("configuration request failed");
    return data;
  }

  async function validateUpdates({ source, sourceText, updates, fetchImpl, baseUrl = "/nut-ui" }) {
    const content = buildUpdatedContent(source, sourceText, updates);
    if (content === sourceText) return { unchanged: true, content };
    await requestConfig(fetchImpl, baseUrl, source.id, "POST", content, "dry-run");
    return { unchanged: false, content };
  }

  async function saveUpdates({ source, loadedText, updates, fetchImpl, baseUrl = "/nut-ui", confirmApply = () => true }) {
    const current = await requestConfig(fetchImpl, baseUrl, source.id, "GET");
    const freshText = String(current.content || "");
    if (!source.wholeFileSecret) {
      for (const field of allFields(source)) {
        if (updates[field.key] !== undefined && updates[field.key] !== "" && field.kind !== "password") {
          const was = readAssignment(loadedText, field.key);
          const now = readAssignment(freshText, field.key);
          if (was !== now) throw new Error("setting changed since load; reload and review before saving");
        }
      }
    }
    const content = buildUpdatedContent(source, freshText, updates);
    if (content === freshText) return { unchanged: true };
    await requestConfig(fetchImpl, baseUrl, source.id, "POST", content, "dry-run");
    if (!confirmApply()) return { cancelled: true };
    await requestConfig(fetchImpl, baseUrl, source.id, "POST", content, "apply");
    return { saved: true };
  }

  return { SOURCES, allFields, readAssignment, replaceAssignment, inspectSource, buildUpdatedContent, validateUpdates, saveUpdates };
});
