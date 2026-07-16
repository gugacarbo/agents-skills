#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-flow"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { rg -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }

assert_envelope() {
  local file="$1" field line previous=0
  for field in \
    'Agent:' \
    'Phase/scope:' \
    'Summary:' \
    'Sources/evidence:' \
    'Decisions:' \
    'Changes/validation:' \
    'Blockers:' \
    'Next action:'; do
    line=$(rg -n -F -- "$field" "$file" | head -n 1 | cut -d: -f1)
    [ -n "$line" ] || fail "missing required evidence field in $file: $field"
    [ "$line" -gt "$previous" ] || fail "evidence fields are out of order in $file: $field"
    previous="$line"
  done
}

assert_exact_agents() {
  local actual expected
  actual=$(find "$SKILL/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' \
    01-issue-writer.md \
    02-issue-reviewer.md \
    03-plan-writer.md \
    04-plan-reviewer.md \
    05-executor.md \
    06-delivery-reviewer.md)
  [ "$actual" = "$expected" ] || fail "unexpected code-flow agent topology: $actual"
}

assert_template_references() {
  local template
  for template in \
    01-epic.md \
    02-user-story.md \
    03-issue-template.md \
    04-issue-review-template.md \
    05-plan-template.md \
    06-review-template.md \
    07-task-evidaence-template.md \
    08-task-review-template.md \
    09-integration-report-template.md \
    10-delivery-report-template.md; do
    [ -f "$SKILL/templates/$template" ] || fail "missing template: $template"
    rg -Fq -- "templates/$template" \
      "$SKILL/SKILL.md" "$SKILL/README.md" "$SKILL/agents" "$SKILL/phases" \
      || fail "template is not referenced by the active flow: $template"
  done
}

test_router_and_subagents() {
  assert_contains '/code-flow issue <#N\|URL> [phase]' "$SKILL/SKILL.md"
  assert_contains '/code-flow batch <#N\|URL>... --from <phase>' "$SKILL/SKILL.md"
  assert_contains '/code-flow tool <doctor\|bootstrap\|review-package>' "$SKILL/SKILL.md"
  for stage in spec-approval needs-plan needs-plan-review approved in-progress needs-task-review blocked; do
    assert_contains "stage:$stage" "$SKILL/references/github-flow.md"
  done
  assert_contains "issue's next gate" "$SKILL/references/github-flow.md"
  for file in 00-issue-context.md 01-brainstorm.md 02-create-issue.md 03-plan.md 04-dispatch.md 05-review.md 06-integrate.md; do
    [ -f "$SKILL/phases/$file" ] || fail "missing phase: $file"
  done
  [ ! -e "$SKILL/phases/02-spec.md" ] || fail 'legacy phase-02 spec file exists'
  assert_contains '/code-flow <brainstorm\|create-issue\|plan\|dispatch\|review\|integrate>' "$SKILL/SKILL.md"
  assert_exact_agents
  assert_template_references
  assert_contains 'Dispatch only these roles' "$SKILL/SKILL.md"
  assert_contains 'multiple independently deliverable outcomes' "$SKILL/SKILL.md"
  assert_contains 'Create an Epic only after the user explicitly selects it' "$SKILL/SKILL.md"
  assert_contains 'tracking-only: no delivery stages, plans, or execution' "$SKILL/SKILL.md"
  assert_contains 'Ask as many clarifying questions as needed to avoid inventing decisions' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'Propose 2–3 approaches' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'obtain explicit user approval' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'Offer the visual companion only when' "$SKILL/phases/01-brainstorm.md"
  [ -f "$SKILL/templates/01-epic.md" ] || fail 'missing Epic template'
  assert_contains '## Child delivery issues' "$SKILL/templates/01-epic.md"
  assert_contains 'Do not add stage:* or needs-human labels' "$SKILL/templates/01-epic.md"
  assert_contains 'Each child must be a delivery/bug issue' "$SKILL/templates/01-epic.md"
  assert_contains 'written with [`templates/02-user-story.md`]' "$SKILL/SKILL.md"
  assert_contains 'GitHub subissues link Epic to delivery issues' "$SKILL/SKILL.md"
  [ -f "$SKILL/templates/02-user-story.md" ] || fail 'missing user-story template'
  assert_contains '## User story' "$SKILL/templates/02-user-story.md"
  assert_contains 'GitHub relation:' "$SKILL/templates/02-user-story.md"
  assert_contains 'implementation-only work' "$SKILL/templates/02-user-story.md"
  assert_contains 'templates/02-user-story.md' "$SKILL/templates/01-epic.md"
  assert_contains 'Before any `code-flow` template' "$SKILL/SKILL.md"
  assert_contains 'Use a compatible local pattern as the base' "$SKILL/SKILL.md"
  assert_contains 'repository-template discovery' "$SKILL/phases/02-create-issue.md"
  for agent in "$SKILL"/agents/*.md; do
    assert_contains 'local pattern' "$agent"
  done
}

test_issue_evidence_contract() {
  local template
  for template in \
    03-issue-template.md \
    04-issue-review-template.md \
    05-plan-template.md \
    06-review-template.md \
    07-task-evidaence-template.md \
    08-task-review-template.md \
    09-integration-report-template.md; do
    [ -f "$SKILL/templates/$template" ] || fail "missing issue evidence template: $template"
    assert_envelope "$SKILL/templates/$template"
  done

  assert_envelope "$SKILL/templates/10-delivery-report-template.md"
  assert_contains 'templates/03-issue-template.md' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'templates/04-issue-review-template.md' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'stage:spec-approval' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'human approves the source set' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'Do not change labels, create a plan, implement code, or self-approve' "$SKILL/agents/02-issue-reviewer.md"

  assert_contains 'Implement exactly one stable task ID' "$SKILL/agents/05-executor.md"
  assert_contains 'fresh instance' "$SKILL/agents/06-delivery-reviewer.md"
  assert_contains 'final auditor' "$SKILL/agents/06-delivery-reviewer.md"
}

test_issue_creation_and_mode_boundaries() {
  assert_contains 'When this workflow creates a delivery issue' "$SKILL/references/github-flow.md"
  assert_contains 'proposed ADR/spec content' "$SKILL/references/github-flow.md"
  assert_contains 'Do not write or update the formal ADR/spec first' "$SKILL/references/github-flow.md"
  assert_contains 'Only `/code-flow issue create` creates the delivery issue' "$SKILL/phases/02-create-issue.md"
  assert_contains 'Do not dispatch `plan-writer` before that evidence exists' "$SKILL/phases/02-create-issue.md"
  assert_contains 'After the user explicitly selects an Epic, create it in GitHub' "$SKILL/phases/02-create-issue.md"
  assert_contains 'Do not create or update a formal ADR/spec before approval' "$SKILL/agents/01-issue-writer.md"
  assert_contains '### Draft or no-spec rationale' "$SKILL/templates/03-issue-template.md"
  assert_contains 'authorizes formal ADR/spec materialization' "$SKILL/templates/03-issue-template.md"
  assert_contains 'plan approval are separate mandatory gates' "$SKILL/phases/03-plan.md"
  assert_contains 'human approves this exact plan snapshot' "$SKILL/templates/06-review-template.md"
  assert_contains 'explicit human approval' "$SKILL/references/github-flow.md"

  assert_contains 'direct` uses the current checkout and writes every envelope' "$SKILL/phases/04-dispatch.md"
  assert_contains 'direct` is repository-only' "$SKILL/SKILL.md"
  assert_contains 'no issue, label, stage, or GitHub comment' "$SKILL/SKILL.md"

  # Repository-mode evidence is versioned and never mutates GitHub.
  assert_contains 'direct-mode delivery record' "$SKILL/agents/04-plan-reviewer.md"
  assert_contains 'Direct: append stop/resume and start a new cycle' "$SKILL/phases/03-plan.md"
  assert_contains '`BLOCKED` is never review-ready' "$SKILL/phases/05-review.md"
  assert_contains 'Direct mode never creates an issue, label, or GitHub comment' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'Direct mode never writes GitHub state' "$SKILL/agents/05-executor.md"
  assert_contains 'Direct mode creates no issue, labels, stages, or GitHub comments' "$SKILL/phases/06-integrate.md"
}

test_no_local_workflow_state() {
  [ ! -e "$SKILL/templates/progress-template.txt" ] || fail 'legacy progress template exists'
  [ ! -e "$SKILL/platforms/continuation" ] || fail 'legacy watchdog platform exists'
  [ ! -e "$SKILL/prompts/watchdogs" ] || fail 'legacy watchdog prompts exist'
  [ ! -e "$SKILL/scripts/materialize-watchdogs.sh" ] || fail 'legacy watchdog materializer exists'
  [ ! -e "$SKILL/scripts/log-task.sh" ] || fail 'legacy task logger exists'
  [ ! -e "$SKILL/phases/08-reference.md" ] || fail 'obsolete phase-08 reference exists'
  assert_contains 'Do not create separate task trackers' "$SKILL/SKILL.md"
  assert_contains 'append-only' "$SKILL/references/github-flow.md"
  assert_contains 'Closure matrix' "$SKILL/references/evidence-contract.md"
}

test_helpers() {
  bash -n "$SKILL/scripts/doctor.sh"
  bash -n "$SKILL/scripts/review-package.sh"
  bash -n "$SKILL/scripts/bootstrap.sh"
  bash -n "$SKILL/scripts/visual-companion/start-server.sh"
  bash -n "$SKILL/scripts/visual-companion/stop-server.sh"
  node --check "$SKILL/scripts/visual-companion/server.cjs"
  assert_contains '--github' "$SKILL/scripts/doctor.sh"
  assert_contains '--pr' "$SKILL/scripts/review-package.sh"
  assert_contains 'git merge-base' "$SKILL/scripts/review-package.sh"
  assert_contains 'mktemp' "$SKILL/scripts/review-package.sh"
  assert_contains 'session_dir: SESSION_DIR' "$SKILL/scripts/visual-companion/server.cjs"
  assert_contains 'payload' "$SKILL/scripts/visual-companion/helper.js"
  assert_contains 'stop-server.sh <session_dir>' "$SKILL/phases/01_1-visual-companion.md"
  ! rg -Fq -- '--project-dir' "$SKILL/scripts/visual-companion/start-server.sh" || fail 'companion persists project sessions'
}

test_bootstrap_excludes_legacy_helpers() {
  local tmp target
  tmp=$(mktemp -d)
  target="$tmp/.code-flow"
  sh "$SKILL/scripts/bootstrap.sh" --target-dir "$target" >/dev/null
  for helper in bootstrap.sh doctor.sh review-package.sh; do
    [ -x "$target/$helper" ] || fail "bootstrap did not install $helper"
  done
  [ ! -e "$target/materialize-watchdogs.sh" ] || fail 'bootstrap installed watchdog materializer'
}

test_companion_uses_temporary_session() {
  local started session_dir
  started=$(bash "$SKILL/scripts/visual-companion/start-server.sh" --idle-timeout-minutes 1)
  session_dir=$(node -e 'process.stdin.once("data", (data) => console.log(JSON.parse(data).session_dir))' <<<"$started")
  case "$session_dir" in
    "${TMPDIR:-/tmp}"/code-flow-brainstorm-*) ;;
    *) fail "companion session is not temporary: $session_dir" ;;
  esac
  [ -d "$session_dir" ] || fail 'companion did not create its session directory'
  bash "$SKILL/scripts/visual-companion/stop-server.sh" "$session_dir" >/dev/null
  [ ! -e "$session_dir" ] || fail 'companion cleanup left its session directory behind'
}

test_doctor_github() {
  local tmp fake
  tmp=$(mktemp -d)
  fake="$tmp/fake-bin"
  mkdir -p "$fake"
  cat > "$fake/gh" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
  chmod +x "$fake/gh"
  (cd "$REPO_ROOT" && PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --target-dir "$SKILL/scripts" --github --issue 42) >/dev/null
}

test_review_package() {
  local tmp repo base output fake initial feature_head default_output
  tmp=$(mktemp -d)
  repo="$tmp/repo"
  output="$tmp/review.md"
  fake="$tmp/fake-bin"
  mkdir -p "$repo" "$fake"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  printf 'one\n' > "$repo/a.txt"
  git -C "$repo" add a.txt && git -C "$repo" commit -qm initial
  base=$(git -C "$repo" rev-parse HEAD)
  printf 'two\n' >> "$repo/a.txt"
  git -C "$repo" add a.txt && git -C "$repo" commit -qm change
  (cd "$repo" && "$SKILL/scripts/review-package.sh" "$base" HEAD "$output") >/dev/null
  assert_contains 'change' "$output"
  assert_contains 'two' "$output"
  default_output=$(cd "$repo" && "$SKILL/scripts/review-package.sh" "$base" HEAD | sed -n 's/^wrote \([^:]*\):.*/\1/p')
  case "$default_output" in
    "${TMPDIR:-/tmp}"/code-flow-review.*) ;;
    *) fail "review package default is not temporary: $default_output" ;;
  esac
  rm -f "$default_output"

  cat > "$fake/gh" <<EOF
#!/usr/bin/env sh
printf '%s\\n' '{"baseRefOid":"$base","headRefOid":"'"$(git -C "$repo" rev-parse HEAD)"'","url":"https://example.test/pr/12"}'
EOF
  chmod +x "$fake/gh"
  (cd "$repo" && PATH="$fake:$PATH" "$SKILL/scripts/review-package.sh" --pr 12 "$tmp/review-pr.md") >/dev/null
  assert_contains 'https://example.test/pr/12' "$tmp/review-pr.md"

  initial=$(git -C "$repo" rev-parse "$base")
  git -C "$repo" checkout -qb merge-base-test "$initial"
  printf 'base-only\n' > "$repo/base-only.txt"
  git -C "$repo" add base-only.txt && git -C "$repo" commit -qm base-only
  base=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -qb feature-branch "$initial"
  printf 'feature-only\n' > "$repo/feature-only.txt"
  git -C "$repo" add feature-only.txt && git -C "$repo" commit -qm feature-only
  feature_head=$(git -C "$repo" rev-parse HEAD)
  cat > "$fake/gh" <<EOF
#!/usr/bin/env sh
printf '%s\\n' '{"baseRefOid":"$base","headRefOid":"$feature_head","url":"https://example.test/pr/13"}'
EOF
  chmod +x "$fake/gh"
  (cd "$repo" && PATH="$fake:$PATH" "$SKILL/scripts/review-package.sh" --pr 13 "$tmp/review-merge-base.md") >/dev/null
  assert_contains "# Review package: $initial..$feature_head" "$tmp/review-merge-base.md"
  ! rg -Fq 'base-only.txt' "$tmp/review-merge-base.md" || fail 'PR package used base tip instead of merge base'
}

test_router_and_subagents
test_issue_evidence_contract
test_issue_creation_and_mode_boundaries
test_no_local_workflow_state
test_helpers
test_bootstrap_excludes_legacy_helpers
test_companion_uses_temporary_session
test_doctor_github
test_review_package
printf 'PASS code-flow tests\n'
