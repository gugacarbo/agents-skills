# Cheatsheet do orquestrador

## Ordem de entrada/resume

1. discovery read-only;
2. validar elegibilidade antes de plano/código/review;
3. ler/propor Complexity e recalcular risco;
4. validar `Workflow` pela tabela de verdade;
5. interpretar próximo gate sem pular estado;
6. despachar papel independente aplicável;
7. validar evidência → precondição → mutação → estado final.

## Stage → operação

| Stage fallback                | Operação  | Próximo ator                                   |
| ----------------------------- | --------- | ---------------------------------------------- |
| `stage:spec-approval`         | issue     | reviewer ou humano conforme rigor              |
| `stage:needs-issue-fix`       | issue     | issue-writer                                   |
| `stage:needs-plan`            | plan      | plan-writer                                    |
| `stage:needs-plan-review`     | plan      | reviewer; humano só após aprovação             |
| `stage:needs-plan-fix`        | plan      | plan-writer                                    |
| `stage:approved`              | dispatch  | humano autoriza; executor inicia               |
| `stage:in-progress`           | dispatch  | executor                                       |
| `stage:needs-delivery-review` | review    | delivery-reviewer                              |
| `stage:needs-changes`         | dispatch  | executor na mesma worktree                     |
| `stage:ready-to-merge`        | integrate | auditor aplicável; depois humano               |
| `stage:ready-to-close`        | integrate | humano fecha/ajusta/aguarda                    |
| `stage:blocked`               | context   | humano resolve; orquestrador usa resume target |

## Check rápido

- Header e estado concordam? Se não, pare por drift.
- Source-set digest foi calculado somente entre marcadores?
- Hard trigger/escopo/base mudaram desde o último gate?
- Autor do evento aplicou a transição e o orquestrador a confirmou?
- Próximo ator é humano? Só então `needs-human` pode existir.
- `NO_CHANGES` usa close gate, nunca merge gate.
- Em batch, cada ID continua independente; `--from` não carrega issue inelegível.
