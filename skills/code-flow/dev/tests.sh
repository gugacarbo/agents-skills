#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-flow"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_contains() { grep -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }
assert_not_contains() { ! grep -Fq -- "$1" "$2" || fail "expected $2 not to contain: $1"; }

assert_comment_contract() {
  local file="$1"
  for field in agent run_id event state_before state_after sources_evidence project_guidance; do
    grep -Eq "^> $field:" "$file" || fail "missing $field in $file"
  done
  grep -Eq '^## Resume$' "$file" || fail "missing Resume in $file"
}

test_structure() {
  local actual expected
  actual=$(find "$SKILL/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' 01-issue-writer.md 02-architect.md 03-executor.md 04-reviewer.md 05-integrator.md)
  [ "$actual" = "$expected" ] || fail "unexpected agents: $actual"

  actual=$(find "$SKILL/templates" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' 01-epic.md 02-issue-template.md \
    03-review-template.md 04-implementation-outline-template.md \
    05-implementation-evidence-template.md 06-integration-report-template.md \
    07-human-gate-spec.md 08-note-template.md)
  [ "$actual" = "$expected" ] || fail "unexpected templates: $actual"

  [ -f "$SKILL/references/workflow-cheatsheet.md" ] || fail 'missing neutral workflow cheatsheet'
  [ ! -e "$SKILL/references/orchestrator-cheatsheet.md" ] || fail 'orchestrator cheatsheet remains'
  [ ! -e "$SKILL/templates/10-native-workflow-mapping.md" ] || fail 'native mapping template remains'
  [ ! -e "$SKILL/references/label-mutation-matrix.md" ] || fail 'label mutation matrix remains (use workflow-states.json)'
  [ ! -e "$SKILL/prompts" ] || fail 'prompts/ dir remains (moved to references/)'
  [ ! -e "$SKILL/templates/02-batch-pre-issue-draft.md" ] || fail '02-batch-pre-issue-draft.md remains (merged into 02-issue-template)'
  [ -f "$SKILL/references/brainstorm.md" ] || fail 'missing references/brainstorm.md'
  [ -f "$SKILL/references/visual-companion.md" ] || fail 'missing references/visual-companion.md'
}

test_router_and_roles() {
  for entry in '/code-flow start <issue>' '/code-flow role <papel> <issue>' '/code-flow gate <issue>' '/code-flow gate <issue> resume <stage>' '/code-flow stop <issue>'; do
    assert_contains "$entry" "$SKILL/SKILL.md"
  done
  assert_contains 'code-flow:active' "$SKILL/SKILL.md"
  assert_contains 'overlay cooperativo' "$SKILL/SKILL.md"
  assert_contains 'não é lock' "$SKILL/SKILL.md"
  assert_contains 'uma delivery review independente' "$SKILL/SKILL.md"
  assert_not_contains 'Resolva native/fallback' "$SKILL/SKILL.md"
  assert_not_contains 'orquestrador valida' "$SKILL/SKILL.md"
  assert_contains 'allow_implicit_invocation: false' "$SKILL/agents/openai.yaml"

  assert_contains 'stage:awaiting-triage-approval + needs-human' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'stage:awaiting-execution-approval + needs-human' "$SKILL/agents/02-architect.md"
  assert_contains 'stage:ready-for-execution' "$SKILL/agents/03-executor.md"
  assert_contains 'stage:ready-to-merge + needs-human' "$SKILL/agents/04-reviewer.md"
  assert_contains 'stage:integration-authorized' "$SKILL/agents/05-integrator.md"
  assert_contains 'Até dois arquivos' "$SKILL/agents/05-integrator.md"
  assert_contains 'range-diff/patch-id' "$SKILL/agents/05-integrator.md"
  assert_contains 'Drift material' "$SKILL/agents/05-integrator.md"

  for agent_file in "$SKILL/agents"/0[1-5]-*.md; do
    assert_contains 'trigger_labels:' "$agent_file"
    assert_contains 'requires_tools:' "$agent_file"
    assert_contains 'inputs:' "$agent_file"
    assert_contains 'outputs:' "$agent_file"
    assert_contains 'next_label:' "$agent_file"
  done

  ! grep -rn -iE 'auditor fresco|auditoria final|stage:needs-audit|agent: auditor|name: auditor' \
    "$SKILL/SKILL.md" "$SKILL/agents" "$SKILL/phases" "$SKILL/references" "$SKILL/templates" \
    || fail 'audit phase remains'
  ! grep -rn -E 'stage:(approved|ready-to-close|merge-authorized|close-authorized)' \
    "$SKILL/SKILL.md" "$SKILL/agents" "$SKILL/phases" "$SKILL/templates" \
    || fail 'removed stage remains active outside migration docs'
}

test_templates() {
  local template
  for template in 03-review-template.md 05-implementation-evidence-template.md \
    06-integration-report-template.md 07-human-gate-spec.md \
    08-note-template.md; do
    assert_comment_contract "$SKILL/templates/$template"
  done
  assert_contains 'run_id' "$SKILL/references/evidence-contract.md"
  assert_contains 'stage:in-progress' "$SKILL/templates/08-note-template.md"
  assert_contains 'NO_CHANGES nunca é' "$SKILL/templates/03-review-template.md"
  assert_contains 'Verificação de rebase' "$SKILL/templates/06-integration-report-template.md"
  assert_contains 'activity reset' "$SKILL/templates/07-human-gate-spec.md"
  assert_contains '<!-- code-flow:architect-review:start -->' "$SKILL/templates/03-review-template.md"
  assert_contains '<!-- code-flow:architect-review:end -->' "$SKILL/templates/03-review-template.md"
}

test_registry() {
  jq -e '
    .schema_version == 2 and
    .activation_label == "code-flow:active" and
    .activity_label == "stage:in-progress" and
    (.states | length == 10) and
    ([.states[].label] | unique | length == 10) and
    ([.states[] | select(.kind == "human") | .label] == [
      "stage:awaiting-triage-approval",
      "stage:awaiting-execution-approval",
      "stage:ready-to-merge",
      "stage:blocked"
    ]) and
    (.states | map(.label) | index("stage:in-progress") == null) and
    (.states | map(.label) | index("stage:integration-authorized") != null)
  ' "$SKILL/references/workflow-states.json" > /dev/null || fail 'invalid workflow registry'

  registry=$(jq -r '.states[].label' "$SKILL/references/workflow-states.json" | sort)
  documented=$(awk '/^\| Label/{f=1} f&&/^$/{exit} f{print}' "$SKILL/references/github-flow.md" | grep -oE 'stage:[a-z-]+' | sort -u)
  [ "$registry" = "$documented" ] || fail 'registry and protocol table differ'
}

test_source_set_digest() {
  local tmp a b c da db dc
  tmp=$(mktemp -d)
  a="$tmp/a"
  b="$tmp/b"
  c="$tmp/c"
  printf '%s\n' x '<!-- code-flow:architect-review:start -->' alpha beta '<!-- code-flow:architect-review:end -->' > "$a"
  printf '%s\r\n' y '<!-- code-flow:architect-review:start -->' alpha beta '<!-- code-flow:architect-review:end -->' > "$b"
  printf '%s\n' x '<!-- code-flow:architect-review:start -->' alpha changed '<!-- code-flow:architect-review:end -->' > "$c"
  da=$(python3 "$SKILL/scripts/source-set-digest.py" "$a")
  db=$(python3 "$SKILL/scripts/source-set-digest.py" "$b")
  dc=$(python3 "$SKILL/scripts/source-set-digest.py" "$c")
  [ "$da" = "$db" ] && [ "$da" != "$dc" ] || fail 'digest contract failed'
}

make_fake_gh() {
  local fake_dir="$1" state="$2" labels="$3" log="$4"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/gh" << EOF
#!/usr/bin/env sh
STATE='$state'
LABELS='$labels'
LOG='$log'
printf '%s\n' "\$*" >> "\$LOG"
case "\$1 \$2" in
  'issue view')
    url='https://github.com/acme/demo/issues/42'
    case "\$3" in http://*|https://*) url="\$3" ;; esac
    printf '{"number":42,"url":"%s","labels":%s}\n' "\$url" "\$(cat "\$STATE")"
    ;;
  'issue edit')
    shift 3
    while [ "\$#" -gt 0 ]; do
      case "\$1" in
        --remove-label) jq --arg n "\$2" '[.[] | select(.name != \$n)]' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"; shift 2 ;;
        --add-label) jq --arg n "\$2" 'if ([.[].name] | index(\$n)) == null then . + [{"name":\$n}] else . end' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"; shift 2 ;;
        *) shift ;;
      esac
    done
    jq -r '.[].name' "\$STATE" > "\$LABELS"
    ;;
  'label view') grep -Fxq -- "\$3" "\$LABELS" ;;
  'label create') grep -Fxq -- "\$3" "\$LABELS" || printf '%s\n' "\$3" >> "\$LABELS" ;;
  'auth status'|'repo view') exit 0 ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$fake_dir/gh"
}

set_state() {
  local state="$1" labels="$2"
  shift 2
  printf '%s\n' "$@" > "$labels"
  jq -Rn '[inputs | {name:.}]' < "$labels" > "$state"
}

assert_label() { grep -Fxq -- "$2" "$1" || fail "missing label $2"; }
assert_no_label() { ! grep -Fxq -- "$2" "$1" || fail "unexpected label $2"; }

test_transition_protocol() {
  local tmp fake state labels log out rc
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state"
  labels="$tmp/labels"
  log="$tmp/log"
  : > "$labels"
  printf '[]\n' > "$state"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --activate > /dev/null
  assert_label "$labels" code-flow:active
  assert_label "$labels" stage:needs-triage

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role issue-writer --require-from stage:needs-triage > /dev/null
  assert_label "$labels" stage:needs-triage
  assert_label "$labels" stage:in-progress

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --finish-to stage:awaiting-triage-approval --require-from stage:needs-triage > /dev/null
  assert_no_label "$labels" stage:needs-triage
  assert_no_label "$labels" stage:in-progress
  assert_label "$labels" stage:awaiting-triage-approval
  assert_label "$labels" needs-human

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-for-execution --require-from stage:awaiting-triage-approval > /dev/null
  assert_no_label "$labels" needs-human
  assert_label "$labels" stage:ready-for-execution

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role executor --require-from stage:ready-for-execution > /dev/null
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --reset-activity --require-from stage:ready-for-execution > /dev/null
  assert_no_label "$labels" stage:in-progress

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role executor --require-from stage:ready-for-execution > /dev/null
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --finish-to stage:needs-delivery-review --require-from stage:ready-for-execution > /dev/null
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role reviewer --require-from stage:needs-delivery-review > /dev/null
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --finish-to stage:ready-to-merge --require-from stage:needs-delivery-review > /dev/null
  assert_label "$labels" stage:ready-to-merge
  assert_label "$labels" needs-human

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:integration-authorized --require-from stage:ready-to-merge > /dev/null
  assert_no_label "$labels" needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role integrator --require-from stage:integration-authorized > /dev/null
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --complete --require-from stage:integration-authorized > /dev/null
  [ ! -s "$labels" ] || fail 'completion did not clear labels'

  set_state "$state" "$labels" stage:awaiting-triage-approval needs-human code-flow:active
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role issue-writer > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'agent started on human state'

  set_state "$state" "$labels" code-flow:active stage:needs-triage stage:in-progress
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role issue-writer > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'second activity was accepted'

  set_state "$state" "$labels" code-flow:active stage:needs-triage
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --start-work --role architect > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'incompatible role was accepted'

  set_state "$state" "$labels" stage:approved
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --migrate-to stage:awaiting-execution-approval > /dev/null
  assert_label "$labels" code-flow:active
  assert_label "$labels" stage:awaiting-execution-approval
  assert_label "$labels" needs-human

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-for-execution --dry-run)
  printf '%s' "$out" | jq -e '.dry_run and .operation == "gate"' > /dev/null || fail 'invalid dry-run output'

  set_state "$state" "$labels" code-flow:active stage:blocked needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-for-execution --require-from stage:blocked > /dev/null
  assert_label "$labels" stage:ready-for-execution
  assert_no_label "$labels" needs-human
}

test_doctor() {
  local tmp fake state labels log out rc
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state"
  labels="$tmp/labels"
  log="$tmp/log"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"

  set_state "$state" "$labels" code-flow:active stage:needs-triage
  PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 > /dev/null

  set_state "$state" "$labels" code-flow:active stage:needs-triage stage:in-progress needs-human
  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 2>&1) || rc=$?
  [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -Fq 'in-progress with needs-human' || fail 'doctor missed overlay/human drift'

  set_state "$state" "$labels" code-flow:active stage:needs-triage stage:needs-architect
  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 2>&1) || rc=$?
  [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -Fq 'exactly one primary' || fail 'doctor missed multiple primary states'

  set_state "$state" "$labels" code-flow:active stage:needs-triage stage:unknown
  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 2>&1) || rc=$?
  [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -Fq 'unknown stage labels' || fail 'doctor missed unknown stage label'
}

test_syntax() {
  sh -n "$SKILL/scripts/doctor.sh"
  sh -n "$SKILL/scripts/transition-issue.sh"
  python3 -m py_compile "$SKILL/scripts/source-set-digest.py"
  node --check "$SKILL/scripts/visual-companion/server.cjs"
}

test_structure
test_router_and_roles
test_templates
test_registry
test_source_set_digest
test_transition_protocol
test_doctor
test_syntax
printf 'PASS: code-flow dev tests\n'
