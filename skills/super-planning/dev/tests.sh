#!/usr/bin/env bash

set -euo pipefail

command -v python3 >/dev/null 2>&1 || { echo "SKIP: python3 required for schema validation and inline validator"; exit 0; }

SCRIPT_DIR=$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P
)
REPO_ROOT=$(
  CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P
)
SUPER_PLAN_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/super-plan.sh"
RENDER_LEDGER_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/render-progress-ledger.sh"
LOG_TASK_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/log-task.sh"
SUMMARIZE_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/summarize-all-tasks.sh"
RENDER_TASK_MD_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/render-task-md.sh"
REVIEW_PACKAGE_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/review-package.sh"
BOOTSTRAP_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/bootstrap.sh"
DOCTOR_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/doctor.sh"

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

test_worktree_decision_gate_is_documented_and_safe_by_default() {
  local skill phase4 phase5 workflow
  skill="$REPO_ROOT/skills/super-planning/SKILL.md"
  phase4="$REPO_ROOT/skills/super-planning/phases/04-decompose.md"
  phase5="$REPO_ROOT/skills/super-planning/phases/05-dispatch.md"
  workflow="$REPO_ROOT/skills/super-planning/phases/04_1-using-git-worktrees.md"

  assert_contains_file "before defining or changing the implementation branch" "$skill"
  assert_contains_file "Should implementation use an isolated Git worktree?" "$phase4"
  assert_contains_file "The branch is not considered defined until the user answers this gate." "$phase4"
  assert_contains_file "Phase 4.1 worktree workflow" "$phase5"
  assert_contains_file "Do not ask for worktree consent again." "$workflow"
  [ ! -e "$REPO_ROOT/skills/using-git-worktrees/SKILL.md" ] || fail "worktree workflow must be embedded in super-planning"

  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-safe-default/super-plan.json"
  "$SUPER_PLAN_SCRIPT" init \
    --plan-id 0001-safe-default \
    --feature-name safe-default \
    --spec docs/specs/0001-safe-default-spec.md \
    --plan docs/plans/0001-safe-default.md \
    --output "$registry" >/dev/null
  python3 - "$registry" <<'PY'
import json, sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert payload["worktree"] == {"enabled": False, "path": ""}
PY
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
        "generalExecutor": {"model": "gpt-5", "agent": "general-executor", "effort": "medium"},
        "deepExecutor": {"model": "gpt-5", "agent": "deep-executor", "effort": "high"},
        "taskReviewer": {"model": "gpt-5", "agent": "task-reviewer", "effort": "medium"},
        "investigator": {"model": "gpt-5", "agent": "investigator", "effort": "medium"},
        "specReviewer": {"model": "gpt-5", "agent": "spec-reviewer", "effort": "medium"},
        "finalAuditor": {"model": "gpt-5", "agent": "final-auditor", "effort": "high"},
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
    task("Task-C-1", "Adicionar testes de autenticação", "general", "C", "surface", dependencies=["Task-B-1"]),
    task("Task-D-1", "Integrar middleware nas rotas", "general", "D", "surface", dependencies=["Task-B-1"]),
    task("Task-E-1", "Revisar documentação", "general", "E", "final", dependencies=["Task-D-1"]),
]
payload["tasks"][0]["filesTouched"] = ["src/types/auth.ts"]
payload["tasks"][0]["files"]["created"] = ["src/types/auth.ts"]
registry.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

root = registry.parent
for task_entry in payload["tasks"]:
    task_dir = root / task_entry["id"]
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "report.md").write_text("# Report\n\n# Process: super-planning\n", encoding="utf-8")
    (task_dir / "review-package.diff.md").write_text("# Review package\n\n# Process: super-planning\n", encoding="utf-8")
    (task_dir / "progress.log").write_text(
        "{" + f'\"timestamp\":\"2026-07-04T14:09:00Z\",\"task\":\"{task_entry["id"]}\",\"event\":\"ready_for_review\",\"try\":1,\"message\":\"Ready for review\"' + "}\n"
        + "{" + f'\"timestamp\":\"2026-07-04T14:10:00Z\",\"task\":\"{task_entry["id"]}\",\"event\":\"completed\",\"try\":1,\"message\":\"Review clean; accepted by orchestrator\"' + "}\n",
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
  template="$REPO_ROOT/skills/super-planning/templates/testing-anti-patterns.md"
  evals="$REPO_ROOT/skills/super-planning/evals/evals.json"

  assert_exists "$template"
  assert_exists "$evals"
  assert_contains_file "## Test Strategy" "$REPO_ROOT/skills/super-planning/templates/spec-template.md"
  assert_contains_file "testing-anti-patterns.md" "$REPO_ROOT/skills/super-planning/phases/02-spec.md"
  assert_contains_file "Should this spec use TDD" "$REPO_ROOT/skills/super-planning/prompts/pre-write-approval.md"
  assert_contains_file "TDD required for this behavior-changing task" "$REPO_ROOT/skills/super-planning/phases/04-decompose.md"
  assert_contains_file "testing guidance" "$REPO_ROOT/skills/super-planning/agents/general-executor.md"
  assert_exists "$REPO_ROOT/skills/super-planning/agents/deep-executor.md"
  assert_exists "$REPO_ROOT/skills/super-planning/agents/investigator.md"
  assert_contains_file "generalExecutor" "$REPO_ROOT/skills/super-planning/phases/05-dispatch.md"
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
  assert_contains_file '"generalExecutor": {' "$registry"
  assert_contains_file '"finalAuditor": {' "$registry"
  assert_contains_file '"model": ""' "$registry"
  assert_contains_file '"agent": ""' "$registry"
  assert_contains_file '"effort": ""' "$registry"
  assert_contains_file "# Progress Ledger: sample" "$ledger"
  assert_contains_file "## Summary" "$ledger"
  assert_contains_file "| pending | 0 |" "$ledger"
  assert_contains_file "## Agent Profiles" "$ledger"
  assert_contains_file "| generalExecutor | default | default | default |" "$ledger"
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
    --set 'agents.generalExecutor.model=gpt-5-mini' \
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
  schema="$REPO_ROOT/skills/super-planning/interfaces/super-plan.schema.json"
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

  # Agent profile effort must remain a string.
  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set agents.generalExecutor.effort=true >"$tmp/output.log" 2>&1; then
    fail "expected non-string effort update to fail"
  fi
  assert_contains_file '"agents.generalExecutor.effort must be a string"' "$tmp/output.log"
}

test_schema_validator_agreement() {
  if ! python3 -c "import jsonschema" 2>/dev/null; then
    echo "SKIP: jsonschema module not available, skipping schema validator agreement test"
    return
  fi

  local tmp schema
  tmp=$(mktemp -d)
  schema="$REPO_ROOT/skills/super-planning/interfaces/super-plan.schema.json"

  python3 -c "
import json, jsonschema, sys
from datetime import datetime, timezone

# Build a minimal valid plan
now = datetime.now(timezone.utc).isoformat()
plan = {
    '\$schema': 'https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills/super-planning/interfaces/super-plan.schema.json',
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
        'generalExecutor': {'model': '', 'agent': '', 'effort': ''},
        'deepExecutor': {'model': '', 'agent': '', 'effort': ''},
        'taskReviewer': {'model': '', 'agent': '', 'effort': ''},
        'investigator': {'model': '', 'agent': '', 'effort': ''},
        'specReviewer': {'model': '', 'agent': '', 'effort': ''},
        'finalAuditor': {'model': '', 'agent': '', 'effort': ''},
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

  # Check every authoritative enum and the critical required-field contracts.
  python3 -c "
import json, jsonschema, sys
with open('$schema') as f:
    s = json.load(f)
expected_root = {'\$schema', 'planId', 'featureName', 'status', 'source', 'goal', 'architectureSummary', 'techStack', 'executionMode', 'reviewCadence', 'agents', 'branchStrategy', 'worktree', 'globalConstraints', 'fileStructure', 'requirementsChecklist', 'taskDirectory', 'rules', 'tasks'}
if set(s['required']) != expected_root:
    print('Schema root required keys drifted', file=sys.stderr)
    sys.exit(1)
expected = {'pending', 'in_progress', 'ready_for_review', 'reviewing', 'needs_fix', 'blocked', 'completed', 'cancelled'}
for label, node in {
    'plan': s['properties']['status'],
    'task': s['\$defs']['task']['properties']['status'],
    'requirement': s['\$defs']['requirement']['properties']['status'],
}.items():
    actual = set(node['enum'])
    if actual != expected:
        print(f'Schema {label} status enum mismatch: extra={actual-expected} missing={expected-actual}', file=sys.stderr)
        sys.exit(1)
task_required = set(s['\$defs']['task']['required'])
for field in {'tryCount', 'maxTries', 'layer', 'reportFile', 'reviewPackage', 'progressLog', 'baseCommit'}:
    if field not in task_required:
        print(f'Schema task contract is missing {field}', file=sys.stderr)
        sys.exit(1)
print('Schema contract: PASS')
" || fail "schema and validator status enums disagree"
}

test_validator_rejects_try_count_above_max_tries() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set 'tasks[Task-A-1].tryCount=4' >"$tmp/try-count.log" 2>&1; then
    fail "validator accepted tryCount greater than maxTries"
  fi
  assert_contains_file 'tryCount must be <= maxTries' "$tmp/try-count.log"
}

test_validator_rejects_schema_forbidden_extra_task_property() {
  local tmp registry
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set 'tasks[Task-A-1].undocumentedField=true' >"$tmp/extra-property.log" 2>&1; then
    fail "validator accepted a task property forbidden by the schema"
  fi
  assert_contains_file 'unexpected keys: undocumentedField' "$tmp/extra-property.log"
}

test_completed_task_requires_review_artifacts_and_event() {
  local tmp registry base task_dir
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"
  set_task_state_directly "$registry" "Task-A-1" pending pending
  base=$(git -C "$REPO_ROOT" rev-parse HEAD)
  task_dir="$(dirname "$registry")/Task-A-1"

  "$SUPER_PLAN_SCRIPT" update --input "$registry" --set "tasks[Task-A-1].baseCommit=$base" >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status in_progress >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status ready_for_review >/dev/null
  "$SUPER_PLAN_SCRIPT" transition-task --input "$registry" --task-id Task-A-1 --status reviewing >/dev/null

  rm "$task_dir/review-package.diff.md"
  if "$SUPER_PLAN_SCRIPT" complete-task --input "$registry" --task-id Task-A-1 >"$tmp/missing-artifact.log" 2>&1; then
    fail "task completed without its review package"
  fi
  assert_contains_file 'cannot complete without reviewPackage' "$tmp/missing-artifact.log"
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
  assert_contains_file "| generalExecutor | gpt-5 | general-executor | medium |" "$ledger"
  assert_contains_file "## Tasks" "$ledger"
  assert_contains_file "| Task-A-1 | Definir tipos e interfaces de autenticação | general → generalExecutor | A | foundation | [DONE] completed | — |" "$ledger"
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
  "task_profile": "deep",
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

RENDER_TASK_MD_SCRIPT="$REPO_ROOT/skills/super-planning/scripts/render-task-md.sh"

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
  assert_contains_file "| generalExecutor | default | default | default |" "$md_file"
}

test_new_registry_rejects_quick_but_legacy_registry_remains_valid() {
  local tmp registry before
  tmp=$(mktemp -d)
  registry="$tmp/docs/jobs/0001-auth-middleware/super-plan.json"
  mkdir -p "$(dirname "$registry")"
  create_test_plan_fixture "$registry"

  before=$(cat "$registry")
  if "$SUPER_PLAN_SCRIPT" update --input "$registry" --set tasks[Task-A-1].task_profile=quick >"$tmp/new-format.log" 2>&1; then
    fail "expected quick task profile to fail for a role-profile registry"
  fi
  [ "$(cat "$registry")" = "$before" ] || fail "new registry changed after rejected quick task profile"
  assert_contains_file "for role agents" "$tmp/new-format.log"

  python3 - "$registry" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["agents"] = {
    "general": {"model": "gpt-5", "agent": "general", "effort": "medium"},
    "deep": {"model": "gpt-5", "agent": "deep", "effort": "high"},
    "quick": {"model": "gpt-5-mini", "agent": "quick", "effort": "low"},
}
payload["tasks"][0]["task_profile"] = "quick"
path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

  "$SUPER_PLAN_SCRIPT" validate --input "$registry" >/dev/null || fail "legacy registry with quick profile was rejected"
  "$RENDER_LEDGER_SCRIPT" --input "$registry" --output "$tmp/legacy-ledger.md" >/dev/null
  assert_contains_file "| quick | gpt-5-mini | quick | low |" "$tmp/legacy-ledger.md"
  assert_contains_file "| Task-A-1 | Definir tipos e interfaces de autenticação | quick |" "$tmp/legacy-ledger.md"
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
  schema="$REPO_ROOT/skills/super-planning/interfaces/super-plan.schema.json"
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
  template="$REPO_ROOT/skills/super-planning/templates/.gitignore-template"
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
    --source-dir "$REPO_ROOT/skills/super-planning" \
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
  bash "$REPO_ROOT/skills/super-planning/scripts/visual-companion/start-server.sh" \
    --project-dir "$project" \
    --idle-timeout-minutes 1 >/dev/null
  session_dir=$(find "$project/.super-planning/brainstorm" -mindepth 1 -maxdepth 1 -type d -name '*-*' | head -n 1)
  [ -n "$session_dir" ] || fail "visual companion did not create a session directory"
  stopped=$(bash "$REPO_ROOT/skills/super-planning/scripts/visual-companion/stop-server.sh" "$session_dir")
  printf '%s\n' "$stopped" | grep -Fq '"status": "stopped"' || fail "visual companion did not stop its background server"
}

test_job_dashboard() {
  local tmp project jobs plan output url port pid cookie snapshot state_dir status ws_output token nested_project symlink_project outside_state stop_project no_state_project stale_project stale_lock state_link_project sentinel probe_project probe_state probe_helper probe_server stop_helper mock_bin system_path handoff_project handoff_state handoff_helper handoff_server handoff_start pid_safety_project pid_safety_state pid_safety_pid pid_safety_mode failure_project failure_state failure_helper successor_output successor_pid occupied_project occupied_output occupied_port
  local dashboard_dir serve_script
  dashboard_dir="$REPO_ROOT/skills/super-planning/scripts/job-dashboard"
  serve_script="$dashboard_dir/serve-jobs.sh"

  if ! command -v node >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v flock >/dev/null 2>&1; then
    echo "SKIP: node, curl, and flock are required for job dashboard coverage"
    return 0
  fi

  assert_exists "$serve_script"
  assert_exists "$dashboard_dir/server.cjs"
  assert_exists "$dashboard_dir/app.js"
  assert_exists "$dashboard_dir/styles.css"

  tmp=$(mktemp -d)
  system_path=$PATH
  mkdir -p "$tmp/empty/docs/jobs"
  output=$(bash "$serve_script" --project-dir "$tmp/empty" --host 127.0.0.1 --url-host 127.0.0.1) || fail "empty jobs root did not start"
  url=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])')
  snapshot=$(curl -sf "${url%/?key=*}/api/snapshot?key=${url##*key=}") || fail "empty jobs root snapshot failed"
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["totalPlans"] == 0 and d["grandTotal"]["totalTasks"] == 0' || fail "empty jobs root did not return zero totals"
  bash "$serve_script" --stop --project-dir "$tmp/empty" >/dev/null || fail "empty jobs root did not stop"
  bash "$serve_script" --project-dir "$tmp/empty" --host 127.0.0.1 --url-host 127.0.0.1 --foreground >"$tmp/foreground.out" 2>"$tmp/foreground.err" &
  foreground_pid=$!
  for _ in $(seq 1 30); do
    [ -f "$tmp/empty/.super-planning/job-dashboard/server-info.json" ] && break
    sleep 0.1
  done
  [ -f "$tmp/empty/.super-planning/job-dashboard/server-info.json" ] || fail "foreground dashboard did not start"
  foreground_port=$(node -e 'console.log(require(process.argv[1]).port)' "$tmp/empty/.super-planning/job-dashboard/server-info.json")
  foreground_token=$(tr -d '[:space:]' < "$tmp/empty/.super-planning/job-dashboard/session-token")
  curl -fsS "http://127.0.0.1:$foreground_port/healthz?key=$foreground_token" >/dev/null || fail "foreground dashboard health check failed"
  bash "$serve_script" --stop --project-dir "$tmp/empty" >/dev/null || fail "foreground dashboard did not stop"
  wait "$foreground_pid" || true

  nested_project="$tmp/nested-state"
  mkdir -p "$nested_project/.super-planning"
  if bash "$serve_script" --project-dir "$nested_project" --base-dir "$nested_project/.super-planning" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/nested-state.out" 2>"$tmp/nested-state.err"; then
    fail "dashboard started with runtime state nested below the jobs root"
  fi
  assert_contains_file "runtime state directory must not be inside jobs root" "$tmp/nested-state.err"
  [ ! -e "$nested_project/.super-planning/job-dashboard" ] || fail "nested jobs root startup wrote runtime state before rejection"

  symlink_project="$tmp/symlinked-state"
  outside_state="$tmp/outside-state"
  mkdir -p "$symlink_project/docs/jobs" "$outside_state"
  ln -s "$outside_state" "$symlink_project/.super-planning"
  if bash "$serve_script" --project-dir "$symlink_project" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/symlinked-state.out" 2>"$tmp/symlinked-state.err"; then
    fail "dashboard started with .super-planning symlinked outside the project"
  fi
  assert_contains_file "runtime state directory must remain inside project directory" "$tmp/symlinked-state.err"
  [ ! -e "$outside_state/job-dashboard" ] || fail "symlinked runtime state wrote outside the project before rejection"

  stop_project="$tmp/stop-nested-state"
  mkdir -p "$stop_project/.super-planning"
  if bash "$serve_script" --stop --project-dir "$stop_project" --base-dir "$stop_project/.super-planning" >"$tmp/stop-nested-state.out" 2>"$tmp/stop-nested-state.err"; then
    fail "dashboard stop accepted a jobs root containing its runtime state"
  fi
  assert_contains_file "runtime state directory must not be inside jobs root" "$tmp/stop-nested-state.err"
  [ ! -e "$stop_project/.super-planning/job-dashboard" ] || fail "nested jobs root stop wrote runtime state before rejection"

  no_state_project="$tmp/stop-no-state"
  mkdir -p "$no_state_project/docs/jobs"
  output=$(bash "$serve_script" --stop --project-dir "$no_state_project") || fail "stop without runtime state failed"
  printf '%s' "$output" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d == {"type":"job-dashboard-stopped","status":"not_running"}' || fail "stop without runtime state did not report not_running"
  [ ! -e "$no_state_project/.super-planning" ] || fail "stop without runtime state created state directories"

  project="$tmp/project"
  jobs="$project/docs/jobs"
  plan="$jobs/0001-dashboard"
  cookie="$tmp/cookies.txt"
  mkdir -p "$plan/Task-A-1"
  cat > "$plan/super-plan.json" <<'JSON'
{
  "planId": "0001-dashboard",
  "featureName": "<script>literal plan</script>",
  "status": "in_progress",
  "requirementsChecklist": [{"id":"REQ-1","title":"Literal requirement","status":"pending","coveredByTasks":["Task-A-1"]}],
  "tasks": [{"id":"Task-A-1","title":"<img src=x onerror=alert(1)>","status":"in_progress","tryCount":1,"maxTries":3,"batch":"A","layer":"core","dependencies":[]}]
}
JSON
  printf '%s\n' '{"timestamp":"2026-07-13T12:00:00Z","event":"started","message":"literal <script>event</script>"}' > "$plan/Task-A-1/progress.log"

  output=$(bash "$serve_script" --project-dir "$project" --host 127.0.0.1 --url-host 127.0.0.1 --refresh-ms 250) || fail "job dashboard did not start"
  printf '%s' "$output" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["type"] == "job-dashboard-started"; assert d["url"].startswith("http://127.0.0.1:")' || fail "dashboard startup output is not the documented JSON"
  url=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])')
  port=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["port"])')
  pid=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pid"])')
  state_dir=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state_dir"])')

  status=$(curl -s -o "$tmp/unauthorized" -w '%{http_code}' "http://127.0.0.1:$port/api/snapshot")
  [ "$status" = 403 ] || fail "unauthenticated snapshot did not return 403"
  if grep -Fq '0001-dashboard' "$tmp/unauthorized"; then fail "unauthenticated response exposed plan data"; fi

  status=$(curl -s -D "$tmp/bootstrap.headers" -c "$cookie" -o /dev/null -w '%{http_code}' "$url")
  [ "$status" = 302 ] || fail "key bootstrap did not redirect"
  assert_contains_file 'Location: /' "$tmp/bootstrap.headers"
  assert_contains_file 'HttpOnly' "$tmp/bootstrap.headers"
  assert_contains_file "connect-src 'self';" "$tmp/bootstrap.headers"
  if grep -Fq ' ws:' "$tmp/bootstrap.headers"; then fail "dashboard CSP permits arbitrary WebSocket origins"; fi
  token=${url##*key=}
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot") || fail "authenticated snapshot failed"
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); g=d["grandTotal"]; assert d["type"]=="job-snapshot" and d["version"]==1 and d["totalPlans"]==1 and g["totalTasks"]==1 and g["taskCounts"]["in_progress"]==1 and g["totalReqs"]==1 and g["reqCounts"]["pending"]==1; t=d["plans"][0]["tasks"][0]; assert t["eventCount"]==1 and len(t["recentEvents"])==1; assert not d["plans"][0]["registryPath"].startswith("/")' || fail "snapshot did not preserve dashboard contract"

  node - "$port" "$cookie" "$tmp/ws.json" <<'NODE' &
const fs = require('node:fs');
const net = require('node:net');
const crypto = require('node:crypto');
const [port, cookie, output] = process.argv.slice(2);
const key = crypto.randomBytes(16).toString('base64');
let raw = Buffer.alloc(0), upgraded = false, snapshots = [];
const socket = net.connect(Number(port), '127.0.0.1');
const finish = (code) => { fs.writeFileSync(output, JSON.stringify(snapshots)); socket.destroy(); process.exit(code); };
const timer = setTimeout(() => finish(1), 5000);
socket.on('connect', () => socket.write(`GET /ws HTTP/1.1\r\nHost: 127.0.0.1:${port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ${key}\r\nSec-WebSocket-Version: 13\r\nOrigin: http://127.0.0.1:${port}\r\nCookie: ${fs.readFileSync(cookie, 'utf8').split('\n').filter((line) => line.includes('\t')).map((line) => { const p=line.split('\t'); return `${p[5]}=${p[6]}`; }).join('; ')}\r\n\r\n`));
socket.on('data', (chunk) => {
  raw = Buffer.concat([raw, chunk]);
  if (!upgraded) { const end = raw.indexOf('\r\n\r\n'); if (end < 0) return; if (!raw.subarray(0, end).toString().startsWith('HTTP/1.1 101')) finish(2); raw = raw.subarray(end + 4); upgraded = true; }
  while (raw.length >= 2) { let n = raw[1] & 127, offset = 2; if (n === 126) { if (raw.length < 4) return; n = raw.readUInt16BE(2); offset = 4; } else if (n === 127) { if (raw.length < 10) return; n = Number(raw.readBigUInt64BE(2)); offset = 10; } if (raw.length < n + offset) return; const text = raw.subarray(offset, n + offset).toString(); raw = raw.subarray(n + offset); const message = JSON.parse(text); if (message.type === 'job-snapshot') snapshots.push(message); if (snapshots.length === 2) { clearTimeout(timer); finish(0); } }
});
socket.on('error', () => finish(3));
NODE
  ws_pid=$!
  sleep 0.4
  mkdir -p "$jobs/0002-second"
  python3 - "$jobs/0002-second/super-plan.json" <<'PY'
import json, sys
path = sys.argv[1]
open(path, 'w', encoding='utf-8').write(json.dumps({"planId":"0002-second","featureName":"second","status":"pending","requirementsChecklist":[],"tasks":[{"id":"Task-B-1","title":"new task","status":"pending","tryCount":1,"maxTries":3,"batch":"B","layer":"core","dependencies":[]}]}))
PY
  wait "$ws_pid" || fail "authenticated WebSocket did not receive snapshots"
  ws_output=$(cat "$tmp/ws.json")
  printf '%s' "$ws_output" | python3 -c 'import json,sys; a=json.load(sys.stdin); assert len(a)==2 and a[0]["totalPlans"]==1 and a[1]["totalPlans"]==2 and a[1]["grandTotal"]["totalTasks"]==2' || fail "WebSocket did not deliver initial and changed snapshots"

  printf '{invalid\n' > "$plan/super-plan.json"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["totalPlans"]==2 and any("0001-dashboard/super-plan.json" in w for w in d["warnings"])' || fail "malformed registry did not retain last valid plan with warning"
  python3 - "$plan/super-plan.json" <<'PY'
import json, sys
open(sys.argv[1], 'w', encoding='utf-8').write(json.dumps({"planId":"0001-dashboard","featureName":"recovered","status":"in_progress","requirementsChecklist":[],"tasks":[{"id":"Task-A-1","title":"recovered","status":"completed","tryCount":1,"maxTries":3,"batch":"A","layer":"core","dependencies":[]}]}))
PY
  for i in $(seq 1 205); do printf '{"timestamp":"2026-07-13T12:00:%02dZ","event":"tick"}\n' "$((i % 60))"; done > "$plan/Task-A-1/progress.log"
  printf 'not json\n' >> "$plan/Task-A-1/progress.log"
  sleep 0.5
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); p=d["plans"][0]; t=p["tasks"][0]; assert p["featureName"]=="recovered" and t["eventCount"]==205 and len(t["recentEvents"])==200 and not any("super-plan.json" in w for w in d["warnings"]) and any("progress.log" in w for w in d["warnings"])' || fail "JSONL cap, warning, or recovery behavior failed"
  for i in $(seq 1 205); do printf '{"timestamp":"2026-07-13T12:01:%02dZ","event":"recovered"}\n' "$((i % 60))"; done > "$plan/Task-A-1/progress.log"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); t=d["plans"][0]["tasks"][0]; assert t["eventCount"]==205 and not any("progress.log" in w for w in d["warnings"])' || fail "recovered JSONL did not remove its warning"
  printf '\n' >> "$plan/Task-A-1/progress.log"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); t=d["plans"][0]["tasks"][0]; assert t["eventCount"]==205 and any("progress.log: malformed JSONL line" in w for w in d["warnings"])' || fail "blank JSONL line did not preserve valid events with a warning"
  for i in $(seq 1 205); do printf '{"timestamp":"2026-07-13T12:02:%02dZ","event":"recovered-again"}\n' "$((i % 60))"; done > "$plan/Task-A-1/progress.log"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert not any("progress.log" in w for w in d["warnings"])' || fail "blank JSONL warning did not clear after recovery"
  : > "$plan/Task-A-1/progress.log"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); t=d["plans"][0]["tasks"][0]; assert t["eventCount"]==0 and not any("progress.log" in w for w in d["warnings"])' || fail "zero-byte JSONL did not produce zero events without a warning"
  for i in $(seq 1 205); do printf '{"timestamp":"2026-07-13T12:03:%02dZ","event":"recovered-after-empty"}\n' "$((i % 60))"; done > "$plan/Task-A-1/progress.log"
  sleep 0.4
  assert_contains_file 'textContent' "$dashboard_dir/app.js"
  assert_contains_file 'Last successful update' "$dashboard_dir/app.js"
  assert_contains_file 'LIFECYCLE_STATUSES' "$dashboard_dir/app.js"
  assert_contains_file 'Covered by:' "$dashboard_dir/app.js"
  if grep -Fq 'innerHTML' "$dashboard_dir/app.js"; then fail "dashboard app uses unsafe innerHTML"; fi
  node - "$dashboard_dir/app.js" <<'NODE'
const fs = require('node:fs'); const vm = require('node:vm');
class Element {
  constructor(tag) { this.tagName = tag; this.children = []; this.className = ''; this.textContent = ''; this.value = ''; }
  get options() { return this.children; }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = children; }
  addEventListener() {}
}
const root = new Element('main');
const context = { document: { querySelector: (selector) => selector === '#app' ? root : null, createElement: (tag) => new Element(tag) }, WebSocket: class { addEventListener() {} }, location: { protocol: 'http:', host: 'dashboard.test' }, setTimeout() {} };
const render = vm.runInNewContext(`${fs.readFileSync(process.argv[2], 'utf8')}\nrender`, context);
render({ totalPlans: 2, generatedAt: 'now', grandTotal: { taskCounts: {}, reqCounts: {} }, warnings: ['0001-dashboard/super-plan.json: malformed or unreadable registry', '0001-dashboard/Task-A-1/progress.log: malformed JSONL line', '0002-other/super-plan.json: malformed or unreadable registry'], plans: [
  { planId: '0001-dashboard', featureName: 'one', registryPath: 'docs/jobs/0001-dashboard/super-plan.json', planStatus: 'pending', completionPercent: 0, completedReqs: 0, totalReqs: 0, taskCounts: {}, requirements: [], tasks: [], totalTasks: 0 },
  { planId: '0002-other', featureName: 'two', registryPath: 'docs/jobs/0002-other/super-plan.json', planStatus: 'pending', completionPercent: 0, completedReqs: 0, totalReqs: 0, taskCounts: {}, requirements: [], tasks: [], totalTasks: 0 }
] });
const visit = (element, found = []) => { if (element.className === 'plan-warning') found.push(element.textContent); for (const child of element.children) visit(child, found); return found; };
const indicators = visit(root); if (JSON.stringify(indicators) !== JSON.stringify(['Warning: 2 issues', 'Warning: 1 issue'])) process.exit(1);
NODE
  [ "$?" = 0 ] || fail "plan cards did not expose registry-specific warning indicators"

  node - "$port" "$token" <<'NODE'
const net = require('node:net'); const crypto = require('node:crypto'); const [port, token] = process.argv.slice(2);
const socket = net.connect(port, '127.0.0.1'); let text = '';
socket.on('connect', () => socket.write(`GET /ws?key=${token} HTTP/1.1\r\nHost: 127.0.0.1:${port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ${crypto.randomBytes(16).toString('base64')}\r\nSec-WebSocket-Version: 13\r\nOrigin: http://evil.example\r\n\r\n`));
socket.on('data', (chunk) => { text += chunk; }); socket.on('close', () => process.exit(text.includes('101') ? 1 : 0)); socket.on('error', () => process.exit(0)); setTimeout(() => { socket.destroy(); process.exit(text.includes('101') ? 1 : 0); }, 1000);
NODE

  mkdir -p "$tmp/outside/Task-A-1"
  printf '%s\n' '# external report must never be read' > "$tmp/outside/Task-A-1/report.md"
  printf '%s\n' '{"event":"external"}' > "$tmp/outside/Task-A-1/progress.log"
  rm -rf "$plan/Task-A-1"
  ln -s "$tmp/outside/Task-A-1" "$plan/Task-A-1"
  mkdir -p "$tmp/outside/linked-plan"
  printf '%s\n' '{"planId":"outside","tasks":[]}' > "$tmp/outside/linked-plan/super-plan.json"
  ln -s "$tmp/outside/linked-plan" "$jobs/linked-plan"
  sleep 0.4
  snapshot=$(curl -sf -b "$cookie" "http://127.0.0.1:$port/api/snapshot")
  printf '%s' "$snapshot" | python3 -c 'import json,sys; d=json.load(sys.stdin); raw=json.dumps(d); t=d["plans"][0]["tasks"][0]; assert d["totalPlans"]==2 and t["eventCount"]==205 and t["reportSummary"] is None and "external report" not in raw and "outside" not in [p["planId"] for p in d["plans"]] and any("rejected progress log outside jobs root" in w for w in d["warnings"])' || fail "symlinked task, report, progress, or registry escaped jobs-root containment"

  mkdir -p "$tmp/occupied/docs/jobs"
  if bash "$serve_script" --project-dir "$tmp/occupied" --host 127.0.0.1 --url-host 127.0.0.1 --port "$port" >"$tmp/occupied.out" 2>"$tmp/occupied.err"; then
    fail "explicit occupied dashboard port unexpectedly succeeded"
  fi

  mkdir -p "$project/docs/alternate-jobs"
  output=$(bash "$serve_script" --project-dir "$project" --base-dir "$project/docs/alternate-jobs" --host 127.0.0.2 --url-host 127.0.0.2) || fail "healthy dashboard was not reused with a different host"
  printf '%s' "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['pid'] == $pid and d['port'] == $port and d['url'].startswith('http://127.0.0.1:') and d['base_dir'] == '$jobs'" || fail "duplicate dashboard start did not reuse the active metadata host, port, and base directory"
  node -e "const i=require(process.argv[1]); if (i.baseDir !== process.argv[2]) process.exit(1)" "$state_dir/server-info.json" "$jobs" || fail "server metadata did not retain the canonical active base directory"
  [ -f "$state_dir/server.pid" ] && [ -f "$state_dir/server-info.json" ] || fail "different-host reuse cleared active dashboard metadata"
  bash "$serve_script" --stop --project-dir "$project" >/dev/null || fail "dashboard stop failed"
  if kill -0 "$pid" 2>/dev/null; then fail "dashboard process remained after stop"; fi
  [ ! -e "$state_dir/server.pid" ] || fail "dashboard left live pid metadata after stop"
  printf '%s\n' "$$" > "$state_dir/server.pid"
  printf '%s\n' 'not-the-dashboard' > "$state_dir/server-instance-id"
  output=$(bash "$serve_script" --stop --project-dir "$project") || fail "stale PID cleanup failed"
  printf '%s' "$output" | grep -Fq 'stale_pid' || fail "stale PID was not reported safely"

  # A missing or malformed instance proof must never degrade into a PID-only
  # stop.  Each case uses a real live dashboard and proves the helper reports
  # stale metadata without signalling that process or clearing its token.
  for pid_safety_mode in absent invalid; do
    pid_safety_project="$tmp/stop-proof-$pid_safety_mode"
    mkdir -p "$pid_safety_project/docs/jobs"
    output=$(bash "$serve_script" --project-dir "$pid_safety_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "dashboard did not start for $pid_safety_mode instance proof coverage"
    pid_safety_pid=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pid"])')
    pid_safety_state=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state_dir"])')
    if [[ "$pid_safety_mode" == absent ]]; then
      rm -f "$pid_safety_state/server-instance-id"
    else
      printf '%s\n' 'invalid-instance-id' > "$pid_safety_state/server-instance-id"
    fi
    output=$(bash "$serve_script" --stop --project-dir "$pid_safety_project") || fail "stop rejected stale $pid_safety_mode instance proof"
    printf '%s' "$output" | python3 -c 'import json,sys; assert json.load(sys.stdin) == {"type":"job-dashboard-stopped","status":"stale_pid"}' || fail "stop did not report stale_pid for $pid_safety_mode instance proof"
    kill -0 "$pid_safety_pid" 2>/dev/null || fail "stop signalled the live dashboard with $pid_safety_mode instance proof"
    [ ! -e "$pid_safety_state/server.pid" ] && [ ! -e "$pid_safety_state/server-instance-id" ] && [ ! -e "$pid_safety_state/server-info.json" ] || fail "stop did not clear only stale lifecycle metadata for $pid_safety_mode instance proof"
    [ -f "$pid_safety_state/session-token" ] || fail "stop removed the session token for $pid_safety_mode instance proof"
    kill -TERM "$pid_safety_pid"
    for _ in $(seq 1 30); do kill -0 "$pid_safety_pid" 2>/dev/null || break; sleep 0.1; done
    if kill -0 "$pid_safety_pid" 2>/dev/null; then fail "PID safety fixture did not terminate after direct cleanup"; fi
  done

  # Force a child bind failure after the original helper has handed off its
  # lock.  While its deterministic cleanup gate is paused, a successor starts
  # and publishes fresh metadata.  The original must reacquire the lifecycle
  # lock and leave that successor intact when it finally cleans up.
  occupied_project="$tmp/failed-launch-occupier"
  failure_project="$tmp/failed-launch-race"
  failure_state="$failure_project/.super-planning/job-dashboard"
  mkdir -p "$occupied_project/docs/jobs" "$failure_project/docs/jobs"
  occupied_output=$(bash "$serve_script" --project-dir "$occupied_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "failed-launch race occupier did not start"
  occupied_port=$(printf '%s' "$occupied_output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["port"])')
  DASHBOARD_TEST_PAUSE_BEFORE_FAILURE_CLEANUP=1 bash "$serve_script" --project-dir "$failure_project" --host 127.0.0.1 --url-host 127.0.0.1 --port "$occupied_port" >"$tmp/failed-launch-original.out" 2>"$tmp/failed-launch-original.err" &
  failure_helper=$!
  for _ in $(seq 1 50); do
    [ -f "$failure_state/.test-before-failure-cleanup-ready" ] && break
    sleep 0.1
  done
  [ -f "$failure_state/.test-before-failure-cleanup-ready" ] || fail "failed-launch race did not reach post-handoff cleanup gate"
  successor_output=$(bash "$serve_script" --project-dir "$failure_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "successor did not start while original cleanup was paused"
  successor_pid=$(printf '%s' "$successor_output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pid"])')
  : > "$failure_state/.test-before-failure-cleanup-release"
  if wait "$failure_helper"; then fail "failed original helper unexpectedly succeeded"; fi
  kill -0 "$successor_pid" 2>/dev/null || fail "original failed-launch cleanup signalled its successor"
  node - "$failure_state/server.pid" "$failure_state/server-instance-id" "$failure_state/server-info.json" "$successor_pid" <<'NODE'
const fs = require('node:fs');
const [pidFile, instanceFile, infoFile, successorPid] = process.argv.slice(2);
const pid = fs.readFileSync(pidFile, 'utf8').trim();
const instance = fs.readFileSync(instanceFile, 'utf8').trim();
const info = JSON.parse(fs.readFileSync(infoFile, 'utf8'));
if (pid !== successorPid || info.pid !== Number(successorPid) || info.instanceId !== instance) process.exit(1);
NODE
  [ "$?" = 0 ] || fail "original failed-launch cleanup removed or corrupted successor metadata"
  bash "$serve_script" --stop --project-dir "$failure_project" >/dev/null || fail "failed-launch race successor did not stop"
  bash "$serve_script" --stop --project-dir "$occupied_project" >/dev/null || fail "failed-launch race occupier did not stop"

  mkdir -p "$tmp/race/docs/jobs"
  bash "$serve_script" --project-dir "$tmp/race" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/race-one.json" 2>"$tmp/race-one.err" &
  race_one=$!
  bash "$serve_script" --project-dir "$tmp/race" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/race-two.json" 2>"$tmp/race-two.err" &
  race_two=$!
  wait "$race_one" || fail "first concurrent dashboard start failed"
  wait "$race_two" || fail "second concurrent dashboard start failed"
  python3 - "$tmp/race-one.json" "$tmp/race-two.json" <<'PY'
import json, sys
one, two = (json.load(open(path, encoding='utf-8')) for path in sys.argv[1:])
assert one['pid'] == two['pid']
PY
  bash "$serve_script" --stop --project-dir "$tmp/race" >/dev/null || fail "concurrent dashboard instance did not stop"
  [ -f "$tmp/race/.super-planning/job-dashboard/start.lock" ] || fail "concurrent dashboard did not retain its lifecycle lock file"

  state_link_project="$tmp/state-file-symlink"
  mkdir -p "$state_link_project/docs/jobs"
  output=$(bash "$serve_script" --project-dir "$state_link_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "dashboard did not start for state-file symlink coverage"
  probe_state=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state_dir"])')
  bash "$serve_script" --stop --project-dir "$state_link_project" >/dev/null || fail "dashboard did not stop before state-file symlink coverage"
  sentinel="$state_link_project/docs/jobs/sentinel"
  printf '%s\n' 'sentinel-must-not-change' > "$sentinel"
  rm -f "$probe_state/server-instance-id"
  ln -s "$sentinel" "$probe_state/server-instance-id"
  if bash "$serve_script" --project-dir "$state_link_project" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/state-file-symlink.out" 2>"$tmp/state-file-symlink.err"; then
    fail "dashboard started with a symlinked runtime instance file"
  fi
  assert_contains_file 'runtime state file must not be a symlink: server-instance-id' "$tmp/state-file-symlink.err"
  [ "$(cat "$sentinel")" = 'sentinel-must-not-change' ] || fail "symlinked server-instance-id modified a jobs-root sentinel"

  # Hold the helper in its first health probe, then SIGKILL it after Node has
  # written its metadata.  The successor --stop must acquire start.lock; this
  # proves the server did not inherit the helper's flock descriptor.
  probe_project="$tmp/helper-sigkill"
  mock_bin="$tmp/mock-bin"
  mkdir -p "$probe_project/docs/jobs" "$mock_bin"
  printf '%s\n' '#!/usr/bin/env bash' 'sleep 30' 'exit 1' > "$mock_bin/curl"
  chmod 700 "$mock_bin/curl"
  PATH="$mock_bin:$system_path" bash "$serve_script" --project-dir "$probe_project" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/helper-sigkill.out" 2>"$tmp/helper-sigkill.err" &
  probe_helper=$!
  probe_state="$probe_project/.super-planning/job-dashboard"
  for _ in $(seq 1 50); do
    [ -f "$probe_state/server-info.json" ] && [ -f "$probe_state/server.pid" ] && break
    sleep 0.1
  done
  [ -f "$probe_state/server-info.json" ] || fail "SIGKILL lock regression did not spawn Node before health probe"
  probe_server=$(tr -d '[:space:]' < "$probe_state/server.pid")
  kill -KILL "$probe_helper"
  wait "$probe_helper" 2>/dev/null || true
  PATH="$system_path" bash "$serve_script" --stop --project-dir "$probe_project" >"$tmp/helper-sigkill-stop.out" 2>"$tmp/helper-sigkill-stop.err" &
  stop_helper=$!
  for _ in $(seq 1 30); do
    kill -0 "$stop_helper" 2>/dev/null || break
    sleep 0.1
  done
  if kill -0 "$stop_helper" 2>/dev/null; then
    kill -KILL "$stop_helper" 2>/dev/null || true
    kill -KILL "$probe_server" 2>/dev/null || true
    fail "--stop could not acquire start.lock after helper SIGKILL"
  fi
  wait "$stop_helper" || fail "--stop failed after helper SIGKILL during health probe"
  grep -Fq '"status":"stopped"' "$tmp/helper-sigkill-stop.out" || fail "--stop did not stop Node after helper SIGKILL"
  if kill -0 "$probe_server" 2>/dev/null; then fail "server remained after helper-SIGKILL stop"; fi

  # The child keeps the inherited lifecycle lock until it has published its
  # own PID and instance proof.  Kill the helper while Node is deliberately
  # paused before that publication; a successor must wait, then reuse the
  # original Node rather than launch a duplicate orphan.
  handoff_project="$tmp/pre-pid-helper-sigkill"
  handoff_state="$handoff_project/.super-planning/job-dashboard"
  mkdir -p "$handoff_project/docs/jobs"
  DASHBOARD_TEST_PAUSE_BEFORE_METADATA=1 bash "$serve_script" --project-dir "$handoff_project" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/pre-pid-helper-sigkill.out" 2>"$tmp/pre-pid-helper-sigkill.err" &
  handoff_helper=$!
  for _ in $(seq 1 50); do
    [ -f "$handoff_state/.test-before-metadata-ready" ] && break
    sleep 0.1
  done
  [ -f "$handoff_state/.test-before-metadata-ready" ] || fail "pre-PID crash regression did not reach the child metadata handoff"
  handoff_server=$(tr -d '[:space:]' < "$handoff_state/.test-before-metadata-ready")
  kill -0 "$handoff_server" 2>/dev/null || fail "pre-PID crash regression did not leave a live Node child"
  [ ! -e "$handoff_state/server.pid" ] || fail "pre-PID crash regression published server.pid too early"
  kill -KILL "$handoff_helper"
  wait "$handoff_helper" 2>/dev/null || true
  bash "$serve_script" --project-dir "$handoff_project" --host 127.0.0.1 --url-host 127.0.0.1 >"$tmp/pre-pid-successor.out" 2>"$tmp/pre-pid-successor.err" &
  handoff_start=$!
  sleep 0.3
  if ! kill -0 "$handoff_start" 2>/dev/null; then
    kill -KILL "$handoff_server" 2>/dev/null || true
    fail "successor crossed the pre-PID lifecycle lock before child publication"
  fi
  [ ! -e "$handoff_state/server.pid" ] || fail "successor created PID metadata before the original child was released"
  : > "$handoff_state/.test-before-metadata-release"
  wait "$handoff_start" || fail "successor failed after the pre-PID handoff was released"
  printf '%s' "$(cat "$tmp/pre-pid-successor.out")" | python3 -c "import json,sys; assert json.load(sys.stdin)['pid'] == $handoff_server" || fail "successor did not reuse the child that survived helper SIGKILL"
  bash "$serve_script" --stop --project-dir "$handoff_project" >/dev/null || fail "pre-PID crash regression dashboard did not stop"
  if kill -0 "$handoff_server" 2>/dev/null; then fail "pre-PID crash regression left a child orphan"; fi

  stale_project="$tmp/stale-lock"
  stale_lock="$stale_project/.super-planning/job-dashboard/start.lock"
  mkdir -p "$stale_project/docs/jobs" "$(dirname "$stale_lock")"
  if bash -c 'exec 9>"$1"; flock -x 9; printf "pid=999999\\noperation=start\\nacquired_at=stale\\n" > "$1"; kill -KILL "$$"' bash "$stale_lock" >/dev/null 2>&1; then
    fail "stale-lock fixture unexpectedly survived SIGKILL"
  fi
  [ -f "$stale_lock" ] || fail "SIGKILL did not leave stale dashboard lock metadata"
  output=$(bash "$serve_script" --project-dir "$stale_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "dashboard startup did not recover a stale SIGKILL lock"
  [ -f "$stale_lock" ] || fail "stale dashboard lock was not retained as a stable lock inode"
  bash "$serve_script" --stop --project-dir "$stale_project" >/dev/null || fail "dashboard stop did not recover a stale SIGKILL lock"
  [ ! -e "$stale_project/.super-planning/job-dashboard/server.pid" ] || fail "stale-lock recovery left live PID metadata after stop"

  for signal in TERM INT; do
    signal_project="$tmp/signal-$signal"
    mkdir -p "$signal_project/docs/jobs"
    output=$(bash "$serve_script" --project-dir "$signal_project" --host 127.0.0.1 --url-host 127.0.0.1) || fail "dashboard did not start for SIG$signal cleanup"
    signal_pid=$(printf '%s' "$output" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pid"])')
    kill -"$signal" "$signal_pid"
    for _ in $(seq 1 30); do [ ! -e "$signal_project/.super-planning/job-dashboard/server.pid" ] && break; sleep 0.1; done
    [ ! -e "$signal_project/.super-planning/job-dashboard/server.pid" ] || fail "SIG$signal left PID metadata"
    [ ! -e "$signal_project/.super-planning/job-dashboard/server-instance-id" ] || fail "SIG$signal left instance metadata"
    [ ! -e "$signal_project/.super-planning/job-dashboard/server-info.json" ] || fail "SIG$signal left server metadata"
  done

  mkdir -p "$tmp/nonloopback/docs/jobs"
  output=$(bash "$serve_script" --project-dir "$tmp/nonloopback" --host 127.0.0.2) || fail "non-loopback host health probe failed"
  printf '%s' "$output" | python3 -c 'import json,sys; assert json.load(sys.stdin)["url"].startswith("http://127.0.0.2:")' || fail "non-loopback URL host was not preserved"
  bash "$serve_script" --stop --project-dir "$tmp/nonloopback" >/dev/null || fail "non-loopback dashboard did not stop"
  lan_host=$(node -e 'const os=require("node:os"); const all=Object.values(os.networkInterfaces()).flat().filter((x)=>x && !x.internal); const pick=all.find((x)=>x.family==="IPv4") || all[0]; process.stdout.write(pick ? pick.address : "");')
  if [[ -n "$lan_host" ]]; then
    mkdir -p "$tmp/lan-default/docs/jobs"
    output=$(bash "$serve_script" --project-dir "$tmp/lan-default") || fail "LAN-default dashboard health probe failed"
    printf '%s' "$output" | python3 -c "import json,sys; assert json.load(sys.stdin)['url'].startswith('http://$lan_host:')" || fail "LAN-default URL did not advertise the local LAN address"
    bash "$serve_script" --stop --project-dir "$tmp/lan-default" >/dev/null || fail "LAN-default dashboard did not stop"
  fi
  if node -e 'const s=require("node:net").createServer(); s.once("error",()=>process.exit(1)); s.listen(0,"::1",()=>s.close(()=>process.exit(0)));'; then
    mkdir -p "$tmp/ipv6/docs/jobs"
    output=$(bash "$serve_script" --project-dir "$tmp/ipv6" --host ::1) || fail "IPv6 host health probe failed"
    printf '%s' "$output" | python3 -c 'import json,sys; assert json.load(sys.stdin)["url"].startswith("http://[::1]:")' || fail "IPv6 URL did not use bracketed host notation"
    bash "$serve_script" --stop --project-dir "$tmp/ipv6" >/dev/null || fail "IPv6 dashboard did not stop"
  fi
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

test_watchdog_templates_materialize_target_config() {
  local materializer template contract target
  materializer="$REPO_ROOT/skills/super-planning/scripts/materialize-watchdogs.sh"
  template="$REPO_ROOT/skills/super-planning/platforms/continuation/codex/watchdogs.template.json"
  contract="$REPO_ROOT/skills/super-planning/platforms/continuation/contract.md"
  assert_exists "$materializer"
  assert_exists "$template"
  assert_exists "$contract"

  target=$(mktemp -d)
  bash "$materializer" --target-dir "$target" >/dev/null
  assert_exists "$target/.super-planning/watchdogs/codex-watchdogs.json"
  assert_exists "$target/.super-planning/watchdogs/prompts/continue-interrupted-task.md"
  assert_exists "$target/.super-planning/watchdogs/prompts/report-execution-status.md"
  assert_contains_file '"default"' "$target/.super-planning/watchdogs/codex-watchdogs.json"
  assert_contains_file '"test"' "$target/.super-planning/watchdogs/codex-watchdogs.json"
}

main() {
  if [ "${SUPER_PLANNING_JOB_DASHBOARD_ONLY:-0}" = "1" ]; then
    test_job_dashboard
    printf 'PASS: job dashboard\n'
    return 0
  fi
  if [ "${SUPER_PLANNING_REVIEW_PACKAGE_ONLY:-0}" = "1" ]; then
    test_review_package_preserves_multiple_commits
    test_review_package_rejects_invalid_ref
    test_review_package_uses_full_hashes_for_default_output
    printf 'PASS: review-package.sh\n'
    return 0
  fi

  test_testing_guidance_and_spec_strategy_are_integrated
  test_worktree_decision_gate_is_documented_and_safe_by_default
  test_init_generates_valid_registry_and_rich_empty_ledger
  test_render_progress_ledger_includes_complete_registry_snapshot
  test_update_rejects_invalid_status_without_mutating_file
  test_update_accepts_cancelled_task_status
  test_update_accepts_reviewing_task_status
  test_active_task_requires_base_commit
  test_update_rejects_invalid_task_profile_without_mutating_file
  test_new_registry_rejects_quick_but_legacy_registry_remains_valid
  test_render_progress_ledger_includes_timeline_and_requirements
  test_schema_validator_agreement
  test_validator_rejects_try_count_above_max_tries
  test_validator_rejects_schema_forbidden_extra_task_property
  test_materialized_logger_wrapper_writes_jsonl_events
  test_summarize_all_tasks_terminal_output
  test_summarize_all_tasks_json_output
  test_summarize_all_tasks_with_plan_id_filter
  test_summarize_all_tasks_with_example_data
  test_render_task_md_full_plan
  test_render_task_md_single_task
  test_render_task_md_empty_plan
  test_render_task_md_invalid_task_id_exits_with_error
  test_watchdog_templates_materialize_target_config
  test_append_task_validate_only
  test_init_uses_documented_safe_defaults
  test_task_lifecycle_rejects_skipped_review_and_accepts_reviewed_completion
  test_completed_task_requires_review_artifacts_and_event
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
