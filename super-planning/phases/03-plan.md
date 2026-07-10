# Phase 3: Writing the Plan

**Save to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec).

A plan bridges the approved spec and the structured execution registry that Phase 4 will create. It must be detailed enough that an implementer subagent can execute any task without asking clarifying questions.

## Plan Structure

Start from [`templates/plan-template.md`](../templates/plan-template.md). The plan file must contain:

1. **Header** — goal, architecture summary, tech stack
2. **Global Constraints** — copied verbatim from the spec; inherited by every task implicitly
3. **File Structure** — map of files/modules the plan will touch, with clear ownership per task
4. **Super-plan reference** — note pointing to the `super-plan.json` that Phase 4 will create in the task directory via the active helper path (in-repo skill scripts when available, otherwise `.super-planning/super-plan.sh`)

The executable part of the plan lives in `super-plan.json`. The plan file provides context and constraints; `super-plan.json` provides the structured specification, requirement coverage, and executable tasks after Phase 4 materializes it.

## Testing Strategy Handoff

Read the spec's **Test Strategy** section and carry it into the plan:

- preserve the selected TDD or conventional-coverage mode;
- preserve the effective `testing-anti-patterns.md` path;
- map each main test scenario to one or more tasks;
- convert TDD requirements into exact global constraints and task acceptance criteria;
- keep documentation, static configuration, and confirmed exceptions outside TDD unless the spec explicitly includes them.

Every behavior-changing task must end with an independently testable deliverable. If a task adds or changes tests, its rules must tell the implementer to read the effective testing guidance file first.

> **Single source of truth:** `super-plan.json` is the single source of truth for task structure and ownership. The plan markdown file is a human-readable summary. Always update `super-plan.json` first, then regenerate if needed.

> **Note:** Task definitions live in `super-plan.json`, not in the plan markdown file. The plan markdown is a human-readable overview; the JSON registry is the machine-readable source of truth.

## Execution Batches and Delivery Layers

Assign each task both a `batch` and a `layer` before writing steps:

- `batch` = execution group. Tasks with the same batch label are intended to run in the same parallel batch when they are file-isolated and dependency-safe.
- `layer` = delivery layer. Use this to classify the work as foundation/core/surface/final without overloading the execution grouping.

### `batch` rules

- Use short labels such as `A`, `B`, `C`, `D`.
- Tasks in the same batch are candidates for parallel execution.
- A task may depend on another task in the same batch only if you intend that batch to run sequentially instead of in parallel.
- If two tasks should definitely run together in the same parallel batch, give them the same batch label.
- If a task must wait for another batch to finish, move it to a later batch.

### `layer` values

| Layer        | Contents                                                      |
| ------------ | ------------------------------------------------------------- |
| `foundation` | Infrastructure, types, shared utilities, config, schemas      |
| `core`       | Primary business logic                                        |
| `surface`    | UI, API endpoints, integration tests, wiring, CLI entrypoints |
| `final`      | Final review, cleanup, documentation, merge preparation       |

Rules:

- `layer` describes the type of work; it does NOT control parallelism.
- Prefer dependencies that point to earlier batches.
- Use `layer` to communicate architectural layering and review expectations.
- Use `batch` to communicate execution order and parallel batches.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh subagent:

- Fold setup, scaffolding, and docs into the task whose deliverable needs them.
- Split only where a reviewer could meaningfully reject one task while approving its neighbor.
- Each task ends with an independently testable deliverable.
- Target 3-7 steps or 1-2 testable deliverables per task.
- Each step within a task is ONE action.

## No Placeholders

These are plan failures — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" without the actual code
- "Write tests for the above" without actual test code
- "Similar to Task N" (repeat the code — subagents may read tasks out of order)
- Steps that describe what to do without showing how
- References to types, functions, or methods not defined in any task

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Self-Review

After writing the plan and preparing its decomposition inputs, check:

1. **Spec coverage:** Can you point from every requirement to a planned task or task group that Phase 4 will encode?
2. **Placeholder scan:** Any TBD/TODO patterns? Fix them.
3. **Type consistency:** Do signatures in later tasks match what earlier tasks define?
4. **Dependency order:** Are dependencies acyclic and aligned with the intended batch order?
5. **File conflicts:** Can tasks in the same batch run in parallel without touching the same files?
6. **Decomposition readiness:** Is the plan concrete enough that Phase 4 can write a complete `super-plan.json` without inventing missing details?

## Pre-Dispatch Conflict Review

Before Phase 4 creates the executable registry, scan the plan once for:

- tasks that contradict one another or the copied Global Constraints;
- dependencies that point forward incorrectly or create a cycle;
- acceptance criteria that the review rubric would reject, such as tests that assert nothing;
- parallel tasks that declare overlapping files or shared mutable state.

If the scan finds a real conflict, present one batched question containing the
conflicting plan text and ask which requirement governs. Do not start
decomposition or dispatch until the conflict is resolved. If the scan is
clean, record that result in the plan handoff and continue without another
confirmation gate.

## Execution Handoff

The parallel vs sequential execution mode was already decided in the decision flow (SKILL.md). Do NOT re-prompt — just document the mode in the plan. If mode is not set, reference the decision flow to decide.
