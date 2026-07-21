---
status: superseded
date: 2026-07-17
builds-on: []
superseded-by: ADR-0002
deciders: [user]
---

# Code-flow persiste contexto operacional sem transformar esforço em risco

> VERDADE ATUAL: substituído por ADR-0002. `Complexity` continua persistida,
> mas o workflow é derivado dinamicamente de `stage:*` e do mapeamento nativo;
> nenhum header `Workflow` controla ou registra o fluxo.

## Contexto e problema

O fluxo anterior proibia qualquer atuação sem issue, esquecia o opt-in nativo
em toda retomada e usava o body inteiro como unidade de aprovação. Isso criava
repetição, drift ambíguo e invalidação de source-set por metadata, enquanto
transições após decisões humanas não tinham owner completo.

## Direcionadores da decisão

- permitir discovery e decisões antes da formalização sem antecipar plano/código;
- retomar uma única máquina de estado de forma auditável;
- separar esforço/coordenação de risco e hard triggers;
- proteger exatamente o source-set aprovado;
- manter independência, worktree e gates humanos explícitos.

## Opções consideradas

### Opção 1 — Estado totalmente efêmero

**Prós:** body menor e nenhuma migração de metadata.

**Contras:** repete opt-in, não distingue issue nativa de fallback incompleto e
dificulta retomada.

### Opção 2 — Persistir perfil de risco

**Prós:** roteamento simples.

**Contras:** congela uma avaliação que precisa ser recalculada e permite
confundir esforço pequeno com risco baixo.

### Opção 3 — Persistir Complexity e Workflow

**Prós:** torna esforço e máquina retomáveis sem congelar risco; permite tabela
de verdade e migração legada.

**Contras:** exige metadata, validação de drift e migração native→fallback.

## Decisão

Adotar a opção 3. `Complexity: S|M|G|X|XL` representa esforço/coordenação e
apenas sugere o caminho inicial; hard triggers sempre promovem. `Workflow:
native|fallback` registra a máquina por issue. Discovery/brainstorm podem ser
pré-issue, mas plano, código, review e integração continuam issue-based.

O source-set recebe marcadores canônicos e digest próprio. Agentes aplicam as
transições causadas por seus artefatos; o orquestrador valida todas e executa
as causadas por decisões humanas.

## Consequências

- issues novas e legadas ganham metadata operacional fora do source-set;
- contradição entre header e estado bloqueia em vez de escolher silenciosamente;
- escolha native é reutilizada enquanto o mapeamento permanece válido;
- native inválido só migra após aceite explícito e recuperação compensável;
- `NO_CHANGES` exige review e gate de fechamento sem commit/PR vazio;
- blockers preservam operação, stage e owner de retorno.

## Confirmação

```bash
pnpm --filter @gugacarbo/skill-code-flow test
python3 scripts/docs-check
pnpm skills-check
```

## Notas

O risco continua efêmero e nunca é persistido pelo nome interno.
