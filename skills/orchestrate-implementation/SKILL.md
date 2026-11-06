---
name: orchestrate-implementation
description: Use only when the user explicitly invokes `$orchestrate-implementation` to execute a written multi-task implementation plan in the current session. Do not activate automatically for ordinary implementation requests or plans.
---

# Orchestrate Implementation

Execute a written implementation plan by coordinating focused subagents. The
controller owns flow, isolation, integration, validation, recovery, and
reporting. It never implements or fixes product code itself.

## Defaults

- Units: shaped by the plan's dependency graph; fewest units per wave.
- Parallelism: automatic, only for waves that pass section 3.
- Unit review: decided per unit by risk (section 5).
- Final review: always, unless the user explicitly turns it off.
- Workspace: isolated worktree, detected from Git (section 1).
- Maximum correction rounds: 2 (review findings and final validation).
- Per-unit validation: focused, run by the implementer; the controller checks
  the evidence instead of re-running it.
- Final validation: repository/plan canonical checks.
- Findings not fixed: recorded, consolidated, and reported at the end.
- Publication: no automatic merge, push, PR, comment, or worktree removal.

Every subagent dispatch has a fixed cost: cold start, repository orientation,
validation, and often review. Speed comes from fewer dispatches and from
running independent units at the same time, not from shorter prompts.

Natural-language overrides take precedence: "revise todas as tasks", "sem
review por task", "sem revisão final", "rode sequencialmente", "use a branch
atual". Structured configuration, when supplied, is only:

```yaml
parallel: auto # auto | off
worktree: auto # auto | current
max_fix_rounds: 2 # 0..2
```

## Invariants

- The controller never writes or corrects implementation code. Implementation
  and fixes always go to subagents. The only exception: the controller may run
  the repository's own deterministic autofix commands (formatter, `lint --fix`)
  and commit their output separately.
- Implementers, reviewers, and fixers do not spawn subagents.
- Never dispatch a subagent with an unapproved model (see Models).
- Run every validation explicitly required by the user, plan, spec, or
  repository policy. Focused validation is the default per unit; full/global
  validation happens once after integration unless explicitly required earlier.
- Git is the source of truth for commits, diffs, and history. Persist only the
  minimum orchestration state needed to resume safely (section 6).
- Nothing leaves the session without an explicit request: no merge, push, PR,
  PR/issue comment, or removal of the integration or user worktree.

## Models

Three roles need a concrete model and effort:

| Role         | Also used for                                              |
| ------------ | ---------------------------------------------------------- |
| implement    | unit fixers, final fixers, deferred-findings consolidation |
| task review  | unit reviews and their scoped re-reviews                   |
| final review | final review and its scoped re-reviews                     |

Resolve each role in this order:

1. models/efforts the user gave in the request;
2. a concrete system/workspace default configured by the user;
3. otherwise, propose them.

`auto`, `inherit`, an omitted model, or an implicit default never count as
approval. To propose, list the models available in the current harness and
show one choice per role with a one-line reason, then request a single
approval before any dispatch:

```text
Models (proposed, needs approval):
  implement:    <model> / <effort> — <reason>
  task review:  <model> / <effort> — <reason>
  final review: <model> / <effort> — <reason>
```

Do not save proposals between runs, build a per-unit model matrix, or escalate
to a more expensive model automatically.

Harness limits: when the harness has no effort control, record effort as `n/a`
— it is not a blocker. When the harness cannot resume a subagent, "resume"
anywhere in this skill means dispatching a new one with the previous brief,
report, and findings as context.

## Preflight

Before implementation, check the plan: every unit needs acceptance criteria
and a focused validation. Derive missing ones from the plan/spec; if they
cannot be derived, stop and ask instead of letting the implementer guess.

Then print this concise report:

```text
Implementation run

Plan: <path>
Workspace: <isolated | existing isolated | explicitly in-place>
Tasks: <N> -> Units: <M>
Waves: <e.g. A -> [B || C] -> D | sequential>
Review:
  units: <reviewed units with reason, e.g. B: migration | none known yet>
  may be added after implementation: diff size, DONE_WITH_CONCERNS
  final: <enabled | disabled by request>
Fix rounds: <0..2>
Models:
  implement: <model / effort>
  task review: <model / effort>
  final review: <model / effort>
Validation:
  per-unit: focused
  final: <checks>
Overrides: <none | summary>
```

This is informational, not an approval gate. Continue automatically unless a
real blocker, missing model approval, or missing authorization exists.

## 1. Resolve the workspace

Default to isolation, decided from Git state only:

```bash
git rev-parse --git-dir --git-common-dir
git status --porcelain
```

Different paths mean a linked worktree.

Before creating anything, check `git worktree list` for a worktree whose
recovery state (section 6) belongs to the same plan. If one exists, switch to it
and resume there instead of creating another.

| State                                   | Action                                           |
| --------------------------------------- | ------------------------------------------------ |
| linked worktree, clean                  | reuse it as integration (`existing isolated`)    |
| linked worktree, uncommitted changes    | stop and report a blocker                        |
| main checkout                           | create an integration worktree (`isolated`)      |
| user explicitly asked for in-place work | use the current checkout (`explicitly in-place`) |

A reused worktree on a non-default branch keeps that branch as the integration
branch, with `HEAD` as the run base. On the default branch, create a new branch
in place instead of another worktree. If the workspace provides the
`using-git-worktrees` skill, prefer it for worktree mechanics; otherwise use only
the minimal Git operations necessary.

## 2. Turn plan tasks into execution units

The plan's task boundaries are requirements boundaries, not mandatory dispatch
boundaries. Build the dependency graph of the plan's tasks and shape units by
layer:

- **foundation** — what everything else depends on (schema, shared interface);
- **branches** — independent areas that only depend on the foundation;
- **closing** — wiring or integration that joins the branches.

Aim for the fewest units per wave, not the fewest units overall:

- group small, tightly related tasks — consecutive tasks touching the same
  area or building on each other belong in one unit;
- do not merge independent branches just to reduce the unit count; together
  they lose parallelism;
- split a large task only when one implementer could not complete it coherently
  or when its parts are independent branches;
- reorder only where dependencies allow it.

Every execution unit must retain a simple mapping back to its source
tasks/requirements so completion remains traceable. Do not create a scheduler
framework.

## 3. Choose sequential vs parallel execution

A wave runs in parallel only when all of these are clearly true:

1. **No dependency conflict.** Units do not depend on results from each other.
2. **No write-set conflict.** Expected write sets are known well enough and do
   not materially overlap.
3. **No interface conflict.** One unit does not alter an interface that another
   unit in the same wave alters or depends on in a conflicting way.
4. **No shared mutable resource.** Units do not share relevant mutable state
   such as a database, migration stream, lockfile, codegen output, port, fixture,
   local service, generated manifest, or external mutable resource.
5. **Worth it.** The wave has 2–3 units and each is substantial. Small units
   cost more in worktree setup, integration, and revalidation than they save;
   group them into one unit instead.

If any condition is uncertain, execute sequentially. `parallel: off` or
"rode sequencialmente" disables waves entirely.

A unit gets its own worktree if and only if it runs in a parallel wave;
sequential units share the integration worktree. When a wave qualifies, read
[`parallel-waves.md`](parallel-waves.md) for setup, integration, conflict
fallback, and cleanup. Sequential runs never need it.

## 4. Dispatch implementers

Use [`implementer-prompt.md`](implementer-prompt.md) as the compact contract,
with the approved `implement` model and effort.

Each unit brief contains only what the implementer needs: objective, source
tasks/requirements, necessary context, relevant files/areas, constraints,
acceptance criteria, expected focused validations, worktree/branch, and the
instructions to stay in scope, not spawn subagents, and create one or more
natural commits. Do not require exactly one commit or squash unless repository
policy says otherwise.

Handle the reported status:

- **DONE** — continue to section 5.
- **DONE_WITH_CONCERNS** — continue to section 5; the unit gets its own review.
- **NEEDS_CONTEXT** — answer from the plan, spec, or repository and resume the
  same implementer. If the controller cannot answer it, treat it as BLOCKED. A
  parallel unit that needs to write outside its write set leaves the wave
  instead (see [`parallel-waves.md`](parallel-waves.md)).
- **BLOCKED** — record a blocker for the unit. Units that do not depend on it
  continue; dependent units stop.

## 5. Validate and review each unit

After implementation:

1. verify the implementer's report of the unit's focused validations: commands
   run, results, and commits present in Git. Re-run a check only when evidence
   is missing, ambiguous, or contradicted by the diff — never by default;
2. decide whether the unit gets its own review; if so, review the complete unit
   range `unit_base..unit_head` with the `task review` model.

### Which units get their own review

Review a unit on its own when at least one applies:

- it touches security, auth, permissions, secrets, or data deletion;
- it changes a migration, schema, persisted format, or public/shared interface
  that later units build on;
- its diff is large (roughly 400+ changed lines) or spans many areas;
- the implementer reported `DONE_WITH_CONCERNS`;
- the plan or user marks it as needing review.

Every other unit is marked `deferred-to-final` and fully covered by the final
review. "revise todas as tasks" reviews every unit; "sem review por task"
reviews none individually. If the final review is turned off, every unit gets
its own review instead; if the user turns off both, the preflight warns that
nothing will be reviewed.

Use [`generic-reviewer-prompt.md`](generic-reviewer-prompt.md) for unit and
final reviews by default. Use `orchestrate-review` only when the user's request
explicitly asks for it or for a full code review.

### Finding gate

Findings are only:

- **material** — a correctness, security, or data-integrity defect, or a
  violated requirement/acceptance criterion, introduced or worsened by this
  implementation, with the evidence the reviewer prompt requires;
- **non-blocking** — everything else: style, refactors, alternative
  abstractions, optional improvements, unrelated pre-existing issues.

The controller does not accept the reviewer's label blindly: a material finding
without location, triggering scenario, or evidence is downgraded and recorded as
`unsupported`. Do not re-investigate it yourself. A material finding whose fix
would require work outside the plan's scope is not fixed: record it as
`out-of-scope` and report it in the final summary. Every finding not sent to a
fixer goes to the deferred-findings log (section 6).

Rounds run only while `max_fix_rounds` allows: with `1`, round 2 never runs;
with `0`, any material finding becomes a blocker immediately.

### Correction round 1

For material unit findings, resume the original implementer with the findings.
It fixes, validates, commits, and the fix is re-reviewed.

### Correction round 2

If material findings remain, dispatch a new implementer with the original brief,
current state, findings, previous attempt, and validation evidence. It fixes,
validates, commits, and the fix is re-reviewed.

### Scoped re-review

`fix_base` is the unit head before the fix; `fix_head` is the head after it. A
re-review does not repeat the full unit review. It checks only:

- whether each material finding is resolved;
- whether `fix_base..fix_head` introduces a new material problem.

Prefer resuming the same reviewer. With `orchestrate-review`, pass the previous
findings and the fix range as its scope.

If material findings remain after `max_fix_rounds` (default 2), stop that unit
and report a blocker. Never loop indefinitely and never require automatic
model escalation.

## 6. Persist minimal recovery state

Keep the state at `$(git rev-parse --git-dir)/orchestrate-implementation/state.md`
inside the integration worktree — outside history, private to that worktree.
If a state file for the same plan exists, resume from it; otherwise start a new
run. Example:

```text
Plan: docs/implementation-plan.md
Base: abc123
Models: implement=<m/e> task-review=<m/e> final-review=<m/e>

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
  worktree: ../repo.units/B

Unit C:
  tasks: [4, 5]
  status: done
  head: 456def
  review: deferred-to-final

Deferred findings:
  - F1 | unit C | unit-review | src/a.ts:42 | maintainability | non-blocking | <summary>

Final validation: pending
Final review: pending
Blockers: none
```

`review` is one of `pass | changes-requested | deferred-to-final | skipped`.
`head` is the unit's head on the integration branch; for a parallel unit, it is
the unit branch head until integration and the integrated head afterwards.
`worktree` exists only for units in a parallel wave. Each deferred finding keeps
id, unit, origin (`unit-review | final-review`), `file:line`, category
(`correctness | tests | maintainability | style | pre-existing`), reason
(`non-blocking | unsupported | out-of-scope`), and a one-line summary.

Do not persist full prompts, copied diffs, exhaustive write sets, dispatch
matrices, every intermediate SHA, or data Git already records.

## 7. Run final validation

After all units are integrated, determine global checks in this order:

1. checks explicitly declared by the user/plan/spec;
2. canonical repository-documented commands;
3. established project scripts/tooling;
4. minimal appropriate checks when no canonical suite exists.

Typical checks may include lint, typecheck, tests, build, or dead-code analysis.
Do not add new tooling solely for this run. If Biome or Knip are already part of
the repository's canonical checks, include them.

For a failing required check, first run the repository's deterministic autofix
commands when they apply. Otherwise an implementation subagent diagnoses and
fixes it. This is capped at `max_fix_rounds` attempts; after that, stop and
report the blocker.

## 8. Run final review

Run the final review after global validation, with the `final review` model,
unless the user explicitly turned it off. It covers:

- cross-unit integration, architecture, and regressions;
- global requirement coverage and validation evidence;
- a complete review of every `deferred-to-final` unit.

It does not reopen units that already passed their own review unless there is
new evidence of a material defect. The same finding gate applies.

For material final-review findings, up to `max_fix_rounds` rounds:

- a finding confined to one unit goes back to that unit's implementer when it
  can still be resumed;
- a cross-unit finding, or one whose implementer cannot be resumed, goes to a
  new fixer;
- revalidate the affected checks and run a scoped re-review.

Before reporting completion after any final fix, the full final validation must
pass on the final head. If a material finding remains after the maximum, stop
and report the blocker.

## 9. Consolidate deferred findings

If the deferred-findings log is not empty, dispatch one implementer (approved
`implement` model) in read-only consolidation mode with the whole log, using the
consolidation template in [`implementer-prompt.md`](implementer-prompt.md). It:

- checks each finding against the final head and drops resolved ones;
- merges duplicates and groups the rest by area or category;
- writes a short report with a suggested next step per group (open an issue,
  or ignore).

It never changes code. Skip this step when the log is empty.

## 10. Finish

Success means the implementation branch/worktree is complete, validated, and
reviewed. Report a short final summary:

```text
Plan: <path>
Status: complete
Units: <done/total>
Unit reviews: <reviewed>/<total> (<deferred> deferred to final)
Final validation: <passed>
Final review: <passed | disabled by request>
Fix rounds used: <N>
Out of scope: <material findings left for later | none>
Deferred findings: <consolidated report | none>
Branch: <branch>
Worktree: <path>
Head: <sha>
```

Always show the consolidated deferred-findings report in the chat. When the run
is tied to a PR or issue, offer to post it there as a comment; post only when
the user asked for it or confirms.

Do not merge, push, create a PR, or remove the integration worktree unless the
user explicitly requests that action.
