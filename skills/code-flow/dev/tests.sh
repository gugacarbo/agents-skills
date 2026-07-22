#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SKILL="$REPO_ROOT/skills/code-flow"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_contains() { rg -Fq -- "$1" "$2" || fail "expected $2 to contain: $1"; }
assert_not_contains() { ! rg -Fq -- "$1" "$2" || fail "expected $2 not to contain: $1"; }

assert_comment_contract() {
  local file="$1"
  rg -q '^> agent:' "$file" || fail "missing agent ownership in $file"
  rg -q '^> sources_evidence:' "$file" || fail "missing immutable source evidence in $file"
  rg -q '^## Resume$' "$file" || fail "missing Resume section in $file"
  assert_not_contains '> phase_scope:' "$file"
  assert_not_contains '> decisions:' "$file"
  assert_not_contains '> changes_validation:' "$file"
  assert_not_contains '> blockers:' "$file"
  assert_not_contains 'Resume stage:' "$file"
  assert_not_contains 'Resume owner:' "$file"
  assert_not_contains 'Next action:' "$file"
  ! rg -q '^Workflow:' "$file" || fail "persisted Workflow header remains in $file"
}

test_structure() {
  local actual expected
  actual=$(find "$SKILL/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' 01-issue-writer.md 02-architect.md 03-executor.md 04-reviewer.md)
  [ "$actual" = "$expected" ] || fail "unexpected agents: $actual"

  actual=$(find "$SKILL/phases" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)
  expected=$(printf '%s\n' context.md dispatch.md integrate.md issue.md plan.md review.md)
  [ "$actual" = "$expected" ] || fail "unexpected semantic operations: $actual"

  [ -f "$SKILL/prompts/brainstorm.md" ] || fail 'missing conditional brainstorm prompt'
  [ ! -e "$SKILL/scripts/bootstrap.sh" ] || fail 'bootstrap helper still exists'
  [ -f "$SKILL/references/risk-profiles.md" ] || fail 'missing risk profiles reference'
  [ -f "$SKILL/templates/15-implementation-outline-template.md" ] || fail 'missing compact outline template'
  [ -f "$SKILL/templates/16-native-workflow-mapping.md" ] || fail 'missing native workflow mapping template'
  [ -f "$SKILL/templates/17-batch-pre-issue-draft.md" ] || fail 'missing batch pre-issue draft template'
  [ -f "$SKILL/templates/18-plan-change-summary.md" ] || fail 'missing plan change summary template'
  [ -f "$SKILL/templates/12-human-gate-spec.md" ] || fail 'missing shared human gate template'
  [ -f "$SKILL/templates/11-follow-up-issues-report.md" ] || fail 'missing follow-up issue report template'
  [ -f "$SKILL/references/follow-up-issue-drafts.md" ] || fail 'missing follow-up issue draft contract'
  [ ! -e "$SKILL/templates/02-user-story.md" ] || fail 'obsolete user-story template remains'
  for obsolete in 11-human-gate-design.md 13-human-gate-plan.md 14-human-gate-merge.md 17-human-gate-close.md; do
    [ ! -e "$SKILL/templates/$obsolete" ] || fail "obsolete gate template remains: $obsolete"
  done
  [ -f "$SKILL/scripts/source-set-digest.py" ] || fail 'missing deterministic source-set digest helper'

  ! rg -n --glob '*.md' 'phases/[0-9][0-9]-|Fase [0-9]|/code-flow tool <[^>]*bootstrap|\.code-flow|/code-flow create-issue' \
    "$SKILL/SKILL.md" "$SKILL/README.md" "$SKILL/agents" "$SKILL/phases" "$SKILL/prompts" "$SKILL/references" "$SKILL/templates" \
    || fail 'obsolete numbered/bootstrap/local-install contract remains active'
}

test_adaptive_contract() {
  assert_contains 'Discovery' "$SKILL/SKILL.md"
  assert_contains 'Urgência, diff pequeno, complexidade S' "$SKILL/references/risk-profiles.md"
  assert_contains '`S → light`' "$SKILL/references/risk-profiles.md"
  assert_contains '`M/G → standard`' "$SKILL/references/risk-profiles.md"
  assert_contains '`X/XL → assured`' "$SKILL/references/risk-profiles.md"
  assert_contains 'WORKFLOW_DRIFT' "$SKILL/references/github-flow.md"
  assert_contains 'NATIVE_INVALID' "$SKILL/references/github-flow.md"
  assert_contains 'um `stage:*` usa' "$SKILL/SKILL.md"
  assert_contains '`Workflow` não é persistido' "$SKILL/references/github-flow.md"
  assert_contains 'native ativo automaticamente' "$SKILL/references/github-flow.md"
  assert_contains 'stage:ready-to-close' "$SKILL/phases/review.md"
  assert_contains 'NO_CHANGES' "$SKILL/phases/dispatch.md"
  assert_contains 'M/G no-spec' "$SKILL/phases/issue.md"
  assert_contains 'Mudança de comportamento' "$SKILL/SKILL.md"
  assert_contains 'auditor fresco' "$SKILL/phases/review.md"
  assert_contains 'nunca autoriza execução' "$SKILL/phases/plan.md"
  assert_contains 'ordem explícita de execução' "$SKILL/phases/plan.md"
  assert_contains '`--from` é piso' "$SKILL/phases/context.md"
  assert_contains 'do próprio gate' "$SKILL/phases/context.md"
  assert_contains 'Merge nunca é automático' "$SKILL/phases/integrate.md"
  assert_contains 'Integrar / Ajustar / Aguardar' "$SKILL/phases/integrate.md"
  assert_contains 'Fechar / Ajustar / Aguardar' "$SKILL/phases/integrate.md"
  assert_contains 'Prova `NO_CHANGES` sempre passa por `reviewer` independente' "$SKILL/SKILL.md"
  assert_contains 'renomear papel, trocar sessão' "$SKILL/SKILL.md"
  assert_contains 'Project V2 Draft Issues' "$SKILL/SKILL.md"
  assert_contains 'DRAFT_ISSUE' "$SKILL/phases/context.md"
  assert_contains 'issue-writer ou orquestrador' "$SKILL/phases/context.md"
  assert_contains 'não crie repository issues' "$SKILL/phases/context.md"

  if rg -n -i '\b(light|standard|assured)\b' "$SKILL/templates"; then
    fail 'profile name persisted in a template'
  fi
}

test_evidence_contract() {
  local template
  for template in 05-plan-template.md \
    07-implementation-evidence-template.md 08-implementation-review-template.md 09-integration-report-template.md \
    10-issue-note-template.md 11-follow-up-issues-report.md 12-human-gate-spec.md 15-implementation-outline-template.md \
    16-native-workflow-mapping.md 18-plan-change-summary.md evidence-contract-template.md; do
    assert_comment_contract "$SKILL/templates/$template"
  done
  ! rg -n '^> (phase_scope|decisions|changes_validation|blockers):' "$SKILL/templates" \
    || fail 'unused generic metadata remains in templates'
  assert_contains 'Estado a retomar' "$SKILL/templates/evidence-contract-template.md"
  assert_contains '<!-- code-flow:source-set:start -->' "$SKILL/templates/evidence-contract-template.md"
  assert_contains '<!-- code-flow:source-set:end -->' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'CRLF normalizado para LF' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'exatamente um LF final' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'templates/15-implementation-outline-template.md' "$SKILL/agents/03-executor.md"
  assert_contains 'templates/17-batch-pre-issue-draft.md' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'Mudança posterior no' "$SKILL/phases/issue.md"
  assert_contains 'Sem diff: `NO_CHANGES`' "$SKILL/templates/07-implementation-evidence-template.md"
  assert_contains 'NO_CHANGES aprovado segue para ready-to-close' "$SKILL/templates/08-implementation-review-template.md"
  assert_contains 'sem commit, PR ou merge' "$SKILL/phases/integrate.md"
  assert_contains 'Critical \| Important \| Minor \| Cannot verify' "$SKILL/templates/08-implementation-review-template.md"
  assert_contains 'APROVAR COM RESSALVAS' "$SKILL/templates/08-implementation-review-template.md"
  assert_contains 'não há `Workflow` persistido' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'estado dinâmico' "$SKILL/phases/dispatch.md"
  assert_contains '> type: <issue | bug | feature | docs>' "$SKILL/templates/03-issue-template.md"
  assert_contains '> Complexity: <S | M | G | X | XL>' "$SKILL/templates/03-issue-template.md"
  assert_contains '### Proposta de spec (`create`)' "$SKILL/templates/03-issue-template.md"
  assert_contains '### Diff de spec (`update`)' "$SKILL/templates/03-issue-template.md"
  assert_contains '### Racional (`not required`)' "$SKILL/templates/03-issue-template.md"
  assert_contains 'Cada filha usa `templates/03-issue-template.md`' "$SKILL/templates/01-epic.md"
  assert_not_contains '**status:**' "$SKILL/templates/01-epic.md"
  assert_not_contains '**status:**' "$SKILL/templates/03-issue-template.md"
  assert_contains '> state: DRAFT_ISSUE' "$SKILL/templates/17-batch-pre-issue-draft.md"
  assert_contains '> target_repository: <owner/repo>' "$SKILL/templates/17-batch-pre-issue-draft.md"
  assert_not_contains '#NNNN' "$SKILL/templates/17-batch-pre-issue-draft.md"
  assert_not_contains 'Complexity:' "$SKILL/templates/17-batch-pre-issue-draft.md"
  assert_contains 'Source-set aprovado:' "$SKILL/templates/05-plan-template.md"
  assert_contains 'Base SHA:' "$SKILL/templates/05-plan-template.md"
  assert_contains '## Abordagem de implementação' "$SKILL/templates/05-plan-template.md"
  assert_contains 'Ação de validação' "$SKILL/templates/05-plan-template.md"
  assert_contains 'Prova de rollback para migração' "$SKILL/templates/05-plan-template.md"
  assert_not_contains 'PR #NNNN' "$SKILL/templates/05-plan-template.md"
  assert_contains 'Aprovar / Ajustar / Bloquear' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'Integrar / Ajustar / Aguardar' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'Fechar / Ajustar / Aguardar' "$SKILL/templates/12-human-gate-spec.md"
  assert_not_contains '**Sim | Não | Ajustar**' "$SKILL/templates/12-human-gate-spec.md"
  assert_contains 'Problemas encontrados' "$SKILL/templates/07-implementation-evidence-template.md"
  assert_contains '<!-- code-flow:canonical-plan:start -->' "$SKILL/templates/05-plan-template.md"
  assert_contains '<!-- code-flow:canonical-plan:end -->' "$SKILL/templates/05-plan-template.md"
  assert_contains 'edita o mesmo comentário in-place' "$SKILL/templates/evidence-contract-template.md"
  assert_contains 'resumo breve' "$SKILL/templates/18-plan-change-summary.md"
  assert_contains 'não substitui nem duplica o plano' "$SKILL/agents/02-architect.md"
  for template in 07-implementation-evidence-template.md 08-implementation-review-template.md; do
    assert_contains 'Issue draft' "$SKILL/templates/$template"
    assert_contains 'Minor não bloqueante: link; demais: n/a' "$SKILL/templates/$template"
    assert_contains 'follow-up-issue-drafts.md' "$SKILL/templates/$template"
  done
  assert_contains '[Minor] <resumo curto do problema>' "$SKILL/references/follow-up-issue-drafts.md"
  assert_contains 'title-percent-encoded' "$SKILL/references/follow-up-issue-drafts.md"
  assert_contains 'nunca cria issue' "$SKILL/references/follow-up-issue-drafts.md"
  assert_contains 'templates/11-follow-up-issues-report.md' "$SKILL/references/follow-up-issue-drafts.md"
  assert_contains 'Nenhuma sugestão de issue não bloqueante encontrada' "$SKILL/templates/11-follow-up-issues-report.md"
  assert_contains 'duplicatas semânticas' "$SKILL/agents/04-reviewer.md"
  assert_contains 'Não oculte os links individuais' "$SKILL/agents/04-reviewer.md"
  assert_contains 'nunca é `DONE`' "$SKILL/agents/04-reviewer.md"
  assert_contains 'liste antes do veredito' "$SKILL/agents/04-reviewer.md"
  assert_contains 'templates/11-follow-up-issues-report.md' "$SKILL/phases/review.md"
  assert_contains 'A review só está completa' "$SKILL/phases/review.md"
  assert_contains 'nunca `DONE`' "$SKILL/phases/review.md"
}

test_helpers_syntax() {
  sh -n "$SKILL/scripts/doctor.sh"
  sh -n "$SKILL/scripts/transition-issue.sh"
  bash -n "$SKILL/scripts/review-package.sh"
  bash -n "$SKILL/scripts/visual-companion/start-server.sh"
  bash -n "$SKILL/scripts/visual-companion/stop-server.sh"
  node --check "$SKILL/scripts/visual-companion/server.cjs"
  python3 -m py_compile "$SKILL/scripts/source-set-digest.py"
  assert_not_contains '--target-dir' "$SKILL/scripts/doctor.sh"
  assert_contains 'fallback label' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'gh label create' "$SKILL/scripts/transition-issue.sh"
  "$SKILL/scripts/doctor.sh" --help > /dev/null
  ! "$SKILL/scripts/doctor.sh" --issue > /dev/null 2>&1 || fail 'doctor accepted --issue without a value'
}

test_source_set_digest() {
  local tmp body_a body_b body_c digest_a digest_b digest_c
  tmp=$(mktemp -d)
  body_a="$tmp/a.md"
  body_b="$tmp/b.md"
  body_c="$tmp/c.md"

  printf '%s\n' 'complexity: M' 'type: feature' '<!-- code-flow:source-set:start -->' 'alpha' 'beta' '<!-- code-flow:source-set:end -->' > "$body_a"
  printf '%s\r\n' 'complexity: G' 'type: docs' '<!-- code-flow:source-set:start -->' 'alpha' 'beta' '<!-- code-flow:source-set:end -->' > "$body_b"
  printf '%s\n' 'complexity: M' 'type: feature' '<!-- code-flow:source-set:start -->' 'alpha' 'changed' '<!-- code-flow:source-set:end -->' > "$body_c"

  digest_a=$(python3 "$SKILL/scripts/source-set-digest.py" "$body_a")
  digest_b=$(python3 "$SKILL/scripts/source-set-digest.py" "$body_b")
  digest_c=$(python3 "$SKILL/scripts/source-set-digest.py" "$body_c")
  [ "$digest_a" = "$digest_b" ] || fail 'metadata or CRLF changed source-set digest'
  [ "$digest_a" != "$digest_c" ] || fail 'source-set content change did not change digest'
  printf '%s\n' 'no markers' > "$tmp/invalid.md"
  ! python3 "$SKILL/scripts/source-set-digest.py" "$tmp/invalid.md" > /dev/null 2>&1 || fail 'digest accepted missing markers'
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
  printf '%s\n' "$out" | jq -e '.dry_run == true and .to == "stage:in-progress"' > /dev/null || fail 'invalid dry-run output'
  ! grep -Fxq 'stage:in-progress' "$labels" || fail 'dry-run created a label'

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:in-progress --clear-needs-human)
  printf '%s\n' "$out" | jq -e '.dry_run == false and .to == "stage:in-progress"' > /dev/null || fail 'mutation output invalid'
  grep -Fxq 'stage:in-progress' "$labels" || fail 'missing target label was not created'
  jq -e '[.[].name] | index("stage:in-progress") != null and index("stage:approved") == null' "$state" > /dev/null || fail 'stage mutation failed'
  grep -Fq 'label view stage:in-progress --repo github.com/acme/demo' "$log" || fail 'label discovery did not preserve issue repository'
  grep -Fq 'label create stage:in-progress --repo github.com/acme/demo' "$log" || fail 'label creation targeted the wrong repository'
  grep -Fq 'issue edit 42 --repo github.com/acme/demo' "$log" || fail 'issue mutation targeted the wrong repository'

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 'https://github.com/acme/demo/issues/42' --require-from stage:in-progress --to stage:needs-delivery-review --dry-run > /dev/null
  grep -Fq 'issue view https://github.com/acme/demo/issues/42' "$log" || fail 'issue URL was not resolved directly'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 'https://ghe.example/acme/demo/issues/42' --require-from stage:in-progress --to stage:in-progress > /dev/null
  grep -Fq 'label view stage:in-progress --repo ghe.example/acme/demo' "$log" || fail 'GitHub Enterprise host was not preserved'

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:in-progress --to stage:needs-delivery-review --needs-human > /dev/null
  grep -Fxq 'needs-human' "$labels" || fail 'needs-human label was not created'
  [ "$(grep -Fxc 'needs-human' "$labels")" -eq 1 ] || fail 'needs-human label creation is not idempotent'

  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:needs-delivery-review --to stage:ready-to-close --needs-human > /dev/null
  jq -e '[.[].name] | index("stage:ready-to-close") != null and index("stage:needs-delivery-review") == null' "$state" > /dev/null || fail 'ready-to-close transition failed'

  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:blocked --dry-run > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'require-from mismatch should fail'

  printf '%s\n' '[{"name":"delivery"}]' > "$state"
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:approved --dry-run > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'zero-stage transition without allow-repair should fail'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:approved --allow-repair > /dev/null
  jq -e '[.[].name] | index("stage:approved") != null' "$state" > /dev/null || fail 'allow-repair did not establish initial fallback stage'

  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'clear-stage without clear-needs-human should fail'
  printf '%s\n' '[{"name":"stage:approved"},{"name":"stage:blocked"},{"name":"needs-human"}]' > "$state"
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage --clear-needs-human > /dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail 'clear-stage should not repair multiple stages implicitly'
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage --clear-needs-human --allow-repair > /dev/null
  jq -e 'length == 0' "$state" > /dev/null || fail 'explicit cleanup did not remove workflow labels'
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

  # Drift: stage:blocked without needs-human must WARN
  printf '%s\n' '[{"name":"stage:blocked"}]' > "$state"
  printf '%s\n' 'stage:blocked' > "$labels"
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 2>&1 || true)
  printf '%s\n' "$out" | grep -Fq 'WARN stage:blocked without needs-human' || fail 'doctor missed blocked-without-human drift'

  # Drift: multiple stage:* must FAIL
  printf '%s\n' '[{"name":"stage:approved"},{"name":"stage:blocked"}]' > "$state"
  printf '%s\n' 'stage:approved' 'stage:blocked' > "$labels"
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --github --issue 42 2>&1 || true)
  printf '%s\n' "$out" | grep -Fq 'FAIL drift: multiple stage:* labels' || fail 'doctor missed multi-stage drift'
}

test_evals_json() {
  jq -e '
    .skill_name == "code-flow" and
    .evaluation_protocol.samples_per_scenario == 5 and
    (.evaluation_protocol.non_critical_threshold | contains("every non-critical scenario")) and
    .evaluation_protocol.baseline_sha == "272a74b32775c7ea687c2f5be9cc94b232d371cf" and
    (.evals | length == 17) and
    ([.evals[].id] | unique | length == 17) and
    ([.evals[] | select((.baseline_failure | type) != "string" or (.baseline_failure | length) == 0)] | length == 0) and
    ((.evals[] | select(.id == 7) | .baseline_failure) == "omits_dynamic_native_selection") and
    ((.evals[] | select(.id == 12) | .baseline_failure) == "omits_transition_ownership_and_start_evidence") and
    ((.evals[] | select(.id == 13) | .baseline_failure) == "lacks_no_changes_contract_human_close_gate_and_follow_up_consolidation") and
    ((.evals[] | select(.id == 13) | .expectations | index("Consolida Minors em comentário append-only, deduplicando e agrupando apenas itens compatíveis")) != null) and
    ((.evals[] | select(.id == 13) | .expectations | index("Inclui um link GitHub issues/new individual para cada Minor de origem")) != null) and
    ((.evals[] | select(.id == 13) | .expectations | index("Inclui um único draft consolidado com as três origens")) != null) and
    ((.evals[] | select(.id == 14) | .baseline_failure) == "regression_guard_batch_and_merge") and
    ((.evals[] | select(.id == 15) | .baseline_failure) == "allows_executor_to_finish_diff_without_published_pr") and
    ((.evals[] | select(.id == 16) | .baseline_failure) == "publishes_batch_pre_issues_before_codebase_review") and
    ((.evals[] | select(.id == 17) | .baseline_failure) == "appends_full_plan_copies_instead_of_editing_canonical_comment")
  ' "$SKILL/evals/evals.json" > /dev/null || fail 'eval corpus or verification protocol incomplete'
}

test_label_mutation() {
  # Artifact producers apply transitions caused by their own artifact/verdict.
  # Human-decision transitions remain orchestrator-owned.
  local a="$SKILL/agents"

  # 01-issue-writer: persists body and applies the resulting issue stage.
  assert_contains 'stage:spec-approval' "$a/01-issue-writer.md"
  assert_contains 'stage:needs-plan' "$a/01-issue-writer.md"

  # 02-architect: publishes the plan and waits for explicit execution authorization.
  assert_contains 'stage:approved + needs-human' "$a/02-architect.md"
  assert_contains 'ordem explícita de execução' "$a/02-architect.md"
  assert_contains 'edite-o in-place' "$a/02-architect.md"
  assert_contains 'templates/18-plan-change-summary.md' "$a/02-architect.md"
  assert_contains 'publique uma nova cópia integral' "$a/02-architect.md"

  # 03-executor: mutates stage per evidence result
  assert_contains 'stage:in-progress' "$a/03-executor.md"
  assert_contains 'stage:needs-delivery-review' "$a/03-executor.md"
  assert_contains 'stage:blocked + needs-human' "$a/03-executor.md"
  assert_contains 'limpe' "$a/03-executor.md"
  assert_contains 'commit, push e PR publicado' "$a/03-executor.md"
  assert_contains 'URL do PR' "$a/03-executor.md"
  assert_contains 'estado draft ou' "$a/03-executor.md"
  assert_contains 'ready segue' "$a/03-executor.md"
  assert_contains 'falha ao publicar' "$a/03-executor.md"
  assert_contains 'commit, push e PR publicado' "$SKILL/phases/dispatch.md"
  assert_contains 'URL do PR publicado' "$SKILL/templates/07-implementation-evidence-template.md"

  # Batch pre-issues remain Project V2 drafts until an authorized promotion.
  assert_contains 'DRAFT_ISSUE' "$a/01-issue-writer.md"
  assert_contains 'issue-writer ou orquestrador' "$SKILL/references/label-mutation-matrix.md"
  assert_contains 'nenhum `stage:*`' "$SKILL/references/label-mutation-matrix.md"

  # 04-reviewer: separates merge and no-diff close gates.
  assert_contains 'stage:ready-to-merge' "$a/04-reviewer.md"
  assert_contains 'stage:ready-to-close' "$a/04-reviewer.md"
  assert_contains 'needs-human' "$a/04-reviewer.md"
  assert_contains 'stage:needs-changes' "$a/04-reviewer.md"
  assert_contains 'blocker' "$a/04-reviewer.md"
  assert_contains '11-follow-up-issues-report.md' "$a/04-reviewer.md"

  # Canonical mutation matrix must exist and be referenced
  [ -f "$SKILL/references/label-mutation-matrix.md" ] || fail 'missing canonical label mutation matrix'
  assert_contains 'transition-issue.sh' "$SKILL/references/github-flow.md"
  assert_contains 'autorização execução autoriza/ajusta/bloqueia' "$SKILL/references/label-mutation-matrix.md"
  assert_contains 'gate integração/fechamento' "$SKILL/references/label-mutation-matrix.md"

  # Evidence precedes label mutation and never substitutes it.
  assert_contains 'Evidência precede mutação' "$SKILL/references/label-mutation-matrix.md"
  assert_contains 'O autor do evento aplica a transição' "$SKILL/references/label-mutation-matrix.md"
}

test_workflow_truth_table() {
  local flow="$SKILL/references/github-flow.md"
  assert_contains 'exatamente um `stage:*`' "$flow"
  assert_contains 'zero `stage:*`' "$flow"
  assert_contains 'native ativo automaticamente' "$flow"
  assert_contains 'header legado' "$flow"
  assert_contains 'stage é autoritativo' "$flow"
  assert_contains 'migração explícita' "$flow"
  assert_contains 'estado original' "$flow"
  assert_contains 'compensação' "$flow"
}

test_structure
test_adaptive_contract
test_evidence_contract
test_helpers_syntax
test_source_set_digest
test_transition_labels
test_doctor
test_evals_json
test_label_mutation
test_workflow_truth_table
printf 'PASS code-flow tests\n'
