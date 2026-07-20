# Matriz de transição e ownership

Evidência precede mutação de estado. O autor do evento aplica a transição; o
orquestrador valida precondição e resultado. Decisão humana sempre transiciona
pelo orquestrador.

| Estado/evento                                | Ator da mutação     | Próximo estado / marcador                                       |
| -------------------------------------------- | ------------------- | --------------------------------------------------------------- |
| issue S no-spec criada                       | orquestrador        | `stage:approved + needs-human`                                  |
| issue M/G no-spec criada                     | `issue-writer`      | `stage:needs-plan`                                              |
| issue M/G create/update criada/corrigida     | `issue-writer`      | `stage:spec-approval + needs-human`                             |
| issue X/XL/hard criada/corrigida             | `issue-writer`      | `stage:spec-approval` sem `needs-human`                         |
| source review aprova/ressalva não bloqueante | `issue-reviewer`    | mantém `stage:spec-approval + needs-human`                      |
| source review ajusta                         | `issue-reviewer`    | `stage:needs-issue-fix`, limpa `needs-human`                    |
| gate humano source aprova                    | orquestrador        | `stage:needs-plan`, limpa `needs-human`                         |
| gate humano source ajusta/bloqueia           | orquestrador        | `stage:needs-issue-fix` / `stage:blocked + needs-human`         |
| plano publicado/corrigido                    | `plan-writer`       | `stage:needs-plan-review`, sem `needs-human`                    |
| plan review aprova/ressalva não bloqueante   | `plan-reviewer`     | mantém `stage:needs-plan-review + needs-human`                  |
| plan review ajusta                           | `plan-reviewer`     | `stage:needs-plan-fix`, limpa `needs-human`                     |
| gate humano plano aprova                     | orquestrador        | `stage:approved + needs-human`                                  |
| gate humano plano ajusta/bloqueia            | orquestrador        | `stage:needs-plan-fix` / `stage:blocked + needs-human`          |
| execução autorizada + evidência inicial      | `executor`          | `stage:in-progress`, limpa `needs-human`                        |
| `DONE`/`DONE_WITH_CONCERNS`/`NO_CHANGES`     | `executor`          | `stage:needs-delivery-review`, sem `needs-human`                |
| execução depende de decisão/acesso externo   | `executor`          | `stage:blocked + needs-human` com resume target                 |
| review aprova mudança, sem auditoria         | `delivery-reviewer` | `stage:ready-to-merge + needs-human`                            |
| review aprova mudança, com auditoria         | `delivery-reviewer` | `stage:ready-to-merge` sem `needs-human`                        |
| review aprova `NO_CHANGES`                   | `delivery-reviewer` | `stage:ready-to-close + needs-human`                            |
| review ajusta / não consegue verificar       | `delivery-reviewer` | `stage:needs-changes`, limpa `needs-human`                      |
| auditoria final aprova                       | auditor fresco      | mantém `stage:ready-to-merge + needs-human`                     |
| gate merge integra/ajusta/aguarda            | orquestrador        | limpa estado / `stage:needs-changes` / mantém pronto            |
| gate close fecha/ajusta/aguarda              | orquestrador        | limpa estado / `stage:needs-changes` / mantém pronto            |
| blocker resolvido                            | orquestrador        | resume target validado; limpa `needs-human` se próximo é agente |

`APROVAR COM RESSALVAS` só é aprovador quando todos os achados são `Minor` e
não bloqueantes. `Critical`, `Important` e `Cannot verify` exigem ajuste ou
bloqueio.

## Blocker

Toda evidência de bloqueio inclui:

- `Resume operation: <context|issue|plan|dispatch|review|integrate>`
- `Resume stage: <stage:* ou estado nativo>`
- `Resume owner: <papel|humano|orquestrador>`

Na resolução, recalcule risco e confirme que o destino ainda cobre o escopo.
Não use o resume target para contornar promoção.

## Verificação fallback

Pré-valide com `--dry-run`, use `--require-from` e confirme após mutar:

```bash
gh issue view <N> --json labels
```
