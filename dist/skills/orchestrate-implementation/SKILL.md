---
name: orchestrate-implementation
description: Use only when the user explicitly invokes `$orchestrate-implementation` to execute a written multi-task implementation plan in the current session. Do not activate automatically for ordinary implementation requests or plans.
---

# Orchestrate Implementation

Execute a written implementation plan by coordinating focused subagents. The
controller owns flow, isolation, integration, validation, recovery, and
reporting. It never implements or fixes product code itself.

## Defaults

- Unit granularity: few, coarse units; group by default.
- Task/unit review: risk-based (`auto`); the final review covers the rest.
- Final review: enabled.
- Parallelism: automatic and conservative.
- Workspace: isolated worktree unless the user explicitly requests in-place work.
- Maximum material-finding correction rounds: 2.
- Per-unit validation: focused, run by the implementer; the controller checks
  the evidence instead of re-running it.
- Final validation: repository/plan canonical checks.
- Publication: no automatic merge, push, PR creation, or worktree removal.

Every subagent dispatch has a fixed cost: cold start, repository orientation,
validation, and often review. Speed comes mainly from fewer dispatches, not from
shorter prompts.

Natural-language overrides such as "review todas as tasks", "sem review por
task", "rode sequencialmente", "use a branch atual", or "não faça review final"
take precedence. If structured configuration is supplied, keep it small:

```yaml
task_review: auto # auto | on | off
final_review: true
parallel: auto # auto | off
worktree: auto # auto | current
max_fix_rounds: 2 # 0..2
```

## Invariants

- The controller never writes or corrects implementation code. Implementation
  and fixes always go to subagents.
- Implementers, reviewers, and fixers do not spawn subagents.
- Never dispatch a subagent with an unapproved model. A concrete model the user
  explicitly selected, or a concrete system/workspace default configured by the
  user, counts as prior approval. `auto`, `inherit`, an omitted model, or an
  implicit default do not.
- If a required role has no approved concrete model, suggest a short list of
  concrete choices and request one approval before dispatch. Do not build a
  per-task model matrix or automatically escalate to a more expensive model.
- Run every validation explicitly required by the user, plan, spec, or
  repository policy. Focused validation is the default per unit; full/global
  validation happens once after integration unless explicitly required earlier.
- Git is the source of truth for commits, diffs, and history. Persist only the
  minimum orchestration state needed to resume safely.

## Preflight

Before implementation, always print this concise report:

```text
Implementation run

Plan: <path>
Workspace: <isolated | existing isolated | explicitly in-place>
Tasks: <N> -> Units: <M>
Execution: <auto-parallel, conservative | sequential>
Task review: <risk-based: <reviewed units> | all units | disabled>
Final review: <enabled | disabled>
Fix rounds: <0..2>
Models:
  implementer: <model>
  reviewer: <model>
Validation:
  per-task: focused
  final: <checks>
Overrides: <none | summary>
```

This is informational, not an approval gate. If there is no real blocker or
missing authorization, continue automatically.

## 1. Resolve the workspace

Default to isolation.

- If already in an isolated worktree created for this run, reuse it.
- Otherwise create an isolated integration worktree.
- Work directly in the current/default worktree only when the user explicitly
  asks for in-place execution.
- If the workspace provides the `using-git-worktrees` skill, prefer it for
  worktree mechanics. Otherwise use only the minimal Git operations necessary.

Sequential units share the integration worktree. Parallel units each receive
their own branch and linked worktree from the same valid integration head.

## 2. Turn plan tasks into execution units

The plan's task boundaries are requirements boundaries, not mandatory dispatch
boundaries. Default to the fewest units that one implementer can complete
coherently; for typical plans that is about 3–5 units, not one per task.

- group small, tightly related tasks by default — consecutive tasks touching
  the same area or building on each other belong in one unit;
- split a large task into smaller units only when one implementer could not
  complete it coherently or when the parts can run in a parallel wave;
- keep a task as its own unit only when it is large, high-risk (see section 5),
  or the dependency other units wait on;
- reorder only where dependencies allow it.

Every execution unit must retain a simple mapping back to its source
tasks/requirements so completion remains traceable.

Do not create a scheduler framework. The goal is to make units understandable,
reviewable, and efficient.

## 3. Choose sequential vs parallel execution

Parallelism is automatic only when all four conditions are clearly true:

1. **No dependency conflict.** Units do not depend on results from each other.
2. **No write-set conflict.** Expected write sets are known well enough and do
   not materially overlap.
3. **No interface conflict.** One unit does not alter an interface that another
   unit in the same wave alters or depends on in a conflicting way.
4. **No shared mutable resource.** Units do not share relevant mutable state
   such as a database, migration stream, lockfile, codegen output, port, fixture,
   local service, generated manifest, or external mutable resource.

If any condition is uncertain, execute sequentially.

For a parallel wave:

- create one branch/worktree per unit from the same integration head;
- dispatch all eligible implementers before waiting;
- keep unit changes isolated;
- integrate successful units in a deterministic order chosen before completion
  order is known.

## 4. Dispatch implementers

Use [`implementer-prompt.md`](implementer-prompt.md) as the compact contract.

Each unit brief contains only what the implementer needs:

- objective;
- source tasks/requirements;
- necessary context;
- relevant files/areas;
- constraints;
- acceptance criteria;
- expected focused validations;
- worktree/branch;
- instruction not to work on other units;
- instruction not to spawn subagents;
- requirement to create one or more commits.

A unit may have multiple natural commits. Do not require exactly one commit or
squash unless repository policy says otherwise.

## 5. Validate and review each unit

After implementation:

1. verify the implementer's report of the unit's focused validations: commands
   run, results, and commits present in Git. Re-run a check only when evidence
   is missing, ambiguous, or contradicted by the diff — never by default;
2. decide whether the unit gets its own review (below); if so, review the
   complete unit range `unit_base..unit_head`;
3. classify findings only as:
   - **material** — must be corrected before the unit can complete;
   - **non-blocking** — may be reported without blocking completion.

With `task_review: auto` (default), review a unit on its own only when at least
one applies:

- it touches security, auth, permissions, secrets, or data deletion;
- it changes a migration, schema, persisted format, or public/shared interface
  that later units build on;
- its diff is large (roughly 400+ changed lines) or spans many areas;
- the implementer reported `DONE_WITH_CONCERNS`;
- the plan/user marks it as needing review.

Units not reviewed individually are still covered by the final review. With
`task_review: on`, review every unit; with `off`, review none individually.

Use `orchestrate-review` for unit or final review only when the user's
request explicitly asks for code review or explicitly invokes that skill.
Otherwise use [`generic-reviewer-prompt.md`](generic-reviewer-prompt.md) as the
minimal review procedure. Do not recreate a large internal reviewer framework.

### Correction round 1

For material unit findings, resume the original implementer with the findings.
It fixes, validates, commits, and the fix is re-reviewed.

### Correction round 2

If material findings remain, dispatch a new implementer with the original brief,
current state, findings, previous attempt, and validation evidence. It fixes,
validates, commits, and the fix is re-reviewed.

### Scoped re-review

A re-review does not repeat the full unit review. It checks only:

- whether each material finding is resolved;
- whether the fix range `fix_base..fix_head` introduces a new material problem.

Prefer resuming the same reviewer when possible; it already has the context.

If material findings remain after the configured maximum (default 2), stop that
unit and report a blocker. Never loop indefinitely and never require automatic
model escalation.

## 6. Integrate parallel results

Integrate approved parallel units into the integration branch by cherry-picking
their commits oldest-first in the predetermined unit order.

If a cherry-pick has a material conflict:

1. abort that unit's cherry-pick;
2. treat the conflict as evidence that the independence assumption failed;
3. keep already integrated successful units;
4. re-run the affected unit sequentially from the current integration head;
5. validate and review it again.

Do not build a stale-result protocol, source-to-integration mapping ledger, or
automatic conflict resolver.

## 7. Persist minimal recovery state

Keep only enough durable state to safely resume, for example:

```text
Plan: docs/implementation-plan.md
Base: abc123

Unit A:
  tasks: [1, 2]
  status: done
  head: def456
  review: pass

Unit B:
  tasks: [3]
  status: fixing
  head: 789abc
  review: changes-requested
  fix_round: 1

Final validation: pending
Final review: pending
Blockers: none
```

Do not persist full prompts, copied diffs, exhaustive write sets, dispatch
matrices, every intermediate SHA, or data Git already records.

## 8. Run final validation

After all units are integrated, determine global checks in this order:

1. checks explicitly declared by the user/plan/spec;
2. canonical repository-documented commands;
3. established project scripts/tooling;
4. minimal appropriate checks when no canonical suite exists.

Typical checks may include lint, typecheck, tests, build, or dead-code analysis.
Do not add new tooling solely for this run. If Biome or Knip are already part of
the repository's canonical checks, include them.

A required failing check must be diagnosed and corrected by an implementation
subagent when a viable path exists. The controller still does not edit code.

## 9. Run final review

Run final review after global validation. It evaluates the whole implementation,
including cross-unit integration, architecture, regressions, requirements, and
validation evidence.

For material final-review findings:

- **Final fix round 1:** dispatch a new fixer.
- Revalidate the affected checks and run a scoped re-review.
- **Final fix round 2:** if needed, dispatch another new fixer.
- Revalidate the affected checks and run a scoped re-review.

Before reporting completion after any final fix, the full final validation must
pass on the final head.

Do not route final findings back to original unit implementers by default. If a
material finding remains after the configured maximum, stop and report the
blocker.

## 10. Finish

Success means the implementation branch/worktree is complete, validated, and
reviewed. Report a short final summary:

```text
Plan: <path>
Status: complete
Units: <done/total>
Task reviews: <passed (<reviewed>/<total> units) | disabled>
Final validation: <passed>
Final review: <passed | disabled>
Fix rounds used: <N>
Branch: <branch>
Worktree: <path>
Head: <sha>
```

Do not merge, push, create a PR, or remove the worktree unless the user
explicitly requests that action.

## Size discipline

Keep the skill and its prompts focused. Aim for about 400 lines or fewer per
primary file. A primary file must not exceed 1000 lines; split by real
responsibility before reaching that ceiling.
