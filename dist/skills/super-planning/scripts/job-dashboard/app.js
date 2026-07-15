"use strict";

const root = document.querySelector("#app");
const LIFECYCLE_STATUSES = ["pending", "in_progress", "ready_for_review", "reviewing", "needs_fix", "blocked", "completed", "cancelled"];
let latest = null;
let query = "";
let status = "";

function node(tag, value, className) { const element = document.createElement(tag); if (className) element.className = className; if (value !== undefined) element.textContent = String(value); return element; }
function countText(counts) { return Object.entries(counts || {}).filter(([, value]) => value).map(([name, value]) => `${name}: ${value}`).join(" · ") || "None"; }
function lastEventText(event) { return event ? [event.timestamp, event.event, event.message].filter(Boolean).join(" · ") || "Event recorded" : "No events yet"; }
function matches(plan) {
  const needle = query.toLowerCase();
  const values = [plan.planId, plan.featureName, plan.planStatus, ...(plan.tasks || []).flatMap((task) => [task.id, task.title, task.status]), ...(plan.requirements || []).flatMap((requirement) => [requirement.id, requirement.title, requirement.status, ...(requirement.coveredByTasks || [])])].join(" ").toLowerCase();
  const hasStatus = !status || plan.planStatus === status || (plan.tasks || []).some((task) => task.status === status) || (plan.requirements || []).some((requirement) => requirement.status === status);
  return (!needle || values.includes(needle)) && hasStatus;
}
function lifecycleSection(title, counts, className) { const section = node("section", undefined, className); section.append(node("h2", title), node("p", countText(counts))); return section; }
function samePathOrSuffix(displayPath, baseRelativePath) { return displayPath === baseRelativePath || displayPath.endsWith(`/${baseRelativePath}`); }
function planWarnings(snapshot, plan) {
  const registryPath = String(plan.registryPath || "");
  const planPath = registryPath.endsWith("/super-plan.json") ? registryPath.slice(0, -"/super-plan.json".length) : "";
  return (snapshot.warnings || []).filter((warning) => {
    const warningPath = String(warning).split(":", 1)[0];
    if (samePathOrSuffix(registryPath, warningPath)) return true;
    return (plan.tasks || []).some((task) => {
      const marker = `/${task.id}/`;
      const markerIndex = warningPath.lastIndexOf(marker);
      return markerIndex >= 0 && planPath && samePathOrSuffix(planPath, warningPath.slice(0, markerIndex));
    });
  });
}
function renderRequirements(plan) {
  const details = node("details"); details.append(node("summary", `Requirements (${plan.completedReqs}/${plan.totalReqs} complete)`));
  for (const requirement of plan.requirements || []) {
    const item = node("section", undefined, "requirement"); item.append(node("h3", `${requirement.id} — ${requirement.title}`), node("p", `Status: ${requirement.status}`), node("p", `Covered by: ${(requirement.coveredByTasks || []).join(", ") || "No tasks linked"}`, "muted"));
    details.append(item);
  }
  return details;
}
function renderTasks(plan) {
  const taskList = node("details"); taskList.append(node("summary", `Tasks (${plan.totalTasks})`));
  for (const task of plan.tasks || []) {
    const taskNode = node("section", undefined, "task"); taskNode.append(node("h3", `${task.id} — ${task.title}`), node("p", `${task.status} · ${task.try}/${task.maxTries} · ${task.batch}/${task.layer}`));
    if (task.dependencies.length) taskNode.append(node("p", `Dependencies: ${task.dependencies.join(", ")}`));
    if (task.reportSummary) taskNode.append(node("p", task.reportSummary, "muted"));
    taskNode.append(node("p", `Last event: ${lastEventText(task.lastEvent)}`, "event"));
    if (task.recentEvents.length > 1) { const events = node("details"); events.append(node("summary", `Recent events (${task.eventCount})`)); for (const event of task.recentEvents) events.append(node("p", lastEventText(event), "event")); taskNode.append(events); }
    taskList.append(taskNode);
  }
  return taskList;
}
function render(snapshot) {
  latest = snapshot; root.replaceChildren();
  const totals = snapshot.grandTotal || {};
  const header = node("header", undefined, "header");
  header.append(node("h1", "Super-planning jobs"), node("p", `${snapshot.totalPlans} plans · ${totals.completedTasks || 0}/${totals.totalTasks || 0} tasks complete · ${totals.completionPercent || 0}%`), node("p", `Requirements: ${totals.completedReqs || 0}/${totals.totalReqs || 0} complete · ${totals.requirementCompletionPercent || 0}%`), node("p", `Last successful update: ${snapshot.generatedAt || "unknown"}`, "muted"));
  const state = node("p", "live", "connection live"); state.id = "connection-state"; header.append(state); root.append(header);
  const controls = node("section", undefined, "controls"); const search = document.createElement("input"); search.type = "search"; search.placeholder = "Filter plans, tasks, and requirements"; search.value = query; search.addEventListener("input", () => { query = search.value; render(latest); }); const select = document.createElement("select"); select.append(node("option", "All statuses")); select.options[0].value = ""; for (const value of LIFECYCLE_STATUSES) { const option = node("option", value); option.value = value; option.selected = status === value; select.append(option); } select.addEventListener("change", () => { status = select.value; render(latest); }); controls.append(search, select); root.append(controls);
  const aggregates = node("section", undefined, "aggregates"); aggregates.append(lifecycleSection("Task lifecycle", totals.taskCounts, "aggregate"), lifecycleSection("Requirement lifecycle", totals.reqCounts, "aggregate")); root.append(aggregates);
  if (snapshot.warnings.length) { const warnings = node("section", undefined, "warnings"); warnings.append(node("h2", "Warnings")); for (const warning of snapshot.warnings) warnings.append(node("p", warning)); root.append(warnings); }
  const plans = node("section", undefined, "plans"); for (const plan of snapshot.plans.filter(matches)) { const card = node("article", undefined, "plan"); const warnings = planWarnings(snapshot, plan); card.append(node("h2", `${plan.planId} — ${plan.featureName}`), node("p", `${plan.planStatus} · ${plan.completionPercent}% task completion · ${plan.completedReqs}/${plan.totalReqs} requirements complete`), node("p", countText(plan.taskCounts), "muted")); if (warnings.length) card.append(node("p", `Warning: ${warnings.length} issue${warnings.length === 1 ? "" : "s"}`, "plan-warning")); card.append(renderRequirements(plan), renderTasks(plan)); plans.append(card); } root.append(plans);
}
function setConnection(value) { const element = document.querySelector("#connection-state"); if (element) element.textContent = value; }
function connect() { const socket = new WebSocket(`${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/ws`); setConnection("connecting"); socket.addEventListener("open", () => setConnection("live")); socket.addEventListener("message", (event) => { try { const data = JSON.parse(event.data); if (data.type === "job-snapshot") render(data); } catch (_) {} }); socket.addEventListener("close", () => { setConnection("disconnected"); setTimeout(connect, 1000); }); socket.addEventListener("error", () => socket.close()); }
connect();
