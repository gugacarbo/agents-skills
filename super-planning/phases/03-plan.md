# Phase 3: Writing the Plan

**Save to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec).

A plan bridges the approved spec and executable tasks. It must be detailed enough that an implementer subagent can execute any task without asking clarifying questions.

## Plan Structure

Start from [`templates/plan-template.md`](../templates/plan-template.md). The plan file must contain:

1. **Header** — goal, architecture summary, tech stack
2. **Global Constraints** — copied verbatim from the spec; inherited by every task implicitly
3. **File Structure** — map of files/modules the plan will touch, with clear ownership per task
4. **Task Registry reference** — note pointing to the `tasks.json` that Phase 4 will produce

The executable part of the plan lives in `tasks.json`. The plan file provides context and constraints; `tasks.json` provides the executable specification.

## Batches and Waves

Assign each task to a batch before writing steps:

| Batch            | Contents                                                      |
| ---------------- | ------------------------------------------------------------- |
| `A` — Foundation | Infrastructure, types, shared utilities, config, schemas      |
| `B` — Core       | Primary business logic that depends on foundation tasks       |
| `C` — Surface    | UI, API endpoints, integration tests, wiring, CLI entrypoints |
| `D` — Final      | Final review, cleanup, documentation, merge preparation       |

Rules:

- A task in batch `B` can only depend on tasks in batch `A` or earlier.
- A task in batch `C` can only depend on tasks in batch `B` or earlier.
- A task in batch `D` can depend on any earlier batch.
- Tasks within the same batch can run in parallel if they have no file conflicts.
- A batch with sequential dependencies becomes a wave.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh subagent:

- Fold setup, scaffolding, and docs into the task whose deliverable needs them.
- Split only where a reviewer could meaningfully reject one task while approving its neighbor.
- Each task ends with an independently testable deliverable.
- Target 2–5 minutes of subagent work per task.
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

After writing the plan and `tasks.json`, check:

1. **Spec coverage:** Can you point to a task for every requirement?
2. **Placeholder scan:** Any TBD/TODO patterns? Fix them.
3. **Type consistency:** Do signatures in later tasks match what earlier tasks define?
4. **Dependency order:** Are dependencies acyclic and only point to earlier batches?
5. **File conflicts:** Can tasks in the same batch run in parallel without touching the same files?
6. **JSON validity:** Is `tasks.json` valid JSON and does it match [`templates/tasks-template.json`](../templates/tasks-template.json)?

## Execution Handoff

After saving the plan and `tasks.json`, offer the user:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks
2. **Sequential** — execute tasks one at a time with review after each

If the user chose parallel dispatch during decomposition, default to subagent-driven with parallel waves.
