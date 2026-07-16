## Plano de implementação

Agent: `plan-writer`
Phase/scope: `ciclo de plano <k>/3`
Summary: `<resultado do plano>`
Sources/evidence: `<links imutáveis das fontes e base SHA>`
Decisions: `<aplicadas, pendentes ou nenhuma>`
Changes/validation: `<mudanças do plano e validação, ou nenhuma>`
Blockers: `<blocker ou none>`
Next action: `plan-reviewer revisa este snapshot`

### Metadados do ciclo

| Campo | Valor |
| --- | --- |
| **Ciclo de plano** | `<k>/3` |
| **Base SHA** | `<full-sha>` |
| **Impacto de spec** | `create \| update \| not required` — `<motivo concreto>` |
| **Aprovação da proposta** | `<URL/comentário humano ou revisão imutável do repositório>` |
| **ADR/spec materializado** | `<blob URL imutável ou not required>` |

---

## Fontes do repositório

| Tipo | Referência |
| --- | --- |
| ADR/spec | `<blob URL imutável no SHA completo ou não aplicável>` |
| Comportamento atual | `<path:line no commit ou URL imutável>` |

---

## Objetivo e limites

**Objetivo:** …

**Fora de escopo:** …

---

## Critérios de aceite

- [ ] …
- [ ] …

---

## Verificação / TDD

| Etapa | Comando / evidência | Resultado esperado |
| --- | --- | --- |
| RED | `<teste ou comando>` | `<falha esperada>` |
| GREEN | `<teste ou comando>` | `<passa>` |
| Regressão | `<comando>` | `<exit 0 ou critério>` |

---

## Casos de borda (EARS)

| # | WHEN | the system MUST |
| --- | --- | --- |
| 1 | | |
| 2 | | |

---

## Definição de pronto

- [ ] Critérios de aceite verificados
- [ ] Casos EARS cobertos ou justificados
- [ ] Verificação/TDD executada conforme plano
- [ ] …

---

## Riscos, rollout e rollback

| Risco | Mitigação | Rollback |
| --- | --- | --- |
| … | … | … |

---

*Processo: code-flow — snapshot append-only do plano (envelope de oito campos).
Não decompor este plano em task IDs. O executor pode organizar o trabalho
internamente; a evidência e a review cobrem o plano aprovado como uma unidade.
Review independente e aprovação humana deste snapshot exato são obrigatórias.*
