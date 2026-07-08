#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P
)
SUPER_PLAN_SCRIPT="$REPO_ROOT/super-planning/scripts/super-plan.sh"
RENDER_LEDGER_SCRIPT="$REPO_ROOT/super-planning/scripts/render-progress-ledger.sh"
LOG_TASK_SCRIPT="$REPO_ROOT/super-planning/scripts/log-task.sh"
SUMMARIZE_SCRIPT="$REPO_ROOT/super-planning/scripts/summarize-all-tasks.sh"
RENDER_TASK_MD_SCRIPT="$REPO_ROOT/super-planning/scripts/render-task-md.sh"
EXAMPLE_PLAN="$REPO_ROOT/super-planning/docs/example/jobs/0001-auth-middleware/super-plan.json"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  if [ ! -e "$path" ]; then
    fail "expected path to exist: $path"
  fi
}

assert_contains_file() {
  local needle="$1"
  local path="$2"
  if ! grep -Fq "$needle" "$path"; then
    fail "expected $path to contain: $needle"
  fi
}

test_init_generates_valid_registry_and_rich_empty_ledger() {
  local tmp registry ledger
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"
  ledger="$tmp/docs/jobs/0001-sample/progress-ledger.md"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" >/dev/null

  assert_exists "$registry"
  assert_exists "$ledger"
  assert_contains_file '"agents": {' "$registry"
  assert_contains_file '"general": {' "$registry"
  assert_contains_file '"model": ""' "$registry"
  assert_contains_file '"agent": ""' "$registry"
  assert_contains_file "# Progress Ledger: sample" "$ledger"
  assert_contains_file "## Summary" "$ledger"
  assert_contains_file "| pending | 0 |" "$ledger"
  assert_contains_file "## Agent Profiles" "$ledger"
  assert_contains_file "| quick | default | default |" "$ledger"
  assert_contains_file "## Timeline" "$ledger"
  assert_contains_file "no task events logged yet" "$ledger"
  assert_contains_file "## Requirements Coverage" "$ledger"
  assert_contains_file "no requirements defined yet" "$ledger"
}

test_update_rejects_invalid_status_without_mutating_file() {
  local tmp registry before
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"
  before=$(cat "$registry")

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=banana >"$tmp/output.log" 2>&1; then
    fail "expected invalid status update to fail"
  fi

  if [ "$(cat "$registry")" != "$before" ]; then
    fail "registry changed after invalid update"
  fi

  assert_contains_file "must be one of" "$tmp/output.log"
}

test_update_accepts_cancelled_task_status() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=cancelled >/dev/null

  assert_contains_file '"status": "cancelled"' "$registry"
  assert_contains_file "⚪ cancelled" "$tmp/docs/jobs/0001-auth-middleware/progress-ledger.md"
}

test_update_accepts_reviewing_task_status() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=reviewing >/dev/null

  assert_contains_file '"status": "reviewing"' "$registry"
  assert_contains_file "🔍 reviewing" "$tmp/docs/jobs/0001-auth-middleware/progress-ledger.md"
}

test_update_rejects_invalid_task_profile_without_mutating_file() {
  local tmp registry before
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"
  before=$(cat "$registry")

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].task_profile=banana >"$tmp/output.log" 2>&1; then
    fail "expected invalid task_profile update to fail"
  fi

  if [ "$(cat "$registry")" != "$before" ]; then
    fail "registry changed after invalid task_profile update"
  fi

  assert_contains_file "task_profile must be one of" "$tmp/output.log"
}

test_errors_are_emitted_as_json() {
  local tmp output
  tmp=$(mktemp -d)

  # Unknown subcommand
  if "$SUPER_PLAN_SCRIPT" bogus >"$tmp/output.log" 2>&1; then
    fail "expected unknown subcommand to fail"
  fi
  python3 -c "import json,sys; json.load(open('$tmp/output.log'))" || fail "unknown subcommand error is not valid JSON"
  assert_contains_file '"error": true' "$tmp/output.log"
  assert_contains_file '"Unknown subcommand: bogus"' "$tmp/output.log"

  # Missing required init argument
  if "$SUPER_PLAN_SCRIPT" init --plan-id 0001-sample >"$tmp/output.log" 2>&1; then
    fail "expected missing required argument to fail"
  fi
  python3 -c "import json,sys; json.load(open('$tmp/output.log'))" || fail "missing argument error is not valid JSON"
  assert_contains_file '"error": true' "$tmp/output.log"

  # Invalid value for enum field
  local registry
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"
  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=banana >"$tmp/output.log" 2>&1; then
    fail "expected invalid status update to fail"
  fi
  python3 -c "import json,sys; json.load(open('$tmp/output.log'))" || fail "validation error is not valid JSON"
  assert_contains_file '"error": true' "$tmp/output.log"
  assert_contains_file '"exit_code": 1' "$tmp/output.log"
}

test_render_progress_ledger_includes_timeline_and_requirements() {
  local tmp registry ledger
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  ledger="$tmp/progress-ledger.md"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"
  cp -R "$REPO_ROOT/super-planning/docs/example/jobs/0001-auth-middleware"/Task-* "$tmp/docs/jobs/0001-auth-middleware/"

  "$RENDER_LEDGER_SCRIPT" --input "$registry" --output "$ledger" >/dev/null

  assert_contains_file "## Summary" "$ledger"
  assert_contains_file "| completed | 5 |" "$ledger"
  assert_contains_file "## Agent Profiles" "$ledger"
  assert_contains_file "| quick | gpt-5-mini | quick |" "$ledger"
  assert_contains_file "## Tasks" "$ledger"
  assert_contains_file "| Task-A-1 | Definir tipos e interfaces de autenticação | general | A | foundation | ✅ completed | — |" "$ledger"
  assert_contains_file "## Timeline" "$ledger"
  assert_contains_file "| 2026-07-04T14:10:00Z | Task-A-1 | completed | 1 |" "$ledger"
  assert_contains_file "## Requirements Coverage" "$ledger"
  assert_contains_file "| REQ-001: Validar token JWT do header Authorization: Bearer <token> | ✅ completed | Task-B-1 |" "$ledger"
}

test_incremental_decompose_appends_tasks_one_by_one() {
  local tmp registry task_a task_b
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" >/dev/null

  assert_exists "$registry"
  assert_contains_file '"tasks": []' "$registry"

  task_a="$tmp/task-a.json"
  cat > "$task_a" <<'EOF'
{
  "id": "Task-A-1",
  "title": "Task A",
  "description": "First task",
  "status": "pending",
  "tryCount": 3,
  "task_profile": "general",
  "batch": "A",
  "phase": "foundation",
  "reportFile": "docs/jobs/0001-sample/Task-A-1/report.md",
  "reviewPackage": "docs/jobs/0001-sample/Task-A-1/review-package.diff.md",
  "progressLog": "docs/jobs/0001-sample/Task-A-1/progress.log",
  "logTaskScript": "docs/jobs/0001-sample/Task-A-1/log-task.sh",
  "dependencies": [],
  "acceptanceCriteria": [],
  "requirements": [],
  "rules": [],
  "steps": [],
  "filesTouched": [],
  "files": {
    "created": [],
    "modified": [],
    "deleted": []
  },
  "notes": []
}
EOF

  task_b="$tmp/task-b.json"
  cat > "$task_b" <<'EOF'
{
  "id": "Task-B-1",
  "title": "Task B",
  "description": "Second task",
  "status": "pending",
  "tryCount": 3,
  "task_profile": "quick",
  "batch": "B",
  "phase": "core",
  "reportFile": "docs/jobs/0001-sample/Task-B-1/report.md",
  "reviewPackage": "docs/jobs/0001-sample/Task-B-1/review-package.diff.md",
  "progressLog": "docs/jobs/0001-sample/Task-B-1/progress.log",
  "logTaskScript": "docs/jobs/0001-sample/Task-B-1/log-task.sh",
  "dependencies": ["Task-A-1"],
  "acceptanceCriteria": [],
  "requirements": [],
  "rules": [],
  "steps": [],
  "filesTouched": [],
  "files": {
    "created": [],
    "modified": [],
    "deleted": []
  },
  "notes": []
}
EOF

  "$SUPER_PLAN_SCRIPT" update \
    --input "$registry" \
    --append tasks="@$task_a" >/dev/null

  "$SUPER_PLAN_SCRIPT" update \
    --input "$registry" \
    --append tasks="@$task_b" >/dev/null

  assert_contains_file '"id": "Task-A-1"' "$registry"
  assert_contains_file '"id": "Task-B-1"' "$registry"
  assert_contains_file '"Task-A-1"' "$tmp/docs/jobs/0001-sample/progress-ledger.md"
  assert_contains_file '"Task-B-1"' "$tmp/docs/jobs/0001-sample/progress-ledger.md"
}

test_materialized_logger_wrapper_writes_jsonl_events() {
  local tmp wrapper log_file
  tmp=$(mktemp -d)
  wrapper="$tmp/docs/jobs/0001-sample/Task-A-1/log-task.sh"
  log_file="$tmp/docs/jobs/0001-sample/Task-A-1/progress.log"

  "$LOG_TASK_SCRIPT" materialize-task-logger \
    --plan 0001-sample \
    --task Task-A-1 \
    --output "$wrapper" \
    --root-script "$LOG_TASK_SCRIPT" >/dev/null

  bash "$wrapper" --event started --try 1 --max-tries 3 --message "Starting implementation" >/dev/null

  assert_exists "$log_file"
  assert_contains_file '"event":"started"' "$log_file"
  assert_contains_file '"task":"Task-A-1"' "$log_file"
}

test_summarize_all_tasks_terminal_output() {
  local tmp
  tmp=$(mktemp -d)

  # Set up two plans with different task states
  mkdir -p "$tmp/docs/jobs/0001-sample"
  mkdir -p "$tmp/docs/jobs/0002-other"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" >/dev/null

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0002-other \
    --feature-name other \
    --spec docs/specs/0002-other-spec.md \
    --plan docs/plans/0002-other.md \
    --output "$tmp/docs/jobs/0002-other/super-plan.json" >/dev/null

  local output
  output=$("$SUMMARIZE_SCRIPT" --base-dir "$tmp/docs/jobs" 2>&1) || fail "summarize-all-tasks.sh failed"

  echo "$output" | grep -q "Plans found: 2" || fail "expected 'Plans found: 2' in output"
  echo "$output" | grep -q "0002-other" || fail "expected 0002-other in output"
  echo "$output" | grep -q "SUPER-PLAN TASK PROGRESS SUMMARY" || fail "expected header in output"
}

test_summarize_all_tasks_json_output() {
  local tmp
  tmp=$(mktemp -d)

  mkdir -p "$tmp/docs/jobs/0001-sample"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" >/dev/null

  local json_output
  json_output=$("$SUMMARIZE_SCRIPT" --base-dir "$tmp/docs/jobs" --json 2>&1) || fail "summarize-all-tasks.sh --json failed"

  echo "$json_output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['totalPlans']==1; assert d['plans'][0]['planId']=='0001-sample'" \
    || fail "JSON output validation failed"
}

test_summarize_all_tasks_with_plan_id_filter() {
  local tmp
  tmp=$(mktemp -d)

  mkdir -p "$tmp/docs/jobs/0001-sample"
  mkdir -p "$tmp/docs/jobs/0002-other"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" >/dev/null

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0002-other \
    --feature-name other \
    --spec docs/specs/0002-other-spec.md \
    --plan docs/plans/0002-other.md \
    --output "$tmp/docs/jobs/0002-other/super-plan.json" >/dev/null

  local output
  output=$("$SUMMARIZE_SCRIPT" --base-dir "$tmp/docs/jobs" --plan-id 0001-sample 2>&1) || fail "summarize-all-tasks.sh with --plan-id failed"

  echo "$output" | grep -q "0001-sample" || fail "expected 0001-sample in filtered output"
  if echo "$output" | grep -q "0002-other"; then
    fail "0002-other should not appear when filtered by --plan-id"
  fi
}

test_summarize_all_tasks_with_example_data() {
  local tmp
  tmp=$(mktemp -d)

  mkdir -p "$tmp/docs/jobs/0001-auth-middleware"
  cp "$EXAMPLE_PLAN" "$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  cp -R "$REPO_ROOT/super-planning/docs/example/jobs/0001-auth-middleware"/Task-* "$tmp/docs/jobs/0001-auth-middleware/"

  local output
  output=$("$SUMMARIZE_SCRIPT" --base-dir "$tmp/docs/jobs" 2>&1) || fail "summarize-all-tasks.sh with example data failed"

  echo "$output" | grep -q "0001-auth-middleware" || fail "expected 0001-auth-middleware in output"
  echo "$output" | grep -q "completed" || fail "expected completed status in output"
  echo "$output" | grep -q "Task-A-1" || fail "expected Task-A-1 in output"
  echo "$output" | grep -q "Task-B-1" || fail "expected Task-B-1 in output"
  echo "$output" | grep -q "Task-C-1" || fail "expected Task-C-1 in output"

  # JSON mode with example data
  local json_output
  json_output=$("$SUMMARIZE_SCRIPT" --base-dir "$tmp/docs/jobs" --json 2>&1) || fail "summarize-all-tasks.sh --json with example data failed"

  echo "$json_output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['totalPlans'] == 1
plan = d['plans'][0]
assert plan['planId'] == '0001-auth-middleware'
assert plan['totalTasks'] == 5
assert plan['completedTasks'] == 5
assert plan['completionPercent'] == 100.0
assert len(plan['tasks']) == 5
print('JSON validation passed')
" || fail "JSON output validation with example data failed"
}

RENDER_TASK_MD_SCRIPT="$REPO_ROOT/super-planning/scripts/render-task-md.sh"

test_render_task_md_full_plan() {
  local tmp registry output
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"

  output=$("$RENDER_TASK_MD_SCRIPT" --input "$registry" 2>&1) || fail "render-task-md.sh --input failed"

  local md_file
  md_file="$tmp/docs/jobs/0001-auth-middleware/task-brief.md"
  assert_exists "$md_file"
  assert_contains_file "# Task Brief: auth-middleware" "$md_file"
  assert_contains_file "## Goal" "$md_file"
  assert_contains_file "## Architecture Summary" "$md_file"
  assert_contains_file "## Tech Stack" "$md_file"
  assert_contains_file "## Agent Profiles" "$md_file"
  assert_contains_file "## Global Constraints" "$md_file"
  assert_contains_file "## File Structure" "$md_file"
  assert_contains_file "## Requirements" "$md_file"
  assert_contains_file "## Plan Rules" "$md_file"
  assert_contains_file "## Tasks" "$md_file"
  assert_contains_file "## Task Task-A-1:" "$md_file"
  assert_contains_file "## Task Task-B-1:" "$md_file"
  assert_contains_file "## Task Task-C-1:" "$md_file"
  assert_contains_file "### Acceptance Criteria" "$md_file"
  assert_contains_file "### Steps" "$md_file"
  assert_contains_file "### Files" "$md_file"
  assert_contains_file "**Created:**" "$md_file"
  assert_contains_file "**Modified:**" "$md_file"
  assert_contains_file 'src/types/auth.ts' "$md_file"
}

test_render_task_md_single_task() {
  local tmp registry output md_file
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"

  output=$("$RENDER_TASK_MD_SCRIPT" --input "$registry" --task-id Task-B-1 --output "$tmp/task-b-brief.md" 2>&1) || fail "render-task-md.sh --task-id failed"

  md_file="$tmp/task-b-brief.md"
  assert_exists "$md_file"
  assert_contains_file "## Task Task-B-1:" "$md_file"
  assert_contains_file "Implementar middleware requireAuth" "$md_file"
  assert_contains_file "### Acceptance Criteria" "$md_file"
  assert_contains_file "### Steps" "$md_file"
  assert_contains_file "### Files" "$md_file"
  assert_contains_file "**Modified:**" "$md_file"

  if grep -q "# Task Brief:" "$md_file"; then
    fail "single task brief should not include plan header"
  fi
  if grep -q "## Goal" "$md_file"; then
    fail "single task brief should not include plan goal section"
  fi
}

test_render_task_md_empty_plan() {
  local tmp registry md_file
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" >/dev/null

  "$RENDER_TASK_MD_SCRIPT" --input "$registry" --output "$tmp/brief.md" >/dev/null

  md_file="$tmp/brief.md"
  assert_exists "$md_file"
  assert_contains_file "# Task Brief: sample" "$md_file"
  assert_contains_file "## Agent Profiles" "$md_file"
  assert_contains_file "| general | default | default |" "$md_file"
}

test_render_task_md_invalid_task_id_exits_with_error() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  cp "$EXAMPLE_PLAN" "$registry"

  if "$RENDER_TASK_MD_SCRIPT" --input "$registry" --task-id Task-Z-9999 --output "$tmp/nowhere.md" 2>/dev/null; then
    fail "expected render-task-md.sh with invalid --task-id to fail"
  fi
}

main() {
  test_init_generates_valid_registry_and_rich_empty_ledger
  test_update_rejects_invalid_status_without_mutating_file
  test_update_accepts_cancelled_task_status
  test_update_accepts_reviewing_task_status
  test_update_rejects_invalid_task_profile_without_mutating_file
  test_render_progress_ledger_includes_timeline_and_requirements
  test_materialized_logger_wrapper_writes_jsonl_events
  test_summarize_all_tasks_terminal_output
  test_summarize_all_tasks_json_output
  test_summarize_all_tasks_with_plan_id_filter
  test_summarize_all_tasks_with_example_data
  test_render_task_md_full_plan
  test_render_task_md_single_task
  test_render_task_md_empty_plan
  test_render_task_md_invalid_task_id_exits_with_error

  printf 'PASS: super-planning.sh\n'
}

main "$@"
