#!/usr/bin/env sh
set -eu

MODE="init"

if [ "$#" -gt 0 ]; then
  case "$1" in
    init|update)
      MODE="$1"
      shift
      ;;
    --*)
      MODE="init"
      ;;
    *)
      echo "Unknown subcommand: $1" >&2
      exit 1
      ;;
  esac
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
LEDGER_SCRIPT="$SCRIPT_DIR/render-progress-ledger.sh"

usage() {
  cat <<'EOF'
Usage:
  super-plan.sh init \
    --plan-id <NNNN-feature-name> \
    --feature-name <feature-name> \
    --spec <docs/specs/...-spec.md> \
    --plan <docs/plans/...md> \
    --output <docs/tasks/.../super-plan.json> \
    [--base-branch <branch>] \
    [--feature-branch <branch>] \
    [--task-directory <docs/tasks/...>] \
    [--worktree-enabled true|false] \
    [--worktree-path <relative-path>] \
    [--execution-mode subagent-driven|sequential] \
    [--review-cadence per_task|per_batch|final_only] \
    [--schema <path/to/interfaces/super-plan.schema.json>]

  super-plan.sh update \
    --input <docs/tasks/.../super-plan.json> \
    [--set <path>=<json-or-string>] \
    [--append <path>=<json-or-@file>] \
    [--remove <path>] ...

Notes:
  - If no subcommand is provided, `init` is assumed for backward compatibility.
  - Every successful write regenerates `progress-ledger.md`.
  - Paths support dot notation plus array selectors by id, e.g.:
      tasks[Task-A-0001].status=ready_for_review
      requirementsChecklist[REQ-001].status=completed
EOF
  exit 1
}

render_ledger() {
  json_path="$1"
  "$LEDGER_SCRIPT" --input "$json_path" >/dev/null
}

if [ "$MODE" = "init" ]; then
  PLAN_ID=""
  FEATURE_NAME=""
  SPEC_PATH=""
  PLAN_PATH=""
  OUTPUT_PATH=""
  BASE_BRANCH="${BASE_BRANCH:-main}"
  FEATURE_BRANCH=""
  TASK_DIRECTORY=""
  WORKTREE_ENABLED="${WORKTREE_ENABLED:-true}"
  WORKTREE_PATH=""
  EXECUTION_MODE="${EXECUTION_MODE:-subagent-driven}"
  REVIEW_CADENCE="${REVIEW_CADENCE:-per_task}"
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
    usage
  fi

  case "$WORKTREE_ENABLED" in
    true|false) ;;
    *)
      echo "Invalid --worktree-enabled value: $WORKTREE_ENABLED" >&2
      exit 1
      ;;
  esac

  case "$EXECUTION_MODE" in
    subagent-driven|sequential) ;;
    *)
      echo "Invalid --execution-mode value: $EXECUTION_MODE" >&2
      exit 1
      ;;
  esac

  case "$REVIEW_CADENCE" in
    per_task|per_batch|final_only) ;;
    *)
      echo "Invalid --review-cadence value: $REVIEW_CADENCE" >&2
      exit 1
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

payload = {
    "$schema": schema_path,
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
    usage
  fi

  python3 - "$INPUT_PATH" "$UPDATE_ARGS_FILE" <<'PY'
import json
import sys
from pathlib import Path

input_path = Path(sys.argv[1])
ops_path = Path(sys.argv[2])

with input_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)


def parse_value(raw: str):
    if raw.startswith("@"):
        with open(raw[1:], "r", encoding="utf-8") as fh:
            return json.load(fh)
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
                raise ValueError(f"Invalid path selector: {path}")
            selector = path[idx + 1 : end]
            tokens.append((field, selector))
            idx = end + 1
            if idx < len(path) and path[idx] == ".":
                idx += 1
            continue
        current += char
        idx += 1
    if current:
        tokens.append((current, None))
    return tokens


def select_child(container, field, selector):
    if field:
        container = container[field]
    if selector is None:
        return container
    if not isinstance(container, list):
        raise TypeError(f"Path selector requires a list at {field!r}")
    if selector.isdigit():
        return container[int(selector)]
    for item in container:
        if isinstance(item, dict) and item.get("id") == selector:
            return item
    raise KeyError(f"Could not find list item with id {selector!r} in {field!r}")


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
                raise TypeError(f"Append target is not a list: {path}")
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
                raise TypeError(f"Append target is not a list: {path}")
            nested.append(value)
        else:
            target[index] = value
        return
    for index, item in enumerate(target):
        if isinstance(item, dict) and item.get("id") == selector:
            if append:
                if not isinstance(item, list):
                    raise TypeError(f"Append target is not a list: {path}")
                item.append(value)
            else:
                target[index] = value
            return
    raise KeyError(f"Could not replace list item with id {selector!r}")


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
    raise KeyError(f"Could not remove list item with id {selector!r}")


with ops_path.open("r", encoding="utf-8") as fh:
    for raw_line in fh:
        raw_line = raw_line.rstrip("\n")
        if not raw_line:
            continue
        op, payload = raw_line.split("\t", 1)
        if op == "--remove":
            remove_value(data, payload)
            continue
        if "=" not in payload:
            raise ValueError(f"Expected <path>=<value> for {op}: {payload}")
        path, raw_value = payload.split("=", 1)
        value = parse_value(raw_value)
        set_value(data, path, value, append=(op == "--append"))

with input_path.open("w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY

  render_ledger "$INPUT_PATH"
  printf '%s\n' "$INPUT_PATH"
  exit 0
fi

usage
