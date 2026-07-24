> agent: executor
> run_id: <uuid>
> protocol_version: <schema_version do workflow-states.json>
> event: implementation-outline | implementation-result
> state_before: <stage:ready-for-execution | stage:needs-changes> + stage:in-progress
> state_after: <stage:ready-for-execution + stage:in-progress | stage:needs-delivery-review | stage:blocked + needs-human>
> sources_evidence: <issue, Base SHA, código, testes, commits, PR e comandos>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

<!-- Preencha apenas o que for necessário. Use `## Planejamento` antes de
     executar e complete `## Evidências` após a execução. Se for complexidade
     S, o planejamento pode ser inline; nos demais, referencie o
     relatório/digest autorizado. -->

## Resume

<objetivo, mudanças, validação e condições de parada — ou DONE | DONE_WITH_CONCERNS | NO_CHANGES | BLOCKED com resumo e próximo papel>

## Planejamento

| Escopo   | Arquivos/áreas | Validação    |
| -------- | -------------- | ------------ |
| `<item>` | `<paths>`      | `<comandos>` |

| Worktree/branch | Base SHA | Rollback |
| --------------- | -------- | -------- |
| `<valor>`       | `<sha>`  | `<ação>` |

Pare para nova arquitetura diante de contrato público, hard trigger, decisão
material ou drift não coberto.

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

## Com diff

PR publicado: `<URL>` · estado: `<draft ou ready>`

| Arquivo  | Mudança       | Validação |
| -------- | ------------- | --------- |
| `<path>` | `<descrição>` | `<prova>` |

## Sem diff: `NO_CHANGES`

<prova objetiva; confirme ausência de commit e PR vazio>

## Problemas encontrados

| Nível     | Problema  | Solução aplicada | Risco pendente | Issue draft  |
| --------- | --------- | ---------------- | -------------- | ------------ |
| `Critical | Important | Minor            | Cannot verify` | `<problema>` | `<ação>` | `<risco>` | `<Minor não bloqueante: link; demais: n/a>` |

_Para Minor, use `references/follow-up-issue-drafts.md`._
