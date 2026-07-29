#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
has() { grep -Fq -- "$1" "$2" || fail "$2 missing: $1"; }
lacks() { ! grep -Fq -- "$1" "$2" || fail "$2 unexpectedly contains: $1"; }

[[ -f "$ROOT/SKILL.md" ]] || fail 'SKILL.md missing'
[[ -f "$ROOT/agents/openai.yaml" ]] || fail 'agents/openai.yaml missing'
[[ -f "$ROOT/references/workflow.md" ]] || fail 'workflow reference missing'
[[ -f "$ROOT/references/source-resolution.md" ]] || fail 'source-resolution reference missing'
[[ -f "$ROOT/references/impact-lifecycle.md" ]] || fail 'impact-lifecycle reference missing'
[[ -f "$ROOT/references/gate-template.md" ]] || fail 'gate template reference missing'
[[ -f "$ROOT/evals/evals.json" && -f "$ROOT/evals/run-evals.mjs" ]] || fail 'eval harness missing'
[[ -f "$ROOT/evals/trigger-evals.json" ]] || fail 'trigger eval catalog missing'
[[ ! -d "$ROOT/assets" && ! -d "$ROOT/scripts" ]] || fail 'placeholder runtime directory present'
[[ ! -f "$ROOT/STANDARD.md" ]] || fail 'STANDARD.md copy present'

[[ $(grep -c '^---$' "$ROOT/SKILL.md") -eq 2 ]] || fail 'invalid frontmatter delimiters'
has 'name: casa-workflow' "$ROOT/SKILL.md"
has 'description:' "$ROOT/SKILL.md"
[[ $(sed -n '2,/^---$/p' "$ROOT/SKILL.md" | grep -Ec '^[a-zA-Z0-9_-]+:') -eq 2 ]] || fail 'frontmatter must contain only name and description'
[[ $(wc -l < "$ROOT/SKILL.md") -le 45 ]] || fail 'SKILL.md must remain a compact router'
[[ $(wc -w < "$ROOT/SKILL.md") -le 400 ]] || fail 'SKILL.md exceeds router word budget'
has '[workflow.md](references/workflow.md)' "$ROOT/SKILL.md"
has 'por completo antes de analisar' "$ROOT/SKILL.md"
has 'agir.' "$ROOT/SKILL.md"
has '[source-resolution.md](source-resolution.md)' "$ROOT/references/workflow.md"
has '[impact-lifecycle.md](impact-lifecycle.md)' "$ROOT/references/workflow.md"
has '[gate-template.md](gate-template.md)' "$ROOT/references/workflow.md"
for section in 'Contexto CASA' 'Achados por risco' 'Impacto de artefatos' 'Ações antes do código' 'Obrigações de fechamento' 'Efeitos externos' 'Gate'; do has "$section" "$ROOT/references/gate-template.md"; done
has 'omita-o por completo' "$ROOT/references/gate-template.md"
for marker in 'título vazio' '`nenhum`' '`não aplicável`' '`N/A`' 'placeholder'; do has "$marker" "$ROOT/references/gate-template.md"; done
has '`Efeitos externos` aparece somente' "$ROOT/references/gate-template.md"
has 'externo concreto' "$ROOT/references/gate-template.md"
has 'parar antes da primeira escrita' "$ROOT/SKILL.md"
for choice in '`Aprovar`' '`Ajustar`' '`Bloquear`'; do has "$choice" "$ROOT/SKILL.md"; done
has 'gate_valido=false' "$ROOT/SKILL.md"
has 'preaprovação alegada' "$ROOT/SKILL.md"
has 'ADR e Spec' "$ROOT/references/workflow.md"
has 'atplus-digital/casa-standard' "$ROOT/references/workflow.md"
has 'Homônimos chamados CASA não são fontes' "$ROOT/references/workflow.md"
has 'allow_implicit_invocation: true' "$ROOT/agents/openai.yaml"
has 'Use $casa-workflow' "$ROOT/agents/openai.yaml"
lacks '[TODO' "$ROOT/SKILL.md"

node -e 'const p=require(process.argv[1]); for (const k of ["test","validate","build"]) if (!p.scripts?.[k]) process.exit(1)' "$ROOT/package.json" || fail 'package scripts missing'
jq -e '.skill_name=="casa-workflow" and (.evals|length>=7)' "$ROOT/evals/evals.json" > /dev/null || fail 'eval catalog invalid'
jq -e 'length==10 and (map(select(.should_trigger==true))|length)==5 and (map(select(.should_trigger==false))|length)==5' "$ROOT/evals/trigger-evals.json" > /dev/null || fail 'trigger eval catalog invalid'

printf 'PASS: casa-workflow tests\n'
