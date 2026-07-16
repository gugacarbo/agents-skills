#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-toolbox"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { rg -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }

test_router_and_subagents() {
  assert_contains '/code-toolbox issue <#N\|URL> [phase]' "$SKILL/SKILL.md"
  assert_contains '/code-toolbox batch <#N\|URL>... --from <phase>' "$SKILL/SKILL.md"
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

test_no_local_workflow_state() {
  [ ! -e "$SKILL/templates/progress-template.txt" ] || fail 'legacy progress template exists'
  assert_contains 'not exposed or used by this workflow' "$SKILL/SKILL.md"
  assert_contains 'not part of this workflow' "$SKILL/phases/08-reference.md"
  assert_contains 'append-only' "$SKILL/references/github-flow.md"
  assert_contains 'Closure matrix' "$SKILL/references/evidence-contract.md"
}

test_helpers() {
  bash -n "$SKILL/scripts/doctor.sh"
  bash -n "$SKILL/scripts/review-package.sh"
  assert_contains '--github' "$SKILL/scripts/doctor.sh"
  assert_contains '--pr' "$SKILL/scripts/review-package.sh"
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
  local tmp repo base output fake
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

  cat > "$fake/gh" <<EOF
#!/usr/bin/env sh
printf '%s\\n' '{"baseRefOid":"$base","headRefOid":"'"$(git -C "$repo" rev-parse HEAD)"'","url":"https://example.test/pr/12"}'
EOF
  chmod +x "$fake/gh"
  (cd "$repo" && PATH="$fake:$PATH" "$SKILL/scripts/review-package.sh" --pr 12 "$tmp/review-pr.md") >/dev/null
  assert_contains 'https://example.test/pr/12' "$tmp/review-pr.md"
}

test_router_and_subagents
test_no_local_workflow_state
test_helpers
test_doctor_github
test_review_package
printf 'PASS code-toolbox tests\n'
