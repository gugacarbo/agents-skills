> agent: executor
> run_id: <uuid>
> event: <implementation-outline | implementation-result>
> state_before: <estado> + stage:in-progress
> state_after: <estado>
> sources_evidence: <issue, Base/Head, código, testes, commits e PR>
> project_guidance: <paths e comandos>

## Resume

<objetivo ou DONE | DONE_WITH_CONCERNS | NO_CHANGES | BLOCKED>

<!-- Publique Planejamento antes de editar e complete o restante ao terminar. -->

## Planejamento

| Escopo   | Áreas     | Validação    |
| -------- | --------- | ------------ |
| `<item>` | `<paths>` | `<comandos>` |

| Worktree/branch | Base SHA | Rollback |
| --------------- | -------- | -------- |
| `<valor>`       | `<sha>`  | `<ação>` |

## Rastreabilidade imutável

| Base SHA | Head SHA | Range/PR       | Branch/worktree |
| -------- | -------- | -------------- | --------------- |
| `<sha>`  | `<sha>`  | `<URL ou n/a>` | `<valor>`       |

## Critérios e evidências

| Critério     | Evidência         | Resultado |
| ------------ | ----------------- | --------- |
| `<critério>` | `<comando/prova>` | `PASS     | FAIL | n/a` |

## Reconciliação de escopo

| Planejado | Implementado | Não feito/motivo   |
| --------- | ------------ | ------------------ |
| `<item>`  | `<item>`     | `<none ou motivo>` |

## Resultado

PR publicado: `<URL ou n/a>`

<mudanças ou prova objetiva NO_CHANGES; nunca crie commit/PR vazio>

## Problemas encontrados

| Nível     | Problema  | Solução | Risco          | Issue draft |
| --------- | --------- | ------- | -------------- | ----------- |
| `Critical | Important | Minor   | Cannot verify` | `<item>`    | `<ação>` | `<risco>` | `<link ou n/a>` |
