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
  for field in agent run_id protocol_version event state_before state_after sources_evidence project_guidance; do
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
  expected=$(printf '%s\n' 01-issue-template.md \
    02-review-template.md \
    03-implementation-evidence-template.md 04-integration-report-template.md \
    05-human-gate-spec.md 06-note-template.md)
  [ "$actual" = "$expected" ] || fail "unexpected templates: $actual"

  [ -f "$SKILL/references/runtime.md" ] || fail 'missing runtime reference'
  [ -f "$SKILL/references/vps-runtime.md" ] || fail 'missing vps-runtime reference'
  [ -f "$SKILL/scripts/validate-evidence.sh" ] || fail 'missing validate-evidence script'
  [ -d "$SKILL/evals" ] || fail 'missing evals directory'
  [ -f "$SKILL/evals/evals.json" ] || fail 'missing evals.json'
  [ -f "$SKILL/evals/run-evals.mjs" ] || fail 'missing run-evals.mjs'
  [ ! -e "$SKILL/references/orchestrator-cheatsheet.md" ] || fail 'orchestrator cheatsheet remains'
  [ ! -e "$SKILL/templates/10-native-workflow-mapping.md" ] || fail 'native mapping template remains'
  [ ! -e "$SKILL/references/label-mutation-matrix.md" ] || fail 'label mutation matrix remains (use workflow-states.json)'
  [ ! -e "$SKILL/prompts" ] || fail 'prompts/ dir remains (moved to references/)'
  [ ! -e "$SKILL/templates/02-batch-pre-issue-draft.md" ] || fail '02-batch-pre-issue-draft.md remains (merged into 01-issue-template)'
}

test_router_and_roles() {
  for entry in '/code-flow role <papel> <issue>' '/code-flow gate <issue> <decisão-humana>' '/code-flow stop <issue>'; do
    assert_contains "$entry" "$SKILL/SKILL.md"
  done
  assert_contains 'code-flow:active' "$SKILL/SKILL.md"
  assert_contains 'overlay cooperativo' "$SKILL/SKILL.md"
  assert_contains 'não é lock' "$SKILL/SKILL.md"
  assert_contains 'uma delivery review independente' "$SKILL/SKILL.md"
  assert_contains 'workflow engine skill' "$SKILL/SKILL.md"
  assert_not_contains 'Resolva native/fallback' "$SKILL/SKILL.md"
  assert_not_contains 'orquestrador valida' "$SKILL/SKILL.md"
  assert_contains 'allow_implicit_invocation: false' "$SKILL/agents/openai.yaml"

  # Ativação implícita foi removida; somente explícita.
  assert_not_contains 'Ativação implícita' "$SKILL/phases/context.md"
  assert_contains 'somente explícita' "$SKILL/phases/context.md"
  # ensure_label foi removido; labels são pré-requisito ou --provision-labels.
  assert_not_contains 'ensure_label' "$SKILL/scripts/transition-issue.sh"
  assert_contains '--provision-labels' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'required labels missing' "$SKILL/scripts/transition-issue.sh"
  # Auto-aprovação XS sem hard trigger é explícita.
  assert_contains 'auto-aprov' "$SKILL/references/runtime.md"
  assert_contains 'XS sem hard trigger' "$SKILL/templates/05-human-gate-spec.md"
  # protocol_version presente em todos os templates de evidência.
  for template in 02-review-template.md 03-implementation-evidence-template.md \
    04-integration-report-template.md 05-human-gate-spec.md 06-note-template.md; do
    assert_contains 'protocol_version' "$SKILL/templates/$template"
  done
  # Desduplicação: agentes referenciam evidence-contract em vez de repetir o parágrafo.
  for agent_file in "$SKILL/agents"/0[1-5]-*.md; do
    assert_contains 'evidence-contract.md#retomada' "$agent_file"
  done
  # Markdown corrigido: placeholder sem >> extra.
  assert_not_contains 'n/a>>' "$SKILL/templates/06-note-template.md"
  # vps-runtime.md referenciado no SKILL.md e runtime.md.
  assert_contains 'vps-runtime.md' "$SKILL/SKILL.md"
  assert_contains 'vps-runtime.md' "$SKILL/references/runtime.md"

  assert_contains 'stage:awaiting-triage-approval + needs-human' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'stage:awaiting-execution-approval + needs-human' "$SKILL/agents/02-architect.md"
  assert_contains 'stage:ready-for-execution' "$SKILL/agents/03-executor.md"
  assert_contains 'stage:ready-to-merge + needs-human' "$SKILL/agents/04-reviewer.md"
  assert_contains 'stage:integration-authorized' "$SKILL/agents/05-integrator.md"
  assert_contains 'Até dois arquivos' "$SKILL/agents/05-integrator.md"
  assert_contains 'range-diff/patch-id' "$SKILL/agents/05-integrator.md"
  assert_contains 'Drift material' "$SKILL/agents/05-integrator.md"

  for agent_file in "$SKILL/agents"/0[1-5]-*.md; do
    assert_contains 'requires_tools:' "$agent_file"
    assert_contains 'inputs:' "$agent_file"
    assert_contains 'outputs:' "$agent_file"
    assert_contains 'workflow-states.json' "$agent_file"
    assert_not_contains 'next_label:' "$agent_file"
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
  for template in 02-review-template.md 03-implementation-evidence-template.md \
    04-integration-report-template.md 05-human-gate-spec.md \
    06-note-template.md; do
    assert_comment_contract "$SKILL/templates/$template"
  done
  assert_contains 'run_id' "$SKILL/references/evidence-contract.md"
  assert_contains 'stage:in-progress' "$SKILL/templates/06-note-template.md"
  assert_contains 'NO_CHANGES nunca é' "$SKILL/templates/02-review-template.md"
  assert_contains 'Verificação de rebase' "$SKILL/templates/04-integration-report-template.md"
  assert_contains 'activity reset' "$SKILL/templates/05-human-gate-spec.md"
  assert_contains '<!-- code-flow:architect-review:start -->' "$SKILL/templates/02-review-template.md"
  assert_contains '<!-- code-flow:architect-review:end -->' "$SKILL/templates/02-review-template.md"
}

test_registry() {
  jq -e '
    .schema_version == 3 and
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
  documented=$(awk '/^\| Label/{f=1} f&&/^$/{exit} f{print}' "$SKILL/references/runtime.md" | grep -oE 'stage:[a-z-]+' | sort -u)
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
  local repo_labels="${labels}.repo"
  local comments="${state}.comments"
  local issue_status="${state}.issue-status"
  : > "$repo_labels"
  [ -f "$comments" ] || printf '[]\n' > "$comments"
  [ -f "$issue_status" ] || printf 'OPEN\n' > "$issue_status"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/gh" << EOF
#!/usr/bin/env sh
STATE='$state'
LABELS='$labels'
REPO_LABELS='$repo_labels'
COMMENTS='$comments'
ISSUE_STATUS='$issue_status'
LOG='$log'
printf '%s\n' "\$*" >> "\$LOG"
case "\$1 \$2" in
  'issue view')
    url='https://github.com/acme/demo/issues/42'
    case "\$3" in http://*|https://*) url="\$3" ;; esac
    printf '{"number":42,"url":"%s","state":"%s","labels":%s,"comments":%s}\n' "\$url" "\$(cat "\$ISSUE_STATUS")" "\$(cat "\$STATE")" "\$(cat "\$COMMENTS")"
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
  'label view') grep -Fxq -- "\$3" "\$REPO_LABELS" ;;
  'label create') grep -Fxq -- "\$3" "\$REPO_LABELS" || printf '%s\n' "\$3" >> "\$REPO_LABELS" ;;
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

set_comments() {
  local state="$1"
  printf '%s\n' "$2" | jq -c 'if type == "array" then . else [.] end' > "${state}.comments"
}

set_issue_status() {
  printf '%s\n' "$2" > "${1}.issue-status"
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

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --activate --provision-labels > /dev/null
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
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --complete --require-from stage:integration-authorized > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'completion accepted an open issue'
  set_issue_status "$state" CLOSED
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --complete --require-from stage:integration-authorized > /dev/null
  [ ! -s "$labels" ] || fail 'completion did not clear labels'

  set_state "$state" "$labels" code-flow:active stage:needs-triage stage:in-progress
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --finish-to stage:ready-for-execution --require-from stage:needs-triage > /dev/null
  assert_label "$labels" stage:ready-for-execution

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
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --migrate-to stage:awaiting-execution-approval --provision-labels > /dev/null
  assert_label "$labels" code-flow:active
  assert_label "$labels" stage:awaiting-execution-approval
  assert_label "$labels" needs-human

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-for-execution --dry-run)
  printf '%s' "$out" | jq -e '.dry_run and .operation == "gate"' > /dev/null || fail 'invalid dry-run output'

  set_state "$state" "$labels" code-flow:active stage:blocked needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-for-execution --require-from stage:blocked > /dev/null
  assert_label "$labels" stage:ready-for-execution
  assert_no_label "$labels" needs-human

  set_state "$state" "$labels" code-flow:active stage:awaiting-triage-approval needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:needs-triage --require-from stage:awaiting-triage-approval > /dev/null
  assert_label "$labels" stage:needs-triage

  set_state "$state" "$labels" code-flow:active stage:awaiting-execution-approval needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:needs-architect --require-from stage:awaiting-execution-approval > /dev/null
  assert_label "$labels" stage:needs-architect

  set_state "$state" "$labels" code-flow:active stage:ready-to-merge needs-human
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:ready-to-merge --require-from stage:ready-to-merge > /dev/null
  assert_label "$labels" stage:ready-to-merge
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --gate-to stage:needs-changes --require-from stage:ready-to-merge > /dev/null
  assert_label "$labels" stage:needs-changes
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
  sh -n "$SKILL/scripts/validate-evidence.sh"
  python3 -m py_compile "$SKILL/scripts/source-set-digest.py"
}

test_labels_not_created() {
  local tmp fake state labels log rc err
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state"
  labels="$tmp/labels"
  log="$tmp/log"
  err="$tmp/err"
  : > "$labels"
  printf '[]\n' > "$state"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"

  # Sem --provision-labels e sem labels no repo, --activate falha com lista.
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --activate > /dev/null 2> "$err" || rc=$?
  [ "$rc" -ne 0 ] || fail 'activate succeeded without labels and without --provision-labels'
  grep -Fq 'required labels missing' "$err" || fail 'missing-labels message not in stderr'

  # Com --provision-labels, cria labels e ativa.
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --activate --provision-labels > /dev/null
  assert_label "$labels" code-flow:active
  assert_label "$labels" stage:needs-triage
}

test_validate_evidence() {
  local tmp fake state labels log out rc
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state"
  labels="$tmp/labels"
  log="$tmp/log"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"

  set_state "$state" "$labels" code-flow:active stage:ready-for-execution stage:in-progress
  set_comments "$state" '{"body":"> agent: executor\n> run_id: run-1\n> protocol_version: 3\n> event: activity-start\n> state_before: stage:ready-for-execution\n> lease_ttl: 3600", "createdAt":"2999-01-01T00:00:00Z", "author":{"login":"executor-bot"}}'
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json)
  printf '%s' "$out" | jq -e '.errors == [] and .warnings == []' > /dev/null || fail 'valid activity evidence was rejected'

  set_comments "$state" '{"body":"> agent: executor\n> run_id: run-1\n> protocol_version: 2\n> event: activity-start\n> state_before: stage:ready-for-execution", "createdAt":"2999-01-01T00:00:00Z", "author":{"login":"executor-bot"}}'
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json)
  printf '%s' "$out" | jq -e '.errors | join(" ") | test("protocol_version")' > /dev/null || fail 'incompatible protocol version was not rejected'

  set_comments "$state" '{"body":"> agent: executor\n> run_id: run-1\n> protocol_version: 3\n> event: activity-start\n> state_before: stage:ready-for-execution\n> lease_ttl: soon", "createdAt":"2999-01-01T00:00:00Z", "author":{"login":"executor-bot"}}'
  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json) || rc=$?
  [ "$rc" -eq 0 ] && printf '%s' "$out" | jq -e '.errors | join(" ") | test("lease_ttl")' > /dev/null || fail 'invalid lease was not reported'

  set_state "$state" "$labels" code-flow:active stage:needs-delivery-review stage:in-progress
  set_comments "$state" '[
    {"body":"> agent: executor\n> run_id: execute-1", "createdAt":"2026-01-01T00:00:00Z", "author":{"login":"shared-bot"}},
    {"body":"> agent: reviewer\n> run_id: review-1\n> protocol_version: 3\n> event: activity-start\n> state_before: stage:needs-delivery-review", "createdAt":"2999-01-01T00:00:00Z", "author":{"login":"shared-bot"}}
  ]'
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json)
  printf '%s' "$out" | jq -e '.errors | join(" ") | test("external human review")' > /dev/null || fail 'self-review authorship was not rejected'

  set_state "$state" "$labels" code-flow:active stage:needs-delivery-review
  set_comments "$state" '[]'
  PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json | jq -e '.errors == []' > /dev/null || fail 'idle reviewer state failed evidence validation'

  set_state "$state" "$labels" code-flow:active stage:ready-for-execution stage:in-progress
  set_comments "$state" '[]'
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/validate-evidence.sh" 42 --json)
  printf '%s' "$out" | jq -e '.errors | join(" ") | test("no activity-start")' > /dev/null || fail 'missing activity-start was not reported'
}

test_evals_structure() {
  jq -e '.skill_name == "code-flow" and (.evals | length == 5)' "$SKILL/evals/evals.json" > /dev/null \
    || fail 'invalid evals.json'
  for id in 1 2 3 4 5; do
    jq -e --arg id "$id" '[.evals[] | select(.id == ($id | tonumber))] | length == 1' "$SKILL/evals/evals.json" > /dev/null \
      || fail "missing eval $id"
  done
  [ -f "$SKILL/evals/fixtures/README.md" ] || fail 'missing evals fixtures README'
  [ -f "$SKILL/evals/fixtures/e5-agents-md/AGENTS.md" ] || fail 'missing e5 fixture'
}

test_structure
test_router_and_roles
test_templates
test_registry
test_source_set_digest
test_transition_protocol
test_doctor
test_syntax
test_labels_not_created
test_validate_evidence
test_evals_structure
printf 'PASS: code-flow dev tests\n'
