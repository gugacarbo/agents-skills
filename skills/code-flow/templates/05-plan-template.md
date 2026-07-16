## Plano de implementação

Agent: `plan-writer`
Phase/scope: `ciclo de plano <k>/3`
Summary: `<resultado do plano>`
Sources/evidence: `<links imutáveis das fontes e base SHA>`
Decisions: `<aplicadas, pendentes ou nenhuma>`
Changes/validation: `<mudanças do plano e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `plan-reviewer revisa este snapshot`

**Ciclo de plano:** `1/3`
**Base SHA:** `<full-sha>`
**Impacto de spec:** `create | update | not required` — `<motivo concreto>`
**Aprovação da proposta:** `<URL/comentário humano ou revisão imutável do repositório>`
**ADR/spec materializado:** `<blob URL imutável ou not required>`

## Fontes do repositório

- ADR/spec: `<blob URL imutável no SHA completo ou não aplicável>`
- Evidência do comportamento atual: `<path:line no commit ou URL imutável>`

## Objetivo e limites

…

## Critérios de aceite

- …

## Verificação / TDD

…

## Casos de borda (EARS)

| # | WHEN | the system MUST |
| --- | --- | --- |
| 1 | | |

## Definição de pronto

- [ ] …

## Riscos, rollout e rollback

…

---

*Processo: code-flow — snapshot append-only do plano (envelope de oito campos).
Não decompor este plano em task IDs. O executor pode organizar o trabalho
internamente; a evidência e a review cobrem o plano aprovado como uma unidade.
Review independente e aprovação humana deste snapshot exato são obrigatórias.*
