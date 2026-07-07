# Phase 5: Dispatch Subagents

## Model Selection

Use the least powerful model that can handle each role:

| Role                                                               | Model                                                | Why                                                               |
| ------------------------------------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Mechanical implementation (isolated, clear spec, 1–2 files)        | Cheap/fast                                           | Most implementation is mechanical when the plan is well-specified |
| Integration and judgment (multi-file, pattern matching, debugging) | Standard                                             | Needs context awareness across files                              |
| Architecture and design                                            | Most capable                                         | Requires broad reasoning                                          |
| Task review (spec compliance + quality)                            | Standard for small diffs, capable for subtle changes | Review is judgment work                                           |
| Final whole-branch review                                          | Most capable                                         | High-stakes, broad scope                                          |

**Specify the model explicitly when the platform supports it.** An omitted model inherits the session's model — often the most expensive — which defeats this section. If the current platform does not support explicit model selection, record that limitation in `super-plan.json` through the active `super-plan.sh update` helper path; the ledger will regenerate from that write automatically.

**Turn count beats token price.** The cheapest models take 2–3× more turns on multi-step work, costing more overall. Use standard as the floor for reviewers and for implementers working from prose descriptions. Reserve the cheapest tier for implementers whose task JSON entry contains the complete code to write.

## Task Profiles and Configured Subagent Slots

Read the task's `task_profile` from `super-plan.json` before dispatching. Every task must map to one of three configured execution slots under `agents`:

- `quick`
- `general`
- `deep`

Use the matching `agents.<task_profile>` configuration when it is populated.

Example:

- `task_profile=quick` → use `agents.quick`
- `task_profile=general` → use `agents.general`
- `task_profile=deep` → use `agents.deep`

## Capability Adapter

Before dispatching, check what the current platform actually supports:

| Capability                         | Preferred behavior                             | Fallback if unavailable                                                                       |
| ---------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Explicit model selection           | Set the model for each role                    | Note the limitation in `super-plan.json` via the active helper path and use the session model |
| Parallel subagent dispatch         | Dispatch 2–4 isolated workers in one turn      | Run the same wave sequentially                                                                |
| Worktree isolation                 | Use one worktree/branch per parallel subagent  | Do not run parallel workers that can touch overlapping files                                  |
| Subagent file handoff/report write | Require report/review files in the task folder | Execute inline but still write the same files yourself                                        |

If any preferred capability is missing, adapt the execution mode instead of pretending the capability exists.

## Profile Validation and Fallback

Before starting any implementation wave, especially a parallel wave, validate the configured execution slots against the current platform:

1. Re-discover the currently available agents/subagents and models using the platform's available tools
2. For each profile used by the pending tasks in the upcoming wave, verify whether the configured `agent` and `model` are still available
3. Run a lightweight pre-flight dispatch/probe with the configured profile before launching the full batch when the platform supports such a test

If a configured profile is empty:

- treat it as "use platform default"
- do not block execution

If a configured profile fails validation or the pre-flight dispatch:

1. Update `super-plan.json` through the active helper path and set that profile's `model` and `agent` to empty strings
2. Record that the orchestrator is falling back to the platform default selection
3. Use the system default configuration for the real subagent dispatch

Never keep retrying a broken explicit model/agent pairing across a batch. Clear it once, persist the fallback, and continue with the platform defaults.

## Resolve the Shared Logging Helper

Before dispatching implementers, resolve the shared logging helper path that matches Phase 4:

1. **If the target repo already contains this `super-planning` skill**, use the in-repo `super-planning/scripts/log-task.sh`.
2. **If the target repo does not contain the skill**, ensure `.super-planning/log-task.sh` exists and copy it there if needed.

The orchestrator owns this shared helper path. Task directories should not receive a full copy of the logging implementation anymore.

## Constructing the Dispatch Prompt

A dispatch prompt contains exactly five things — nothing more:

1. **One line of context:** where this task fits in the project
2. **The registry path:** "Read the task entry in `super-plan.json` first — it is your requirements"
3. **Interfaces and decisions** from earlier tasks that the JSON entry cannot know
4. **Your resolution** of any ambiguity you noticed in the task entry
5. **The report-file path** and report contract

Use the minimal template at [`prompts/worker-prompt-template.md`](../prompts/worker-prompt-template.md) as the starting point.

## Report File Convention

Every implementer is expected to produce a full report that will live in the task directory once Phase 6 materializes task artifacts. Default convention:

```
docs/tasks/{NNNN-<feature-name>}/{task-id}/report.md
```

Example for task `Task-A-0001` under plan `0003-auth-middleware`:

```
docs/tasks/0003-auth-middleware/Task-A-0001/report.md
```

The subagent returns only a one-line status to the orchestrator. Detail belongs in the report file once persisted.

## What Phase 5 Must Create

Phase 5 must ensure the shared logging helper is available at the active helper path. When the skill is already in the repo, reuse `super-planning/scripts/log-task.sh`; otherwise create:

- `.super-planning/log-task.sh`

Then the orchestrator uses that script's `materialize-task-logger` subcommand to generate thin task-local wrappers later in Phase 6.

## What Phase 5 Must Not Create

Phase 5 does **not** create:

- task directories
- task-local wrapper scripts such as `log-task.sh`
- task-local `progress.log`

The ledger already exists by this phase and must be regenerated by the active `super-plan.sh` helper path whenever the registry changes. Task directories, task-local wrapper scripts, and task-local log files are still materialized in Phase 6.

## Review Package Convention

Before dispatching a reviewer, generate a review package in the task directory once Phase 6 has materialized it:

```
docs/tasks/{NNNN-<feature-name>}/{task-id}/review-package.diff.md
```

The package must include:

1. Task id, plan id, base ref, head ref, and commit range
2. `git log --oneline <base>..<head>`
3. `git diff --stat <base>..<head>`
4. `git diff --find-renames --find-copies --function-context <base>..<head>`
5. Implementer-reported verification commands and results

**Do NOT:**

- Paste the entire plan into every dispatch
- Paste accumulated prior-task summaries into later dispatches
- Include process narration or history
- Give the subagent access to your session's context

## Sequential Dispatch

For each task:

1. Read the task entry from `docs/tasks/{NNNN-<feature-name>}/super-plan.json`.
2. Resolve the task's `task_profile` and the corresponding `agents.<task_profile>` config.
3. Validate the configured model/agent if present; otherwise use the system default.
4. Do **not** create task directories in this phase.
5. Dispatch one implementer subagent with the task JSON entry + scene-setting context.
6. If the subagent asks questions, answer before letting it proceed.
7. When the subagent returns DONE/DONE_WITH_CONCERNS, update `super-plan.json` to `ready_for_review` via script so the ledger regenerates.
8. Read `reviewCadence` from `super-plan.json`.
9. If `reviewCadence=per_task`, set the task status to `reviewing` via script, then hand off immediately to Phase 6 for artifact materialization, review package generation, and reviewer dispatch.
10. If `reviewCadence=per_batch`, wait until the current batch is fully `ready_for_review`, then set each task to `reviewing` and hand off the batch to Phase 6.
11. If `reviewCadence=final_only`, continue implementation without task-level review, keep the task at `ready_for_review`, and defer the independent review gate to final integration, where reviewers are still dispatched one batch at a time before any task transitions to `completed`.
12. If the reviewer later finds issues, update `super-plan.json` to `needs_fix` via script, dispatch a fix subagent, and re-review according to the same cadence.
13. After clean review at the configured cadence, append a `completed` log entry with the task-local wrapper `log-task.sh` and update the JSON status to `completed` via script so the ledger regenerates. Skip this step during implementation when `reviewCadence=final_only`.

## Parallel Dispatch

For independent tasks with no file conflicts:

1. Extract all task entries from `super-plan.json` at once.
2. Resolve which profiles are needed in the wave from each task's `task_profile`.
3. Validate the configured `agents.quick|general|deep` entries needed for the wave and run a lightweight pre-flight dispatch/probe before the real batch when the platform supports it.
4. For any failed configured profile, clear `model` and `agent` in `super-plan.json` before the batch and use the system defaults instead.
5. Do **not** create task directories in this phase.
6. Dispatch ALL subagents in ONE message (parallel tool calls), if the platform supports it.
7. Wait for all to return.
8. Mark returned tasks as `ready_for_review` via script so the ledger regenerates.
9. Read `reviewCadence` from `super-plan.json`.
10. If `reviewCadence=per_task`, set each finished task to `reviewing` via script, then dispatch a reviewer subagent immediately for each task as soon as that task's implementer finishes. Do not wait for sibling tasks in the same parallel batch.
11. If `reviewCadence=per_batch`, wait for the full batch to reach `ready_for_review`, then set each task to `reviewing` and hand the batch to Phase 6 together.
12. If `reviewCadence=final_only`, skip task-level review during the parallel wave, keep accepted tasks at `ready_for_review`, and defer independent review to final integration, where one reviewer subagent must still be dispatched per batch before any task transitions to `completed`.
13. Dispatch fix subagents for any reviewed tasks that need fixes.
14. Integrate all changes onto the working branch.
15. After clean review at the configured cadence, append `completed` log entries with each task-local wrapper `log-task.sh` and update the JSON status for the accepted tasks via script so the ledger regenerates. Skip this step during implementation when `reviewCadence=final_only`.

**Critical:** Multiple dispatch calls in one response = parallel execution. One per response = sequential. The dispatch pattern controls parallelism.

**Critical:** In parallel mode with `reviewCadence=per_task`, implementation and review overlap. The orchestrator must launch the reviewer for each finished task immediately instead of waiting for the rest of the batch.

**Worktree isolation for parallel mode:** When the platform supports it, use `isolation: "worktree"` so each parallel subagent works in its own git worktree. This prevents index-lock races and file conflicts.

**Practical limit:** Dispatch 2–4 subagents per batch. More than that adds coordination overhead. If you have 8 independent tasks, use 2–3 batches of 3 rather than one batch of 8.

## Batch-Based Execution

When tasks have partial dependencies, organize them into execution batches:

1. Group tasks that should run in parallel under the same `batch` label.
2. Move dependent tasks to a later `batch`.
3. Use the task `phase` field to describe whether the work is `foundation`, `core`, `surface`, or `final`.

Tasks within a batch can run in parallel if they don't conflict on files and do not depend on each other. Batches run sequentially. Each batch boundary is a natural checkpoint for integration testing.

## Common Mistakes in Dispatch Prompts

| Mistake                                          | Fix                                                 |
| ------------------------------------------------ | --------------------------------------------------- |
| Too broad: "Fix all the tests"                   | Focused: "Fix agent-tool-abort.test.ts failures"    |
| No context: "Fix the race condition"             | Paste error messages and test names                 |
| No constraints: agent refactors everything       | "Do NOT change production code" or "Fix tests only" |
| Vague output: "Fix it"                           | "Return summary of root cause and changes"          |
| Pasting the whole plan into dispatch             | Hand only the task entry from `super-plan.json`     |
| Accumulating prior summaries in later dispatches | Each dispatch is self-contained                     |

## When NOT to Use Parallel Mode

Use sequential when:

- **Failures are related** — fixing one might fix others
- **Need full system context** — understanding requires seeing the entire system
- **Exploratory debugging** — you don't yet know what's broken
- **Shared state** — tasks modify the same database tables or global config
- **Uncertain file isolation** — you're not sure tasks can avoid touching the same files

When in doubt, run sequentially. Parallel mode is an optimization, not a default.

## Scope Violation Detection

After each subagent returns, check that its changes stay within the declared scope:

- **File scope:** If a task declares specific files, the resulting commit should not touch files outside that list (infrastructure files like `package.json` or lockfiles are acceptable).
- **If scope is violated:** Reject the task, re-dispatch with tighter constraints or a smaller scope.

## Implementer Guidance

When constructing dispatch prompts for implementers, include the expectations from [`prompts/implementer-guidance.md`](../prompts/implementer-guidance.md). Key points:

- Ask before starting if anything is unclear
- Follow the plan's file structure and established codebase patterns
- Stop and escalate (BLOCKED / NEEDS_CONTEXT) when in over your head
- Self-review before reporting: completeness, quality, discipline (YAGNI), testing
- TDD evidence when required: show RED then GREEN
- Verify commits stay within the task's declared Files section

## Investigator Guidance

When you need to locate symbols, trace dependencies, verify facts, or explore the codebase without making changes, dispatch an investigator subagent instead of an implementer. Use an investigator when:

- A reviewer flags a concern that requires checking other parts of the codebase
- You need to verify that an interface contract matches what a consuming task expects
- You need to trace the impact of a proposed change before dispatching an implementer
- A subagent returns BLOCKED and you need to gather context before re-dispatching

An investigator is **read-only** — it must not modify any files. It returns a structured summary using the investigator compressed output format (see Phase 8 Context Compression). Use a standard model for investigators.

## Pre-Flight Checks

Before dispatching any subagent, verify:

1. **Repository state:** clean working tree, correct base branch checked out
2. **Tooling available:** test runner, linter, and build commands are accessible and work
3. **Structured registry written:** `super-plan.json` exists with all tasks defined and set to `pending`, and the generated ledger matches it
4. **Execution profiles validated:** any configured `agents.<profile>` used by the upcoming wave still exists on the current platform, or has already been cleared to default fallback

If any check fails, fix it before dispatching.

## Subagent Status Handling

| Status                 | Meaning                        | Action                                                                                |
| ---------------------- | ------------------------------ | ------------------------------------------------------------------------------------- |
| **DONE**               | Implemented, tests pass        | Mark `ready_for_review`, generate review package, proceed to review                   |
| **DONE_WITH_CONCERNS** | Completed but flagged doubts   | Read concerns, decide whether to address before review                                |
| **NEEDS_CONTEXT**      | Missing information to proceed | Provide context and re-dispatch                                                       |
| **BLOCKED**            | Cannot complete the task       | Assess: provide context, upgrade model, break into smaller tasks, or escalate to user |

**Never** ignore an escalation or force the same model to retry without changes.

## Branch Strategy

Never start implementation on `main` or `master` without explicit user consent. Create a feature branch for the plan:

- **Branch name:** `NNNN-<feature-name>` (e.g., `0003-auth-middleware`)
- **Base branch:** check out from the default branch
- **Parallel subagents:** When using worktree isolation, each subagent works on a branch derived from the feature branch (e.g., `0003-auth-middleware/Task-A-0001`)
- **Integration:** After each task review, merge the task branch into the feature branch. After Phase 7, the feature branch is ready for a PR or merge

If the user does not specify a branch strategy, propose one before Phase 5 dispatch.

## Error Recovery

See [`phases/08-reference.md`](08-reference.md#error-recovery) for the full retry process, failure categories, and task status transitions.
