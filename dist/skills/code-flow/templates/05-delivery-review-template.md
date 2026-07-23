> agent: reviewer
> run_id: <uuid distinto dos autores>
> event: delivery-review-result
> state_before: stage:needs-delivery-review + stage:in-progress
> state_after: <stage:ready-to-merge + needs-human | stage:integration-authorized | stage:needs-changes | stage:blocked + needs-human>
> sources_evidence: <issue, arquitetura/outline, executor e PR/NO_CHANGES>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<veredito, escopo, ressalvas e próximo responsável>

**Independência:** não produzi issue, arquitetura, código ou evidência revisada.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

## Cobertura dos critérios

| Critério     | Evidência revisada | Resultado | Observação |
| ------------ | ------------------ | --------- | ---------- |
| `<critério>` | `<prova>`          | `PASS     | FAIL       | Cannot verify` | `<nota>` |

## Reconciliação de escopo

| Autorizado | Entregue | Divergência               |
| ---------- | -------- | ------------------------- |
| `<item>`   | `<item>` | `<none ou justificativa>` |

## Achados

| Severidade | Local/prova | Impacto | Ação           | Issue draft         |
| ---------- | ----------- | ------- | -------------- | ------------------- |
| `Critical  | Important   | Minor   | Cannot verify` | `<file:line/prova>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

## NO_CHANGES

<prova revisada de ausência de diff e confirmação de nenhum commit/PR vazio>

## Consolidação de follow-ups

| Grupo     | Sugestões/origens | Justificativa                    | Issue draft |
| --------- | ----------------- | -------------------------------- | ----------- |
| `<grupo>` | `<itens e links>` | `<deduplicação/compatibilidade>` | `<URL>`     |

Sem itens, publique: `Nenhuma sugestão de issue não bloqueante encontrada`.

_Para cada Minor, use `references/follow-up-issue-drafts.md`. NO_CHANGES nunca é
DONE e, aprovado, segue sem gate humano para `stage:integration-authorized`._
