<!--
Preencha os campos e mantenha exatamente um par de marcadores.
Publique como Markdown cru. Não use blocos de código cercados para envolver o
relatório; headings, listas e linhas de tabela começam na coluna 1. Se houver
um exemplo de código ou diff, encerre-o antes do heading seguinte.
-->

> agent: architect
> run_id: <uuid>
> event: architecture-result
> state_before: stage:needs-architect + stage:in-progress
> state_after: <destino>
> sources_evidence: <issue, guidance, código/testes e Base SHA>
> project_guidance: <paths e comandos>

<!-- code-flow:event:v1 {"event_id":"<uuid>","run_id":"<uuid>","role":"architect","event":"architecture-review"} -->

## Resume

<decisão técnica, spec/ADR, riscos e próximo responsável>

<!-- code-flow:architect-review:start -->

## Solução e fronteiras técnicas

<abordagem, componentes, contratos e limites; referencie objetivo/DoD da issue>

Base SHA: `<sha>`

## Decisão de spec/ADR

- Ação: `<create | update | not required>`
- Fonte aceita: `<URL/path ou n/a>`
- Conteúdo/diff/racional: <material completo>

## Riscos, casos de borda e rollback

| Risco/caso | Mitigação | Rollback/prova |
| ---------- | --------- | -------------- |
| `<item>`   | `<ação>`  | `<prova>`      |

## Validação e blockers

| Item     | Evidência | Ação     |
| -------- | --------- | -------- |
| `<item>` | `<prova>` | `<ação>` |

## Veredito final

Veredito: `EXECUÇÃO DIRETA | REQUER APROVAÇÃO HUMANA | BLOQUEADO`
Destino: `stage:ready-for-execution | stage:awaiting-execution-approval | stage:blocked`
Justificativa: <síntese baseada em complexidade, hard triggers, spec/ADR e blockers>
Próximo responsável: `<executor | gate | architect após desbloqueio>`

<!-- code-flow:architect-review:end -->
