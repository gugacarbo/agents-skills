# code-flow

Coordena entregas não triviais via papéis independentes, issues GitHub, gates
de aprovação e evidência de PR.

Comandos, fases e regras canônicas: [SKILL.md](SKILL.md).

Contratos: [references/github-flow.md](references/github-flow.md),
[templates/evidence-contract-template.md](templates/evidence-contract-template.md),
[references/orchestrator-cheatsheet.md](references/orchestrator-cheatsheet.md).

## Estados da issue

```mermaid
flowchart TD
  spec["stage:spec-approval"] -->|"aprovação da proposta"| plan["stage:needs-plan"]
  spec -->|"issue-reviewer pede ajustes"| issueFix["stage:needs-issue-fix"]
  issueFix -->|"issue-writer corrige o source-set"| spec
  plan -->|"plano publicado"| planReview["stage:needs-plan-review"]
  planReview -->|"plano aprovado + aprovação humana"| approved["stage:approved"]
  planReview -->|"plan-reviewer pede ajustes (ciclo < 3)"| planFix["stage:needs-plan-fix"]
  planFix -->|"plan-writer publica novo ciclo"| planReview
  approved -->|"worktree + execução autorizada"| progress["stage:in-progress"]
  progress -->|"evidência do executor"| deliveryReview["stage:needs-delivery-review"]
  deliveryReview -->|"review aprovada"| ready["stage:ready-to-merge"]
  deliveryReview -->|"ajustes solicitados"| changes["stage:needs-changes"]
  ready -->|"auditoria final pede ajustes"| changes
  changes -->|"nova evidência"| deliveryReview
  ready -->|"DoD, aprovação do PR e merge"| closed["Fechada (sem stage)"]

  spec -. "decisão humana ou dependência externa" .-> blocked["stage:blocked + needs-human"]
  planReview -. "rejeição, erro ou 3º ajuste" .-> blocked
  progress -. "blocker" .-> blocked
  deliveryReview -. "decisão de produto/acesso" .-> blocked
```

`needs-human` é uma label ortogonal: aparece nos gates de aprovação e em
`stage:blocked`, mas não substitui o `stage:*` atual.

## Quando usar code-flow vs super-planning

- **code-flow:** entrega governada com ADR/spec, stages GitHub, gates humanos e
  evidência de PR; um plano aprovado executado como unidade (sem task IDs).
- **super-planning:** decomposição multi-step com task registry, progresso
  local e dispatch paralelo/sequencial de subagentes.

Nome histórico: entregas antigas neste repo podem citar `code-toolbox`; a skill
publicada é `code-flow` (não reescreva evidência histórica em `docs/delivery/`).
