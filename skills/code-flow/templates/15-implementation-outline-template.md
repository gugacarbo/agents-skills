---
agent: executor
phase_scope: execução S autorizada / início
sources_evidence: <issue, digest, base SHA, código e testes>
decisions: <abordagem e limites>
changes_validation: nenhuma mudança ainda; publicar antes de in-progress
blockers: <blocker ou none>
---

> <resumo claro da mudança, motivo, resultado esperado e fora de escopo>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Resumo para execução

<mudança autorizada, motivo, resultado esperado e fora de escopo>

## Prontidão para execução

| Ordem explícita | Worktree/branch    | Base SHA |
| --------------- | ------------------ | -------- |
| `<evidência>`   | `<caminho/branch>` | `<sha>`  |

## Áreas, mudanças e validação

| Área/arquivo | Mudança   | Validação esperada |
| ------------ | --------- | ------------------ |
| `<área>`     | `<passo>` | `<prova>`          |

## Rollback

| Condição de disparo | Ação concreta de reversão |
| ------------------- | ------------------------- |
| `<condição>`        | `<ação>`                  |

## Condições para parar e promover

<contrato público, risco novo, comportamento inesperado ou drift material
interrompem S e retornam ao primeiro gate aplicável.>
