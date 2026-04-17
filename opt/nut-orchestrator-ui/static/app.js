async function postJson(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body || {})
  });
  return await res.json();
}

function setOutput(data) {
  const out = document.getElementById('action-output');
  out.textContent =
    "OK: " + data.ok + "\n" +
    "Return code: " + data.returncode + "\n\n" +
    "--- STDOUT ---\n" + (data.stdout || "") + "\n" +
    "--- STDERR ---\n" + (data.stderr || "");
}

async function saveConfig(configId, mode) {
  const content = document.getElementById('content-' + configId).value;
  const data = await postJson('/api/config/' + configId, {content, mode});
  setOutput(data);
}

async function runTest(mode) {
  const data = await postJson('/api/test/' + mode, {});
  setOutput(data);
}

async function backupNow() {
  const data = await postJson('/api/backup', {});
  setOutput(data);
}

async function rollbackConfig(configId) {
  const data = await postJson('/api/rollback/' + configId, {});
  setOutput(data);
}
