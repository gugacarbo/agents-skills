# Integração e fechamento

O orquestrador é proprietário dos gates finais e registra o resultado mecânico
com `templates/09-integration-report-template.md`.

## Com diff: ready-to-merge

Use o gate compartilhado com `Integrar / Ajustar / Aguardar`. Integrar executa
merge, confirma o alvo, fecha issue e limpa workflow; Ajustar move a
needs-changes; Aguardar mantém pronto. Merge nunca é automático.

## Sem diff: ready-to-close

Use o gate compartilhado com `Fechar / Ajustar / Aguardar`. Fechar registra
evidência, fecha issue e limpa workflow sem commit, PR ou merge; Ajustar volta
a needs-changes; Aguardar mantém pronto.

## Falha, blocker e Epic

Falha transitória preserva estado pronto e registra causa em nota isolada;
dependência externa usa Resume e gate compartilhado quando exigir decisão. Epic
fecha somente após checkpoint compartilhado `Fechar Epic / Replanejar /
Aguardar`, com filhas, medidas e decisões transversais verificadas.
