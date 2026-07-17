## Plano formal de implementação

Agent: `plan-writer`
Phase/scope: `plan / ciclo <k>/3`
Summary: `<resultado>`
Sources/evidence: `<links imutáveis e base SHA>`
Decisions: `<aplicadas ou none>`
Changes/validation: `<plano e validação>`
Blockers: `<blocker ou none>`
Next action: `plan-reviewer revisa este snapshot`

Source-set aprovado: `<URL do gate + SHA-256 do body; digest atual confirmado>`

### Objetivo e limites

**Objetivo:** …

**Fora de escopo:** …

### Critérios de aceite e verificação

- [ ] …

| Etapa     | Comando/evidência | Resultado esperado   |
| --------- | ----------------- | -------------------- |
| RED       | `<teste>`         | `<falha esperada>`   |
| GREEN     | `<teste>`         | `<passa>`            |
| Regressão | `<suite>`         | `<critério binário>` |

### Prova de rollback (obrigatória para migração)

| Comando/simulação/demonstração | Resultado binário esperado        |
| ------------------------------ | --------------------------------- |
| `<como provar o rollback>`     | `<estado restaurado verificável>` |

### Casos de borda, riscos e rollback

| Gatilho/risco | Resposta/mitigação | Rollback |
| ------------- | ------------------ | -------- |
| …             | …                  | …        |

_Plano formal append-only, sem task IDs. Review independente e aprovação
humana deste snapshot são obrigatórias antes da execução._
