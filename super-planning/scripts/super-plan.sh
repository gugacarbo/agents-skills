#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
if [ "$(basename "$SCRIPT_DIR")" = "scripts" ]; then
  SKILL_DIR="$(dirname "$SCRIPT_DIR")"
else
  SKILL_DIR="$SCRIPT_DIR"
fi
LEDGER_SCRIPT="$SCRIPT_DIR/render-progress-ledger.sh"

error_json() {
  status_code="${1:-1}"
  shift
  printf '{"error": true, "message": "%s", "exit_code": %s}\n' "$*" "$status_code" >&2
  exit "$status_code"
}

usage() {
  cat <<'EOF'
Usage:
  super-plan.sh init \
    --plan-id <NNNN-feature-name> \
    --feature-name <feature-name> \
    --spec <docs/specs/...-spec.md> \
    --plan <docs/plans/...md> \
    --output <docs/jobs/.../super-plan.json> \
    [--base-branch <branch>] \
    [--feature-branch <branch>] \
    [--task-directory <docs/jobs/...>] \
    [--worktree-enabled true|false] \
    [--worktree-path <relative-path>] \
    [--execution-mode subagent-driven|sequential] \
    [--review-cadence per_task|per_batch|final_only] \
    [--schema <path/to/interfaces/super-plan.schema.json>]

  super-plan.sh update \
    --input <docs/jobs/.../super-plan.json> \
    [   --set <path>=<json-or-string>] \
    [--append <path>=<json-or-@file>] ...

  super-plan.sh transition-task \
    --input <docs/jobs/.../super-plan.json> \
    --task-id <Task-A-1> \
    --status <pending|in_progress|ready_for_review|reviewing|needs_fix|blocked|completed|cancelled>

  super-plan.sh complete-task \
    --input <docs/jobs/.../super-plan.json> \
    --task-id <Task-A-1>

  super-plan.sh complete-plan --input <docs/jobs/.../super-plan.json>

  super-plan.sh transition-plan \
    --input <docs/jobs/.../super-plan.json> \
    --status <pending|in_progress|ready_for_review|reviewing|needs_fix|blocked|completed|cancelled>

  super-plan.sh validate --input <docs/jobs/.../super-plan.json>

Append-only update mode for tasks:
  super-plan.sh append-task \
    --input <docs/jobs/.../super-plan.json> \
    [--task <json-or-@file>] \
    [--tasks <json-array-or-@file>] \
    [--validate-only <json-array-or-@file>]

  super-plan.sh reference [--output <path>] [--repo-url <url>] [--ref <name>] [--commit <sha>]

Notes:
  - `append-task` appends task objects to `tasks` and can validate an entire
    task array without writing anything when `--validate-only` is used.
  - `--task` appends a single task object; `--tasks` appends each element of a
    JSON array. They may be combined in one invocation.
  - The `append-task` mode is the preferred way for Phase 4 to add tasks one
    by one so that every task is validated independently.

Notes:
  - If no subcommand is provided, `init` is assumed for backward compatibility.
  - Every successful write regenerates `progress-ledger.md`.
  - Paths support dot notation plus array selectors by id, e.g.:
      tasks[Task-A-1].status=ready_for_review
      requirementsChecklist[REQ-001].status=completed
EOF
  exit 1
}

render_ledger() {
  json_path="$1"
  "$LEDGER_SCRIPT" --input "$json_path" >/dev/null
}

validate_json() {
  json_path="$1"
  python3 - "$json_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])

PLAN_STATUSES = {"pending", "in_progress", "ready_for_review", "reviewing", "needs_fix", "blocked", "completed", "cancelled"}
TASK_STATUSES = PLAN_STATUSES
REVIEW_CADENCE = {"per_task", "per_batch", "final_only"}
EXECUTION_MODE = {"subagent-driven", "sequential"}
TASK_LAYERS = {"foundation", "core", "surface", "final"}
TASK_PROFILES = {"general", "deep", "quick"}


def fail(message: str):
    error = {"error": True, "message": message, "exit_code": 1}
    print(json.dumps(error), file=sys.stderr)
    sys.exit(1)


def expect_type(value, expected_type, path_label: str):
    if not isinstance(value, expected_type):
        fail(f"{path_label} must be {expected_type.__name__}")


def expect_non_empty_string(value, path_label: str):
    if not isinstance(value, str) or not value:
        fail(f"{path_label} must be a non-empty string")


def expect_string_list(value, path_label: str):
    expect_type(value, list, path_label)
    for index, item in enumerate(value):
        expect_non_empty_string(item, f"{path_label}[{index}]")


def expect_status(value, allowed, path_label: str):
    expect_non_empty_string(value, path_label)
    if value not in allowed:
        fail(f"{path_label} must be one of: {', '.join(sorted(allowed))}")


def expect_keys(obj, required_keys, path_label: str):
    expect_type(obj, dict, path_label)
    missing = [key for key in required_keys if key not in obj]
    if missing:
        fail(f"{path_label} is missing required keys: {', '.join(missing)}")


with path.open("r", encoding="utf-8") as fh:
    payload = json.load(fh)

expect_keys(
    payload,
    [
        "$schema",
        "planId",
        "featureName",
        "status",
        "source",
        "goal",
        "architectureSummary",
        "techStack",
        "executionMode",
        "reviewCadence",
        "agents",
        "branchStrategy",
        "worktree",
        "globalConstraints",
        "fileStructure",
        "requirementsChecklist",
        "taskDirectory",
        "rules",
        "tasks",
    ],
    "root",
)

expect_non_empty_string(payload["$schema"], "$schema")
expect_non_empty_string(payload["planId"], "planId")
expect_non_empty_string(payload["featureName"], "featureName")
expect_status(payload["status"], PLAN_STATUSES, "status")
expect_type(payload["goal"], str, "goal")
expect_type(payload["architectureSummary"], str, "architectureSummary")
expect_string_list(payload["techStack"], "techStack")
expect_string_list(payload["globalConstraints"], "globalConstraints")
expect_string_list(payload["rules"], "rules")
expect_non_empty_string(payload["taskDirectory"], "taskDirectory")

expect_keys(payload["source"], ["spec", "plan"], "source")
expect_non_empty_string(payload["source"]["spec"], "source.spec")
expect_non_empty_string(payload["source"]["plan"], "source.plan")

expect_non_empty_string(payload["executionMode"], "executionMode")
if payload["executionMode"] not in EXECUTION_MODE:
    fail(f"executionMode must be one of: {', '.join(sorted(EXECUTION_MODE))}")

expect_non_empty_string(payload["reviewCadence"], "reviewCadence")
if payload["reviewCadence"] not in REVIEW_CADENCE:
    fail(f"reviewCadence must be one of: {', '.join(sorted(REVIEW_CADENCE))}")

expect_keys(payload["agents"], ["general", "deep", "quick"], "agents")
for profile_name in ("general", "deep", "quick"):
    profile = payload["agents"][profile_name]
    expect_keys(profile, ["model", "agent"], f"agents.{profile_name}")
    if not isinstance(profile["model"], str):
        fail(f"agents.{profile_name}.model must be a string")
    if not isinstance(profile["agent"], str):
        fail(f"agents.{profile_name}.agent must be a string")

expect_keys(payload["branchStrategy"], ["baseBranch", "featureBranch"], "branchStrategy")
expect_non_empty_string(payload["branchStrategy"]["baseBranch"], "branchStrategy.baseBranch")
expect_non_empty_string(payload["branchStrategy"]["featureBranch"], "branchStrategy.featureBranch")

expect_keys(payload["worktree"], ["enabled", "path"], "worktree")
if not isinstance(payload["worktree"]["enabled"], bool):
    fail("worktree.enabled must be a boolean")
if not isinstance(payload["worktree"]["path"], str):
    fail("worktree.path must be a string")
if payload["worktree"]["enabled"] and not payload["worktree"]["path"]:
    fail("worktree.path must be a non-empty string when worktree.enabled is true")

expect_type(payload["fileStructure"], list, "fileStructure")
for index, entry in enumerate(payload["fileStructure"]):
    path_label = f"fileStructure[{index}]"
    expect_keys(entry, ["path", "ownerTask", "notes"], path_label)
    expect_non_empty_string(entry["path"], f"{path_label}.path")
    expect_non_empty_string(entry["ownerTask"], f"{path_label}.ownerTask")
    expect_type(entry["notes"], str, f"{path_label}.notes")

expect_type(payload["requirementsChecklist"], list, "requirementsChecklist")
req_ids = [r.get("id") for r in payload["requirementsChecklist"] if isinstance(r, dict)]
seen_reqs = []
for rid in req_ids:
    if rid in seen_reqs:
        fail(f"Duplicate requirement id: {rid}")
    seen_reqs.append(rid)

for index, requirement in enumerate(payload["requirementsChecklist"]):
    path_label = f"requirementsChecklist[{index}]"
    expect_keys(
        requirement,
        ["id", "title", "source", "status", "acceptanceCriteria", "coveredByTasks", "notes"],
        path_label,
    )
    expect_non_empty_string(requirement["id"], f"{path_label}.id")
    expect_non_empty_string(requirement["title"], f"{path_label}.title")
    expect_type(requirement["source"], str, f"{path_label}.source")
    expect_status(requirement["status"], PLAN_STATUSES, f"{path_label}.status")
    expect_string_list(requirement["acceptanceCriteria"], f"{path_label}.acceptanceCriteria")
    expect_string_list(requirement["coveredByTasks"], f"{path_label}.coveredByTasks")
    expect_string_list(requirement["notes"], f"{path_label}.notes")

expect_type(payload["tasks"], list, "tasks")
task_ids = [t.get("id") for t in payload["tasks"] if isinstance(t, dict)]
seen = []
for tid in task_ids:
    if tid in seen:
        fail(f"Duplicate task id: {tid}")
    seen.append(tid)

for index, task in enumerate(payload["tasks"]):
    path_label = f"tasks[{index}]"
    expect_keys(
        task,
        [
            "id",
            "title",
            "description",
            "status",
            "tryCount",
            "maxTries",
            "task_profile",
            "batch",
            "layer",
            "reportFile",
            "reviewPackage",
            "progressLog",
            "logTaskScript",
            "baseCommit",
            "dependencies",
            "acceptanceCriteria",
            "requirements",
            "rules",
            "steps",
            "filesTouched",
            "files",
            "notes",
        ],
        path_label,
    )
    expect_non_empty_string(task["id"], f"{path_label}.id")
    expect_non_empty_string(task["title"], f"{path_label}.title")
    expect_type(task["description"], str, f"{path_label}.description")
    expect_status(task["status"], TASK_STATUSES, f"{path_label}.status")
    if not isinstance(task["tryCount"], int) or task["tryCount"] < 1:
        fail(f"{path_label}.tryCount must be an integer >= 1")
    if not isinstance(task["maxTries"], int) or task["maxTries"] < 1:
        fail(f"{path_label}.maxTries must be an integer >= 1")
    expect_non_empty_string(task["task_profile"], f"{path_label}.task_profile")
    if task["task_profile"] not in TASK_PROFILES:
        fail(f"{path_label}.task_profile must be one of: {', '.join(sorted(TASK_PROFILES))}")
    expect_non_empty_string(task["batch"], f"{path_label}.batch")
    expect_non_empty_string(task["layer"], f"{path_label}.layer")
    if task["layer"] not in TASK_LAYERS:
        fail(f"{path_label}.layer must be one of: {', '.join(sorted(TASK_LAYERS))}")
    expect_non_empty_string(task["reportFile"], f"{path_label}.reportFile")
    expect_non_empty_string(task["reviewPackage"], f"{path_label}.reviewPackage")
    expect_non_empty_string(task["progressLog"], f"{path_label}.progressLog")
    expect_non_empty_string(task["logTaskScript"], f"{path_label}.logTaskScript")
    expect_non_empty_string(task["baseCommit"], f"{path_label}.baseCommit")
    if task["status"] in {"in_progress", "ready_for_review", "reviewing", "needs_fix", "completed"} and task["baseCommit"] == "pending":
        fail(f"{path_label}.baseCommit must be a commit SHA before the task leaves pending")
    expect_string_list(task["dependencies"], f"{path_label}.dependencies")
    expect_string_list(task["acceptanceCriteria"], f"{path_label}.acceptanceCriteria")
    expect_string_list(task["requirements"], f"{path_label}.requirements")
    expect_string_list(task["rules"], f"{path_label}.rules")
    expect_string_list(task["filesTouched"], f"{path_label}.filesTouched")
    expect_string_list(task["notes"], f"{path_label}.notes")

    expect_type(task["steps"], list, f"{path_label}.steps")
    for step_index, step in enumerate(task["steps"]):
        step_label = f"{path_label}.steps[{step_index}]"
        expect_keys(step, ["order", "title", "description", "command", "expectedResult", "codeExample"], step_label)
        if not isinstance(step["order"], int) or step["order"] < 1:
            fail(f"{step_label}.order must be an integer >= 1")
        expect_non_empty_string(step["title"], f"{step_label}.title")
        expect_type(step["description"], str, f"{step_label}.description")
        if step["command"] is not None and not isinstance(step["command"], str):
            fail(f"{step_label}.command must be a string or null")
        if step["expectedResult"] is not None and not isinstance(step["expectedResult"], str):
            fail(f"{step_label}.expectedResult must be a string or null")
        if step["codeExample"] is not None and not isinstance(step["codeExample"], str):
            fail(f"{step_label}.codeExample must be a string or null")

    expect_keys(task["files"], ["created", "modified", "deleted"], f"{path_label}.files")
    expect_string_list(task["files"]["created"], f"{path_label}.files.created")
    expect_string_list(task["files"]["modified"], f"{path_label}.files.modified")
    expect_string_list(task["files"]["deleted"], f"{path_label}.files.deleted")
PY
}

MODE="init"

if [ "$#" -gt 0 ]; then
  case "$1" in
    init|update|append-task|reference|transition-task|complete-task|complete-plan|transition-plan|validate)
      MODE="$1"
      shift
      ;;
    --*)
      MODE="init"
      ;;
    *)
      error_json 1 "Unknown subcommand: $1"
      ;;
  esac
fi

if [ "$MODE" = "validate" ]; then
  INPUT_PATH=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input) INPUT_PATH="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
  if [ -z "$INPUT_PATH" ]; then
    error_json 1 "validate requires --input"
  fi
  validate_json "$INPUT_PATH"
  printf '%s\n' "$INPUT_PATH"
  exit 0
fi

if [ "$MODE" = "complete-plan" ]; then
  INPUT_PATH=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input) INPUT_PATH="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
  if [ -z "$INPUT_PATH" ]; then
    error_json 1 "complete-plan requires --input"
  fi
  exec "$0" update --input "$INPUT_PATH" --set status=completed
fi

if [ "$MODE" = "transition-plan" ]; then
  INPUT_PATH=""
  NEXT_STATUS=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input) INPUT_PATH="$2"; shift 2 ;;
      --status) NEXT_STATUS="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
  if [ -z "$INPUT_PATH" ] || [ -z "$NEXT_STATUS" ]; then
    error_json 1 "transition-plan requires --input and --status"
  fi
  exec "$0" update --input "$INPUT_PATH" --set "status=$NEXT_STATUS"
fi

if [ "$MODE" = "transition-task" ] || [ "$MODE" = "complete-task" ]; then
  INPUT_PATH=""
  TASK_ID=""
  NEXT_STATUS=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input) INPUT_PATH="$2"; shift 2 ;;
      --task-id) TASK_ID="$2"; shift 2 ;;
      --status)
        if [ "$MODE" = "complete-task" ]; then
          error_json 1 "complete-task does not accept --status"
        fi
        NEXT_STATUS="$2"
        shift 2
        ;;
      *) usage ;;
    esac
  done

  if [ -z "$INPUT_PATH" ] || [ -z "$TASK_ID" ]; then
    error_json 1 "$MODE requires --input and --task-id"
  fi
  if [ "$MODE" = "complete-task" ]; then
    NEXT_STATUS="completed"
  elif [ -z "$NEXT_STATUS" ]; then
    error_json 1 "transition-task requires --status"
  fi

  # Delegate to the sole mutation path. Its transition validator is the
  # authoritative lifecycle gate, so this command cannot bypass review.
  exec "$0" update --input "$INPUT_PATH" --set "tasks[$TASK_ID].status=$NEXT_STATUS"
fi

if [ "$MODE" = "reference" ]; then
  OUTPUT_PATH="$SKILL_DIR/super-planning-reference.json"
  REPOSITORY_URL=""
  REF_NAME=""
  COMMIT_SHA=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output) OUTPUT_PATH="$2"; shift 2 ;;
      --repo-url) REPOSITORY_URL="$2"; shift 2 ;;
      --ref) REF_NAME="$2"; shift 2 ;;
      --commit) COMMIT_SHA="$2"; shift 2 ;;
      *) usage ;;
    esac
  done

  REPO_ROOT="$(git -C "$SKILL_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$SKILL_DIR")"
  if [ -z "$REPOSITORY_URL" ]; then
    REPOSITORY_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
  fi
  if [ -z "$REF_NAME" ]; then
    REF_NAME="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || printf '%s' detached)"
  fi
  if [ -z "$COMMIT_SHA" ]; then
    COMMIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || printf '%s' unknown)"
  fi
  VERSION="$(git -C "$REPO_ROOT" describe --tags --always --dirty 2>/dev/null || printf '%s' "$COMMIT_SHA")"

  mkdir -p "$(dirname "$OUTPUT_PATH")"
  python3 - "$OUTPUT_PATH" "$REPOSITORY_URL" "$REF_NAME" "$COMMIT_SHA" "$VERSION" "$SKILL_DIR" <<'PY'
import json
import sys
from datetime import datetime, timezone

output, repository, ref_name, commit, version, skill_path = sys.argv[1:]
payload = {
    "format": 1,
    "skill": "super-planning",
    "repository": repository,
    "ref": ref_name,
    "commit": commit,
    "version": version,
    "skillPath": skill_path,
    "generatedAt": datetime.now(timezone.utc).isoformat(),
}
with open(output, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
  printf '%s\n' "$OUTPUT_PATH"
  exit 0
fi

if [ "$MODE" = "init" ]; then
  PLAN_ID=""
  FEATURE_NAME=""
  SPEC_PATH=""
  PLAN_PATH=""
  OUTPUT_PATH=""
  BASE_BRANCH="${BASE_BRANCH:-main}"
  FEATURE_BRANCH=""
  TASK_DIRECTORY=""
  WORKTREE_ENABLED="false"
  WORKTREE_PATH=""
  EXECUTION_MODE="sequential"
  REVIEW_CADENCE="per_task"
  SCHEMA_PATH=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --plan-id)
        PLAN_ID="$2"
        shift 2
        ;;
      --feature-name)
        FEATURE_NAME="$2"
        shift 2
        ;;
      --spec)
        SPEC_PATH="$2"
        shift 2
        ;;
      --plan)
        PLAN_PATH="$2"
        shift 2
        ;;
      --output)
        OUTPUT_PATH="$2"
        shift 2
        ;;
      --base-branch)
        BASE_BRANCH="$2"
        shift 2
        ;;
      --feature-branch)
        FEATURE_BRANCH="$2"
        shift 2
        ;;
      --task-directory)
        TASK_DIRECTORY="$2"
        shift 2
        ;;
      --worktree-enabled)
        WORKTREE_ENABLED="$2"
        shift 2
        ;;
      --worktree-path)
        WORKTREE_PATH="$2"
        shift 2
        ;;
      --execution-mode)
        EXECUTION_MODE="$2"
        shift 2
        ;;
      --review-cadence)
        REVIEW_CADENCE="$2"
        shift 2
        ;;
      --schema)
        SCHEMA_PATH="$2"
        shift 2
        ;;
      *)
        usage
        ;;
    esac
  done

  if [ -z "$PLAN_ID" ] || [ -z "$FEATURE_NAME" ] || [ -z "$SPEC_PATH" ] || [ -z "$PLAN_PATH" ] || [ -z "$OUTPUT_PATH" ]; then
    error_json 1 "Missing required argument for init: --plan-id, --feature-name, --spec, --plan, --output"
  fi

  case "$WORKTREE_ENABLED" in
    true|false) ;;
    *)
      error_json 1 "Invalid --worktree-enabled value: $WORKTREE_ENABLED"
      ;;
  esac

  case "$EXECUTION_MODE" in
    subagent-driven|sequential) ;;
    *)
      error_json 1 "Invalid --execution-mode value: $EXECUTION_MODE"
      ;;
  esac

  case "$REVIEW_CADENCE" in
    per_task|per_batch|final_only) ;;
    *)
      error_json 1 "Invalid --review-cadence value: $REVIEW_CADENCE"
      ;;
  esac

  if [ -z "$SCHEMA_PATH" ]; then
    if [ -f "$SCRIPT_DIR/super-plan.schema.json" ]; then
      SCHEMA_PATH="$SCRIPT_DIR/super-plan.schema.json"
    else
      SCHEMA_PATH="$SKILL_DIR/interfaces/super-plan.schema.json"
    fi
  fi

  if [ -z "$FEATURE_BRANCH" ]; then
    FEATURE_BRANCH="$PLAN_ID"
  fi

  if [ -z "$TASK_DIRECTORY" ]; then
    TASK_DIRECTORY="$(dirname "$OUTPUT_PATH")"
  fi

  if [ -z "$WORKTREE_PATH" ]; then
    WORKTREE_PATH="../$PLAN_ID-worktree"
  fi

  mkdir -p "$(dirname "$OUTPUT_PATH")"

  python3 - "$PLAN_ID" "$FEATURE_NAME" "$SPEC_PATH" "$PLAN_PATH" "$OUTPUT_PATH" "$BASE_BRANCH" "$FEATURE_BRANCH" "$TASK_DIRECTORY" "$WORKTREE_ENABLED" "$WORKTREE_PATH" "$EXECUTION_MODE" "$REVIEW_CADENCE" "$SCHEMA_PATH" <<'PY'
import json
import sys
from datetime import datetime, timezone

(
    plan_id,
    feature_name,
    spec_path,
    plan_path,
    output_path,
    base_branch,
    feature_branch,
    task_directory,
    worktree_enabled,
    worktree_path,
    execution_mode,
    review_cadence,
    schema_path,
) = sys.argv[1:]

now = datetime.now(timezone.utc).isoformat()

payload = {
    "$schema": "https://raw.githubusercontent.com/gugacarbo/agents-skills/main/super-planning/interfaces/super-plan.schema.json",
    "createdAt": now,
    "planId": plan_id,
    "featureName": feature_name,
    "status": "pending",
    "source": {
        "spec": spec_path,
        "plan": plan_path,
    },
    "goal": "",
    "architectureSummary": "",
    "techStack": [],
    "executionMode": execution_mode,
    "reviewCadence": review_cadence,
    "agents": {
        "general": {"model": "", "agent": ""},
        "deep": {"model": "", "agent": ""},
        "quick": {"model": "", "agent": ""},
    },
    "branchStrategy": {
        "baseBranch": base_branch,
        "featureBranch": feature_branch,
    },
    "worktree": {
        "enabled": worktree_enabled == "true",
        "path": worktree_path,
    },
    "globalConstraints": [],
    "fileStructure": [],
    "requirementsChecklist": [],
    "taskDirectory": task_directory,
    "rules": [],
    "tasks": [],
}

with open(output_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY

  validate_json "$OUTPUT_PATH"
  render_ledger "$OUTPUT_PATH"
  printf '%s\n' "$OUTPUT_PATH"
  exit 0
fi

if [ "$MODE" = "update" ]; then
  INPUT_PATH=""
  UPDATE_ARGS_FILE="$(mktemp)"
  trap 'rm -f "$UPDATE_ARGS_FILE"' EXIT HUP INT TERM

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input)
        INPUT_PATH="$2"
        shift 2
        ;;
      --set|--append|--remove)
        op="$1"
        value="$2"
        shift 2
        printf '%s\t%s\n' "$op" "$value" >> "$UPDATE_ARGS_FILE"
        ;;
      *)
        usage
        ;;
    esac
  done

  if [ -z "$INPUT_PATH" ] || [ ! -s "$UPDATE_ARGS_FILE" ]; then
    error_json 1 "update requires --input and at least one --set/--append/--remove operation"
  fi

  TEMP_OUTPUT_PATH="$(mktemp)"
  trap 'rm -f "$UPDATE_ARGS_FILE" "$TEMP_OUTPUT_PATH"' EXIT HUP INT TERM

  python3 - "$INPUT_PATH" "$UPDATE_ARGS_FILE" "$TEMP_OUTPUT_PATH" <<'PY'
import copy
import json
import sys
from pathlib import Path

input_path = Path(sys.argv[1])
ops_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])


def emit_error(message: str, code: int = 1):
    print(json.dumps({"error": True, "message": message, "exit_code": code}), file=sys.stderr)
    sys.exit(code)


def parse_value(raw: str):
    if raw.startswith("@"):
        try:
            with open(raw[1:], "r", encoding="utf-8") as fh:
                return json.load(fh)
        except FileNotFoundError:
            emit_error(f"File not found: {raw[1:]}")
        except json.JSONDecodeError as exc:
            emit_error(f"Invalid JSON in file {raw[1:]}: {exc}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


def parse_path(path: str):
    tokens = []
    current = ""
    idx = 0
    while idx < len(path):
        char = path[idx]
        if char == ".":
            if current:
                tokens.append((current, None))
                current = ""
            idx += 1
            continue
        if char == "[":
            field = current
            current = ""
            end = path.find("]", idx)
            if end == -1:
                emit_error(f"Invalid path selector: {path}")
            selector = path[idx + 1 : end]
            tokens.append((field, selector))
            idx = end + 1
            if idx < len(path) and path[idx] == ".":
                idx += 1
            continue
        # NOTE: ids containing "]" are not supported by this parser
        current += char
        idx += 1
    if current:
        tokens.append((current, None))
    return tokens


def select_child(container, field, selector):
    if field:
        try:
            container = container[field]
        except (KeyError, TypeError):
            emit_error(f"field '{field}' not found in object")
    if selector is None:
        return container
    if not isinstance(container, list):
        emit_error(f"Path selector requires a list at '{field}'")
    if selector.isdigit():
        return container[int(selector)]
    for item in container:
        if isinstance(item, dict) and item.get("id") == selector:
            return item
    emit_error(f"Could not find list item with id '{selector}' in '{field}'")


def get_parent(root, tokens):
    cursor = root
    for field, selector in tokens[:-1]:
        cursor = select_child(cursor, field, selector)
    return cursor, tokens[-1]


def set_value(root, path, value, append=False):
    tokens = parse_path(path)
    parent, (field, selector) = get_parent(root, tokens)
    if selector is None:
        if append:
            target = parent[field]
            if not isinstance(target, list):
                emit_error(f"Append target is not a list: {path}")
            target.append(value)
        else:
            parent[field] = value
        return
    target = select_child(parent, field, None)
    if selector.isdigit():
        index = int(selector)
        if append:
            nested = target[index]
            if not isinstance(nested, list):
                emit_error(f"Append target is not a list: {path}")
            nested.append(value)
        else:
            target[index] = value
        return
    for index, item in enumerate(target):
        if isinstance(item, dict) and item.get("id") == selector:
            if append:
                if not isinstance(item, list):
                    emit_error(f"Append target is not a list: {path}")
                item.append(value)
            else:
                target[index] = value
            return
    emit_error(f"Could not replace list item with id {selector!r}")


def remove_value(root, path):
    tokens = parse_path(path)
    parent, (field, selector) = get_parent(root, tokens)
    if selector is None:
        del parent[field]
        return
    target = select_child(parent, field, None)
    if selector.isdigit():
        del target[int(selector)]
        return
    for index, item in enumerate(target):
        if isinstance(item, dict) and item.get("id") == selector:
            del target[index]
            return
    emit_error(f"Could not remove list item with id {selector!r}")


with input_path.open("r", encoding="utf-8") as fh:
    try:
        data = json.load(fh)
    except json.JSONDecodeError as exc:
        emit_error(f"Invalid JSON in input file {input_path}: {exc}")

original_data = copy.deepcopy(data)

with ops_path.open("r", encoding="utf-8") as fh:
    for raw_line in fh:
        raw_line = raw_line.rstrip("\n")
        if not raw_line:
            continue
        try:
            op, payload = raw_line.split("\t", 1)
        except ValueError:
            emit_error(f"Malformed operation line: {raw_line}")
        if op == "--remove":
            try:
                remove_value(data, payload)
            except (KeyError, TypeError) as exc:
                emit_error(str(exc))
            continue
        if "=" not in payload:
            emit_error(f"Expected <path>=<value> for {op}: {payload}")
        path, raw_value = payload.split("=", 1)
        value = parse_value(raw_value)
        try:
            set_value(data, path, value, append=(op == "--append"))
        except (KeyError, TypeError) as exc:
            emit_error(str(exc))


TASK_TRANSITIONS = {
    "pending": {"in_progress", "blocked", "cancelled"},
    "in_progress": {"ready_for_review", "blocked", "cancelled"},
    "ready_for_review": {"reviewing", "blocked", "cancelled"},
    "reviewing": {"needs_fix", "completed", "blocked", "cancelled"},
    "needs_fix": {"in_progress", "blocked", "cancelled"},
    "blocked": {"pending", "in_progress", "cancelled"},
    "completed": set(),
    "cancelled": set(),
}
KNOWN_STATUSES = set(TASK_TRANSITIONS)


def validate_transition(entity_label, previous, current, transitions):
    if previous == current:
        return
    if current not in transitions.get(previous, set()):
        emit_error(f"Invalid {entity_label} status transition: {previous} -> {current}")


original_tasks = {task.get("id"): task for task in original_data.get("tasks", []) if isinstance(task, dict)}
for task in data.get("tasks", []):
    if not isinstance(task, dict) or task.get("id") not in original_tasks:
        continue
    previous_task = original_tasks[task["id"]]
    previous_status = previous_task.get("status")
    current_status = task.get("status")
    # Leave malformed status values to the shared registry validator so callers
    # receive the same enum error for update and append paths.
    if previous_status in KNOWN_STATUSES and current_status in KNOWN_STATUSES:
        validate_transition(f"task {task['id']}", previous_status, current_status, TASK_TRANSITIONS)
    if current_status == "completed" and previous_status != "completed":
        if task.get("baseCommit") in (None, "", "pending"):
            emit_error(f"Task {task['id']} cannot complete without a recorded baseCommit")
        if previous_status != "reviewing":
            emit_error(f"Task {task['id']} can only complete after reviewing")

PLAN_TRANSITIONS = {
    "pending": {"in_progress", "blocked", "cancelled"},
    "in_progress": {"ready_for_review", "blocked", "cancelled"},
    "ready_for_review": {"reviewing", "blocked", "cancelled"},
    "reviewing": {"needs_fix", "completed", "blocked", "cancelled"},
    "needs_fix": {"in_progress", "blocked", "cancelled"},
    "blocked": {"pending", "in_progress", "cancelled"},
    "completed": set(),
    "cancelled": set(),
}
previous_plan_status = original_data.get("status")
current_plan_status = data.get("status")
if previous_plan_status in KNOWN_STATUSES and current_plan_status in KNOWN_STATUSES:
    validate_transition("plan", previous_plan_status, current_plan_status, PLAN_TRANSITIONS)
if current_plan_status == "completed" and previous_plan_status != "completed":
    unfinished_tasks = [task.get("id", "<unknown>") for task in data.get("tasks", []) if task.get("status") not in {"completed", "cancelled"}]
    unfinished_requirements = [requirement.get("id", "<unknown>") for requirement in data.get("requirementsChecklist", []) if requirement.get("status") not in {"completed", "cancelled"}]
    if unfinished_tasks:
        emit_error("Plan cannot complete while tasks are unfinished: " + ", ".join(unfinished_tasks))
    if unfinished_requirements:
        emit_error("Plan cannot complete while requirements are unfinished: " + ", ".join(unfinished_requirements))

from datetime import datetime, timezone
data["updatedAt"] = datetime.now(timezone.utc).isoformat()

with output_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY

  validate_json "$TEMP_OUTPUT_PATH"
  mv "$TEMP_OUTPUT_PATH" "$INPUT_PATH"
  render_ledger "$INPUT_PATH"
  printf '%s\n' "$INPUT_PATH"
  exit 0
fi

if [ "$MODE" = "append-task" ]; then
  INPUT_PATH=""
  TASK_JSON=""
  TASKS_JSON=""
  VALIDATE_ONLY=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --input)
        INPUT_PATH="$2"
        shift 2
        ;;
      --task)
        TASK_JSON="$2"
        shift 2
        ;;
      --tasks)
        TASKS_JSON="$2"
        shift 2
        ;;
      --validate-only)
        VALIDATE_ONLY="$2"
        shift 2
        ;;
      *)
        usage
        ;;
    esac
  done

  if [ -z "$INPUT_PATH" ]; then
    error_json 1 "append-task requires --input"
  fi

  if [ -z "$TASK_JSON" ] && [ -z "$TASKS_JSON" ] && [ -z "$VALIDATE_ONLY" ]; then
    error_json 1 "append-task requires at least one of --task, --tasks, or --validate-only"
  fi

  if [ -n "$VALIDATE_ONLY" ] && { [ -n "$TASK_JSON" ] || [ -n "$TASKS_JSON" ]; }; then
    error_json 1 "--validate-only cannot be combined with --task or --tasks"
  fi

  TEMP_OUTPUT_PATH="$(mktemp)"
  trap 'rm -f "$TEMP_OUTPUT_PATH"' EXIT HUP INT TERM

  python3 - "$INPUT_PATH" "$TASK_JSON" "$TASKS_JSON" "$VALIDATE_ONLY" "$TEMP_OUTPUT_PATH" <<'PY'
import json
import sys
from pathlib import Path

input_path = Path(sys.argv[1])
task_json = sys.argv[2] if sys.argv[2] else None
tasks_json = sys.argv[3] if sys.argv[3] else None
validate_only = sys.argv[4] if sys.argv[4] else None
output_path = Path(sys.argv[5])


def emit_error(message: str, code: int = 1):
    print(json.dumps({"error": True, "message": message, "exit_code": code}), file=sys.stderr)
    sys.exit(code)


def parse_value(raw: str):
    if raw.startswith("@"):
        try:
            with open(raw[1:], "r", encoding="utf-8") as fh:
                return json.load(fh)
        except FileNotFoundError:
            emit_error(f"File not found: {raw[1:]}")
        except json.JSONDecodeError as exc:
            emit_error(f"Invalid JSON in file {raw[1:]}: {exc}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return raw


with input_path.open("r", encoding="utf-8") as fh:
    try:
        data = json.load(fh)
    except json.JSONDecodeError as exc:
        emit_error(f"Invalid JSON in input file {input_path}: {exc}")

if validate_only:
    tasks_to_validate = parse_value(validate_only)
    if not isinstance(tasks_to_validate, list):
        emit_error("--validate-only value must be a JSON array")
    # Validate the supplied array through the same complete registry validator
    # used by writes. Do not merge it with existing tasks: this mode is used to
    # check a prospective task array before it is appended or written.
    data["tasks"] = tasks_to_validate

new_tasks = []
if task_json:
    task = parse_value(task_json)
    if not isinstance(task, dict):
        emit_error("--task value must be a JSON object")
    new_tasks.append(task)

if tasks_json:
    tasks = parse_value(tasks_json)
    if not isinstance(tasks, list):
        emit_error("--tasks value must be a JSON array")
    new_tasks.extend(tasks)

for task in new_tasks:
    if not isinstance(task, dict):
        emit_error("--tasks entries must be JSON objects")
    if task.get("status") != "pending":
        emit_error("New tasks must start with status pending; use update for lifecycle transitions")
data.setdefault("tasks", []).extend(new_tasks)

with output_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY

  if [ -n "$VALIDATE_ONLY" ]; then
    validate_json "$TEMP_OUTPUT_PATH"
    python3 - "$VALIDATE_ONLY" <<'PY'
import json
import sys

raw = sys.argv[1]
if raw.startswith("@"):
    with open(raw[1:], encoding="utf-8") as handle:
        tasks = json.load(handle)
else:
    tasks = json.loads(raw)
print(json.dumps({"valid": True, "count": len(tasks)}))
PY
    exit 0
  fi

  validate_json "$TEMP_OUTPUT_PATH"
  mv "$TEMP_OUTPUT_PATH" "$INPUT_PATH"
  render_ledger "$INPUT_PATH"
  printf '%s\n' "$INPUT_PATH"
  exit 0
fi

usage
