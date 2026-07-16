# Cheatsheet do orquestrador

Carregue antes de retomar uma issue ou mutar labels. Contratos completos:
`github-flow.md`, `evidence-contract.md`.

## Ordem obrigatória

1. Comentário/evidência autorizadora (envelope de oito campos) publicado.
2. Mutar labels via `scripts/transition-issue.sh` (fallback: `gh issue edit`).
3. Confirmar com a saída JSON do helper ou `gh issue view <n> --json labels`.
4. Só então continuar (despachar próximo agente ou prompt humano).

Texto de comentário / `Next action:` **não** é status. Labels são a fonte de verdade.

## Quem muta labels

| Ator | Quando |
| --- | --- |
| Orquestrador | Após posts dos papéis (plano, reviews, evidência do executor, auditoria). |
| `issue-writer` | Na criação (`spec-approval` + `needs-human`) e na materialização pós-aprovação → `needs-plan`. |
| Demais papéis | Nunca mutam labels. |

## Matriz stage → fase → ação

| Stage observado | Fase | Agente / ação | `transition-issue.sh` | Prompt humano |
| --- | --- | --- | --- | --- |
| `spec-approval` | 2 | Opcional: `issue-reviewer` (pedido ou alto risco); aguardar humano | (criação já aplicou) | `templates/12-human-gate-spec.md` |
| pós-aprovação spec | 2→3 | `issue-writer` materializa | `--to stage:needs-plan --clear-needs-human` | — |
| `needs-plan` | 3 | `plan-writer` | após plano: `--to stage:needs-plan-review` | — |
| `needs-plan-review` | 3 | `plan-reviewer`; se APROVO → gate humano | se APROVO: `--to stage:needs-plan-review --needs-human`; se PEÇO AJUSTES: `--to stage:needs-plan`; se NÃO APROVO: `--to stage:blocked --needs-human` | `templates/13-human-gate-plan.md` |
| humano aprovou plano | 3→4 | — | `--to stage:approved --clear-needs-human` | — |
| `approved` + `later` | 4 | Aguardar | `--to stage:approved --needs-human` | pedir `worktree` ou `later` |
| `approved` + worktree | 4 | `executor` | `--to stage:in-progress --clear-needs-human` | — |
| `in-progress` DONE | 4→5 | — | `--to stage:needs-delivery-review` | — |
| `needs-delivery-review` | 5 | `delivery-reviewer` | APROVO → `--to stage:ready-to-merge`; PEÇO AJUSTES → `--to stage:needs-changes`; NÃO APROVO produto → `--to stage:blocked --needs-human` | — |
| `needs-changes` | 4 | `executor` | após evidência: `--to stage:needs-delivery-review` | — |
| `ready-to-merge` | 6 | auditoria final fresca | pós PR aprovado: `--to stage:ready-to-merge --needs-human` | `templates/14-human-gate-merge.md` |
| merged/fechado | 6 | — | `--clear-stage --clear-needs-human` | — |
| `blocked` | — | Apresentar blocker | (já em blocked) | decisão humana registrada |
| 0 ou >1 `stage:*` | 0 | Drift | `--to stage:blocked --needs-human --allow-repair` | explicar mismatch |

## Gates humanos (templates)

| Gate | Template | Não pular |
| --- | --- | --- |
| Design (Fase 1) | `templates/11-human-gate-design.md` | Antes de criar issue / ADR formal |
| Source-set | `templates/12-human-gate-spec.md` | Antes de materializar e `needs-plan` |
| Plano | `templates/13-human-gate-plan.md` | Antes de `approved` / execução |
| Merge | `templates/14-human-gate-merge.md` | Antes de merge/integração |

## Resume rápido

Leia labels → linha da matriz → carregue a fase → se `needs-human`, apresente o
template do gate e pare. Não invente aprovação.
