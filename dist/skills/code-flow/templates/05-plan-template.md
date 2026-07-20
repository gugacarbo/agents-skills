## Plano formal de implementação

Agent: `plan-writer`
Phase/scope: `plan / ciclo <k>/3`
Summary: `<resultado>`
Sources/evidence: `<links imutáveis e base SHA>`
Decisions: `<aplicadas ou none>`
Changes/validation: `<plano e validação>`
Blockers: `<blocker ou none>`
Resume operation: `<plan ou none>`
Resume stage: `<stage:needs-plan-fix ou none>`
Resume owner: `<plan-writer ou none>`
Next action: `plan-reviewer revisa este snapshot`

Source-set aprovado: `<URL do gate + digest do bloco; digest atual confirmado>`

### Objetivo e limites

**Objetivo:** …

**Fora de escopo:** …

### Critérios e verificação adaptativa

- [ ] …

| Tipo de mudança                 | Evidência anterior/falha       | Ação                    | Resultado binário esperado |
| ------------------------------- | ------------------------------ | ----------------------- | -------------------------- |
| `<código/docs/config/operação>` | `<RED, antes ou estado atual>` | `<comando/walkthrough>` | `<GREEN/depois/PASS>`      |

### Prova de rollback para migração

| Comando/simulação/demonstração | Resultado restaurado esperado |
| ------------------------------ | ----------------------------- |
| `<prova>`                      | `<critério binário>`          |

### Casos de borda, riscos e rollback

| Gatilho/risco | Resposta/mitigação | Rollback |
| ------------- | ------------------ | -------- |
| …             | …                  | …        |

_Após publicação, mover para needs-plan-review sem needs-human._
