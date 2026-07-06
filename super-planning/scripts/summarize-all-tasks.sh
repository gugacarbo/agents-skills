#!/usr/bin/env sh
set -eu

# Summarize all super-plan task progress across the workspace.
#
# Usage:
#   scripts/summarize-all-tasks.sh [--base-dir <path>] [--plan-id <id>] [--json]
#
# Scans <base-dir> (default: docs/tasks) for super-plan.json files and prints
# a consolidated progress summary. Use --plan-id to filter to a single plan.
# Use --json for machine-readable output.

BASE_DIR="docs/tasks"
PLAN_ID=""
OUTPUT_MODE="terminal"

usage() {
  cat <<'EOF'
Usage: summarize-all-tasks.sh [--base-dir <path>] [--plan-id <id>] [--json]

Options:
  --base-dir <path>   Root directory to scan for super-plan.json files (default: docs/tasks)
  --plan-id <id>      Filter to a single plan (e.g. 0001-auth-middleware)
  --json              Output machine-readable JSON instead of terminal-friendly text
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    --plan-id)
      PLAN_ID="$2"
      shift 2
      ;;
    --json)
      OUTPUT_MODE="json"
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

if [ ! -d "$BASE_DIR" ]; then
  echo "Error: base directory not found: $BASE_DIR" >&2
  exit 1
fi

# Collect all super-plan.json paths
if [ -n "$PLAN_ID" ]; then
  TARGET_DIR="$BASE_DIR/$PLAN_ID"
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: plan directory not found: $TARGET_DIR" >&2
    exit 1
  fi
  REGISTRY_PATH="$TARGET_DIR/super-plan.json"
  if [ ! -f "$REGISTRY_PATH" ]; then
    echo "Error: super-plan.json not found in $TARGET_DIR" >&2
    exit 1
  fi
  set -- "$REGISTRY_PATH"
else
  # shellcheck disable=SC2046
  set -- $(find "$BASE_DIR" -maxdepth 2 -name 'super-plan.json' -type f | sort)
fi

if [ "$#" -eq 0 ]; then
  echo "No super-plan.json files found under $BASE_DIR" >&2
  exit 0
fi

python3 - "$OUTPUT_MODE" "$@" <<'PY'
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

output_mode = sys.argv[1]
registry_paths = sys.argv[2:]

STATUS_MAP = {
    "pending": "⏳ pending",
    "in_progress": "🔄 in progress",
    "ready_for_review": "🔎 ready for review",
    "needs_fix": "🔁 needs-fix",
    "blocked": "❌ blocked",
    "completed": "✅ completed",
    "cancelled": "⚪ cancelled",
}

ALL_STATUSES = ["pending", "in_progress", "ready_for_review", "needs_fix", "blocked", "completed", "cancelled"]


def status_label(status: str) -> str:
    return STATUS_MAP.get(status, status or "unknown")


def load_registry(path: str) -> dict | None:
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (json.JSONDecodeError, OSError) as exc:
        if output_mode == "json":
            return None
        print(f"  ⚠️  Skipping {path}: {exc}", file=sys.stderr)
        return None


def read_progress_log(log_path: Path) -> list[dict]:
    """Read JSONL progress log if it exists."""
    events = []
    if log_path.exists():
        try:
            with log_path.open("r", encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if line:
                        try:
                            events.append(json.loads(line))
                        except json.JSONDecodeError:
                            pass
        except OSError:
            pass
    return events


def read_report_summary(report_path: Path) -> str | None:
    """Extract the first meaningful line from a report.md."""
    if not report_path.exists():
        return None
    try:
        with report_path.open("r", encoding="utf-8") as fh:
            for line in fh:
                stripped = line.strip()
                if stripped and not stripped.startswith("#") and len(stripped) > 3:
                    return stripped[:120]
    except OSError:
        pass
    return None


def count_tasks_by_status(tasks: list[dict]) -> dict[str, int]:
    counts = {s: 0 for s in ALL_STATUSES}
    for task in tasks:
        status = task.get("status", "pending")
        if status in counts:
            counts[status] += 1
        else:
            counts["pending"] += 1
    return counts


def count_requirements_by_status(requirements: list[dict]) -> dict[str, int]:
    counts = {s: 0 for s in ALL_STATUSES}
    for req in requirements:
        status = req.get("status", "pending")
        if status in counts:
            counts[status] += 1
        else:
            counts["pending"] += 1
    return counts


def build_plan_summary(registry_path: str) -> dict | None:
    registry = load_registry(registry_path)
    if registry is None:
        return None

    plan_dir = Path(registry_path).parent
    plan_id = registry.get("planId", plan_dir.name)
    feature_name = registry.get("featureName", plan_id)
    plan_status = registry.get("status", "pending")
    tasks = registry.get("tasks", [])
    requirements = registry.get("requirementsChecklist", [])

    task_counts = count_tasks_by_status(tasks)
    req_counts = count_requirements_by_status(requirements)
    total_tasks = len(tasks)
    total_reqs = len(requirements)
    completed_tasks = task_counts.get("completed", 0)
    completed_reqs = req_counts.get("completed", 0)

    # Per-task details
    task_details = []
    for task in tasks:
        tid = task.get("id", "?")
        tstatus = task.get("status", "pending")
        ttitle = task.get("title", "")
        tbatch = task.get("batch", "")
        tphase = task.get("phase", "")
        ttry = task.get("try", 1)
        tmax = task.get("maxTries", 3)
        tdeps = task.get("dependencies", [])

        # Try to read progress log
        progress_log_path = plan_dir / tid / "progress.log"
        events = read_progress_log(progress_log_path)

        # Try to read report summary
        report_path = plan_dir / tid / "report.md"
        report_summary = read_report_summary(report_path)

        # Find last event
        last_event = events[-1] if events else None

        task_details.append({
            "id": tid,
            "title": ttitle,
            "batch": tbatch,
            "phase": tphase,
            "status": tstatus,
            "try": ttry,
            "maxTries": tmax,
            "dependencies": tdeps,
            "lastEvent": last_event,
            "reportSummary": report_summary,
            "eventCount": len(events),
        })

    return {
        "planId": plan_id,
        "featureName": feature_name,
        "planStatus": plan_status,
        "registryPath": str(registry_path),
        "taskCounts": task_counts,
        "reqCounts": req_counts,
        "totalTasks": total_tasks,
        "totalReqs": total_reqs,
        "completedTasks": completed_tasks,
        "completedReqs": completed_reqs,
        "taskDetails": task_details,
        "requirements": [
            {
                "id": r.get("id", "?"),
                "title": r.get("title", ""),
                "status": r.get("status", "pending"),
                "coveredByTasks": r.get("coveredByTasks", []),
            }
            for r in requirements
        ],
    }


def format_terminal(summaries: list[dict]) -> str:
    lines = []
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines.append("=" * 72)
    lines.append("  SUPER-PLAN TASK PROGRESS SUMMARY")
    lines.append(f"  Generated: {now}")
    lines.append(f"  Plans found: {len(summaries)}")
    lines.append("=" * 72)

    grand_total_tasks = 0
    grand_completed_tasks = 0
    grand_total_reqs = 0
    grand_completed_reqs = 0
    grand_status_counts = {s: 0 for s in ALL_STATUSES}

    for summary in summaries:
        grand_total_tasks += summary["totalTasks"]
        grand_completed_tasks += summary["completedTasks"]
        grand_total_reqs += summary["totalReqs"]
        grand_completed_reqs += summary["completedReqs"]
        for s in ALL_STATUSES:
            grand_status_counts[s] += summary["taskCounts"][s]

    # Grand total bar
    if grand_total_tasks > 0:
        pct = (grand_completed_tasks / grand_total_tasks) * 100
        bar_width = 30
        filled = int(bar_width * grand_completed_tasks / grand_total_tasks)
        bar = "█" * filled + "░" * (bar_width - filled)
        lines.append(f"\n  📊 OVERALL: {grand_completed_tasks}/{grand_total_tasks} tasks ({pct:.0f}%)  {bar}")
    lines.append("")

    # Per-plan sections
    for i, summary in enumerate(summaries):
        pid = summary["planId"]
        fname = summary["featureName"]
        pstatus = summary["planStatus"]
        total = summary["totalTasks"]
        completed = summary["completedTasks"]
        pct = (completed / total * 100) if total > 0 else 0

        lines.append(f"  ┌─ Plan: {pid} ({fname})")
        lines.append(f"  │  Status: {status_label(pstatus)}")
        lines.append(f"  │  Registry: {summary['registryPath']}")
        lines.append(f"  │  Tasks: {completed}/{total} completed ({pct:.0f}%)")

        # Task status breakdown
        status_parts = []
        for s in ALL_STATUSES:
            cnt = summary["taskCounts"][s]
            if cnt > 0:
                status_parts.append(f"{status_label(s)}: {cnt}")
        if status_parts:
            lines.append(f"  │  Breakdown: {' | '.join(status_parts)}")

        # Requirements
        if summary["totalReqs"] > 0:
            lines.append(f"  │  Requirements: {summary['completedReqs']}/{summary['totalReqs']} completed")

        # Per-task table
        if summary["taskDetails"]:
            lines.append(f"  │")
            lines.append(f"  │  {'Task ID':<16s} {'Title':<40s} {'Phase':<12s} {'Status':<22s} {'Try':<5s} {'Log':<5s}")
            lines.append(f"  │  {'─'*16} {'─'*40} {'─'*12} {'─'*22} {'─'*5} {'─'*5}")
            for td in summary["taskDetails"]:
                tid = td["id"]
                ttitle = td["title"][:38]
                tphase = td["phase"]
                tstatus = status_label(td["status"])
                ttry = f"{td['try']}/{td['maxTries']}"
                tevents = str(td["eventCount"])
                lines.append(f"  │  {tid:<16s} {ttitle:<40s} {tphase:<12s} {tstatus:<22s} {ttry:<5s} {tevents:<5s}")

                # Show last event if available
                le = td.get("lastEvent")
                if le:
                    le_ts = le.get("timestamp", "")[:16].replace("T", " ")
                    le_event = le.get("event", "?")
                    le_msg = le.get("message", "")[:60]
                    lines.append(f"  │    └─ Last: {le_ts} | {le_event} | {le_msg}")

                # Show report summary if available
                rs = td.get("reportSummary")
                if rs:
                    lines.append(f"  │    └─ Report: {rs}")

        # Requirements table
        if summary["requirements"]:
            lines.append(f"  │")
            lines.append(f"  │  Requirements:")
            for req in summary["requirements"]:
                rid = req["id"]
                rtitle = req["title"][:50]
                rstatus = status_label(req["status"])
                rcovered = ", ".join(req.get("coveredByTasks", [])) or "—"
                lines.append(f"  │    {rid}: {rtitle}")
                lines.append(f"  │      Status: {rstatus} | Covered by: {rcovered}")

        if i < len(summaries) - 1:
            lines.append("  │")
        lines.append("  └" + "─" * 70)
        lines.append("")

    return "\n".join(lines)


def format_json(summaries: list[dict]) -> str:
    output = {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "totalPlans": len(summaries),
        "plans": [],
    }

    grand_total = 0
    grand_completed = 0
    for summary in summaries:
        grand_total += summary["totalTasks"]
        grand_completed += summary["completedTasks"]

        plan_entry = {
            "planId": summary["planId"],
            "featureName": summary["featureName"],
            "planStatus": summary["planStatus"],
            "registryPath": summary["registryPath"],
            "taskCounts": summary["taskCounts"],
            "totalTasks": summary["totalTasks"],
            "completedTasks": summary["completedTasks"],
            "completionPercent": round(
                (summary["completedTasks"] / summary["totalTasks"] * 100) if summary["totalTasks"] > 0 else 0, 1
            ),
            "reqCounts": summary["reqCounts"],
            "totalReqs": summary["totalReqs"],
            "completedReqs": summary["completedReqs"],
            "tasks": [
                {
                    "id": td["id"],
                    "title": td["title"],
                    "batch": td["batch"],
                    "phase": td["phase"],
                    "status": td["status"],
                    "try": td["try"],
                    "maxTries": td["maxTries"],
                    "dependencies": td["dependencies"],
                    "lastEvent": td.get("lastEvent"),
                    "reportSummary": td.get("reportSummary"),
                    "eventCount": td["eventCount"],
                }
                for td in summary["taskDetails"]
            ],
            "requirements": summary["requirements"],
        }
        output["plans"].append(plan_entry)

    output["grandTotal"] = {
        "totalTasks": grand_total,
        "completedTasks": grand_completed,
        "completionPercent": round(
            (grand_completed / grand_total * 100) if grand_total > 0 else 0, 1
        ),
    }

    return json.dumps(output, indent=2, ensure_ascii=False)


# Main
summaries = []
for rp in registry_paths:
    summary = build_plan_summary(rp)
    if summary is not None:
        summaries.append(summary)

if output_mode == "json":
    print(format_json(summaries))
else:
    print(format_terminal(summaries))
PY
