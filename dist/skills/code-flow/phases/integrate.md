# Integração e fechamento

O orquestrador é proprietário das transições causadas pelos gates finais.

## Com diff: `stage:ready-to-merge`

Confirme auditoria aplicável, DoD, commits, checks e aprovação exigida do PR.
Apresente
[`templates/14-human-gate-merge.md`](../templates/14-human-gate-merge.md):

- `Integrar`: execute merge mecânico, verifique o alvo, feche issue e limpe
  stage/needs-human;
- `Ajustar`: mova a `stage:needs-changes`, limpe needs-human e devolva ao
  executor;
- `Aguardar`: mantenha `stage:ready-to-merge + needs-human` sem mutar PR.

Merge nunca é automático, mesmo com PR aprovada.
Sempre mostre as três opções literais `Integrar / Ajustar / Aguardar`; não
resuma o checkpoint apenas à opção recomendada.

## Sem diff: `stage:ready-to-close`

Apresente
[`templates/17-human-gate-close.md`](../templates/17-human-gate-close.md):

- `Fechar`: registre evidência, feche issue e limpe estado sem commit/PR/merge;
- `Ajustar`: volte a `stage:needs-changes`;
- `Aguardar`: mantenha `stage:ready-to-close + needs-human`.

Sempre mostre as três opções literais `Fechar / Ajustar / Aguardar`.
Fechamento e limpeza só ocorrem depois de `Fechar` explícito.

## Falha e blocker

Achado corrigível volta a changes. Dependência externa usa blocker com resume
target. Falha transitória de merge/check mantém a issue pronta e reporta a
causa; não invente sucesso nem feche a issue.

Registre o resultado mecânico com
[`templates/09-integration-report-template.md`](../templates/09-integration-report-template.md).

## Epic

Quando todas as filhas in-scope terminarem, verifique medidas de sucesso e
decisões transversais e apresente checkpoint humano. Só então feche o Epic.
