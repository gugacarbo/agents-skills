# Design futuro: runner VPS da code-flow

> Status: planejado, não implementado e não publicado com a skill.

A `code-flow` atual coordena trabalho por labels cooperativas. Não oferece claim
atômico, worker identity, heartbeat, lease ou recuperação automática.

Um runner externo futuro poderá consumir `workflow-states.json` e oferecer:

1. descoberta por webhook/poll;
2. claim atômico em serviço externo ou Project V2;
3. worker/run identity e heartbeat;
4. retry e expiração;
5. worktree isolada por issue/run;
6. despacho portátil dos papéis.

Até esse componente existir, overlay inconsistente exige decisão humana
`activity reset`; nenhum script da skill deve alegar exclusão concorrente.
