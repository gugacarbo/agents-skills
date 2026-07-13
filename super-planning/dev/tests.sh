#!/usr/bin/env bash

set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "SKIP: python3 required for schema validation and inline validator"; exit 0; }

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
REVIEW_PACKAGE_SCRIPT="$REPO_ROOT/super-planning/scripts/review-package.sh"
BOOTSTRAP_SCRIPT="$REPO_ROOT/super-planning/scripts/bootstrap.sh"
DOCTOR_SCRIPT="$REPO_ROOT/super-planning/scripts/doctor.sh"

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

create_test_plan_fixture() {
  local registry="$1"
  local task_directory
  task_directory="docs/jobs/$(basename "$(dirname "$registry")")"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-auth-middleware \
    --feature-name auth-middleware \
    --spec docs/specs/0001-auth-spec.md \
    --plan docs/plans/0001-auth.md \
    --output "$registry" \
    --task-directory "$task_directory" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  python3 - "$registry" <<'PY'
import json
import sys
from pathlib import Path

registry = Path(sys.argv[1])
payload = json.loads(registry.read_text(encoding="utf-8"))
payload.update({
    "goal": "Implement authentication middleware",
    "architectureSummary": "Shared middleware validates bearer tokens before protected routes.",
    "techStack": ["TypeScript", "Cloudflare Workers"],
    "agents": {
        "general": {"model": "gpt-5", "agent": "general"},
        "deep": {"model": "gpt-5", "agent": "deep"},
        "quick": {"model": "gpt-5-mini", "agent": "quick"},
    },
    "globalConstraints": ["Do not expose secrets"],
    "fileStructure": [{"path": "src/middleware/auth.ts", "ownerTask": "Task-B-1", "notes": "Protected route middleware"}],
    "rules": ["Use the repository test runner"],
    "requirementsChecklist": [{
        "id": "REQ-001",
        "title": "Validar token JWT do header Authorization: Bearer <token>",
        "source": "spec",
        "status": "completed",
        "acceptanceCriteria": ["Reject missing tokens"],
        "coveredByTasks": ["Task-B-1"],
        "notes": [],
    }],
})

def task(task_id, title, profile, batch, layer, status="completed", dependencies=None, files=None):
    return {
        "id": task_id,
        "title": title,
        "description": "Implement and verify this task.",
        "status": status,
        "tryCount": 1,
        "maxTries": 3,
        "task_profile": profile,
        "batch": batch,
        "layer": layer,
        "reportFile": f"{payload['taskDirectory']}/{task_id}/report.md",
        "reviewPackage": f"{payload['taskDirectory']}/{task_id}/review-package.diff.md",
        "progressLog": f"{payload['taskDirectory']}/{task_id}/progress.log",
        "logTaskScript": f"{payload['taskDirectory']}/{task_id}/log-task.sh",
        "baseCommit": "test-base-commit",
        "dependencies": dependencies or [],
        "acceptanceCriteria": ["Focused tests pass"],
        "requirements": ["REQ-001"] if task_id == "Task-B-1" else [],
        "rules": ["Keep the middleware reusable"],
        "steps": [{"order": 1, "title": "Implement", "description": "Write the implementation.", "command": "npm test", "expectedResult": "Tests pass", "codeExample": "const result = true;"}],
        "filesTouched": files or [],
        "files": {"created": [], "modified": files or [], "deleted": []},
        "notes": [],
    }

payload["tasks"] = [
    task("Task-A-1", "Definir tipos e interfaces de autenticação", "general", "A", "foundation"),
    task("Task-B-1", "Implementar middleware requireAuth", "deep", "B", "core", dependencies=["Task-A-1"], files=["src/middleware/auth.ts"]),
    task("Task-C-1", "Adicionar testes de autenticação", "quick", "C", "surface", dependencies=["Task-B-1"]),
    task("Task-D-1", "Integrar middleware nas rotas", "general", "D", "surface", dependencies=["Task-B-1"]),
    task("Task-E-1", "Revisar documentação", "quick", "E", "final", dependencies=["Task-D-1"]),
]
payload["tasks"][0]["filesTouched"] = ["src/types/auth.ts"]
payload["tasks"][0]["files"]["created"] = ["src/types/auth.ts"]
registry.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

root = registry.parent
log_dir = root / "Task-A-1"
log_dir.mkdir(parents=True, exist_ok=True)
(log_dir / "progress.log").write_text(
    '{"timestamp":"2026-07-04T14:10:00Z","task":"Task-A-1","event":"completed","try":1,"message":"Review clean; accepted by orchestrator"}\n',
    encoding="utf-8",
)
PY
}

set_task_state_directly() {
  local registry="$1"
  local task_id="$2"
  local status="$3"
  local base_commit="${4:-pending}"

  python3 - "$registry" "$task_id" "$status" "$base_commit" <<'PY'
import json
import sys

path, task_id, status, base_commit = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)
for task in payload["tasks"]:
    if task["id"] == task_id:
        task["status"] = status
        task["baseCommit"] = base_commit
        break
else:
    raise SystemExit(f"missing task: {task_id}")
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
}

test_review_package_preserves_multiple_commits() {
  local tmp repo base head output
  tmp=$(mktemp -d)
  repo="$tmp/repo"
  output="$tmp/review.diff"
  mkdir -p "$repo"

  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Review Package Test"
  printf 'initial\n' > "$repo/first.txt"
  git -C "$repo" add first.txt
  git -C "$repo" commit -qm initial
  base=$(git -C "$repo" rev-parse HEAD)

  printf 'first change\n' >> "$repo/first.txt"
  git -C "$repo" add first.txt
  git -C "$repo" commit -qm "first task commit"
  printf 'second change\n' > "$repo/second.txt"
  git -C "$repo" add second.txt
  git -C "$repo" commit -qm "second task commit"
  head=$(git -C "$repo" rev-parse HEAD)

  (cd "$repo" && "$REVIEW_PACKAGE_SCRIPT" "$base" "$head" "$output") >/dev/null

  assert_contains_file "first task commit" "$output"
  assert_contains_file "second task commit" "$output"
  assert_contains_file "first change" "$output"
  assert_contains_file "second change" "$output"
}

test_review_package_rejects_invalid_ref() {
  local tmp repo output
  tmp=$(mktemp -d)
  repo="$tmp/repo"
  output="$tmp/review.diff"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Review Package Test"
  printf 'initial\n' > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -qm initial

  if (cd "$repo" && "$REVIEW_PACKAGE_SCRIPT" missing-ref HEAD "$output") >"$tmp/output.log" 2>&1; then
    fail "expected review-package.sh to reject an invalid ref"
  fi

  assert_contains_file "bad BASE: missing-ref" "$tmp/output.log"
  if [ -e "$output" ]; then
    fail "review package was created after invalid ref"
  fi

  if (cd "$repo" && "$REVIEW_PACKAGE_SCRIPT" HEAD missing-ref "$output") >"$tmp/head-output.log" 2>&1; then
    fail "expected review-package.sh to reject an invalid HEAD"
  fi

  assert_contains_file "bad HEAD: missing-ref" "$tmp/head-output.log"
}

test_review_package_uses_full_hashes_for_default_output() {
  local tmp repo base head output full_base full_head
  tmp=$(mktemp -d)
  repo="$tmp/repo"
  mkdir -p "$repo"

  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Review Package Test"
  printf 'initial\n' > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -qm initial
  base=$(git -C "$repo" rev-parse HEAD)
  printf 'change\n' >> "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -qm change
  head=$(git -C "$repo" rev-parse HEAD)
  full_base=$(git -C "$repo" rev-parse "$base")
  full_head=$(git -C "$repo" rev-parse "$head")

  output=$(cd "$repo" && "$REVIEW_PACKAGE_SCRIPT" "$base" "$head")
  output=${output#wrote }
  output=${output%%:*}
  assert_exists "$output"
  case "$output" in
    *"$full_base..$full_head.diff") : ;;
    *) fail "default review package path did not use full hashes: $output" ;;
  esac
}

test_testing_guidance_and_spec_strategy_are_integrated() {
  local template evals
  template="$REPO_ROOT/super-planning/templates/testing-anti-patterns.md"
  evals="$REPO_ROOT/super-planning/evals/evals.json"

  assert_exists "$template"
  assert_exists "$evals"
  assert_contains_file "## Test Strategy" "$REPO_ROOT/super-planning/templates/spec-template.md"
  assert_contains_file "testing-anti-patterns.md" "$REPO_ROOT/super-planning/phases/02-spec.md"
  assert_contains_file "Should this spec use TDD" "$REPO_ROOT/super-planning/prompts/pre-write-approval.md"
  assert_contains_file "TDD required for this behavior-changing task" "$REPO_ROOT/super-planning/phases/04-decompose.md"
  assert_contains_file "testing-anti-patterns.md" "$REPO_ROOT/super-planning/prompts/implementer-guidance.md"
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
    --output "$registry" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

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

test_render_progress_ledger_includes_complete_registry_snapshot() {
  local tmp registry ledger
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"
  ledger="$tmp/docs/jobs/0001-sample/progress-ledger.md"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  "$SUPER_PLAN_SCRIPT" update \
    --input "$registry" \
    --set 'goal=Keep every registry parameter visible in the ledger' \
    --set 'agents.quick.model=gpt-5-mini' \
    --set 'worktree.enabled=false' >/dev/null

  assert_contains_file "## Registry Parameters" "$ledger"
  assert_contains_file '"createdAt":' "$ledger"
  assert_contains_file '"goal": "Keep every registry parameter visible in the ledger"' "$ledger"
  assert_contains_file '"executionMode": "subagent-driven"' "$ledger"
  assert_contains_file '"reviewCadence": "per_task"' "$ledger"
  assert_contains_file '"featureBranch": "0001-sample"' "$ledger"
  assert_contains_file '"enabled": false' "$ledger"
  assert_contains_file '"requirementsChecklist": []' "$ledger"
  assert_contains_file '"tasks": []' "$ledger"
}

test_update_rejects_invalid_status_without_mutating_file() {
  local tmp registry before
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
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
  local tmp registry schema
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  schema="$REPO_ROOT/super-planning/interfaces/super-plan.schema.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" ready_for_review test-base-commit

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=cancelled >/dev/null

  assert_contains_file '"status": "cancelled"' "$registry"
  assert_contains_file "[CANC] cancelled" "$tmp/docs/jobs/0001-auth-middleware/progress-ledger.md"

  # Also validate against schema.json to avoid false positives
  if python3 -c "import jsonschema" 2>/dev/null; then
    python3 -c "
import json, jsonschema, sys
with open('$registry') as f:
    data = json.load(f)
with open('$schema') as f:
    schema = json.load(f)
try:
    jsonschema.validate(data, schema)
except jsonschema.ValidationError as e:
    print(f'Schema validation failed: {e}', file=sys.stderr)
    sys.exit(1)
" || fail "cancelled task failed schema validation"
  else
    echo "SKIP: jsonschema module not available, skipping schema validation"
  fi
}

test_update_accepts_reviewing_task_status() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" pending pending

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set "tasks[Task-A-1].baseCommit=$(git -C "$REPO_ROOT" rev-parse HEAD)" >/dev/null
  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=in_progress >/dev/null
  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=ready_for_review >/dev/null
  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=reviewing >/dev/null

  assert_contains_file '"status": "reviewing"' "$registry"
  assert_contains_file "[AUDIT] reviewing" "$tmp/docs/jobs/0001-auth-middleware/progress-ledger.md"
}

test_active_task_requires_base_commit() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" ready_for_review test-base-commit
  python3 - "$registry" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)
for task in payload["tasks"]:
    task.pop("baseCommit", None)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle)
PY

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=reviewing >"$tmp/output.log" 2>&1; then
    fail "expected active task without baseCommit to fail"
  fi

  assert_contains_file "baseCommit" "$tmp/output.log"
}

test_update_rejects_invalid_task_profile_without_mutating_file() {
  local tmp registry before
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
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
  create_test_plan_fixture "$registry"
  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=banana >"$tmp/output.log" 2>&1; then
    fail "expected invalid status update to fail"
  fi
  python3 -c "import json,sys; json.load(open('$tmp/output.log'))" || fail "validation error is not valid JSON"
  assert_contains_file '"error": true' "$tmp/output.log"
  assert_contains_file '"exit_code": 1' "$tmp/output.log"
}

test_schema_validator_agreement() {
  if ! python3 -c "import jsonschema" 2>/dev/null; then
    echo "SKIP: jsonschema module not available, skipping schema validator agreement test"
    return
  fi

  local tmp schema
  tmp=$(mktemp -d)
  schema="$REPO_ROOT/super-planning/interfaces/super-plan.schema.json"

  python3 -c "
import json, jsonschema, sys
from datetime import datetime, timezone

# Build a minimal valid plan
now = datetime.now(timezone.utc).isoformat()
plan = {
    '\$schema': 'https://raw.githubusercontent.com/gugacarbo/agents-skills/main/super-planning/interfaces/super-plan.schema.json',
    'createdAt': now,
    'planId': '0001-test',
    'featureName': 'test-feature',
    'status': 'pending',
    'source': {'spec': 'docs/specs/test.md', 'plan': 'docs/plans/test.md'},
    'goal': '',
    'architectureSummary': '',
    'techStack': [],
    'executionMode': 'subagent-driven',
    'reviewCadence': 'per_task',
    'agents': {
        'general': {'model': '', 'agent': ''},
        'deep': {'model': '', 'agent': ''},
        'quick': {'model': '', 'agent': ''},
    },
    'branchStrategy': {'baseBranch': 'main', 'featureBranch': '0001-test'},
    'worktree': {'enabled': False, 'path': ''},
    'globalConstraints': [],
    'fileStructure': [],
    'requirementsChecklist': [],
    'taskDirectory': 'docs/jobs/0001-test',
    'rules': [],
    'tasks': [],
}

# Validate against schema.json
with open('$schema') as f:
    s = json.load(f)
try:
    jsonschema.validate(plan, s)
    print('Schema: PASS')
except jsonschema.ValidationError as e:
    print(f'Schema: FAIL - {e}', file=sys.stderr)
    sys.exit(1)
"

  # Also validate that schema accepts all valid status values
  python3 -c "
import json, jsonschema, sys
with open('$schema') as f:
    s = json.load(f)
status_enum = s['properties']['status']['enum']
expected = {'pending', 'in_progress', 'ready_for_review', 'reviewing', 'needs_fix', 'blocked', 'completed', 'cancelled'}
actual = set(status_enum)
if actual != expected:
    print(f'Schema status enum mismatch: extra={actual-expected} missing={expected-actual}', file=sys.stderr)
    sys.exit(1)
print('Status enum: PASS')
" || fail "schema and validator status enums disagree"
}

test_render_progress_ledger_includes_timeline_and_requirements() {
  local tmp registry ledger
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  ledger="$tmp/progress-ledger.md"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  "$RENDER_LEDGER_SCRIPT" --input "$registry" --output "$ledger" >/dev/null

  assert_contains_file "## Summary" "$ledger"
  assert_contains_file "| completed | 5 |" "$ledger"
  assert_contains_file "## Agent Profiles" "$ledger"
  assert_contains_file "| quick | gpt-5-mini | quick |" "$ledger"
  assert_contains_file "## Tasks" "$ledger"
  assert_contains_file "| Task-A-1 | Definir tipos e interfaces de autenticação | general | A | foundation | [DONE] completed | — |" "$ledger"
  assert_contains_file "## Timeline" "$ledger"
  assert_contains_file "| 2026-07-04T14:10:00Z | Task-A-1 | completed | 1 | Review clean; accepted by orchestrator |" "$ledger"
  assert_contains_file "Review clean; accepted by orchestrator" "$ledger"
  assert_contains_file "## Requirements Coverage" "$ledger"
  assert_contains_file "| REQ-001: Validar token JWT do header Authorization: Bearer <token> | [DONE] completed | Task-B-1 |" "$ledger"
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
    --output "$registry" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

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
  "maxTries": 3,
  "task_profile": "general",
  "batch": "A",
  "layer": "foundation",
  "reportFile": "docs/jobs/0001-sample/Task-A-1/report.md",
  "reviewPackage": "docs/jobs/0001-sample/Task-A-1/review-package.diff.md",
  "progressLog": "docs/jobs/0001-sample/Task-A-1/progress.log",
  "logTaskScript": "docs/jobs/0001-sample/Task-A-1/log-task.sh",
  "baseCommit": "pending",
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
  "maxTries": 3,
  "task_profile": "quick",
  "batch": "B",
  "layer": "core",
  "reportFile": "docs/jobs/0001-sample/Task-B-1/report.md",
  "reviewPackage": "docs/jobs/0001-sample/Task-B-1/review-package.diff.md",
  "progressLog": "docs/jobs/0001-sample/Task-B-1/progress.log",
  "logTaskScript": "docs/jobs/0001-sample/Task-B-1/log-task.sh",
  "baseCommit": "pending",
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
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0002-other \
    --feature-name other \
    --spec docs/specs/0002-other-spec.md \
    --plan docs/plans/0002-other.md \
    --output "$tmp/docs/jobs/0002-other/super-plan.json" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

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
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

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
    --output "$tmp/docs/jobs/0001-sample/super-plan.json" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0002-other \
    --feature-name other \
    --spec docs/specs/0002-other-spec.md \
    --plan docs/plans/0002-other.md \
    --output "$tmp/docs/jobs/0002-other/super-plan.json" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

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
  create_test_plan_fixture "$tmp/docs/jobs/0001-auth-middleware/super-plan.json"

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
  create_test_plan_fixture "$registry"

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
  assert_contains_file "## Task-A-1:" "$md_file"
  assert_contains_file "## Task-B-1:" "$md_file"
  assert_contains_file "## Task-C-1:" "$md_file"
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
  create_test_plan_fixture "$registry"

  output=$("$RENDER_TASK_MD_SCRIPT" --input "$registry" --task-id Task-B-1 --output "$tmp/task-b-brief.md" 2>&1) || fail "render-task-md.sh --task-id failed"

  md_file="$tmp/task-b-brief.md"
  assert_exists "$md_file"
  assert_contains_file "# Task Brief: Task-B-1:" "$md_file"
  assert_contains_file "Implementar middleware requireAuth" "$md_file"
  assert_contains_file "### Acceptance Criteria" "$md_file"
  assert_contains_file "### Steps" "$md_file"
  assert_contains_file "### Files" "$md_file"
  assert_contains_file "**Modified:**" "$md_file"

  assert_contains_file "Process:" "$md_file"
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
    --output "$registry" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  "$RENDER_TASK_MD_SCRIPT" --input "$registry" --output "$tmp/brief.md" >/dev/null

  md_file="$tmp/brief.md"
  assert_exists "$md_file"
  assert_contains_file "# Task Brief: sample" "$md_file"
  assert_contains_file "## Agent Profiles" "$md_file"
  assert_contains_file "| general | default | default |" "$md_file"
}

test_append_task_validate_only() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" \
    --worktree-enabled true \
    --execution-mode subagent-driven \
    --review-cadence per_task >/dev/null

  local task_json='[{"id":"Task-A-1","title":"A","description":"","status":"pending","tryCount":3,"maxTries":3,"task_profile":"general","batch":"A","layer":"foundation","reportFile":"a.md","reviewPackage":"b.md","progressLog":"c.log","logTaskScript":"d.sh","baseCommit":"pending","dependencies":[],"acceptanceCriteria":[],"requirements":[],"rules":[],"steps":[],"filesTouched":[],"files":{"created":[],"modified":[],"deleted":[]},"notes":[]}]'
  local output
  output=$("$SUPER_PLAN_SCRIPT" append-task --input "$registry" --validate-only "$task_json" 2>&1) || fail "append-task --validate-only failed"
  echo "$output" | grep -q '"valid": true' || fail "expected valid:true in append-task --validate-only output"

  local invalid_task_json='[{"id":"Task-Z-1"}]'
  if "$SUPER_PLAN_SCRIPT" append-task --input "$registry" --validate-only "$invalid_task_json" >"$tmp/invalid.log" 2>&1; then
    fail "append-task --validate-only accepted an invalid task array"
  fi
  assert_contains_file "missing required keys" "$tmp/invalid.log"
  assert_contains_file '"tasks": []' "$registry"

  local non_pending_task_json
  non_pending_task_json=${task_json/\"status\":\"pending\"/\"status\":\"in_progress\"}
  non_pending_task_json=${non_pending_task_json/\"baseCommit\":\"pending\"/\"baseCommit\":\"test-base-commit\"}
  if "$SUPER_PLAN_SCRIPT" append-task --input "$registry" --tasks "$non_pending_task_json" >"$tmp/non-pending.log" 2>&1; then
    fail "append-task accepted a task that skipped the pending state"
  fi
  assert_contains_file "New tasks must start with status pending" "$tmp/non-pending.log"
}

test_init_uses_documented_safe_defaults() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-sample/super-plan.json"

  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-sample \
    --feature-name sample \
    --spec docs/specs/0001-sample-spec.md \
    --plan docs/plans/0001-sample.md \
    --output "$registry" >/dev/null

  assert_contains_file '"enabled": false' "$registry"
  assert_contains_file '"executionMode": "sequential"' "$registry"
  assert_contains_file '"reviewCadence": "per_task"' "$registry"
}

test_task_lifecycle_rejects_skipped_review_and_accepts_reviewed_completion() {
  local tmp registry base
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" pending pending
  base=$(git -C "$REPO_ROOT" rev-parse HEAD)

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].status=completed >"$tmp/skipped-review.log" 2>&1; then
    fail "task completed without passing the review lifecycle"
  fi
  assert_contains_file "Invalid task Task-A-1 status transition: pending -> completed" "$tmp/skipped-review.log"

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set "tasks[Task-A-1].baseCommit=$base" >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status in_progress >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status ready_for_review >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status reviewing >/dev/null
  "$SUPER_PLAN_SCRIPT" complete-task --input "$registry" --task-id Task-A-1 >/dev/null
  assert_contains_file '"status": "completed"' "$registry"
}

test_plan_lifecycle_rejects_early_completion() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set status=completed >"$tmp/early-completion.log" 2>&1; then
    fail "plan completed directly from pending"
  fi
  assert_contains_file "Invalid plan status transition: pending -> completed" "$tmp/early-completion.log"
}

test_plan_lifecycle_accepts_reviewed_completion_when_all_gates_pass() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  "$SUPER_PLAN_SCRIPT" transition-plan --input "$registry" --status in_progress >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-plan --input "$registry" --status ready_for_review >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-plan --input "$registry" --status reviewing >/dev/null
  "$SUPER_PLAN_SCRIPT" complete-plan --input "$registry" >/dev/null
  assert_contains_file '"status": "completed"' "$registry"
}

test_completed_task_base_commit_rule_matches_schema() {
  local tmp registry schema
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  schema="$REPO_ROOT/super-planning/interfaces/super-plan.schema.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" completed pending

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set 'goal=trigger validation' >"$tmp/validator.log" 2>&1; then
    fail "registry validator accepted a completed task with baseCommit=pending"
  fi
  assert_contains_file "baseCommit" "$tmp/validator.log"

  if python3 -c "import jsonschema" 2>/dev/null; then
    if python3 - "$registry" "$schema" 2>"$tmp/schema-validation.log" <<'PY'
import json
import sys
import jsonschema

with open(sys.argv[1], encoding="utf-8") as handle:
    registry = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    schema = json.load(handle)
jsonschema.validate(registry, schema)
PY
    then
      fail "JSON schema accepted a completed task with baseCommit=pending"
    fi
  else
    echo "SKIP: jsonschema module not available, skipping completed-task schema agreement"
  fi
}

test_update_set_requirement_status() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set 'requirementsChecklist[REQ-001].status=completed' >/dev/null

  assert_contains_file '"status": "completed"' "$registry"

  local req_line
  req_line=$(grep -A5 '"id": "REQ-001"' "$registry" | grep '"status"' || true)
  echo "$req_line" | grep -q '"completed"' || fail "requirement status not updated to completed"
}

test_log_task_log_command() {
  local tmp log_file
  tmp=$(mktemp -d)
  log_file="$tmp/progress.log"
  mkdir -p "$(dirname "$log_file")"

  AGENTS_SKILLS_ORCHESTRATOR=1 "$LOG_TASK_SCRIPT" \
    --plan 0001-test \
    --task Task-A-1 \
    --event ready_for_review \
    --log-dir "$(dirname "$log_file")" \
    --try 1 \
    --max-tries 3 \
    --message "Ready for review" >/dev/null

  assert_exists "$log_file"
  assert_contains_file '"event":"ready_for_review"' "$log_file"
  assert_contains_file '"task":"Task-A-1"' "$log_file"
}

test_gitignore_template_contains_only_visual_companion_directory() {
  local template expected
  template="$REPO_ROOT/super-planning/templates/.gitignore-template"
  expected='brainstorm/'

  assert_exists "$template"
  if [ "$(cat "$template")" != "$expected" ]; then
    fail "$template must contain only: $expected"
  fi
}

test_bootstrap_materializes_complete_flat_manifest_with_source_provenance() {
  local tmp target commit doctor_output
  tmp=$(mktemp -d)
  target="$tmp/project/.super-planning"
  commit=$(git -C "$REPO_ROOT" rev-parse HEAD)

  sh "$BOOTSTRAP_SCRIPT" \
    --source-dir "$REPO_ROOT/super-planning" \
    --target-dir "$target" \
    --repo-url https://github.com/gugacarbo/agents-skills.git \
    --ref main \
    --commit "$commit" >/dev/null

  for file in super-plan.sh super-update.sh render-progress-ledger.sh log-task.sh review-package.sh render-task-md.sh summarize-all-tasks.sh doctor.sh bootstrap.sh super-plan.schema.json super-planning-reference.json; do
    assert_exists "$target/$file"
  done
  for file in start-server.sh stop-server.sh server.cjs helper.js frame-template.html; do
    assert_exists "$target/visual-companion/$file"
  done
  assert_contains_file '"repository": "https://github.com/gugacarbo/agents-skills.git"' "$target/super-planning-reference.json"
  assert_contains_file "\"commit\": \"$commit\"" "$target/super-planning-reference.json"

  doctor_output=$(cd "$REPO_ROOT" && sh "$DOCTOR_SCRIPT" --target-dir "$target" --visual)
  printf '%s\n' "$doctor_output" | grep -Fq 'PASS super-planning-reference.json' || fail "doctor did not validate bootstrap provenance"
}

test_visual_companion_background_lifecycle() {
  local tmp project session_dir stopped
  if ! command -v node >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    echo "SKIP: node and curl are required for visual companion lifecycle coverage"
    return 0
  fi

  tmp=$(mktemp -d)
  project="$tmp/project"
  mkdir -p "$project"
  bash "$REPO_ROOT/super-planning/scripts/visual-companion/start-server.sh" \
    --project-dir "$project" \
    --idle-timeout-minutes 1 >/dev/null
  session_dir=$(find "$project/.super-planning/brainstorm" -mindepth 1 -maxdepth 1 -type d -name '*-*' | head -n 1)
  [ -n "$session_dir" ] || fail "visual companion did not create a session directory"
  stopped=$(bash "$REPO_ROOT/super-planning/scripts/visual-companion/stop-server.sh" "$session_dir")
  printf '%s\n' "$stopped" | grep -Fq '"status": "stopped"' || fail "visual companion did not stop its background server"
}

test_render_task_md_invalid_task_id_exits_with_error() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  if "$RENDER_TASK_MD_SCRIPT" --input "$registry" --task-id Task-Z-9999 --output "$tmp/nowhere.md" 2>/dev/null; then
    fail "expected render-task-md.sh with invalid --task-id to fail"
  fi
}

main() {
  if [ "${SUPER_PLANNING_REVIEW_PACKAGE_ONLY:-0}" = "1" ]; then
    test_review_package_preserves_multiple_commits
    test_review_package_rejects_invalid_ref
    test_review_package_uses_full_hashes_for_default_output
    printf 'PASS: review-package.sh\n'
    return 0
  fi

  test_testing_guidance_and_spec_strategy_are_integrated
  test_init_generates_valid_registry_and_rich_empty_ledger
  test_render_progress_ledger_includes_complete_registry_snapshot
  test_update_rejects_invalid_status_without_mutating_file
  test_update_accepts_cancelled_task_status
  test_update_accepts_reviewing_task_status
  test_active_task_requires_base_commit
  test_update_rejects_invalid_task_profile_without_mutating_file
  test_render_progress_ledger_includes_timeline_and_requirements
  test_schema_validator_agreement
  test_materialized_logger_wrapper_writes_jsonl_events
  test_summarize_all_tasks_terminal_output
  test_summarize_all_tasks_json_output
  test_summarize_all_tasks_with_plan_id_filter
  test_summarize_all_tasks_with_example_data
  test_render_task_md_full_plan
  test_render_task_md_single_task
  test_render_task_md_empty_plan
  test_render_task_md_invalid_task_id_exits_with_error
  test_append_task_validate_only
  test_init_uses_documented_safe_defaults
  test_task_lifecycle_rejects_skipped_review_and_accepts_reviewed_completion
  test_plan_lifecycle_rejects_early_completion
  test_plan_lifecycle_accepts_reviewed_completion_when_all_gates_pass
  test_completed_task_base_commit_rule_matches_schema
  test_update_set_requirement_status
  test_log_task_log_command
  test_gitignore_template_contains_only_visual_companion_directory
  test_bootstrap_materializes_complete_flat_manifest_with_source_provenance
  test_visual_companion_background_lifecycle

  printf 'PASS: super-planning.sh\n'
}

main "$@"
