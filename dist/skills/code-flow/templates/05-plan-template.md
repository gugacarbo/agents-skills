> agent: plan-writer
> phase_scope: plan / ciclo <k>/3
> sources_evidence: <links imutáveis e base SHA>
> decisions: <aplicadas ou none>
> changes_validation: <plano e validação>
> blockers: <blocker ou none>

## Resume

<resumo claro da entrega, decisão envolvida e resultado esperado para revisão humana>

## Objetivo

<resultado que o plano entrega>

## Limites

<fora de escopo, dependências e restrições>

Source-set aprovado: `<URL do gate + digest atual confirmado>`

## Critérios de aprovação

| Critério                        | Evidência anterior/falha       | Ação                    | Resultado binário esperado |
| ------------------------------- | ------------------------------ | ----------------------- | -------------------------- |
| `<código/docs/config/operação>` | `<RED, antes ou estado atual>` | `<comando/walkthrough>` | `<GREEN/depois/PASS>`      |

## Casos de borda/testes, riscos e rollback

| Gatilho ou teste | Resposta/mitigação | Rollback |
| ---------------- | ------------------ | -------- |
| `<caso>`         | `<ação>`           | `<ação>` |

## Prova de rollback para migração

Use apenas para migração: descreva como a reversão será exercitada e qual estado
restaurado demonstra que o rollback é seguro.

| Comando/simulação/demonstração | Resultado restaurado esperado |
| ------------------------------ | ----------------------------- |
| `<prova>`                      | `<critério binário>`          |

_Após publicação, mover para needs-plan-review sem needs-human._
