"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

const STATUSES = ["pending", "in_progress", "ready_for_review", "reviewing", "needs_fix", "blocked", "completed", "cancelled"];
const WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
const OPCODES = { TEXT: 1, CLOSE: 8, PING: 9, PONG: 10 };
const BASE_DIR = fs.realpathSync(process.env.DASHBOARD_BASE_DIR || ".");
const PROJECT_DIR = fs.realpathSync(process.env.DASHBOARD_PROJECT_DIR || process.cwd());
const STATE_DIR = process.env.DASHBOARD_STATE_DIR || path.join(PROJECT_DIR, ".super-planning", "job-dashboard");
const TOKEN = process.env.DASHBOARD_TOKEN || "";
const HOST = process.env.DASHBOARD_HOST || "0.0.0.0";
const URL_HOST = process.env.DASHBOARD_URL_HOST || "localhost";
const PORT = Number(process.env.DASHBOARD_PORT || 0);
const REFRESH_MS = Math.max(250, Number(process.env.DASHBOARD_REFRESH_MS || 1000));
const INSTANCE_ID = (process.argv.find((item) => item.startsWith("--instance-id=")) || "").slice(14);
const LIFECYCLE_LOCK_FD = Number(process.env.DASHBOARD_LIFECYCLE_LOCK_FD || -1);
const TEST_PAUSE_BEFORE_METADATA = process.env.DASHBOARD_TEST_PAUSE_BEFORE_METADATA === "1";
const APP_JS = fs.readFileSync(path.join(__dirname, "app.js"));
const STYLES = fs.readFileSync(path.join(__dirname, "styles.css"));

if (!TOKEN || !INSTANCE_ID || !Number.isInteger(PORT) || PORT < 0 || PORT > 65535) {
  process.stderr.write("job dashboard: invalid server configuration\n");
  process.exit(1);
}

function statePath(name) { return path.join(STATE_DIR, name); }
function stateEntry(name) {
  const target = statePath(name);
  let stat;
  try { stat = fs.lstatSync(target); } catch (error) { if (error.code === "ENOENT") return null; throw error; }
  if (stat.isSymbolicLink()) throw new Error(`runtime state file must not be a symlink: ${name}`);
  if (!stat.isFile()) throw new Error(`runtime state file must be a regular file: ${name}`);
  return stat;
}
function assertStateDirectory() {
  const stat = fs.lstatSync(STATE_DIR);
  if (stat.isSymbolicLink() || !stat.isDirectory()) throw new Error("runtime state directory must be a real directory");
}
function atomicStateWrite(name, value) {
  assertStateDirectory();
  stateEntry(name);
  const target = statePath(name);
  const temp = statePath(`.${name}.${process.pid}.${crypto.randomBytes(8).toString("hex")}.tmp`);
  const fd = fs.openSync(temp, fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL | fs.constants.O_NOFOLLOW, 0o600);
  try { fs.writeFileSync(fd, value); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  // rename(2) replaces a racing symlink rather than following it.
  try { fs.renameSync(temp, target); } catch (error) { try { fs.unlinkSync(temp); } catch (_) {} throw error; }
}
function ownedStateText(name) {
  stateEntry(name);
  return fs.readFileSync(statePath(name), "utf8").trim();
}
function releaseLifecycleLock() {
  if (Number.isInteger(LIFECYCLE_LOCK_FD) && LIFECYCLE_LOCK_FD >= 3) {
    try { fs.closeSync(LIFECYCLE_LOCK_FD); } catch (_) {}
  }
}
function waitForTestMetadataRelease(next) {
  if (!TEST_PAUSE_BEFORE_METADATA) return next();
  const ready = statePath(".test-before-metadata-ready");
  const release = statePath(".test-before-metadata-release");
  let fd;
  try {
    fd = fs.openSync(ready, fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL | fs.constants.O_NOFOLLOW, 0o600);
    fs.writeFileSync(fd, `${process.pid}\n`);
    fs.closeSync(fd);
  } catch (error) {
    try { if (fd !== undefined) fs.closeSync(fd); } catch (_) {}
    process.stderr.write(`job dashboard: could not create test startup marker: ${error.message}\n`);
    process.exit(1);
  }
  const poll = setInterval(() => {
    try {
      const stat = fs.lstatSync(release);
      if (!stat.isFile() || stat.isSymbolicLink()) throw new Error("test startup release must be a regular file");
      clearInterval(poll);
      try { fs.unlinkSync(ready); fs.unlinkSync(release); } catch (_) {}
      next();
    } catch (error) {
      if (error.code !== "ENOENT") {
        clearInterval(poll);
        process.stderr.write(`job dashboard: ${error.message}\n`);
        process.exit(1);
      }
    }
  }, 10);
}
function safeEqual(a, b) { const left = Buffer.from(String(a)); const right = Buffer.from(String(b)); return left.length === right.length && crypto.timingSafeEqual(left, right); }
function cookies(header) { const result = {}; for (const value of String(header || "").split(";")) { const i = value.indexOf("="); if (i > 0) result[value.slice(0, i).trim()] = value.slice(i + 1).trim(); } return result; }
function pathname(req) { return new URL(req.url, "http://dashboard.invalid").pathname; }
function queryKey(req) { return new URL(req.url, "http://dashboard.invalid").searchParams.get("key"); }
let cookieName = "job-dashboard";
function authorized(req) { const key = queryKey(req); return Boolean((key && safeEqual(key, TOKEN)) || (cookies(req.headers.cookie)[cookieName] && safeEqual(cookies(req.headers.cookie)[cookieName], TOKEN))); }
function headers(extra = {}) { return { "Cache-Control": "no-store", "Content-Security-Policy": "default-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'", "Cross-Origin-Resource-Policy": "same-origin", "Referrer-Policy": "no-referrer", "X-Content-Type-Options": "nosniff", "X-Frame-Options": "DENY", ...extra }; }
function forbidden(res) { res.writeHead(403, headers({ "Content-Type": "text/plain; charset=utf-8" })); res.end("Forbidden"); }
function insideBase(target) { const rel = path.relative(BASE_DIR, target); return rel && !rel.startsWith(".." + path.sep) && rel !== ".." && !path.isAbsolute(rel); }
function resolvedInsideBase(target) { try { const resolved = fs.realpathSync(target); return insideBase(resolved) ? resolved : null; } catch (_) { return null; } }
function displayPath(target) { const rel = path.relative(PROJECT_DIR, target); return !rel.startsWith(".." + path.sep) && rel !== ".." && !path.isAbsolute(rel) ? rel.split(path.sep).join("/") : path.relative(BASE_DIR, target).split(path.sep).join("/"); }
function relativeBase(target) { return path.relative(BASE_DIR, target).split(path.sep).join("/"); }
function text(value, fallback = "") { return typeof value === "string" ? value : value == null ? fallback : String(value); }
function statuses(items) { const result = Object.fromEntries(STATUSES.map((status) => [status, 0])); for (const item of Array.isArray(items) ? items : []) { const status = text(item && item.status, "pending"); result[STATUSES.includes(status) ? status : "pending"] += 1; } return result; }
function reportSummary(report) { try { for (const line of fs.readFileSync(report, "utf8").split(/\r?\n/)) { const trimmed = line.trim(); if (trimmed && !trimmed.startsWith("#") && trimmed.length > 3) return trimmed.slice(0, 120); } } catch (_) {} return null; }

const lastValidPlans = new Map();
const lastValidLogs = new Map();
function registryPaths() {
  const found = [];
  function visit(dir) {
    const resolvedDir = dir === BASE_DIR ? BASE_DIR : resolvedInsideBase(dir);
    if (!resolvedDir) return;
    let entries; try { entries = fs.readdirSync(resolvedDir, { withFileTypes: true }); } catch (_) { return; }
    for (const entry of entries) {
      if (entry.isSymbolicLink()) continue;
      const candidate = path.join(resolvedDir, entry.name);
      if (!insideBase(candidate)) continue;
      if (entry.isDirectory()) visit(candidate);
      else if (entry.isFile() && entry.name === "super-plan.json") {
        const resolved = resolvedInsideBase(candidate);
        if (resolved) found.push(resolved);
      }
    }
  }
  visit(BASE_DIR);
  return found.sort();
}
function progressFor(planDir, taskId, warnings) {
  if (!/^[A-Za-z0-9_.-]+$/.test(taskId)) return { eventCount: 0, recentEvents: [], lastEvent: null };
  const file = path.join(planDir, taskId, "progress.log");
  const key = relativeBase(file);
  if (!insideBase(file)) return { eventCount: 0, recentEvents: [], lastEvent: null };
  try {
    if (!fs.existsSync(file)) { lastValidLogs.delete(key); return { eventCount: 0, recentEvents: [], lastEvent: null }; }
    const resolved = resolvedInsideBase(file);
    if (!resolved) { warnings.push(`${key}: rejected progress log outside jobs root`); return lastValidLogs.get(key) || { eventCount: 0, recentEvents: [], lastEvent: null }; }
    if (fs.statSync(resolved).size === 0) {
      const data = { eventCount: 0, recentEvents: [], lastEvent: null };
      lastValidLogs.set(key, data);
      return data;
    }
    const events = []; let malformed = false;
    const lines = fs.readFileSync(resolved, "utf8").split(/\r?\n/);
    for (let index = 0; index < lines.length; index += 1) {
      const raw = lines[index];
      if (!raw.trim()) {
        const terminalDelimiter = index === lines.length - 1 && raw === "" && lines.length > 1;
        if (!terminalDelimiter) malformed = true;
        continue;
      }
      try { const event = JSON.parse(raw); if (event && typeof event === "object" && !Array.isArray(event)) events.push(event); else malformed = true; } catch (_) { malformed = true; }
    }
    if (malformed) warnings.push(`${key}: malformed JSONL line`);
    if (malformed && events.length === 0 && lastValidLogs.has(key)) return lastValidLogs.get(key);
    const data = { eventCount: events.length, recentEvents: events.slice(-200), lastEvent: events.length ? events[events.length - 1] : null };
    lastValidLogs.set(key, data); return data;
  } catch (_) { warnings.push(`${key}: unreadable progress log`); return lastValidLogs.get(key) || { eventCount: 0, recentEvents: [], lastEvent: null }; }
}
function planFromRegistry(file, raw, warnings) {
  const planDir = path.dirname(file); const tasks = Array.isArray(raw.tasks) ? raw.tasks : []; const requirements = Array.isArray(raw.requirementsChecklist) ? raw.requirementsChecklist : [];
  const taskCounts = statuses(tasks); const reqCounts = statuses(requirements);
  const details = tasks.map((task) => {
    const id = text(task && task.id, "?"); const progress = progressFor(planDir, id, warnings);
    const safeTaskId = /^[A-Za-z0-9_.-]+$/.test(id);
    const report = safeTaskId ? path.join(planDir, id, "report.md") : "";
    const safeReport = report && insideBase(report) ? resolvedInsideBase(report) : null;
    return { id, title: text(task && task.title), description: text(task && task.description), batch: text(task && task.batch), layer: text(task && task.layer), status: text(task && task.status, "pending"), try: Number(task && task.tryCount) || 1, maxTries: Number(task && task.maxTries) || 3, dependencies: Array.isArray(task && task.dependencies) ? task.dependencies.map((v) => text(v)) : [], lastEvent: progress.lastEvent, reportSummary: safeReport ? reportSummary(safeReport) : null, eventCount: progress.eventCount, recentEvents: progress.recentEvents };
  });
  const totalTasks = tasks.length; const completedTasks = taskCounts.completed;
  return { planId: text(raw.planId, path.basename(planDir)), featureName: text(raw.featureName, path.basename(planDir)), planStatus: text(raw.status, "pending"), registryPath: displayPath(file), taskCounts, reqCounts, totalTasks, completedTasks, completionPercent: totalTasks ? Math.round((completedTasks / totalTasks) * 1000) / 10 : 0, totalReqs: requirements.length, completedReqs: reqCounts.completed, tasks: details, requirements: requirements.map((req) => ({ id: text(req && req.id, "?"), title: text(req && req.title), status: text(req && req.status, "pending"), coveredByTasks: Array.isArray(req && req.coveredByTasks) ? req.coveredByTasks.map((v) => text(v)) : [] })) };
}
function buildSnapshot() {
  const warnings = []; const files = registryPaths(); const live = new Set(files.map(relativeBase)); const plans = [];
  for (const [key] of lastValidPlans) if (!live.has(key)) lastValidPlans.delete(key);
  for (const file of files) {
    const key = relativeBase(file);
    try { const parsed = JSON.parse(fs.readFileSync(file, "utf8")); const plan = planFromRegistry(file, parsed, warnings); lastValidPlans.set(key, plan); plans.push(plan); }
    catch (_) { warnings.push(`${key}: malformed or unreadable registry`); if (lastValidPlans.has(key)) plans.push(lastValidPlans.get(key)); }
  }
  plans.sort((a, b) => a.registryPath.localeCompare(b.registryPath));
  const totalTasks = plans.reduce((sum, plan) => sum + plan.totalTasks, 0); const completedTasks = plans.reduce((sum, plan) => sum + plan.completedTasks, 0);
  const totalReqs = plans.reduce((sum, plan) => sum + plan.totalReqs, 0); const completedReqs = plans.reduce((sum, plan) => sum + plan.completedReqs, 0);
  const taskCounts = statuses(plans.flatMap((plan) => plan.tasks)); const reqCounts = statuses(plans.flatMap((plan) => plan.requirements));
  return { type: "job-snapshot", version: 1, generatedAt: new Date().toISOString(), totalPlans: plans.length, grandTotal: { totalTasks, completedTasks, completionPercent: totalTasks ? Math.round((completedTasks / totalTasks) * 1000) / 10 : 0, taskCounts, totalReqs, completedReqs, requirementCompletionPercent: totalReqs ? Math.round((completedReqs / totalReqs) * 1000) / 10 : 0, reqCounts }, plans, warnings: [...new Set(warnings)].sort() };
}
function fingerprint(snapshot) { const copy = { ...snapshot }; delete copy.generatedAt; return JSON.stringify(copy); }
function frame(opcode, payload) { const data = Buffer.isBuffer(payload) ? payload : Buffer.from(payload); let head; if (data.length < 126) { head = Buffer.from([0x80 | opcode, data.length]); } else if (data.length < 65536) { head = Buffer.alloc(4); head[0] = 0x80 | opcode; head[1] = 126; head.writeUInt16BE(data.length, 2); } else { head = Buffer.alloc(10); head[0] = 0x80 | opcode; head[1] = 127; head.writeBigUInt64BE(BigInt(data.length), 2); } return Buffer.concat([head, data]); }
function accept(key) { return crypto.createHash("sha1").update(`${key}${WS_MAGIC}`).digest("base64"); }
function sameOrigin(req) { return Boolean(req.headers.host && req.headers.origin && req.headers.origin === `http://${req.headers.host}`); }
const clients = new Set(); let snapshot = buildSnapshot(); let currentFingerprint = fingerprint(snapshot); let stopping = false;
function broadcast(data) { const dataFrame = frame(OPCODES.TEXT, JSON.stringify(data)); for (const socket of clients) { try { socket.write(dataFrame); } catch (_) { clients.delete(socket); } } }
function handleUpgrade(req, socket) {
  if (pathname(req) !== "/ws" || !authorized(req) || !sameOrigin(req) || !req.headers["sec-websocket-key"]) { socket.destroy(); return; }
  socket.write(`HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${accept(req.headers["sec-websocket-key"])}\r\n\r\n`);
  clients.add(socket); socket.write(frame(OPCODES.TEXT, JSON.stringify(snapshot)));
  socket.on("data", (data) => { if ((data[0] & 15) === OPCODES.PING) socket.write(frame(OPCODES.PONG, data.subarray(Math.min(2, data.length)))); });
  socket.on("close", () => clients.delete(socket)); socket.on("error", () => clients.delete(socket));
}
const page = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Super-planning jobs</title><link rel="stylesheet" href="/styles.css"></head><body><main id="app"><p>Loading dashboard…</p></main><script src="/app.js" defer></script></body></html>`;
function handleRequest(req, res) {
  if (!authorized(req)) return forbidden(res);
  const route = pathname(req);
  if (route === "/" && queryKey(req)) { res.writeHead(302, headers({ Location: "/", "Set-Cookie": `${cookieName}=${TOKEN}; HttpOnly; SameSite=Strict; Path=/` })); return res.end(); }
  if (route === "/") { res.writeHead(200, headers({ "Content-Type": "text/html; charset=utf-8" })); return res.end(page); }
  if (route === "/healthz") { res.writeHead(200, headers({ "Content-Type": "application/json; charset=utf-8" })); return res.end(JSON.stringify({ type: "job-dashboard-health", status: "ok" })); }
  if (route === "/api/snapshot") { res.writeHead(200, headers({ "Content-Type": "application/json; charset=utf-8" })); return res.end(JSON.stringify(snapshot)); }
  if (route === "/app.js") { res.writeHead(200, headers({ "Content-Type": "application/javascript; charset=utf-8" })); return res.end(APP_JS); }
  if (route === "/styles.css") { res.writeHead(200, headers({ "Content-Type": "text/css; charset=utf-8" })); return res.end(STYLES); }
  res.writeHead(404, headers({ "Content-Type": "text/plain; charset=utf-8" })); res.end("Not found");
}
const server = http.createServer(handleRequest); server.on("upgrade", handleUpgrade);
const timer = setInterval(() => { const next = buildSnapshot(); const nextFingerprint = fingerprint(next); if (nextFingerprint !== currentFingerprint) { snapshot = next; currentFingerprint = nextFingerprint; broadcast(snapshot); } }, REFRESH_MS); timer.unref();
function removeOwnedMetadata() {
  try { if (stateEntry("server-info.json") && JSON.parse(ownedStateText("server-info.json")).instanceId === INSTANCE_ID) fs.unlinkSync(statePath("server-info.json")); } catch (_) {}
  try { if (stateEntry("server.pid") && ownedStateText("server.pid") === String(process.pid)) fs.unlinkSync(statePath("server.pid")); } catch (_) {}
  try { if (stateEntry("server-instance-id") && ownedStateText("server-instance-id") === INSTANCE_ID) fs.unlinkSync(statePath("server-instance-id")); } catch (_) {}
}
function shutdown() { if (stopping) return; stopping = true; clearInterval(timer); for (const client of clients) try { client.destroy(); } catch (_) {} clients.clear(); removeOwnedMetadata(); server.close(() => process.exit(0)); setTimeout(() => process.exit(0), 1000).unref(); }
process.on("SIGTERM", shutdown); process.on("SIGINT", shutdown);
server.once("error", (error) => { process.stderr.write(`job dashboard: server failed to bind: ${error.message}\n`); process.exit(1); });
try {
  assertStateDirectory();
  for (const name of ["server.pid", "server-instance-id", "server-info.json", "server.log"]) stateEntry(name);
} catch (error) {
  process.stderr.write(`job dashboard: ${error.message}\n`);
  process.exit(1);
}
waitForTestMetadataRelease(() => server.listen(PORT, HOST, () => {
  const address = server.address(); cookieName = `job-dashboard-${address.port}`;
  const info = { instanceId: INSTANCE_ID, pid: process.pid, port: address.port, host: HOST, urlHost: URL_HOST, baseDir: BASE_DIR };
  try {
    // These values are written by the live Node process, never inferred from
    // the helper's background PID.  The inherited lifecycle lock remains held
    // until all proof needed by pid_matches_instance is available.
    atomicStateWrite("server.pid", `${process.pid}\n`);
    atomicStateWrite("server-instance-id", `${INSTANCE_ID}\n`);
    atomicStateWrite("server-info.json", `${JSON.stringify(info)}\n`);
    atomicStateWrite("server.log", `${JSON.stringify({ type: "job-dashboard-server-started", port: address.port })}\n`);
  } catch (error) {
    process.stderr.write(`job dashboard: ${error.message}\n`);
    return server.close(() => process.exit(1));
  }
  releaseLifecycleLock();
  process.stderr.write(`${JSON.stringify({ type: "job-dashboard-server-started", port: address.port })}\n`);
}));
