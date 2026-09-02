# Parallel Implementation Waves

Read this reference before dispatching two or more implementation subagents at
the same time. The integration worktree is the only place where completed task
commits are combined and reviewed.

## Eligibility contract

A task may share a parallel wave only when every condition below is proven from
the plan and repository inspection:

1. All of its dependencies were complete before the wave base was recorded.
2. Its complete write set is known and disjoint from every other task in the
   wave. Count generated files, lockfiles, snapshots, manifests, migrations,
   formatter outputs, and codegen products as writes.
3. It neither changes nor consumes an interface another task in the wave is
   changing. Types, schemas, configuration keys, protocols, and exported APIs
   are interfaces even when their implementations live in different files.
4. Its commands do not mutate the same database, port, cache, service, device,
   deployment, or other shared resource.
5. Every concurrent implementer can work in its own linked worktree and branch
   created from the same integration commit.
6. The controller has enough child-agent capacity for the whole selected wave
   while retaining its own coordination slot.

Missing or uncertain evidence fails the test. Run that task sequentially. Do
not infer independence merely from different filenames or directories.

## Form the wave

Choose ready tasks in plan order. A task is ready only when all declared
dependencies are already integrated and reviewed. Limit the wave to available
child-agent slots; remaining ready tasks form a later wave.

Record in the ledger:

```text
Wave <W>: base <sha>; tasks <N, M>; parallel because <disjoint writes/state evidence>
Task <N>: branch <branch>; worktree <absolute path>; writes <paths>
```

Before creating task worktrees, record `WAVE_BASE=$(git rev-parse HEAD)` in the
integration worktree. Create every task branch at exactly that commit. Prefer
compatible native worktree tooling. Otherwise use external sibling worktrees,
following the placement and verification guardrails from the
`using-git-worktrees` skill. Never place a task worktree inside the repository
or let two implementers share a checkout, index, branch, or `HEAD`.

Verify each task worktree before dispatch:

- its `HEAD` equals `WAVE_BASE`;
- its current branch is unique to that task;
- the integration worktree's branch, `HEAD`, index, and files are unchanged;
- the task's brief and report paths are absolute and unique.

If isolation cannot be established, collapse the affected tasks to sequential
execution. Parallel writes in one worktree are forbidden even when declared
file sets are disjoint because Git state is shared.

## Dispatch contract

Dispatch all implementers in the wave before waiting. Each prompt includes:

- the absolute task worktree and unique task branch;
- the task brief and report paths;
- the approved write set;
- the report path as the only allowed write outside that source set;
- a prohibition on pull, merge, rebase, cherry-pick, branch switching, and
  writes outside that set;
- `NEEDS_CONTEXT` as the required status if another write becomes necessary.

Implementers commit only to their own task branches. They do not touch the
integration worktree or ledger. One implementer's failure does not cancel
unrelated tasks already running, but no failed or uncertain result is
integrated.

## Integrate deterministically

Wait for every implementer in the wave to finish, then integrate tasks one at a
time in plan order. For each task:

1. Confirm its reported branch and worktree match the ledger.
2. Record `INTEGRATION_BASE=$(git rev-parse HEAD)`.
3. Inspect the task range from `WAVE_BASE` to its task-branch head. Confirm all
   commits belong to the task and `git diff --name-only` stays within the
   approved write set.
4. Cherry-pick the task's commits oldest-first with `-x` into the integration
   worktree and record the source-to-integration commit mapping in the ledger.
5. Generate the task review package from `INTEGRATION_BASE` to the new
   integration `HEAD` and complete the ordinary review/fix loop before
   integrating the next task.

Never use `HEAD~1` for a multi-commit task. Never merge a task branch wholesale;
the explicit commit range makes provenance and ordering auditable.

If path verification reveals an undeclared write, do not integrate the task.
Reclassify it against the still-pending tasks and run it sequentially from the
current integration head.

If cherry-pick reports a conflict, abort that cherry-pick. The conflict is
evidence that the independence proof was wrong; do not resolve it inside the
wave. Preserve the task branch and report, record the reclassification, and
re-run the affected task sequentially from the current integration head.

## Reviews and fixes

Review gates remain task-scoped and sequential on the integration branch. A
parallel implementer finishing early does not make its result eligible to skip
plan order or review.

For fix rounds, resume the original implementer in its task worktree through
round 3. It appends a report and creates new commits on the same task branch.
Verify the new commit range, cherry-pick it into the integration branch, and
create the scoped re-review package from the integration head that the previous
review saw.

Before integrating a fix, compare its changed paths with every pending task in
the wave. If they overlap, or if the fix changes an interface a pending task
uses, mark those pending results stale and re-run them sequentially from the
new integration head.

After every task in the wave passes its own gate, run the plan's integration or
full-suite command once on the combined integration branch. Treat a failure
that appears only after combination as one integration problem: dispatch one
sequential diagnosis/fix task with the involved task reports and combined diff.
Do not dispatch competing speculative fixers.

## Cleanup

Keep each task worktree until that task's review and fix loop are complete.
Before removal, prove that every task commit has a recorded cherry-picked
integration commit, that the integration tree matches the task branch for the
approved write set, and that the task worktree is clean. Remove only this
plan's task worktree and branch; sibling plans and unrelated worktrees are out
of scope.
