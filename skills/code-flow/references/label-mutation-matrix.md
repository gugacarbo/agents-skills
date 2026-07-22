# Matriz de transição e ownership

Evidência precede mutação. O autor do evento aplica a transição; o
orquestrador valida resultado. Decisão humana sempre transiciona pelo
orquestrador e é apresentada com `templates/12-human-gate-spec.md`.

| Evento                                        | Ator da mutação              | Próximo estado                                                                                                |
| --------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------- |
| pré-issue de batch criada                     | orquestrador                 | Project V2 `DRAFT_ISSUE`; nenhum `stage:*`                                                                    |
| pré-issue completa promovida                  | issue-writer ou orquestrador | repository `ISSUE`; depois aplica a transição da linha elegível                                               |
| issue S no-spec criada                        | orquestrador                 | `stage:approved + needs-human`                                                                                |
| issue M/G/X/XL criada                         | issue-writer                 | `stage:needs-architect`                                                                                       |
| relatório de arquitetura publicado            | architect                    | comentário canônico criado; `stage:approved` (+ `needs-human` se gate de execução)                            |
| relatório de arquitetura corrigido            | architect                    | comentário canônico editado + resumo append-only; `stage:approved` (+ `needs-human` se gate de execução)      |
| autorização execução autoriza/ajusta/bloqueia | orquestrador                 | `in-progress` (após evidência de início) / `needs-architect` + devolve ao architect / `blocked + needs-human` |
| executor inicia                               | executor                     | `stage:in-progress` sem needs-human                                                                           |
| executor entrega ou NO_CHANGES                | executor                     | `stage:needs-delivery-review`                                                                                 |
| executor bloqueia                             | executor                     | `stage:blocked + needs-human`                                                                                 |
| review aprova diff ou NO_CHANGES              | reviewer                     | `ready-to-merge` ou `ready-to-close` conforme auditoria                                                       |
| review ajusta/não verifica                    | reviewer                     | `stage:needs-changes`                                                                                         |
| gate integração/fechamento                    | orquestrador                 | integra/fecha, devolve ou mantém pronto                                                                       |

Todo blocker usa `## Resume` com operação, estado a retomar e responsável.
