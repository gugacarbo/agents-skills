> agent: orchestrator
> phase_scope: <brainstorm | issue | plan | dispatch | review | integrate | epic>
> sources_evidence: <artefatos e evidências que fundamentam o gate>
> decisions: <decisão solicitada>
> changes_validation: <transição que será confirmada>
> blockers: <blocker ou none>

## Resume

<resumo humano da decisão solicitada e do motivo do gate>

## Estado atual

<stage/estado nativo, artefato aprovado e contexto observável>

## Resumo do gate

<o que a pessoa precisa decidir agora, sem substituir a instrução específica da fase>

## Impactos

| Opção                | Workflow/estado | Artefatos/evidências | Consequência                      |
| -------------------- | --------------- | -------------------- | --------------------------------- |
| `<resposta literal>` | `<transição>`   | `<registro>`         | `<autoriza, devolve ou bloqueia>` |

## Decisão solicitada

| Resposta                  | Ação do orquestrador   |
| ------------------------- | ---------------------- |
| `<opção literal da fase>` | `<ação e confirmação>` |

_As opções, transições e proibições próprias de cada fase vivem nas instruções
daquela fase. Este template apenas apresenta o gate de forma consistente._
