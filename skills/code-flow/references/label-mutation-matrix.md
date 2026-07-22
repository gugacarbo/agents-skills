# Matriz de transição e ownership

Evidência precede mutação. O autor do evento aplica a transição; o
orquestrador valida resultado. Decisão humana sempre transiciona pelo
orquestrador e é apresentada com `templates/12-human-gate-spec.md`.

| Evento                                | Ator da mutação   | Próximo estado                                                        |
| ------------------------------------- | ----------------- | --------------------------------------------------------------------- |
| pré-issue de batch criada             | orquestrador      | Project V2 `DRAFT_ISSUE`; nenhum `stage:*`                            |
| pré-issue completa promovida          | issue-writer ou orquestrador | repository `ISSUE`; depois aplica a transição da linha elegível |
| issue S no-spec criada                | orquestrador      | `stage:approved + needs-human`                                        |
| issue M/G no-spec criada              | issue-writer      | `stage:needs-plan`                                                    |
| source-set M/G criado/corrigido       | issue-writer      | `stage:spec-approval + needs-human`                                   |
| source-set X/XL/hard criado/corrigido | issue-writer      | `stage:spec-approval` sem needs-human                                 |
| source review aprova                  | issue-reviewer    | mantém stage e adiciona needs-human                                   |
| source review ajusta                  | issue-reviewer    | `stage:needs-issue-fix`                                               |
| gate source aprova/ajusta/bloqueia    | orquestrador      | `needs-plan` / `needs-issue-fix` / `blocked + needs-human`            |
| plano inicial publicado               | plan-writer       | comentário canônico criado; `stage:needs-plan-review` sem needs-human |
| plano corrigido                       | plan-writer       | comentário canônico editado + resumo append-only; `stage:needs-plan-review` sem needs-human |
| plan review aprova/ajusta             | plan-reviewer     | mantém + needs-human / `needs-plan-fix`                               |
| gate plano aprova/ajusta/bloqueia     | orquestrador      | `approved + needs-human` / `needs-plan-fix` / `blocked + needs-human` |
| executor inicia                       | executor          | `stage:in-progress` sem needs-human                                   |
| executor entrega ou NO_CHANGES        | executor          | `stage:needs-delivery-review`                                         |
| executor bloqueia                     | executor          | `stage:blocked + needs-human`                                         |
| review aprova diff ou NO_CHANGES      | delivery-reviewer | `ready-to-merge` ou `ready-to-close` conforme auditoria               |
| review ajusta/não verifica            | delivery-reviewer | `stage:needs-changes`                                                 |
| gate integração/fechamento            | orquestrador      | integra/fecha, devolve ou mantém pronto                               |

Todo blocker usa `## Resume` com operação, estado a retomar e responsável.
