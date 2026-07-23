> agent: <issue-writer | architect | executor | reviewer | integrator>
> run_id: <uuid>
> event: activity-start
> state_before: <estado principal>
> state_after: <estado principal + stage:in-progress>
> sources_evidence: <issue, artefatos, Base/Head e branch/worktree quando aplicável>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<papel, resultado esperado e como retomar com este run_id>

## Início

- Estado principal: `<stage:*>`
- Iniciado em: `<ISO-8601>`
- Resultado esperado: `<artefato e próximo estado>`
- Base/Head: `<sha/sha ou n/a>`
- Branch/worktree: `<valor ou n/a>`

_Publique antes de adicionar `stage:in-progress`. O overlay é cooperativo e não
constitui lock atômico._
