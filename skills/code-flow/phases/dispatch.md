# Dispatch e execução

Antes da ordem, recalcule risco, valide estado dinâmico, digest,
relatório de arquitetura/outline e base SHA. Ordem explícita autoriza dispatch;
orquestrador cria worktree isolada. Em S, executor publica outline; nos demais
caminhos referencia relatório de arquitetura aprovado. Evidência de início
precede `stage:in-progress`.

Drift material, contrato público, risco novo ou comportamento inesperado
interrompe código e retorna ao primeiro gate aplicável. Falha corrigível fica
in-progress; blocker usa Resume e gate compartilhado quando exigir decisão.

Executor publica evidência condicional de DONE, DONE_WITH_CONCERNS, NO_CHANGES
ou BLOCKED antes da transição. Com diff, DONE e DONE_WITH_CONCERNS exigem
commit, push e PR publicado, cuja URL remota entra na evidência; sem isso a
execução permanece in-progress ou bloqueia quando depender de acesso, decisão
ou serviço externo. Os três primeiros seguem a delivery review; NO_CHANGES
nunca cria commit/PR vazio.
