# Review — issue `<#n>` — ciclo `<k>`

> agent: <architect | reviewer>
> run_id: <uuid>
> protocol_version: <schema_version do workflow-states.json>
> event: <architecture-result | delivery-review-result>
> state_before: <stage:needs-architect + stage:in-progress | stage:needs-delivery-review + stage:in-progress>
> state_after: <stage:ready-for-execution | stage:awaiting-execution-approval + needs-human | stage:ready-to-merge + needs-human | stage:integration-authorized | stage:needs-changes | stage:blocked + needs-human>
> sources_evidence: <issue, guidance, código/testes e Base SHA | issue, arquitetura/outline, executor e PR/NO_CHANGES>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<resultado, decisão de spec/ADR, gaps/blockers e próximo gate | veredito, escopo, ressalvas e próximo responsável>

**Independência (reviewer):** não produzi issue, arquitetura, código ou evidência revisada.

**Veredito (reviewer):** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

## Arquitetura (architect)

<!-- code-flow:architect-review:start -->

### Objetivo e limites

<resultado, fora de escopo, dependências e restrições>

Base SHA: `<sha>`

### Decisão de spec/ADR

- **Ação:** `<create | update | not required>`
- **Fonte aceita:** `<URL/path ou not applicable>`
- **Padrão do repositório:** `<form/template/guidance ou none>`

#### Proposta de spec (`create`)

<conteúdo completo>

#### Diff de spec (`update`)

```diff
- <antes>
+ <depois>
```

#### Racional (`not required`)

<por que nenhuma spec/ADR muda>

### Gaps, necessidades e blockers

| Item     | Tipo  | Detalhe | Recomendação |
| -------- | ----- | ------- | ------------ |
| `<item>` | `<gap | need    | blocker>`    | `<descrição>` | `<ação>` |

### Casos de borda e riscos

| Caso/risco | Mitigação | Rollback ou n/a |
| ---------- | --------- | --------------- |
| `<caso>`   | `<ação>`  | `<prova>`       |

### Prova de rollback para migração

<prova executável ou not applicable>

### Blocker e retomada

- Estado a retomar: `<stage:needs-architect ou not applicable>`
- Responsável: `<architect | human | not applicable>`
- Impedimento: `<fato/evidência ou not applicable>`

<!-- code-flow:architect-review:end -->

## Delivery review (reviewer)

### Cobertura dos critérios

| Critério     | Evidência revisada | Resultado                       | Observação |
| ------------ | ------------------ | ------------------------------- | ---------- |
| `<critério>` | `<prova>`          | `PASS \| FAIL \| Cannot verify` | `<nota>`   |

### Reconciliação de escopo

| Autorizado | Entregue | Divergência               |
| ---------- | -------- | ------------------------- |
| `<item>`   | `<item>` | `<none ou justificativa>` |

### Achados

| Severidade | Local/prova | Impacto | Ação           | Issue draft         |
| ---------- | ----------- | ------- | -------------- | ------------------- |
| `Critical  | Important   | Minor   | Cannot verify` | `<file:line/prova>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

### NO_CHANGES

<prova revisada de ausência de diff e confirmação de nenhum commit/PR vazio>

### Consolidação de follow-ups

| Grupo     | Sugestões/origens | Justificativa                    | Issue draft |
| --------- | ----------------- | -------------------------------- | ----------- |
| `<grupo>` | `<itens e links>` | `<deduplicação/compatibilidade>` | `<URL>`     |

Sem itens, publique: `Nenhuma sugestão de issue não bloqueante encontrada`.

_Para cada Minor, use `references/follow-up-issue-drafts.md`. NO_CHANGES nunca é
DONE e, aprovado, segue sem gate humano para `stage:integration-authorized`._
