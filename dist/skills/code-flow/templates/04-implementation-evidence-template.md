> agent: executor
> run_id: <uuid>
> event: implementation-result
> state_before: <stage:ready-for-execution | stage:needs-changes> + stage:in-progress
> state_after: <stage:needs-delivery-review | stage:blocked + needs-human>
> sources_evidence: <outline/relatório, digest, commits, PR e comandos>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<DONE | DONE_WITH_CONCERNS | NO_CHANGES | BLOCKED — resumo e próximo papel>

## Rastreabilidade imutável

| Base SHA | Head SHA | Range/PR | Branch/worktree |
| --- | --- | --- | --- |
| `<sha>` | `<sha>` | `<URL ou n/a>` | `<valor>` |

## Critérios e evidências

| Critério | Evidência | Resultado |
| --- | --- | --- |
| `<critério>` | `<comando/prova>` | `PASS | FAIL | n/a` |

## Reconciliação de escopo

| Planejado | Implementado | Não feito/motivo |
| --- | --- | --- |
| `<item>` | `<item>` | `<none ou motivo>` |

## Com diff

PR publicado: `<URL>` · estado: `<draft ou ready>`

| Arquivo | Mudança | Validação |
| --- | --- | --- |
| `<path>` | `<descrição>` | `<prova>` |

## Sem diff: `NO_CHANGES`

<prova objetiva; confirme ausência de commit e PR vazio>

## Problemas encontrados

| Nível | Problema | Solução aplicada | Risco pendente | Issue draft |
| --- | --- | --- | --- | --- |
| `Critical | Important | Minor | Cannot verify` | `<problema>` | `<ação>` | `<risco>` | `<Minor não bloqueante: link; demais: n/a>` |

_Para Minor, use `references/follow-up-issue-drafts.md`._
