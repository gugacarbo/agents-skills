# Phase 3: Writing the Plan

**Save to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec).

A plan bridges the approved spec and the structured execution registry that Phase 4 will create. It must be detailed enough that an implementer subagent can execute any task without asking clarifying questions.

## Verify Library and Framework Documentation

After extracting the general requirements, architecture constraints, and technology choices from the approved spec, first look for an applicable implementation pattern in the repository. External documentation lookup is conditional: perform it only when the repository has no suitable pattern or when the plan introduces a new, ambiguous, version-sensitive, or otherwise undocumented implementation.

Before writing the plan's executable task details:

1. Search the repository first: manifests, lockfiles, runtime configuration, existing imports, wrappers, adapters, utilities, tests, examples, and nearby features. Record the pattern, source file, and reason it applies.
2. Decide for each technology whether external lookup is needed. Skip lookup when an existing repository pattern fully defines the intended behavior and there is no version-sensitive or ambiguous point. Record `repository-pattern` and the relevant source paths in the plan.
3. When lookup is needed, load [`../prompts/find-docs.md`](../prompts/find-docs.md). Use it for new integrations, missing repository precedent, unclear APIs, version-sensitive behavior, migration questions, or conflicting local patterns.
4. Prefer Context7 for the lookup. Resolve the library before querying its documentation, use version-specific documentation when the project pins a version, and keep each query focused on one implementation decision.
5. If Context7 is unavailable, fails, cannot resolve the library, or does not provide sufficiently authoritative coverage, use web fetch/search against the library's official documentation, repository, or specification. Do not silently rely on model memory. Record the fallback and the official source URLs.
6. Compare the documented behavior with the target application's actual context: installed version, runtime, existing architecture, neighboring code, adapters, conventions, and constraints. Do not copy an example without checking that its API and assumptions match this repository.
7. Resolve discrepancies before decomposition. If documentation invalidates an architectural choice, update the plan and its task boundaries; if the discrepancy requires a product decision, stop and ask the user.

The plan must include a **Documentation Verification** section containing, for every researched technology:

- package/framework and installed or targeted version;
- focused question or implementation decision;
- lookup method (`repository-pattern`, `Context7`, or `official-web-fallback`);
- authoritative source or documentation URL;
- relevant API/configuration contract and version caveats;
- how the finding maps to this application's files, runtime, and task design;
- unresolved risks or decisions requiring user input.

No plan is ready for Phase 4 until the repository-pattern assessment is complete for every material technology choice and any required external lookup is complete, or the plan explicitly records why no external documentation lookup is necessary.

## Plan Structure

Start from [`templates/plan-template.md`](../templates/plan-template.md). The plan file must contain:

1. **Summary and context** — goal, scope, exclusions, success signal, current behavior, and entry points
2. **Context and design** — architecture, technology versions, execution mode, flow, and implementation-relevant contracts
3. **References and constraints** — links to specs/ADRs/RFCs with implementation consequences, unresolved decisions, and constraints
4. **Files and tasks** — ownership map plus concise batch/dependency sequence
5. **Documentation Verification** — current technology findings, sources, and application-context mapping
6. **Verification** — test commands, scenario matrix, edge/error cases, compatibility checks, and human review
7. **Risks and handoff** — rollback, rollout, readiness checklist, and registry paths

The plan is a concise implementation handoff: an implementer should not need
to reopen the spec for operational context, contracts, tests, or rollback
steps. When a decision or rationale already exists in a spec, ADR, RFC, or
decision record, reference its path and section instead of copying it. Include
only the implementation consequence needed by the worker.

The plan markdown is a human-readable overview, while `super-plan.json` is the
single source of truth for task structure, ownership, dependencies, steps,
requirements coverage, and acceptance criteria. Keep the overview and registry
aligned during decomposition; do not create a second, conflicting task list.

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
