#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-toolbox"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { rg -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }
assert_not_contains() { ! rg -Fq -- "$1" "$2" || fail "expected $2 not to contain: $1"; }

test_router_and_subagents() {
  assert_contains '/code-toolbox issue <#N\|URL> [phase]' "$SKILL/SKILL.md"
  assert_contains '/code-toolbox batch <#N\|URL>... --from <phase>' "$SKILL/SKILL.md"
  assert_contains '/code-toolbox tool <doctor\|bootstrap\|review-package>' "$SKILL/SKILL.md"
  assert_not_contains 'tool <doctor\|bootstrap\|review-package\|log-task>' "$SKILL/SKILL.md"
  assert_contains 'stage:blocked' "$SKILL/SKILL.md"
  for stage in spec-approval needs-plan needs-plan-review approved in-progress needs-task-review blocked; do
    assert_contains "stage:$stage" "$SKILL/references/github-flow.md"
  done
  assert_contains "issue's next gate" "$SKILL/references/github-flow.md"
  for file in 00-issue-context.md 01-brainstorm.md 02-spec.md 03-plan.md 04-dispatch.md 05-review.md 06-integrate.md; do
    [ -f "$SKILL/phases/$file" ] || fail "missing phase: $file"
  done
  for agent in investigator.md spec-author.md plan-author.md plan-reviewer.md general-executor.md code-reviewer.md spec-compliance-auditor.md; do
    [ -f "$SKILL/agents/$agent" ] || fail "missing agent: $agent"
  done
}

test_issue_creation_and_mode_boundaries() {
  assert_contains 'When this workflow creates a delivery issue' "$SKILL/references/github-flow.md"
  assert_contains 'Create the issue at `stage:spec-approval` plus `needs-human`' "$SKILL/references/github-flow.md"
  assert_contains 'Only `/code-toolbox issue create` may create the delivery issue' "$SKILL/phases/02-spec.md"
  assert_contains 'then apply exactly `stage:spec-approval` and `needs-human`' "$SKILL/phases/02-spec.md"

  assert_contains 'direct` uses the current checkout, creates no issue, applies no labels' "$SKILL/phases/04-dispatch.md"
  assert_contains 'direct` is allowed only in this mode' "$SKILL/SKILL.md"
  assert_contains 'no GitHub issue, labels, comments' "$SKILL/SKILL.md"

  # Repository-mode rejection, BLOCKED evidence, and review all use the
  # versioned delivery record. GitHub mutation is reserved for issue mode.
  assert_contains 'repository delivery record' "$SKILL/agents/plan-reviewer.md"
  assert_contains 'In repository mode append the rejection and required changes to the delivery record' "$SKILL/phases/03-plan.md"
  assert_contains 'then stop with no GitHub labels, stages, or comments' "$SKILL/phases/03-plan.md"
  assert_contains 'in issue mode retain `stage:blocked` plus `needs-human`' "$SKILL/phases/05-review.md"
  assert_contains 'repository mode append the blocker and `Resume: <phase/task>` to the delivery record, then stop without GitHub state' "$SKILL/phases/05-review.md"
  assert_contains 'Repository mode never changes GitHub labels/stages or posts GitHub comments' "$SKILL/agents/code-reviewer.md"
  assert_contains 'Repository mode creates no issue, labels, stages, or GitHub comments' "$SKILL/phases/06-integrate.md"
}

test_no_local_workflow_state() {
  [ ! -e "$SKILL/templates/progress-template.txt" ] || fail 'legacy progress template exists'
  [ ! -e "$SKILL/platforms/continuation" ] || fail 'legacy watchdog platform exists'
  [ ! -e "$SKILL/prompts/watchdogs" ] || fail 'legacy watchdog prompts exist'
  [ ! -e "$SKILL/scripts/materialize-watchdogs.sh" ] || fail 'legacy watchdog materializer exists'
  assert_contains 'Do not create local task trackers' "$SKILL/phases/08-reference.md"
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
  target="$tmp/.code-toolbox"
  sh "$SKILL/scripts/bootstrap.sh" --target-dir "$target" >/dev/null
  for helper in bootstrap.sh doctor.sh review-package.sh; do
    [ -x "$target/$helper" ] || fail "bootstrap did not install $helper"
  done
  [ ! -e "$target/log-task.sh" ] || fail 'bootstrap installed legacy task logger'
  [ ! -e "$target/materialize-watchdogs.sh" ] || fail 'bootstrap installed watchdog materializer'
  assert_not_contains 'log-task.sh' "$SKILL/scripts/bootstrap.sh"
}

test_companion_uses_temporary_session() {
  local started session_dir
  started=$(bash "$SKILL/scripts/visual-companion/start-server.sh" --idle-timeout-minutes 1)
  session_dir=$(node -e 'process.stdin.once("data", (data) => console.log(JSON.parse(data).session_dir))' <<<"$started")
  case "$session_dir" in
    "${TMPDIR:-/tmp}"/code-toolbox-brainstorm-*) ;;
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
    "${TMPDIR:-/tmp}"/code-toolbox-review.*) ;;
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
test_issue_creation_and_mode_boundaries
test_no_local_workflow_state
test_helpers
test_bootstrap_excludes_legacy_helpers
test_companion_uses_temporary_session
test_doctor_github
test_review_package
printf 'PASS code-toolbox tests\n'
