# Nota operacional — issue `<#n>`

> agent: <issue-writer | architect | executor | reviewer | integrator | papel>
> run_id: <uuid ou n/a para gate>
> event: <activity-start | architect-change | gate-decision | activity-reset | migration | stop | failure>
> state_before: <estado principal | labels>
> state_after: <estado principal + stage:in-progress | labels>
> sources_evidence: <issue, artefatos, Base/Head e branch/worktree quando aplicável | links/comandos/fontes>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<papel, resultado esperado e como retomar com este run_id | evento, consequência e próximo responsável>

## Início (activity-start)

- Estado principal: `<stage:*>`
- Iniciado em: `<ISO-8601>`
- Resultado esperado: `<artefato e próximo estado>`
- Base/Head: `<sha/sha ou n/a>`
- Branch/worktree: `<valor ou n/a>>

_Publique antes de adicionar `stage:in-progress`. O overlay é cooperativo e não
constitui lock atômico._

## Evidência e impacto (demais eventos)

| Fato     | Evidência      | Impacto     | Próximo passo |
| -------- | -------------- | ----------- | ------------- |
| `<fato>` | `<link/saída>` | `<impacto>` | `<ação>`      |

## Alterações do architect (architect-change)

<resumo breve apontando ao comentário canônico ou not applicable>

_Nota append-only; não substitui issue, relatório, review ou evidência final._
