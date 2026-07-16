# Phase 4: Dispatch

Dispatch only after plan approval. In issue mode require `stage:approved`, an explicit implementation request, and `worktree` or `later`. `later` adds `needs-human` and changes no code; `worktree` removes it and sets `stage:in-progress`. Never offer `direct` for an issue or batch.

In repository mode, ask for a worktree or `direct`. `direct` uses the current checkout and writes every envelope, review, and DoD result only to the versioned delivery record. It creates no issue, label, stage, or GitHub comment and cannot later convert to issue creation.

Dispatch only `agents/05-executor.md`. It receives issue URL when present, plan revision, task ID, base SHA, allowed files, acceptance criteria, verification, and evidence destination. It posts `templates/07-task-evidaence-template.md` in issue mode or the same eight-field envelope in direct mode. A `BLOCKED` outcome stops: issue mode uses `stage:blocked` + `needs-human`; direct mode appends `Resume: <phase/task>` with no GitHub state.

Tasks are sequential by default. Parallel work needs plan-confirmed disjoint files, separate worktrees/branches, assembly branch/order, integration verification, and a fresh assembled-range delivery review. Only when every planned task has non-blocked evidence may an issue move to `stage:needs-task-review`.
