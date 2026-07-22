# Plano e autorização de execução

S sem hard trigger usa outline após ordem explícita. M/G/X/XL usam architect
e, depois, ordem humana explícita de execução. Plano formal usa
`templates/05-plan-template.md`. Não há reviewer autônomo nem gate formal de
plano: o snapshot publicado é a entrada para a autorização humana de execução.

Architect publica o primeiro snapshot em um único comentário canônico marcado
e registra sua URL/ID. Em correções, edita esse comentário in-place e publica
somente um comentário append-only com resumo breve das alterações, usando
`templates/18-plan-change-summary.md`; não adiciona outra cópia integral do
plano. Marcador ausente ou duplicado bloqueia a entrega até resolver o drift.
Somente após o plano canônico e, quando aplicável, seu changelog estarem
publicados, transicione `stage:needs-plan` para
`stage:approved + needs-human` e aguarde ordem explícita de execução.
O architect nunca autoriza execução, apenas entrega o snapshot para a decisão
humana. Manter `needs-plan` seria drift.

`needs-plan-fix` não é mais um estado usado: o architect corrige o comentário
canônico in-place e republica o resumo de alterações; caso o humano peça novo
ciclo, o estágio permanece `needs-plan` (com `needs-human` removido enquanto o
agente edita e devolvido ao fim da publicação). Se o executor ou o orquestrador
identificar decisão material depois da publicação, pare, promova rigor e só
retome com novo snapshot publicado.

## Autorização humana de execução

Apresente o checkpoint compartilhado com `Autorizar / Ajustar / Bloquear`:
autorizar move a `stage:in-progress` (depois da evidência de início do
executor) e consome a autorização; ajustar devolve a `needs-plan` ao
plan-writer para editar o canônico e republicar o resumo; bloquear preserva
`Resume`. Aprovação do plano e autorização de execução são a mesma decisão
humana: nunca inicie código sem ordem explícita e worktree isolada. O
checkpoint não se aplica ao outline S, que já depende de ordem explícita.
