# Dispatch e execução

Antes de executar, recalcule risco e confirme que o estado cobre o escopo
atual. Toda execução usa worktree isolada.

Em mudança interna, `stage:approved + needs-human` significa somente “aguarda
ordem explícita de execução”. Após a ordem, crie worktree automaticamente,
remova `needs-human`, mova a `stage:in-progress` e despache
`agents/05-executor.md`; não ofereça `worktree|later`. O executor publica o
outline compacto e implementa na mesma invocação.

Nos demais caminhos, `stage:approved` exige plano formal revisado e aprovado.
A ordem de execução cria a worktree e move a `stage:in-progress`.

O executor publica `templates/07-implementation-evidence-template.md`.
`BLOCKED` vai a `stage:blocked + needs-human`. Evidência não bloqueada move a
`stage:needs-delivery-review`. Correções em `stage:needs-changes` retornam ao
mesmo executor/worktree e depois à review.
