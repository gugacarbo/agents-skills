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

**Always specify the model explicitly.** An omitted model inherits the session's model — often the most expensive — which defeats this section.

**Turn count beats token price.** The cheapest models take 2–3× more turns on multi-step work, costing more overall. Use standard as the floor for reviewers and for implementers working from prose descriptions. Reserve the cheapest tier for implementers whose task JSON entry contains the complete code to write.

## Constructing the Dispatch Prompt

A dispatch prompt contains exactly five things — nothing more:

1. **One line of context:** where this task fits in the project
2. **The task registry path:** "Read the task entry in `tasks.json` first — it is your requirements"
3. **Interfaces and decisions** from earlier tasks that the JSON entry cannot know
4. **Your resolution** of any ambiguity you noticed in the task entry
5. **The report-file path** and report contract

Use the minimal template at [`prompts/worker-prompt-template.md`](../prompts/worker-prompt-template.md) as the starting point.

## Report File Convention

Every implementer must write a full report to a file in the task directory. Default convention:

```
docs/tasks/{NNNN-<feature-name>}/task-{task-id}-report.md
```

Example for task `Task-A-0001` under plan `0003-auth-middleware`:

```
docs/tasks/0003-auth-middleware/task-Task-A-0001-report.md
```

The subagent returns only a one-line status to the orchestrator. Detail lives in the report file.

**Do NOT:**

- Paste the entire plan into every dispatch
- Paste accumulated prior-task summaries into later dispatches
- Include process narration or history
- Give the subagent access to your session's context

## Sequential Dispatch

For each task:

1. Read the task entry from `docs/tasks/{NNNN-<feature-name>}/tasks.json`.
2. Dispatch one implementer subagent with the task JSON entry + scene-setting context.
3. If the subagent asks questions, answer before letting it proceed.
4. When the subagent returns, generate a review package and dispatch a reviewer.
5. If the reviewer finds issues, dispatch a fix subagent and re-review.
6. Append a `completed` log entry via [`scripts/log-task.sh`](../scripts/log-task.sh) and update the JSON status.

## Parallel Dispatch

For independent tasks with no file conflicts:

1. Extract all task entries from `tasks.json` at once.
2. Dispatch ALL subagents in ONE message (parallel tool calls).
3. Wait for all to return.
4. Review all results.
5. Dispatch fix subagents for any that need fixes.
6. Integrate all changes onto the working branch.
7. Append `completed` log entries and update the JSON status for all tasks in the wave.

**Critical:** Multiple dispatch calls in one response = parallel execution. One per response = sequential. The dispatch pattern controls parallelism.

**Worktree isolation for parallel mode:** When the platform supports it, use `isolation: "worktree"` so each parallel subagent works in its own git worktree. This prevents index-lock races and file conflicts.

**Practical limit:** Dispatch 2–4 subagents per wave. More than that adds coordination overhead. If you have 8 independent tasks, use 2–3 waves of 3 rather than one wave of 8.

## Wave-Based Execution

When tasks have partial dependencies, organize them into waves:

1. **Foundation wave** — infrastructure, types, shared utilities (must complete first)
2. **Core wave** — primary business logic (may depend on foundation)
3. **Surface wave** — UI, API endpoints, integration tests (depends on core)

Tasks within a wave can run in parallel if they don't conflict on files. Waves run sequentially. Each wave boundary is a natural checkpoint for integration testing.

## Common Mistakes in Dispatch Prompts

| Mistake                                          | Fix                                                 |
| ------------------------------------------------ | --------------------------------------------------- |
| Too broad: "Fix all the tests"                   | Focused: "Fix agent-tool-abort.test.ts failures"    |
| No context: "Fix the race condition"             | Paste error messages and test names                 |
| No constraints: agent refactors everything       | "Do NOT change production code" or "Fix tests only" |
| Vague output: "Fix it"                           | "Return summary of root cause and changes"          |
| Pasting the whole plan into dispatch             | Hand only the task entry from `tasks.json`          |
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
3. **Task registry written:** `tasks.json` exists with all tasks defined and set to `pending`
4. **Progress log initialized:** `progress.log` exists and is empty; `log-task.sh` is present and executable

If any check fails, fix it before dispatching.

## Subagent Status Handling

| Status                 | Meaning                        | Action                                                                                |
| ---------------------- | ------------------------------ | ------------------------------------------------------------------------------------- |
| **DONE**               | Completed, tests pass          | Proceed to review                                                                     |
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
