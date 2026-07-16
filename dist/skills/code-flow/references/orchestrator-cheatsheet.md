# Cheatsheet do orquestrador

Carregue antes de retomar uma issue ou mutar labels. Contratos completos:
`github-flow.md`, `evidence-contract.md`.

## Ordem obrigatória

1. Evidência autorizadora publicada (comentário append-only **ou** body da issue para `issue-writer` / source-set).
2. Mutar labels via `scripts/transition-issue.sh` (fallback: `gh issue edit`).
3. Confirmar com a saída JSON do helper ou `gh issue view <n> --json labels`.
4. Só então continuar (despachar próximo agente ou prompt humano).

Texto de comentário / `Next action:` **não** é status. Labels são a fonte de verdade.

## Quem muta labels

| Ator             | Quando                                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| Orquestrador     | Após posts dos papéis (plano, reviews, evidência do executor, auditoria).                                           |
| `issue-writer`   | Na criação ou edição do body (`spec-approval`, sem `needs-human`) e na materialização pós-aprovação → `needs-plan`. |
| `issue-reviewer` | Em `PEÇO AJUSTES`, atribui `stage:needs-issue-fix`; nos demais vereditos, ajusta `needs-human`.                     |
| `plan-reviewer`  | Em `PEÇO AJUSTES` antes do ciclo 3, atribui `stage:needs-plan-fix`; nos demais vereditos, ajusta `needs-human`.     |
| Demais papéis    | Nunca mutam labels.                                                                                                 |

## Matriz stage → fase → ação

| Stage observado         | Fase | Agente / ação                                   | `transition-issue.sh`                                                                                                                    | Prompt humano                      |
| ----------------------- | ---- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `spec-approval`         | 2    | `issue-reviewer` obrigatório; aguardar veredito | criação aplica só `stage:spec-approval`; em `PEÇO AJUSTES`, reviewer → `stage:needs-issue-fix`; se abrir o gate, adiciona `needs-human`  | `templates/12-human-gate-spec.md`  |
| `needs-issue-fix`       | 2    | `issue-writer` corrige o body                   | `--to stage:spec-approval --clear-needs-human`                                                                                           | —                                  |
| pós-aprovação spec      | 2→3  | `issue-writer` materializa                      | `--to stage:needs-plan --clear-needs-human`                                                                                              | —                                  |
| `needs-plan`            | 3    | `plan-writer`                                   | após plano: `--to stage:needs-plan-review`                                                                                               | —                                  |
| `needs-plan-review`     | 3    | `plan-reviewer`; se APROVO → gate humano        | writer: `--to stage:needs-plan-review`; em `PEÇO AJUSTES`, reviewer → `stage:needs-plan-fix`; em APROVO/NÃO APROVO, ajusta `needs-human` | `templates/13-human-gate-plan.md`  |
| `needs-plan-fix`        | 3    | `plan-writer` publica o próximo ciclo           | após plano: `--to stage:needs-plan-review`                                                                                               | —                                  |
| humano aprovou plano    | 3→4  | —                                               | `--to stage:approved --clear-needs-human`                                                                                                | —                                  |
| `approved` + `later`    | 4    | Aguardar                                        | `--to stage:approved --needs-human`                                                                                                      | pedir `worktree` ou `later`        |
| `approved` + worktree   | 4    | `executor`                                      | `--to stage:in-progress --clear-needs-human`                                                                                             | —                                  |
| `in-progress` DONE      | 4→5  | —                                               | `--to stage:needs-delivery-review`                                                                                                       | —                                  |
| `needs-delivery-review` | 5    | `delivery-reviewer`                             | APROVO → `--to stage:ready-to-merge`; PEÇO AJUSTES → `--to stage:needs-changes`; NÃO APROVO produto → `--to stage:blocked --needs-human` | —                                  |
| `needs-changes`         | 4    | `executor`                                      | após evidência: `--to stage:needs-delivery-review`                                                                                       | —                                  |
| `ready-to-merge`        | 6    | auditoria final fresca                          | pós PR aprovado: `--to stage:ready-to-merge --needs-human`                                                                               | `templates/14-human-gate-merge.md` |
| merged/fechado          | 6    | —                                               | `--clear-stage --clear-needs-human`                                                                                                      | —                                  |
| `blocked`               | —    | Apresentar blocker                              | (já em blocked)                                                                                                                          | decisão humana registrada          |
| 0 ou >1 `stage:*`       | 0    | Drift                                           | `--to stage:blocked --needs-human --allow-repair`                                                                                        | explicar mismatch                  |

## Gates humanos (templates)

| Gate            | Template                            | Não pular                            |
| --------------- | ----------------------------------- | ------------------------------------ |
| Design (Fase 1) | `templates/11-human-gate-design.md` | Antes de criar issue / ADR formal    |
| Source-set      | `templates/12-human-gate-spec.md`   | Antes de materializar e `needs-plan` |
| Plano           | `templates/13-human-gate-plan.md`   | Antes de `approved` / execução       |
| Merge           | `templates/14-human-gate-merge.md`  | Antes de merge/integração            |

## Resume rápido

Leia labels → linha da matriz → carregue a fase → se `needs-human`, apresente o
template do gate e pare. Não invente aprovação.
