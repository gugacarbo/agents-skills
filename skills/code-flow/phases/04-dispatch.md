# Fase 4: Dispatch

Despache só após aprovação do plano, ou para corrigir achados quando a issue
estiver em `stage:needs-changes`. A primeira execução exige `stage:approved`,
pedido explícito de implementação e `worktree` ou `later`. `later` adiciona
`needs-human` e não muda código; `worktree` remove essa label e muta para
`stage:in-progress`. Em `needs-changes`, despache o executor sobre os achados
da review sem novo pedido de `worktree` se a worktree já existir.
Nunca executar no checkout compartilhado sem worktree isolada.

Despache apenas `agents/05-executor.md`. Ele recebe URL da issue, revisão do
plano, base SHA, escopo/limites, critérios de aceite, verificação e destino da
evidência. Implementa o plano aprovado como uma unidade — sem lista
decomposable de tasks — e pode organizar o trabalho internamente. Publica
`templates/07-implementation-evidence-template.md`. Um resultado `BLOCKED` para:
mute labels para `stage:blocked` + `needs-human` após o comentário de evidência.

Use uma worktree/branch/PR por issue. Quando existir evidência não bloqueada do
executor para o plano aprovado, mutue labels para `stage:needs-delivery-review`.
