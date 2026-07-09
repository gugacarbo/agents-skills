#!/usr/bin/env sh
set -eu

INPUT_PATH=""
OUTPUT_PATH=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage: render-task-md.sh --input <super-plan.json> [--output <path>] [--task-id <id>]

Options:
  --input <path>    Path to super-plan.json (required)
  --output <path>   Output markdown path (default: same dir as input)
  --task-id <id>    Render only the specified task (default: all tasks)
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      INPUT_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$INPUT_PATH" ]; then
  usage
fi

if [ -z "$OUTPUT_PATH" ]; then
  OUTPUT_PATH="$(dirname "$INPUT_PATH")/task-brief.md"
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

python3 - "$INPUT_PATH" "$OUTPUT_PATH" "$TASK_ID" <<'PY'
import json
import sys
from pathlib import Path

input_path, output_path, task_id_filter = sys.argv[1:]
input_path = Path(input_path)
output_path = Path(output_path)

STATUS_MAP = {
    "pending": "⏳ pending",
    "in_progress": "🔄 in progress",
    "ready_for_review": "🔎 ready for review",
    "reviewing": "🔍 reviewing",
    "needs_fix": "🔁 needs-fix",
    "blocked": "❌ blocked",
    "completed": "✅ completed",
    "cancelled": "⚪ cancelled",
}

with input_path.open("r", encoding="utf-8") as fh:
    payload = json.load(fh)

plan_id = payload.get("planId", "")
feature_name = payload.get("featureName", "")
plan_status = payload.get("status", "")
goal = payload.get("goal", "")
arch = payload.get("architectureSummary", "")
tech_stack = payload.get("techStack", [])
exec_mode = payload.get("executionMode", "")
review_cadence = payload.get("reviewCadence", "")
agents = payload.get("agents", {})
branch = payload.get("branchStrategy", {})
worktree = payload.get("worktree", {})
constraints = payload.get("globalConstraints", [])
file_structure = payload.get("fileStructure", [])
requirements = payload.get("requirementsChecklist", [])
rules = payload.get("rules", [])
tasks = payload.get("tasks", [])
task_directory = payload.get("taskDirectory", "")
source = payload.get("source", {})


def status_label(status):
    return STATUS_MAP.get(status, status or "unknown")


def bold_list(items):
    if not items:
        return "_None_"
    return "\n".join(f"- **{item}**" for item in items)


def bullet_list(items):
    if not items:
        return "_None_"
    return "\n".join(f"- {item}" for item in items)


def render_plan_header():
    lines = []
    lines.append(f"# Task Brief: {feature_name}")
    lines.append("")
    lines.append(f"| Field | Value |")
    lines.append(f"|-------|-------|")
    lines.append(f"| Plan ID | `{plan_id}` |")
    lines.append(f"| Feature | {feature_name} |")
    lines.append(f"| Status | {status_label(plan_status)} |")
    lines.append(f"| Execution Mode | {exec_mode} |")
    lines.append(f"| Review Cadence | {review_cadence} |")
    if source:
        spec = source.get("spec", "")
        plan_src = source.get("plan", "")
        lines.append(f"| Spec | `{spec}` |")
        lines.append(f"| Plan Source | `{plan_src}` |")
    base = branch.get("baseBranch", "")
    feat = branch.get("featureBranch", "")
    lines.append(f"| Base Branch | `{base}` |")
    lines.append(f"| Feature Branch | `{feat}` |")
    wt_enabled = worktree.get("enabled", False)
    wt_path = worktree.get("path", "")
    lines.append(f"| Worktree | {'✅ ' + wt_path if wt_enabled else '⚪ disabled'} |")
    lines.append(f"| Task Directory | `{task_directory}` |")
    lines.append("")
    return lines


def render_goal():
    lines = []
    if goal:
        lines.append("## Goal")
        lines.append("")
        lines.append(goal)
        lines.append("")
    if arch:
        lines.append("## Architecture Summary")
        lines.append("")
        lines.append(arch)
        lines.append("")
    return lines


def render_tech_stack():
    if not tech_stack:
        return []
    lines = []
    lines.append("## Tech Stack")
    lines.append("")
    lines.append(bullet_list(tech_stack))
    lines.append("")
    return lines


def render_agents():
    if not agents:
        return []
    lines = []
    lines.append("## Agent Profiles")
    lines.append("")
    lines.append("| Profile | Model | Agent |")
    lines.append("|---------|-------|-------|")
    for name in ("general", "deep", "quick"):
        profile = agents.get(name, {})
        model = profile.get("model", "") or "default"
        agent = profile.get("agent", "") or "default"
        lines.append(f"| {name} | {model} | {agent} |")
    lines.append("")
    return lines


def render_constraints():
    if not constraints:
        return []
    lines = []
    lines.append("## Global Constraints")
    lines.append("")
    lines.append(bullet_list(constraints))
    lines.append("")
    return lines


def render_file_structure():
    if not file_structure:
        return []
    lines = []
    lines.append("## File Structure")
    lines.append("")
    lines.append("| Path | Owner Task | Notes |")
    lines.append("|------|------------|-------|")
    for entry in file_structure:
        path = entry.get("path", "—")
        owner = entry.get("ownerTask", "—")
        notes = entry.get("notes", "—")
        lines.append(f"| `{path}` | `{owner}` | {notes} |")
    lines.append("")
    return lines


def render_requirements():
    if not requirements:
        return []
    lines = []
    lines.append("## Requirements")
    lines.append("")
    for req in requirements:
        rid = req.get("id", "—")
        rtitle = req.get("title", "—")
        rstatus = status_label(req.get("status", ""))
        rsource = req.get("source", "")
        criteria = req.get("acceptanceCriteria", [])
        covered = req.get("coveredByTasks", [])
        rnotes = req.get("notes", [])
        lines.append(f"### {rid}: {rtitle}")
        lines.append("")
        lines.append(f"**Status:** {rstatus}")
        if rsource:
            lines.append(f"**Source:** {rsource}")
        if covered:
            lines.append(f"**Covered by:** {', '.join(f'`{t}`' for t in covered)}")
        lines.append("")
        if criteria:
            lines.append("**Acceptance Criteria:**")
            lines.append("")
            for c in criteria:
                lines.append(f"- [ ] {c}")
            lines.append("")
        if rnotes:
            lines.append("**Notes:**")
            lines.append("")
            for n in rnotes:
                lines.append(f"- {n}")
            lines.append("")
    return lines


def render_plan_rules():
    if not rules:
        return []
    lines = []
    lines.append("## Plan Rules")
    lines.append("")
    lines.append(bullet_list(rules))
    lines.append("")
    return lines


def render_task(task):
    lines = []
    tid = task.get("id", "—")
    ttitle = task.get("title", "—")
    tdesc = task.get("description", "")
    tstatus = task.get("status", "pending")
    tprofile = task.get("task_profile", "—")
    tbatch = task.get("batch", "—")
    tlayer = task.get("layer", "—")
    ttry = task.get("tryCount", 1)
    deps = task.get("dependencies", [])
    criteria = task.get("acceptanceCriteria", [])
    reqs = task.get("requirements", [])
    trules = task.get("rules", [])
    steps = task.get("steps", [])
    ftouched = task.get("filesTouched", [])
    fcreated = task.get("files", {}).get("created", [])
    fmodified = task.get("files", {}).get("modified", [])
    fdeleted = task.get("files", {}).get("deleted", [])
    tnotes = task.get("notes", [])

    lines.append(f"## {tid}: {ttitle}")
    lines.append("")
    lines.append(f"| Field | Value |")
    lines.append(f"|-------|-------|")
    lines.append(f"| ID | `{tid}` |")
    lines.append(f"| Status | {status_label(tstatus)} |")
    lines.append(f"| Profile | {tprofile} |")
    lines.append(f"| Layer | {tlayer} |")
    lines.append(f"| Batch | {tbatch} |")
    lines.append(f"| Try Count | {ttry} |")
    if deps:
        lines.append(f"| Dependencies | {', '.join(f'`{d}`' for d in deps)} |")
    else:
        lines.append(f"| Dependencies | _None_ |")
    lines.append("")

    if tdesc:
        lines.append(tdesc)
        lines.append("")

    if criteria:
        lines.append("### Acceptance Criteria")
        lines.append("")
        for c in criteria:
            lines.append(f"- [ ] {c}")
        lines.append("")

    if reqs:
        lines.append("### Requirements")
        lines.append("")
        for r in reqs:
            lines.append(f"- `{r}`")
        lines.append("")

    if trules:
        lines.append("### Rules")
        lines.append("")
        for r in trules:
            lines.append(f"- {r}")
        lines.append("")

    if steps:
        lines.append("### Steps")
        lines.append("")
        for step in sorted(steps, key=lambda s: s.get("order", 0)):
            sorder = step.get("order", "?")
            stitle = step.get("title", "—")
            sdesc = step.get("description", "")
            scmd = step.get("command")
            sexpected = step.get("expectedResult")
            scode = step.get("codeExample")
            lines.append(f"**Step {sorder}: {stitle}**")
            lines.append("")
            if sdesc:
                lines.append(sdesc)
                lines.append("")
            if scmd:
                lines.append("```sh")
                lines.append(scmd)
                lines.append("```")
                lines.append("")
            if sexpected:
                lines.append(f"**Expected result:** {sexpected}")
                lines.append("")
            if scode:
                lines.append("<details>")
                lines.append("<summary>Code Example</summary>")
                lines.append("")
                lines.append("```")
                lines.append(scode)
                lines.append("```")
                lines.append("")
                lines.append("</details>")
                lines.append("")

    files_have_content = ftouched or fcreated or fmodified or fdeleted
    if files_have_content:
        lines.append("### Files")
        lines.append("")
        if fcreated:
            lines.append("**Created:**")
            lines.append("")
            for f in fcreated:
                lines.append(f"- `{f}`")
            lines.append("")
        if fmodified:
            lines.append("**Modified:**")
            lines.append("")
            for f in fmodified:
                lines.append(f"- `{f}`")
            lines.append("")
        if fdeleted:
            lines.append("**Deleted:**")
            lines.append("")
            for f in fdeleted:
                lines.append(f"- `{f}`")
            lines.append("")

    if tnotes:
        lines.append("### Notes")
        lines.append("")
        for n in tnotes:
            lines.append(f"- {n}")
        lines.append("")

    lines.append("---")
    lines.append("")
    return lines


filtered_tasks = tasks
if task_id_filter:
    filtered_tasks = [t for t in tasks if t.get("id") == task_id_filter]
    if not filtered_tasks:
        print(f"Error: task '{task_id_filter}' not found in {input_path}", file=sys.stderr)
        sys.exit(1)

all_lines = []

if not task_id_filter:
    all_lines.extend(render_plan_header())
    all_lines.extend(render_goal())
    all_lines.extend(render_tech_stack())
    all_lines.extend(render_agents())
    all_lines.extend(render_constraints())
    all_lines.extend(render_file_structure())
    all_lines.extend(render_requirements())
    all_lines.extend(render_plan_rules())

    if filtered_tasks:
        all_lines.append("## Tasks")
        all_lines.append("")
        all_lines.append(f"**Total tasks:** {len(filtered_tasks)}")
        all_lines.append("")

        summary_lines = []
        summary_lines.append("| Task ID | Title | Layer | Status | Dependencies |")
        summary_lines.append("|---------|-------|-------|--------|-------------|")
        for task in filtered_tasks:
            tid = task.get("id", "—")
            ttitle = task.get("title", "—")
            tlayer = task.get("layer", "—")
            tstatus = status_label(task.get("status"))
            deps = task.get("dependencies", [])
            deps_str = ", ".join(deps) if deps else "—"
            summary_lines.append(f"| `{tid}` | {ttitle} | {tlayer} | {tstatus} | {deps_str} |")
        summary_lines.append("")
        all_lines.extend(summary_lines)

        for task in filtered_tasks:
            all_lines.extend(render_task(task))
else:
    for task in filtered_tasks:
        all_lines.extend(render_task(task))

with output_path.open("w", encoding="utf-8") as fh:
    fh.write("\n".join(all_lines))
    fh.write("\n")

print(output_path)
PY