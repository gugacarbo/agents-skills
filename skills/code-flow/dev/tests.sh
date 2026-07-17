#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-flow"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { rg -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }
assert_not_contains() { ! rg -Fq -- "$1" "$2" || fail "expected $2 not to contain: $1"; }

assert_envelope() {
  local file="$1" field line previous=0
  for field in 'Agent:' 'Phase/scope:' 'Summary:' 'Sources/evidence:' 'Decisions:' 'Changes/validation:' 'Blockers:' 'Next action:'; do
    line=$(rg -n -F -- "$field" "$file" | head -n 1 | cut -d: -f1)
    [ -n "$line" ] || fail "missing evidence field in $file: $field"
    [ "$line" -gt "$previous" ] || fail "evidence fields out of order in $file: $field"
    previous="$line"
  done
}

test_structure() {
  local actual expected
  actual=$(find "$SKILL/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' 01-issue-writer.md 02-issue-reviewer.md 03-plan-writer.md 04-plan-reviewer.md 05-executor.md 06-delivery-reviewer.md)
  [ "$actual" = "$expected" ] || fail "unexpected agents: $actual"

  actual=$(find "$SKILL/phases" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' context.md dispatch.md integrate.md issue.md plan.md review.md)
  [ "$actual" = "$expected" ] || fail "unexpected semantic operations: $actual"

  [ -f "$SKILL/prompts/brainstorm.md" ] || fail 'missing conditional brainstorm prompt'
  [ ! -e "$SKILL/scripts/bootstrap.sh" ] || fail 'bootstrap helper still exists'
  [ -f "$SKILL/references/risk-profiles.md" ] || fail 'missing risk profiles reference'
  [ -f "$SKILL/templates/15-implementation-outline-template.md" ] || fail 'missing compact outline template'
  [ -f "$SKILL/templates/16-native-workflow-mapping.md" ] || fail 'missing native workflow mapping template'

  ! rg -n --glob '*.md' 'phases/[0-9][0-9]-|Fase [0-9]|/code-flow tool <[^>]*bootstrap|\.code-flow' \
    "$SKILL/SKILL.md" "$SKILL/README.md" "$SKILL/agents" "$SKILL/phases" "$SKILL/prompts" "$SKILL/references" "$SKILL/templates" \
    || fail 'obsolete numbered/bootstrap/local-install contract remains active'
}

test_adaptive_contract() {
  assert_contains 'Recalcule o risco antes de interpretar labels' "$SKILL/SKILL.md"
  assert_contains 'O nível mais restritivo vence' "$SKILL/references/risk-profiles.md"
  assert_contains 'Hard trigger nunca pode ser rebaixado' "$SKILL/references/risk-profiles.md"
  assert_contains 'stage:approved + needs-human' "$SKILL/phases/dispatch.md"
  assert_contains 'não ofereça `worktree|later`' "$SKILL/phases/dispatch.md"
  assert_contains 'sem review/gate de fonte' "$SKILL/phases/issue.md"
  assert_contains 'review independente obrigatória' "$SKILL/phases/issue.md"
  assert_contains 'Auditoria final' "$SKILL/phases/review.md"
  assert_contains 'Qualquer `stage:*`' "$SKILL/references/github-flow.md"
  assert_contains 'O aceite não é persistido' "$SKILL/references/github-flow.md"
  assert_contains 'encerre a atuação da skill' "$SKILL/references/github-flow.md"
  assert_contains 'nunca ofereça workflow nativo' "$SKILL/references/github-flow.md"
  assert_contains 'NATIVE_INCOMPLETE' "$SKILL/references/github-flow.md"
  assert_contains 'fallback selecionado' "$SKILL/templates/16-native-workflow-mapping.md"
  assert_contains 'sem me perguntar' "$SKILL/templates/16-native-workflow-mapping.md"
  assert_contains 'só roda após aceite' "$SKILL/SKILL.md"
  assert_contains 'Merge nunca é automático' "$SKILL/templates/14-human-gate-merge.md"

  if rg -n -i '\b(light|standard|assured)\b' "$SKILL/templates"; then
    fail 'profile name persisted in a template'
  fi
}

test_evidence_contract() {
  local template
  for template in 03-issue-template.md 04-issue-review-template.md 05-plan-template.md 06-review-template.md \
    07-implementation-evidence-template.md 08-implementation-review-template.md 09-integration-report-template.md \
    10-issue-note-template.md 15-implementation-outline-template.md; do
    assert_envelope "$SKILL/templates/$template"
  done
  assert_contains 'Opt-in de workflow nativo também não é evidência persistida' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'templates/15-implementation-outline-template.md' "$SKILL/agents/05-executor.md"
  assert_contains 'Comportamento observável localizado, por si só' "$SKILL/phases/issue.md"
  assert_contains 'Sem prova executada de rollback' "$SKILL/templates/07-implementation-evidence-template.md"
  assert_contains 'prova executada de rollback verificada' "$SKILL/templates/08-implementation-review-template.md"
  assert_contains 'Rollback de migração' "$SKILL/templates/09-integration-report-template.md"
  assert_contains 'plano formal ou outline compacto' "$SKILL/templates/01-epic.md"
  assert_contains 'plano formal ou' "$SKILL/templates/02-user-story.md"
  assert_not_contains 'plano aprovado de cada filha' "$SKILL/templates/01-epic.md"
  assert_contains 'Critical \| Important \| Minor \| Cannot verify' "$SKILL/templates/04-issue-review-template.md"
  assert_contains 'Critical \| Important \| Minor \| Cannot verify' "$SKILL/templates/06-review-template.md"
  assert_contains 'create/update` ou hard trigger' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'arquivo só na execução' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'SHA-256 do body aprovado' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'Digest divergente invalida' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'reconfirme que o SHA-256' "$SKILL/phases/dispatch.md"
  assert_contains 'só é materializado' "$SKILL/phases/issue.md"
  assert_contains 'stage:approved + needs-human' "$SKILL/templates/13-human-gate-plan.md"
  assert_contains 'somente se nenhuma auditoria final for exigida' "$SKILL/phases/review.md"
  assert_contains '`NÃO APROVO` corrigível' "$SKILL/phases/issue.md"
  assert_contains '`NÃO APROVO` corrigível' "$SKILL/phases/plan.md"
  assert_contains '`NÃO APROVO` corrigível' "$SKILL/phases/review.md"
}

test_helpers_syntax() {
  sh -n "$SKILL/scripts/doctor.sh"
  sh -n "$SKILL/scripts/transition-issue.sh"
  bash -n "$SKILL/scripts/review-package.sh"
  bash -n "$SKILL/scripts/visual-companion/start-server.sh"
  bash -n "$SKILL/scripts/visual-companion/stop-server.sh"
  node --check "$SKILL/scripts/visual-companion/server.cjs"
  assert_not_contains '--target-dir' "$SKILL/scripts/doctor.sh"
  assert_contains 'fallback label' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'gh label create' "$SKILL/scripts/transition-issue.sh"
  "$SKILL/scripts/doctor.sh" --help >/dev/null
  ! "$SKILL/scripts/doctor.sh" --issue >/dev/null 2>&1 || fail 'doctor accepted --issue without a value'
}

make_fake_gh() {
  local fake_dir="$1" state="$2" labels="$3" log="$4"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/gh" <<EOF
#!/usr/bin/env sh
STATE='$state'
LABELS='$labels'
LOG='$log'
printf '%s\n' "\$*" >> "\$LOG"
case "\$1 \$2" in
  'issue view')
    issue_url='https://github.com/acme/demo/issues/42'
    case "\$3" in http://*|https://*) issue_url="\$3" ;; esac
    printf '{"number":42,"url":"%s","labels":%s}\n' "\$issue_url" "\$(cat "\$STATE")"
    ;;
  'label list')
    cat "\$LABELS"
    ;;
  'label view')
    grep -Fxq -- "\$3" "\$LABELS"
    ;;
  'label create')
    label_name="\$3"
    grep -Fxq -- "\$label_name" "\$LABELS" || printf '%s\n' "\$label_name" >> "\$LABELS"
    ;;
  'issue edit')
    shift 2
    shift
    while [ "\$#" -gt 0 ]; do
      case "\$1" in
        --remove-label)
          jq --arg n "\$2" '[.[] | select(.name != \$n)]' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"
          shift 2
          ;;
        --add-label)
          jq --arg n "\$2" 'if ([.[].name] | index(\$n)) == null then . + [{"name":\$n}] else . end' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"
          shift 2
          ;;
        *) shift ;;
      esac
    done
    ;;
  'auth status'|'repo view') exit 0 ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$fake_dir/gh"
}

test_transition_labels() {
  local tmp fake state labels log out rc
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state.json"
  labels="$tmp/labels.txt"
  log="$tmp/gh.log"
  printf '%s\n' '[{"name":"stage:approved"},{"name":"delivery"}]' > "$state"
  printf '%s\n' 'stage:approved' 'delivery' > "$labels"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:in-progress --dry-run)
  printf '%s\n' "$out" | jq -e '.dry_run == true and .to == "stage:in-progress"' >/dev/null || fail 'invalid dry-run output'
  ! grep -Fxq 'stage:in-progress' "$labels" || fail 'dry-run created a label'

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:in-progress --clear-needs-human)
  printf '%s\n' "$out" | jq -e '.dry_run == false and .to == "stage:in-progress"' >/dev/null || fail 'mutation output invalid'
  grep -Fxq 'stage:in-progress' "$labels" || fail 'missing target label was not created'
  jq -e '[.[].name] | index("stage:in-progress") != null and index("stage:approved") == null' "$state" >/dev/null || fail 'stage mutation failed'
  grep -Fq 'label view stage:in-progress --repo github.com/acme/demo' "$log" || fail 'label discovery did not preserve issue repository'
  grep -Fq 'label create stage:in-progress --repo github.com/acme/demo' "$log" || fail 'label creation targeted the wrong repository'
  grep -Fq 'issue edit 42 --repo github.com/acme/demo' "$log" || fail 'issue mutation targeted the wrong repository'

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 'https://github.com/acme/demo/issues/42' --require-from stage:in-progress --to stage:needs-delivery-review --dry-run >/dev/null
  grep -Fq 'issue view https://github.com/acme/demo/issues/42' "$log" || fail 'issue URL was not resolved directly'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 'https://ghe.example/acme/demo/issues/42' --require-from stage:in-progress --to stage:in-progress >/dev/null
  grep -Fq 'label view stage:in-progress --repo ghe.example/acme/demo' "$log" || fail 'GitHub Enterprise host was not preserved'

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:in-progress --to stage:needs-delivery-review --needs-human >/dev/null
  grep -Fxq 'needs-human' "$labels" || fail 'needs-human label was not created'
  [ "$(grep -Fxc 'needs-human' "$labels")" -eq 1 ] || fail 'needs-human label creation is not idempotent'

  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:blocked --dry-run >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'require-from mismatch should fail'

  printf '%s\n' '[{"name":"delivery"}]' > "$state"
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:approved --dry-run >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'zero-stage transition without allow-repair should fail'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:approved --allow-repair >/dev/null
  jq -e '[.[].name] | index("stage:approved") != null' "$state" >/dev/null || fail 'allow-repair did not establish initial fallback stage'

  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'clear-stage without clear-needs-human should fail'
  printf '%s\n' '[{"name":"stage:approved"},{"name":"stage:blocked"},{"name":"needs-human"}]' > "$state"
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage --clear-needs-human >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'clear-stage should not repair multiple stages implicitly'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage --clear-needs-human --allow-repair >/dev/null
  jq -e 'length == 0' "$state" >/dev/null || fail 'explicit cleanup did not remove workflow labels'
}

test_doctor() {
  local tmp fake state labels log out
  tmp=$(mktemp -d)
  fake="$tmp/bin"
  state="$tmp/state.json"
  labels="$tmp/labels.txt"
  log="$tmp/gh.log"
  printf '%s\n' '[{"name":"stage:approved"}]' > "$state"
  printf '%s\n' 'stage:approved' > "$labels"
  : > "$log"
  make_fake_gh "$fake" "$state" "$labels" "$log"
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42)
  printf '%s\n' "$out" | grep -Fq 'PASS transition-issue-dry-run' || fail 'doctor did not probe fallback helper'
  printf '%s\n' "$out" | grep -Fq 'PASS gh-issue 42' || fail 'doctor did not inspect issue'
}

test_evals_json() {
  jq -e '
    .skill_name == "code-flow" and
    .evaluation_protocol.samples_per_scenario == 5 and
    (.evaluation_protocol.non_critical_threshold | contains("every non-critical scenario")) and
    .evaluation_protocol.baseline_sha == "36badae14c63717311e9a1e0a708113b7000524f" and
    (.evals | length == 12) and
    ([.evals[].id] | unique | length == 12) and
    ([.evals[] | select((.baseline_outcome | type) != "string" or (.baseline_outcome | length) == 0)] | length == 0) and
    ((.evals[] | select(.id == 6) | .expectations) | index("Presents the validated native-to-gate mapping before choosing") != null) and
    ([.evals[] | select(.id == 3 or .id == 4 or .id == 5 or .id == 6 or .id == 7 or .id == 8 or .id == 10 or .id == 11 or .id == 12)] | length == 9)
  ' "$SKILL/evals/evals.json" >/dev/null || fail 'eval corpus or verification protocol incomplete'
}

test_structure
test_adaptive_contract
test_evidence_contract
test_helpers_syntax
test_transition_labels
test_doctor
test_evals_json
printf 'PASS code-flow tests\n'
