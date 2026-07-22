# Matriz de transição e ownership

Evidência precede mutação. O autor do evento aplica a transição; o
orquestrador valida resultado. Decisão humana sempre transiciona pelo
orquestrador e é apresentada com `templates/12-human-gate-spec.md`.

| Evento                                        | Ator da mutação              | Próximo estado                                                                                           |
| --------------------------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| pré-issue de batch criada                     | orquestrador                 | Project V2 `DRAFT_ISSUE`; nenhum `stage:*`                                                               |
| pré-issue completa promovida                  | issue-writer ou orquestrador | repository `ISSUE`; depois aplica a transição da linha elegível                                          |
| issue S no-spec criada                        | orquestrador                 | `stage:approved + needs-human`                                                                           |
| issue M/G no-spec criada                      | issue-writer                 | `stage:needs-plan`                                                                                       |
| source-set M/G criado/corrigido               | issue-writer                 | `stage:spec-approval + needs-human`                                                                      |
| source-set X/XL/hard criado/corrigido         | issue-writer                 | `stage:spec-approval + needs-human`                                                                      |
| gate source aprova/ajusta/bloqueia            | orquestrador                 | `needs-plan` / `needs-issue-fix` / `blocked + needs-human`                                               |
| plano inicial publicado                       | architect                    | comentário canônico criado; `stage:approved + needs-human`                                               |
| plano corrigido                               | architect                    | comentário canônico editado + resumo append-only; `stage:approved + needs-human`                         |
| autorização execução autoriza/ajusta/bloqueia | orquestrador                 | `in-progress` (após evidência de início) / `needs-plan` + devolve ao architect / `blocked + needs-human` |
| executor inicia                               | executor                     | `stage:in-progress` sem needs-human                                                                      |
| executor entrega ou NO_CHANGES                | executor                     | `stage:needs-delivery-review`                                                                            |
| executor bloqueia                             | executor                     | `stage:blocked + needs-human`                                                                            |
| review aprova diff ou NO_CHANGES              | reviewer                     | `ready-to-merge` ou `ready-to-close` conforme auditoria                                                  |
| review ajusta/não verifica                    | reviewer                     | `stage:needs-changes`                                                                                    |
| gate integração/fechamento                    | orquestrador                 | integra/fecha, devolve ou mantém pronto                                                                  |

Todo blocker usa `## Resume` com operação, estado a retomar e responsável.
