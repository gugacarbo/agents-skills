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

Ao criar um batch para investigação posterior, descubra o Project V2 gravável
e o repositório alvo de cada item. Use
`templates/17-batch-pre-issue-draft.md` e crie cada pré-issue como um item cujo
tipo observado seja `DRAFT_ISSUE`. Verifique o tipo após a mutação. Enquanto
for draft, não aplique labels, `stage:*`, número de repository issue ou workflow
de entrega.

Se o Project V2 estiver ausente, ambíguo ou sem acesso de escrita, pare e peça
o alvo correto; não crie repository issues abertas como fallback e não simule
draft com título, label ou comentário. O `issue-writer` investiga a codebase e
completa o body ainda no draft. A promoção pertence a issue-writer ou orquestrador.
Depois da evidência, um deles pode converter o item; confirme URL, número,
repositório e tipo `ISSUE` antes de iniciar o fluxo normal de `phases/issue.md`.

`--from` é piso: issue anterior é inelegível; issue no piso ou adiante continua
do próprio gate sem pular ou retroceder. Estado, worktree, falha e gate ficam
isolados por issue.
