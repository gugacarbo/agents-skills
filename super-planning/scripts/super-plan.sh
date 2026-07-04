#!/usr/bin/env sh
set -eu

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
SCHEMA_PATH=""

usage() {
  cat <<'EOF'
Usage: super-plan.sh \
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
  [--schema <path/to/interfaces/super-plan.schema.json>]
EOF
  exit 1
}

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

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

if [ -z "$SCHEMA_PATH" ]; then
  SCHEMA_PATH="$SKILL_DIR/interfaces/super-plan.schema.json"
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

python3 - "$PLAN_ID" "$FEATURE_NAME" "$SPEC_PATH" "$PLAN_PATH" "$OUTPUT_PATH" "$BASE_BRANCH" "$FEATURE_BRANCH" "$TASK_DIRECTORY" "$WORKTREE_ENABLED" "$WORKTREE_PATH" "$EXECUTION_MODE" "$SCHEMA_PATH" <<'PY'
import json
import os
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

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

printf '%s\n' "$OUTPUT_PATH"
