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
    07-implementation-evidence-template.md \
    08-implementation-review-template.md \
    09-integration-report-template.md \
    11-human-gate-design.md \
    12-human-gate-spec.md \
    13-human-gate-plan.md \
    14-human-gate-merge.md; do
    [ -f "$SKILL/templates/$template" ] || fail "missing template: $template"
    rg -Fq -- "templates/$template" \
      "$SKILL/SKILL.md" "$SKILL/README.md" "$SKILL/agents" "$SKILL/phases" "$SKILL/references" \
      || fail "template is not referenced by the active flow: $template"
  done
  [ ! -e "$SKILL/templates/10-delivery-report-template.md" ] || fail 'legacy direct delivery-report template still exists'
  [ ! -e "$SKILL/templates/07-task-evidence-template.md" ] || fail 'legacy 07-task-evidence template still exists'
  [ ! -e "$SKILL/templates/08-task-review-template.md" ] || fail 'legacy 08-task-review template still exists'
}

test_router_and_subagents() {
  assert_contains '/code-flow issue <#N\|URL> [phase]' "$SKILL/SKILL.md"
  assert_contains '/code-flow batch <#N\|URL>... --from <phase>' "$SKILL/SKILL.md"
  assert_contains '/code-flow tool <doctor\|bootstrap\|review-package\|transition-issue>' "$SKILL/SKILL.md"
  assert_contains 'Alias de `/code-flow issue create`' "$SKILL/SKILL.md"
  assert_contains 'scripts/transition-issue.sh' "$SKILL/references/github-flow.md"
  assert_contains 'gh issue edit' "$SKILL/references/github-flow.md"
  [ -f "$SKILL/references/orchestrator-cheatsheet.md" ] || fail 'missing orchestrator cheatsheet'
  assert_contains 'orchestrator-cheatsheet.md' "$SKILL/SKILL.md"
  assert_contains 'Matriz stage → fase → ação' "$SKILL/references/orchestrator-cheatsheet.md"
  for stage in spec-approval needs-issue-fix needs-plan needs-plan-review needs-plan-fix approved in-progress needs-delivery-review needs-changes ready-to-merge blocked; do
    assert_contains "stage:$stage" "$SKILL/references/github-flow.md"
  done
  if rg -Fq -- 'needs-task-review' \
    "$SKILL/references/github-flow.md" \
    "$SKILL/SKILL.md" \
    "$SKILL/phases" \
    "$SKILL/evals/evals.json" \
    "$SKILL/agents"; then
    fail 'legacy stage needs-task-review still present'
  fi
  assert_contains 'stage:needs-changes' "$SKILL/phases/05-review.md"
  assert_contains 'stage:ready-to-merge' "$SKILL/phases/05-review.md"
  assert_contains 'stage:ready-to-merge' "$SKILL/phases/06-integrate.md"
  assert_contains 'stage:needs-changes' "$SKILL/phases/04-dispatch.md"
  assert_contains 'próximo gate' "$SKILL/references/github-flow.md"
  assert_contains 'Mutação de labels (obrigatória)' "$SKILL/references/github-flow.md"
  assert_contains 'só labels são status durável' "$SKILL/references/github-flow.md"
  assert_contains 'gh issue view <n> --json labels' "$SKILL/references/github-flow.md"
  assert_contains 'texto de comentário sozinho não é atualização de status' "$SKILL/SKILL.md"
  assert_contains 'Mencionar um stage no comentário não é mudança de estado' "$SKILL/references/evidence-contract.md"
  for file in 00-issue-context.md 01-brainstorm.md 02-create-issue.md 03-plan.md 04-dispatch.md 05-review.md 06-integrate.md; do
    [ -f "$SKILL/phases/$file" ] || fail "missing phase: $file"
  done
  [ -f "$SKILL/prompts/visual-companion.md" ] || fail 'missing prompts/visual-companion.md'
  assert_contains 'prompts/visual-companion.md' "$SKILL/SKILL.md"
  assert_contains 'prompts/visual-companion.md' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'prompts/interview-me.md' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'decisões importantes ainda não verificadas' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'templates/11-human-gate-design.md' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'Fast-path (sem pular gates)' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'agents/02-issue-reviewer.md' "$SKILL/phases/02-create-issue.md"
  assert_contains 'alto risco' "$SKILL/phases/02-create-issue.md"
  assert_contains 'mutar labels para `stage:needs-plan`' "$SKILL/phases/02-create-issue.md"
  assert_contains 'templates/12-human-gate-spec.md' "$SKILL/phases/02-create-issue.md"
  assert_contains 'templates/13-human-gate-plan.md' "$SKILL/phases/03-plan.md"
  assert_contains 'templates/14-human-gate-merge.md' "$SKILL/phases/06-integrate.md"
  [ -f "$SKILL/prompts/interview-me.md" ] || fail 'missing prompts/interview-me.md'
  assert_contains 'code-flow vs super-planning' "$SKILL/README.md"
  assert_contains 'code-toolbox' "$SKILL/README.md"
  [ ! -e "$SKILL/phases/02-spec.md" ] || fail 'legacy phase-02 spec file exists'
  assert_contains '/code-flow brainstorm' "$SKILL/SKILL.md"
  assert_contains '/code-flow <plan\|dispatch\|review\|integrate>' "$SKILL/SKILL.md"
  assert_contains 'Não há modo sem issue' "$SKILL/SKILL.md"
  assert_contains 'entrega exige issue GitHub' "$SKILL/SKILL.md"
  assert_exact_agents
  assert_template_references
  assert_contains 'Despache apenas estes papéis' "$SKILL/SKILL.md"
  assert_contains 'múltiplos resultados independentemente entregáveis' "$SKILL/SKILL.md"
  assert_contains 'Crie um Epic só depois que o usuário o selecionar explicitamente' "$SKILL/SKILL.md"
  assert_contains 'sem stages de entrega, planos ou execução' "$SKILL/SKILL.md"
  assert_contains 'Faça tantas perguntas de esclarecimento quanto necessário' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'Proponha 2–3 abordagens' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'obtenha aprovação explícita do usuário' "$SKILL/phases/01-brainstorm.md"
  assert_contains 'Ofereça o companheiro visual só quando' "$SKILL/phases/01-brainstorm.md"
  [ -f "$SKILL/templates/01-epic.md" ] || fail 'missing Epic template'
  assert_contains '## Issues de entrega filhas' "$SKILL/templates/01-epic.md"
  assert_contains 'Não adicionar labels stage:* ou needs-human' "$SKILL/templates/01-epic.md"
  assert_contains 'Cada filha deve ser uma issue de entrega/bug' "$SKILL/templates/01-epic.md"
  assert_contains 'escrita com [`templates/02-user-story.md`]' "$SKILL/SKILL.md"
  assert_contains 'Subissues do GitHub ligam Epic às issues de' "$SKILL/SKILL.md"
  [ -f "$SKILL/templates/02-user-story.md" ] || fail 'missing user-story template'
  assert_contains '## User story' "$SKILL/templates/02-user-story.md"
  assert_contains 'Relação no GitHub:' "$SKILL/templates/02-user-story.md"
  assert_contains 'como uma unidade do executor' "$SKILL/templates/02-user-story.md"
  assert_contains 'templates/02-user-story.md' "$SKILL/templates/01-epic.md"
  assert_contains 'Antes de qualquer template `code-flow`' "$SKILL/SKILL.md"
  assert_contains 'Use um padrão local compatível como base' "$SKILL/SKILL.md"
  assert_contains 'descoberta de padrão do repositório' "$SKILL/phases/02-create-issue.md"
  assert_contains 'Não há modo sem issue' "$SKILL/SKILL.md"
  for agent in "$SKILL"/agents/*.md; do
    assert_contains 'padrão local' "$agent"
  done
  [ ! -e "$SKILL/templates/07-task-evidaence-template.md" ] || fail 'legacy evidaence typo template still exists'
  [ ! -e "$SKILL/templates/07-task-evidence-template.md" ] || fail 'legacy 07-task-evidence template still exists'
  [ ! -e "$SKILL/templates/10-delivery-report-template.md" ] || fail 'legacy direct delivery-report template still exists'
}

test_issue_evidence_contract() {
  local template
  for template in \
    03-issue-template.md \
    04-issue-review-template.md \
    05-plan-template.md \
    06-review-template.md \
    07-implementation-evidence-template.md \
    08-implementation-review-template.md \
    09-integration-report-template.md; do
    [ -f "$SKILL/templates/$template" ] || fail "missing issue evidence template: $template"
    assert_envelope "$SKILL/templates/$template"
  done

  assert_contains 'templates/03-issue-template.md' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'body da issue' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'nunca em comentário' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'Sobrescreva' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'somente `stage:spec-approval`' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'essa label é adicionada' "$SKILL/agents/01-issue-writer.md"
  assert_not_contains 'aplique `stage:spec-approval` + `needs-human`' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'templates/04-issue-review-template.md' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'stage:spec-approval' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'aprovar o source-set' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'atribuir `stage:needs-issue-fix`' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'pedido explícito do usuário **ou** alto risco' "$SKILL/agents/02-issue-reviewer.md"
  assert_contains 'Best-effort mutate' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'stage:needs-issue-fix' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'stage:needs-plan-fix' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'best-effort' "$SKILL/references/github-flow.md"
  assert_contains 'zero `stage:*`' "$SKILL/references/github-flow.md"

  assert_contains 'Implemente o plano aprovado como uma unidade' "$SKILL/agents/05-executor.md"
  assert_contains 'Pode organizar o trabalho internamente' "$SKILL/agents/05-executor.md"
  assert_contains 'Não decompor o plano em task IDs,' "$SKILL/agents/03-plan-writer.md"
  assert_contains 'não adicione `needs-human`' "$SKILL/agents/03-plan-writer.md"
  assert_contains 'Não decompor este plano em task IDs.' "$SKILL/templates/05-plan-template.md"
  assert_contains 'Não exija decomposição em task IDs' "$SKILL/agents/04-plan-reviewer.md"
  assert_contains 'atribuir `stage:needs-plan-fix`' "$SKILL/agents/04-plan-reviewer.md"
  assert_contains 'instância fresca' "$SKILL/agents/06-delivery-reviewer.md"
  assert_contains 'auditor final' "$SKILL/agents/06-delivery-reviewer.md"
  assert_contains 'APROVO COM RESSALVAS' "$SKILL/templates/04-issue-review-template.md"
  assert_contains 'PEÇO AJUSTES' "$SKILL/templates/09-integration-report-template.md"
  assert_contains 'templates/06-review-template.md' "$SKILL/templates/08-implementation-review-template.md"
  assert_contains 'scripts/review-package.sh' "$SKILL/phases/05-review.md"
  assert_contains 'templates/07-implementation-evidence-template.md' "$SKILL/agents/05-executor.md"
  assert_contains 'templates/08-implementation-review-template.md' "$SKILL/agents/06-delivery-reviewer.md"
  assert_contains 'stage:needs-delivery-review' "$SKILL/phases/04-dispatch.md"
  assert_contains 'stage:needs-delivery-review' "$SKILL/phases/05-review.md"
}

test_issue_creation_and_mode_boundaries() {
  assert_contains 'Quando este fluxo cria ou preenche uma issue de entrega' "$SKILL/references/github-flow.md"
  assert_contains 'conteúdo proposto de ADR/spec' "$SKILL/references/github-flow.md"
  assert_contains 'Não escrever' "$SKILL/references/github-flow.md"
  assert_contains 'ADR/spec formal primeiro' "$SKILL/references/github-flow.md"
  assert_contains 'alias: `/code-flow create-issue`' "$SKILL/phases/02-create-issue.md"
  assert_contains 'Não despachar `plan-writer` antes dessa evidência existir' "$SKILL/phases/02-create-issue.md"
  assert_contains 'Após o usuário selecionar explicitamente um Epic, crie-o no GitHub' "$SKILL/phases/02-create-issue.md"
  assert_contains 'sobrescreve o body' "$SKILL/phases/02-create-issue.md"
  assert_contains 'nunca como comentário' "$SKILL/phases/02-create-issue.md"
  assert_contains '### Rascunho ou racional no-spec' "$SKILL/templates/03-issue-template.md"
  assert_contains 'Não criar nem atualizar' "$SKILL/agents/01-issue-writer.md"
  assert_contains 'Exceção: source-set no body' "$SKILL/references/evidence-contract.md"
  assert_contains 'autoriza a materialização formal do ADR/spec' "$SKILL/templates/03-issue-template.md"
  assert_contains 'gates obrigatórios separados' "$SKILL/phases/03-plan.md"
  assert_contains 'humano aprova este snapshot exato' "$SKILL/templates/06-review-template.md"
  assert_contains 'aprovação humana explícita' "$SKILL/references/github-flow.md"

  assert_contains 'Nunca executar no checkout compartilhado sem worktree isolada' "$SKILL/phases/04-dispatch.md"
  assert_contains 'Não há modo sem issue' "$SKILL/SKILL.md"
  assert_contains 'Exige issue' "$SKILL/SKILL.md"

  assert_contains 'Publique `templates/06-review-template.md`' "$SKILL/agents/04-plan-reviewer.md"
  assert_contains '`BLOCKED` nunca está pronto para review' "$SKILL/phases/05-review.md"
  assert_contains 'nunca faça merge automaticamente' "$SKILL/phases/06-integrate.md"
  ! rg -Fq -- 'modo `direct`' "$SKILL/SKILL.md" "$SKILL/phases" "$SKILL/agents" "$SKILL/references" \
    || fail 'modo direct still present in active flow docs'
}

test_no_local_workflow_state() {
  [ ! -e "$SKILL/templates/progress-template.txt" ] || fail 'legacy progress template exists'
  [ ! -e "$SKILL/platforms/continuation" ] || fail 'legacy watchdog platform exists'
  [ ! -e "$SKILL/prompts/watchdogs" ] || fail 'legacy watchdog prompts exist'
  [ -f "$SKILL/prompts/interview-me.md" ] || fail 'interview-me prompt missing'
  [ ! -e "$SKILL/scripts/materialize-watchdogs.sh" ] || fail 'legacy watchdog materializer exists'
  [ ! -e "$SKILL/scripts/log-task.sh" ] || fail 'legacy task logger exists'
  [ ! -e "$SKILL/phases/08-reference.md" ] || fail 'obsolete phase-08 reference exists'
  assert_contains 'Não criar trackers de task' "$SKILL/SKILL.md"
  assert_contains 'append-only' "$SKILL/references/github-flow.md"
  assert_contains 'Evidência de fechamento' "$SKILL/references/evidence-contract.md"
}

test_helpers() {
  bash -n "$SKILL/scripts/doctor.sh"
  bash -n "$SKILL/scripts/review-package.sh"
  bash -n "$SKILL/scripts/bootstrap.sh"
  bash -n "$SKILL/scripts/transition-issue.sh"
  sh -n "$SKILL/scripts/transition-issue.sh"
  bash -n "$SKILL/scripts/visual-companion/start-server.sh"
  bash -n "$SKILL/scripts/visual-companion/stop-server.sh"
  node --check "$SKILL/scripts/visual-companion/server.cjs"
  assert_contains '--github' "$SKILL/scripts/doctor.sh"
  assert_contains 'transition-issue.sh' "$SKILL/scripts/doctor.sh"
  assert_contains 'transition-issue.sh' "$SKILL/scripts/bootstrap.sh"
  assert_contains '--to' "$SKILL/scripts/transition-issue.sh"
  assert_contains '--dry-run' "$SKILL/scripts/transition-issue.sh"
  assert_contains '--allow-repair' "$SKILL/scripts/transition-issue.sh"
  assert_contains 'code-flow-visual-' "$SKILL/scripts/visual-companion/server.cjs"
  ! rg -Fq -- 'primeradiant.com' "$SKILL/scripts/visual-companion/server.cjs" || fail 'external primeradiant brand URL still present'
  ! rg -Fq -- 'brainstorm-key-' "$SKILL/scripts/visual-companion/server.cjs" || fail 'legacy brainstorm-key cookie still present'
  assert_contains '--pr' "$SKILL/scripts/review-package.sh"
  assert_contains 'git merge-base' "$SKILL/scripts/review-package.sh"
  assert_contains 'mktemp' "$SKILL/scripts/review-package.sh"
  assert_contains 'session_dir: SESSION_DIR' "$SKILL/scripts/visual-companion/server.cjs"
  assert_contains 'payload' "$SKILL/scripts/visual-companion/helper.js"
  assert_contains 'stop-server.sh <session_dir>' "$SKILL/prompts/visual-companion.md"
  ! rg -Fq -- '--project-dir' "$SKILL/scripts/visual-companion/start-server.sh" || fail 'companion persists project sessions'
}

test_bootstrap_excludes_legacy_helpers() {
  local tmp target
  tmp=$(mktemp -d)
  target="$tmp/.code-flow"
  sh "$SKILL/scripts/bootstrap.sh" --target-dir "$target" >/dev/null
  for helper in bootstrap.sh doctor.sh review-package.sh transition-issue.sh; do
    [ -x "$target/$helper" ] || fail "bootstrap did not install $helper"
  done
  [ ! -e "$target/materialize-watchdogs.sh" ] || fail 'bootstrap installed watchdog materializer'
}

test_transition_issue_dry_run() {
  local tmp fake out
  tmp=$(mktemp -d)
  fake="$tmp/fake-bin"
  mkdir -p "$fake"
  cat > "$fake/gh" <<'EOF'
#!/usr/bin/env sh
case "$1 $2" in
  "issue view")
    printf '%s\n' '{"number":42,"url":"https://example.test/issues/42","labels":[{"name":"stage:needs-plan"},{"name":"delivery"}]}'
    ;;
  "label list")
    printf '%s\n' 'stage:needs-plan'
    printf '%s\n' 'stage:needs-plan-review'
    printf '%s\n' 'needs-human'
    printf '%s\n' 'delivery'
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$fake/gh"
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:needs-plan --to stage:needs-plan-review --dry-run)
  printf '%s\n' "$out" | rg -Fq '"issue":42' || fail "dry-run missing issue id: $out"
  printf '%s\n' "$out" | rg -Fq '"to":"stage:needs-plan-review"' || fail "dry-run missing to stage: $out"
  printf '%s\n' "$out" | rg -Fq '"dry_run":true' || fail "dry-run flag missing: $out"
}

test_transition_issue_edges() {
  local tmp fake out rc
  tmp=$(mktemp -d)
  fake="$tmp/fake-bin"
  mkdir -p "$fake"
  cat > "$fake/gh" <<'EOF'
#!/usr/bin/env sh
case "$1 $2" in
  "issue view")
    printf '%s\n' '{"number":42,"url":"https://example.test/issues/42","labels":[{"name":"stage:needs-plan"},{"name":"delivery"}]}'
    ;;
  "label list")
    printf '%s\n' 'stage:needs-plan'
    printf '%s\n' 'stage:needs-plan-review'
    printf '%s\n' 'stage:approved'
    printf '%s\n' 'needs-human'
    printf '%s\n' 'delivery'
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$fake/gh"

  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:approved --to stage:needs-plan-review --dry-run 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "expected --require-from mismatch to fail"
  printf '%s\n' "$out" | rg -Fq "expected current stage" || fail "mismatch error missing: $out"

  rc=0
  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:approved --clear-stage --dry-run 2>&1) || rc=$?
  [ "$rc" -ne 0 ] || fail "expected --to + --clear-stage to fail"
  printf '%s\n' "$out" | rg -Fq "mutually exclusive" || fail "mutual exclusion error missing: $out"

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --clear-stage --dry-run)
  printf '%s\n' "$out" | rg -Fq '"to":null' || fail "clear-stage dry-run should have null to: $out"
  printf '%s\n' "$out" | rg -Fq '"dry_run":true' || fail "clear-stage dry-run flag missing: $out"
}

test_transition_issue_mutation() {
  local tmp fake state out
  tmp=$(mktemp -d)
  fake="$tmp/fake-bin"
  state="$tmp/labels.json"
  mkdir -p "$fake"
  printf '%s\n' '[{"name":"stage:needs-plan"},{"name":"delivery"}]' > "$state"
  cat > "$fake/gh" <<EOF
#!/usr/bin/env sh
STATE="$state"
case "\$1 \$2" in
  "issue view")
    printf '{"number":42,"url":"https://example.test/issues/42","labels":%s}\n' "\$(cat "\$STATE")"
    ;;
  "label list")
    printf '%s\n' 'stage:needs-plan'
    printf '%s\n' 'stage:needs-plan-review'
    printf '%s\n' 'needs-human'
    printf '%s\n' 'delivery'
    ;;
  "issue edit")
    # \$3=number; remaining flags: --remove-label X / --add-label Y
    shift 2
    issue_num="\$1"
    shift
    while [ "\$#" -gt 0 ]; do
      case "\$1" in
        --remove-label)
          jq --arg n "\$2" '[.[] | select(.name != \$n)]' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"
          shift 2
          ;;
        --add-label)
          jq --arg n "\$2" '. + [{"name":\$n}]' "\$STATE" > "\$STATE.tmp" && mv "\$STATE.tmp" "\$STATE"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$fake/gh"

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --require-from stage:needs-plan --to stage:needs-plan-review)
  printf '%s\n' "$out" | rg -Fq '"to":"stage:needs-plan-review"' || fail "mutation missing to: $out"
  printf '%s\n' "$out" | rg -Fq '"dry_run":false' || fail "mutation should not be dry-run: $out"
  jq -e '[.[].name] | index("stage:needs-plan-review") != null' "$state" >/dev/null \
    || fail "state missing needs-plan-review: $(cat "$state")"
  jq -e '[.[].name] | index("stage:needs-plan") == null' "$state" >/dev/null \
    || fail "state still has old stage: $(cat "$state")"

  # Ambiguous stages without --allow-repair must fail
  printf '%s\n' '[{"name":"stage:needs-plan"},{"name":"stage:approved"}]' > "$state"
  rc=0
  PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:needs-plan-review >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 0 ] || fail "expected ambiguous stages without --allow-repair to fail"

  out=$(PATH="$fake:$PATH" "$SKILL/scripts/transition-issue.sh" 42 --to stage:needs-plan-review --allow-repair)
  printf '%s\n' "$out" | rg -Fq '"to":"stage:needs-plan-review"' || fail "allow-repair mutation failed: $out"
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
  local tmp fake out
  tmp=$(mktemp -d)
  fake="$tmp/fake-bin"
  mkdir -p "$fake"
  cat > "$fake/gh" <<'EOF'
#!/usr/bin/env sh
case "$1 $2" in
  "auth status"|"repo view")
    exit 0
    ;;
  "issue view")
    printf '%s\n' '{"number":42,"url":"https://example.test/issues/42","labels":[{"name":"stage:needs-plan"},{"name":"delivery"}]}'
    ;;
  "label list")
    printf '%s\n' 'stage:needs-plan'
    printf '%s\n' 'stage:needs-plan-review'
    printf '%s\n' 'needs-human'
    printf '%s\n' 'delivery'
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$fake/gh"
  out=$(cd "$REPO_ROOT" && PATH="$fake:$PATH" "$SKILL/scripts/doctor.sh" --target-dir "$SKILL/scripts" --github --issue 42)
  printf '%s\n' "$out" | rg -Fq 'PASS transition-issue-dry-run' || fail "doctor missing PASS transition-issue-dry-run: $out"
  printf '%s\n' "$out" | rg -Fq 'PASS gh-issue 42' || fail "doctor missing PASS gh-issue: $out"
  ! printf '%s\n' "$out" | rg -Fq 'WARN transition-issue dry-run failed' || fail "doctor still warns on dry-run with valid fake gh"
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
test_transition_issue_dry_run
test_transition_issue_edges
test_transition_issue_mutation
test_companion_uses_temporary_session
test_doctor_github
test_review_package
printf 'PASS code-flow tests\n'
