---
process: code-flow
base-sha: <full-sha>
sources: []
---

# <Título da entrega>

Este é um registro de entrega versionado, não um registry gerado. Mantenha cada
snapshot abaixo append-only e faça commit de cada atualização material. Vincule
toda fonte, review, evidência e DoD a um SHA completo ou URL imutável do
repositório. Toda execução/resultado de agente usa o envelope ordenado de oito
campos: `Agent`, `Phase/scope`, `Summary`, `Sources/evidence`, `Decisions`,
`Changes/validation`, `Blockers` e `Next action`.

**Caminho padrão:** `docs/delivery/<slug>.md`. Antes de criar o arquivo,
pergunte ao usuário se deve usar outro caminho.

Este registro é a única superfície de coordenação no modo `direct`: nunca criar
issue nem usar comentários, labels ou stages do GitHub.

## Envelope de execução do agente

Anexe esta seção uma vez para cada resultado de agente, incluindo sem mudança,
`BLOCKED`, review rejeitada, erro ou veredito ausente. Não substitua uma seção
anterior.

Agent: `<role>`
Phase/scope: `<fase, ciclo, range ou auditoria>`
Summary: `<resultado conciso>`
Sources/evidence: `<fonte imutável, commit, comando, saída ou none>`
Decisions: `<aplicadas, pendentes ou nenhuma>`
Changes/validation: `<arquivos/efeito e validação, ou nenhuma>`
Blockers: `<blocker e decisão humana necessária, ou none>`
Next action: `<ação e owner>`

## Aprovação da proposta de ADR/spec

- **ADR/spec aceito ou racional no-spec aprovado:** …
- **Proposta / racional no-spec:** …
- **Evidência de aprovação humana:** …
- **Link imutável do ADR/spec materializado:** …
- **Revisão da fonte:** `<SHA completo / URL imutável>`

## Snapshot do plano — ciclo `<k>/3`

- **Revisão do plano:** `<SHA completo / URL imutável>`
- **Objetivo, limites, aceite, verificação, EARS e DoD:** …

## Review independente do plano

- **Revisão da review:** `<SHA completo / URL imutável>`
- **Independência do reviewer:** …
- **Veredito:** `APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO`
- **Resume:** `<Fase 3 | parar aguardando decisão humana>`

## Evidência de implementação e reviews de código

| Entrega | Status | Commit/range | Revisão da evidência | Revisão da review independente |
| --- | --- | --- | --- | --- |
| Plano aprovado | `DONE | DONE_WITH_CONCERNS | BLOCKED | CANCELLED` | | | |

`CANCELLED` exige a decisão imutável de cancelamento do usuário na coluna de
evidência e `review: not applicable`.

Para cada `BLOCKED`, review rejeitada, falha de auditoria ou item de DoD
pendente, anexe o blocker exato e `Resume: Phase 4` aqui.

## DoD e auditoria final

- **Revisão e independência da auditoria:** …
- **Comando/resultado do DoD:** …
- **Decisão opcional de merge do PR:** `not applicable | awaiting explicit request | merged at <SHA>`
