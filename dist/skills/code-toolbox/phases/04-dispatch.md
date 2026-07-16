# Phase 4: Dispatch

Dispatch only after plan approval. In issue mode require `stage:approved`, an explicit implementation request, and one explicit choice:

> Implementar agora? `worktree` — isolada (obrigatória); `later` — manter aprovado.

`later` adds `needs-human` and performs no code change. `worktree` removes it and sets `stage:in-progress`. Never offer, select, or infer `direct` for an issue or batch.

In repository mode, after the versioned plan review approves execution, ask whether to use a worktree or `direct`. `direct` uses the current checkout, creates no issue, applies no labels, and records its task evidence/review/DoD only in the versioned delivery record. It can never transition into `/code-toolbox issue create` or write GitHub comments. Repository-mode parallel work still requires isolated worktrees and an explicit assembly branch.

## Isolation and parallelism

- Parallel issues require one branch, worktree, and PR per issue from the plan's base SHA.
- Before dispatch, compare ownership and dependencies across batch issues. Overlap/dependency imposes an explicit order.
- Tasks within an issue run sequentially by default. Parallel task work needs plan-confirmed disjoint files, a branch/worktree per task, and a recorded assembly branch plus merge/cherry-pick order.
- For parallel tasks, assemble the reviewed task branches onto the issue assembly branch from the plan base SHA. Record each included task commit, resolve conflicts there, run integration verification, and send the assembled range to a fresh independent reviewer before opening the issue PR. This assembly is mandatory evidence preparation, not an automatic merge to the repository's target branch.
- A rebase, assembly, or merge conflict blocks only its issue; resolve it and re-review the changed diff.

Use `general-executor` for bounded work and `deep-executor` for cross-cutting work. Every executor receives the issue URL when present, plan snapshot URL/revision, task ID, base SHA, allowed files, acceptance criteria, verification, and the applicable evidence template. Issue mode publishes through [`templates/issue-task-evidence.md`](../templates/issue-task-evidence.md); repository mode appends to its versioned delivery record. Never create a local report or progress log. In issue mode, set `stage:needs-task-review` only when every planned task has evidence with `DONE` or `DONE_WITH_CONCERNS` and no task is `BLOCKED`; any `BLOCKED` evidence sets `stage:blocked` plus `needs-human` and stops the issue from advancing. In repository mode, append `BLOCKED`, its exact decision, and `Resume: <phase/task>` to the delivery record, then stop without GitHub state (labels, stages, or comments).
