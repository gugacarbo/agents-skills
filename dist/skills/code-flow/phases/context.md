# Contexto, discovery e retomada

Discovery sem issue é read-only: leia guidance, forms, ADR/spec, código/testes,
labels, comentários, PRs e entregas antes de perguntar fatos descobríveis.

Antes de operar issue, confirme entrega/bug, proponha Complexity, recalcule
risco e aplique a tabela de `references/github-flow.md`: um stage é fallback;
zero stage reavalia native; múltiplos stages bloqueiam por drift.

Issue nova com mapeamento native incompleto inicializa fallback equivalente.
Header legado `Workflow: native` que agora falha pausa e abre gate humano de
migração; headers legados nunca controlam o fluxo e só somem numa edição
legítima do body. Blocker resolvido lê `## Resume`, recalcula risco e valida o
destino antes de transicionar.

## Batch

`--from` é piso: issue anterior é inelegível; issue no piso ou adiante continua
do próprio gate sem pular ou retroceder. Estado, worktree, falha e gate ficam
isolados por issue.
