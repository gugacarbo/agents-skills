---
status: accepted
date: 2026-07-20
builds-on: [ADR-0001]
superseded-by: null
deciders: [user]
---

# Code-flow deriva workflow do estado observado

## Contexto

ADR-0001 persistia `Workflow: native|fallback` no body. Isso duplicava o
estado já observável em labels e no mapeamento nativo, exigia migração de
metadata e deixava o header de issue maior que o necessário.

## Decisão

Persistir apenas `Complexity`. Um único `stage:*` seleciona fallback; sem stage,
o orquestrador revalida o mapeamento e usa native automaticamente se todas as
capacidades passam. Issue nova com mapeamento incompleto inicializa fallback.

Headers legados nunca são autoritativos e são removidos somente em edição
legítima do body. Header legado `Workflow: native` que perde capacidade pausa e
exige decisão humana para migrar ao fallback equivalente, com compensação.

## Consequências

- não há opt-in ou persistência de workflow por issue;
- retomada sempre usa estado e capacidades atuais;
- migração legada inválida continua explícita e auditável;
- source-set e digest permanecem independentes de metadata operacional.

## Confirmação

```bash
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-code-flow build
python3 scripts/docs-check --emit-index
```
