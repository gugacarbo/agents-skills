# Phase 4: Dispatch

Dispatch only after plan approval. In issue mode require `stage:approved`, an explicit implementation request, and one explicit choice:

> Implementar agora? `worktree` — isolada (padrão); `direct` — workspace atual; `later` — manter aprovado.

`later` adds `needs-human` and performs no code change. `worktree` removes it and sets `stage:in-progress`. `direct` requires explicit consent to use the checkout and is sequential for a batch.

## Isolation and parallelism

- Parallel issues require one branch, worktree, and PR per issue from the plan's base SHA.
- Before dispatch, compare ownership and dependencies across batch issues. Overlap/dependency imposes an explicit order.
- Tasks within an issue run sequentially by default. Parallel task work needs plan-confirmed disjoint files, a branch/worktree per task, and a recorded integration order.
- A rebase or merge conflict blocks only its issue; resolve it and re-review the changed diff.

Use `general-executor` for bounded work and `deep-executor` for cross-cutting work. Every executor receives the issue URL when present, plan snapshot URL/revision, task ID, base SHA, allowed files, acceptance criteria, verification, and evidence-comment template. It must publish evidence through [`templates/issue-task-evidence.md`](../templates/issue-task-evidence.md), not a local report or progress log. When every currently scheduled task has evidence and no active executor, set `stage:needs-task-review`.
