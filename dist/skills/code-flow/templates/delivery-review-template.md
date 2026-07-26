<!-- Use somente em instância nova e liste todos os run_ids produtores. -->

> agent: code-reviewer
> run_id: <uuid novo>
> event: delivery-review-result
> state_before: stage:needs-delivery-review + stage:in-progress
> state_after: <destino>
> sources_evidence: <issue, planejamento/arquitetura, executor e PR/NO_CHANGES>
> project_guidance: <paths e comandos>

## Resume

<veredito, escopo, ressalvas e próximo responsável>

Produtores revisados: `<agent:run_id, ...>`
Instância independente: `sim`
Veredito: `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

## Cobertura dos critérios

| Critério     | Evidência | Resultado | Observação |
| ------------ | --------- | --------- | ---------- |
| `<critério>` | `<prova>` | `PASS     | FAIL       | Cannot verify` | `<nota>` |

## Reconciliação de escopo

| Autorizado | Entregue | Divergência               |
| ---------- | -------- | ------------------------- |
| `<item>`   | `<item>` | `<none ou justificativa>` |

## Achados

| Severidade | Local/prova | Impacto | Ação           | Issue draft |
| ---------- | ----------- | ------- | -------------- | ----------- |
| `Critical  | Important   | Minor   | Cannot verify` | `<prova>`   | `<impacto>` | `<ação>` | `<link ou n/a>` |

## NO_CHANGES

<prova revisada ou not applicable>

## Consolidação de follow-ups

| Grupo     | Origens   | Justificativa    | Issue draft |
| --------- | --------- | ---------------- | ----------- |
| `<grupo>` | `<itens>` | `<deduplicação>` | `<URL>`     |

<!-- Sem itens, escreva: Nenhuma sugestão de issue não bloqueante encontrada. -->
