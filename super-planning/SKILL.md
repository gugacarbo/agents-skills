---
name: super-planning
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature spec or requirements for a multi-step task, before touching code. Covers plan writing, task decomposition, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression."
---

# super-planning

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** You delegate tasks to agents with isolated context. By crafting their instructions precisely, they stay focused. They do not inherit your session's context or history. This preserves your own context for coordination work and prevents context pollution between tasks.

**Core principle:** Fresh subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

**Scope of this skill:** Use `super-planning` for implementation planning and execution. Use the `brainstorming` skill upstream for refining requirements. Use the `commit-changes` skill downstream for committing final work.

## When to Use

```
Have a feature idea or requirements for a multi-step task?
├─ No → Start at Phase 1 (BRAINSTORM)
├─ Yes → Is there already an approved spec in docs/specs/?
│   ├─ Yes → Skip to Phase 3 (PLAN), reference the spec number
│   └─ No → Start at Phase 2 (SPEC), write the spec first
│       └─ After spec approval → Phase 3 (PLAN)
│           └─ Are tasks mostly independent of each other?
│               ├─ Yes → Can they run in parallel without file conflicts?
│               │   ├─ Yes → PARALLEL MODE (dispatch all in one message)
│               │   └─ No → SEQUENTIAL MODE (one at a time, review after each)
│               └─ No → SEQUENTIAL MODE (tasks depend on each other's output)
└─ Single trivial task? → Just do it inline, no skill needed
```

**Sequential mode** — dispatch one implementer subagent per task, review after each, continue. Best for dependent tasks or tasks that touch overlapping files.

**Parallel mode** — dispatch multiple implementer subagents simultaneously in one message, review all after completion. Best for independent tasks touching different modules. Requires file-level isolation (no two tasks write the same file).

## The Workflow

```
Phase 1: BRAINSTORM   Refine the idea into requirements and design decisions
Phase 2: SPEC          Write the feature spec, get user approval
Phase 3: PLAN          Write the implementation plan (same numbering as spec)
Phase 4: DECOMPOSE     Break plan into atomic tasks with a JSON registry
Phase 5: DISPATCH      Send subagents (sequential or parallel)
Phase 6: REVIEW        Spec compliance + code quality gates
Phase 7: INTEGRATE     Merge results, final review, finish
```

---

## Phase 1: Brainstorm

<HARD-GATE>
You MUST invoke the brainstorming skill before writing the spec. Do not skip this step, even if the feature seems simple or well-understood.
</HARD-GATE>

Use the **brainstorming** skill to refine the idea into a spec. Flow:

1. **Invoke the brainstorming skill** — present the feature idea and let it guide the exploration
2. **Collect outputs** — the brainstorming skill produces requirements, constraints, non-goals, and design decisions
3. **Carry the outputs into the spec** — use the brainstorming results as the foundation for the spec summary (next phase)

Do NOT proceed to Phase 2 (SPEC) until the brainstorming skill has been invoked and its outputs are available.

### Fallback When Brainstorming Skill Is Unavailable

If the **brainstorming** skill is not present in the workspace, do **not** treat this as permission to skip Phase 1. Perform a lightweight manual brainstorm:

1. **Quick assessment** — Based on the user's request, identify the core problem, the goal, and the likely scope (3-5 sentences).
2. **Clarifying questions** — Ask the user 2-5 focused questions to surface requirements, constraints, non-goals, and design preferences. Examples:
   - What is the most important outcome for you?
   - Are there any constraints (time, budget, tech stack, dependencies)?
   - What is explicitly out of scope?
   - Are there existing patterns, code, or specs this should align with?
   - Who will use or consume the result?
3. **Capture outputs** — Summarize the answers into requirements, constraints, non-goals, and design decisions.
4. **Proceed only after confirmation** — Present the summary to the user and confirm before moving to Phase 2.

---

## Phase 2: Writing the Spec

Before any planning or code, capture what you're building in a spec document. The spec is the contract between the user and the implementation — every task in the plan must trace back to it.

### Check Workspace Documentation Patterns

Before writing the spec, scan the workspace for existing documentation conventions:

1. **Look for existing specs:** `docs/specs/`, `specs/`, `docs/`, or any directory with spec-like files
2. **Check naming conventions:** sequential numbering (`0001-`), date-based (`YYYY-MM-DD-`), or other patterns
3. **Check file format:** markdown, plain text, or structured formats
4. **Check content structure:** headers, sections, required fields that existing specs use
5. **Check for templates:** `docs/templates/spec.template.md` or similar

Follow the workspace's existing patterns. If no pattern exists, use the default below.

### Spec File Location

Save specs to:

```
docs/specs/NNNN-<feature-name>-spec.md
```

Where `NNNN` is a zero-padded sequential number. Check existing specs in `docs/specs/` to determine the next number. If the directory doesn't exist, create it.

**The plan MUST use the same `NNNN` number** so the spec and plan are linked:

```
docs/specs/0003-auth-middleware-spec.md    ← the spec
docs/plans/0003-auth-middleware.md          ← the plan (same number)
```

### Default Spec Format

If no workspace pattern is found, use the template at `templates/spec-template.md`. Key sections to fill in:

- **Objective** — what the user/system can do once this is implemented
- **Flow** — step-by-step observable behavior (happy path + key branches)
- **Contract** — inputs, outputs, formats, guarantees (API events, UI, data shapes)
- **Edge cases** — enumerated and decided using the EARS pattern (WHEN ⟨trigger⟩ the system MUST ⟨response⟩). Undecided cases go to Open questions, not here
- **Open questions** — each item blocks an implementation point; the agent must not improvise on an open question
- **Definition of Done** — runnable commands with binary pass/fail criteria
- **Human review** — what requires human eyes and is NOT in the agent loop

### Spec Numbering

The spec number (NNNN) becomes the plan number. If the workspace uses sequential numbering:

1. Scan existing specs for the highest number
2. Use the next number
3. The implementation plan will use the same number: `docs/plans/NNNN-<feature-name>.md`

If the workspace uses date-based naming, use dates for both spec and plan.

### Pre-Write Approval Gate

<HARD-GATE>
Do NOT write the spec file until the user has approved the summary. This applies regardless of perceived simplicity.
</HARD-GATE>

Before writing the spec file:

1. **Present a summary** to the user covering:
   - Problem statement (1-2 sentences)
   - Goal (1 sentence)
   - Key requirements (bullet list, 3-7 items)
   - Non-goals (what's out of scope)
   - Architecture approach (1-2 sentences)
   - Open questions (if any)
2. **Ask the user** for approval using the question/ask tool. Use the prompt template at `prompts/pre-write-approval.md`

3. **If approved:** Write the spec file
4. **If changes requested:** Incorporate the feedback and present the summary again

### Post-Write Approval Gate

After writing the spec file, ask the user to review it before proceeding to planning. Use the prompt template at `prompts/post-write-approval.md`

Do NOT proceed to Phase 3 (planning) until the spec is approved. If changes are requested, update the spec and ask again.

### Spec Status Lifecycle

The spec `status` frontmatter field tracks where the spec is in its lifecycle:

| Status        | When                                                                                           |
| ------------- | ---------------------------------------------------------------------------------------------- |
| `draft`       | Initial state. Set when the spec file is created.                                             |
| `accepted`    | User has reviewed and approved the spec (after Post-Write Approval Gate). Transition immediately. |
| `implemented` | All tasks are complete, final review is clean, and the spec's Definition of Done passes.        |
| `deprecated`  | The spec is no longer relevant (superseded, cancelled, or replaced by a newer spec).            |

Transition rules:
- Only move to `accepted` after the Post-Write Approval Gate passes.
- Only move to `implemented` after Phase 7 completes and the spec's DoD commands run green.
- Update the `implemented-by` field when transitioning to `implemented` — list the real paths (code, migrations, functions) that deliver the spec.
- Never skip states. A spec cannot jump from `draft` to `implemented`.

---

## Phase 3: Writing the Plan

**Announce:** "I'm using the super-planning skill to create and execute this implementation plan."

**Save plans to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec)

A plan is the bridge between the approved spec and executable tasks. It must be detailed enough that an implementer subagent can execute any task without asking clarifying questions.

### Plan Structure

Start from `templates/plan-template.md`. The plan file must contain:

1. **Header** — goal, architecture summary, tech stack
2. **Global Constraints** — copied verbatim from the spec. Every task inherits these implicitly, so do not repeat them inside tasks.
3. **File Structure** — map of files/modules the plan will touch, with clear ownership per task
4. **Task Registry reference** — a note pointing to the `tasks.json` that Phase 4 will produce

The plan is **not** a collection of narrative sections. The executable part of the plan lives in the `tasks.json` registry created in Phase 4. The plan file itself provides context and constraints; the tasks.json provides the executable specification.

### Batches and Waves

Assign each task to a batch before writing steps:

- **`A` — Foundation:** infrastructure, types, shared utilities, config, database schemas
- **`B` — Core:** primary business logic that depends on foundation tasks
- **`C` — Surface:** UI, API endpoints, integration tests, wiring, CLI entrypoints
- **`D` — Final:** final review, cleanup, documentation, merge preparation

Rules:

- A task in batch `B` can only depend on tasks in batch `A` or earlier
- A task in batch `C` can only depend on tasks in batch `B` or earlier
- A task in batch `D` can depend on any earlier batch
- Tasks within the same batch can run in parallel if they have no file conflicts
- A batch with sequential dependencies becomes a wave

### Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh subagent. Rules:

- Fold setup, scaffolding, and docs into the task whose deliverable needs them
- Split only where a reviewer could meaningfully reject one task while approving its neighbor
- Each task ends with an independently testable deliverable
- Target 2-5 minutes of subagent work per task
- Each step within a task is ONE action

### No Placeholders

These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" (without the actual code)
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the subagent may read tasks out of order)
- Steps that describe what to do without showing how
- References to types, functions, or methods not defined in any task

### Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

### Self-Review

After writing the complete plan and tasks.json, check it yourself:

1. **Spec coverage:** Can you point to a task for every requirement?
2. **Placeholder scan:** Any TBD/TODO patterns? Fix them.
3. **Type consistency:** Do signatures in later tasks match what earlier tasks define?
4. **Dependency order:** Are dependencies acyclic and only point to earlier batches?
5. **File conflicts:** Can tasks in the same batch run in parallel without touching the same files?
6. **JSON validity:** Is `tasks.json` valid JSON and does it match `templates/tasks-template.json`?

### Execution Handoff

After saving the plan and `tasks.json`, offer the user an execution choice:

1. **Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks, fast iteration
2. **Sequential** — Execute tasks one at a time with review after each

If the user chose parallel dispatch during decomposition, default to subagent-driven with parallel waves.

---

## Phase 4: Decompose into Tasks

Before dispatching any subagent, generate the task directory and a single machine-readable registry that is the source of truth for every task:

### Task Registry (JSON)

Create the registry in the plan's task directory:

```
docs/tasks/{NNNN-<feature-name>}/tasks.json
```

Replace `{NNNN-<feature-name>}` with the same plan reference used in `docs/plans/NNNN-<feature-name>.md`. Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/tasks.json
```

The registry is the implementer's single source of requirements. It contains the exact values, code, and acceptance criteria.

Structure and field definitions: see `templates/tasks-template.json`. All fields marked as required in the template must be present.

**Rules for status:**

- Set all tasks to `pending` when creating the registry
- Update status after each dispatch/review cycle
- A task cannot move to `completed` until its review is clean

### Progress Log

Track progress in an append-only log file that survives context compaction, also under the same task directory:

```
docs/tasks/{NNNN-<feature-name>}/progress.log
```

Example:

```
docs/tasks/0003-auth-middleware/progress.log
```

Format: see `templates/progress-template.txt`

The log is append-only. Subagents must NOT write to it directly. They must call the provided helper:

```bash
scripts/log-task.sh \\
  --plan 0003-auth-middleware \
  --task Task-A-0001 \
  --event started \
  --try 1 \
  --max-tries 3 \
  --message "Beginning implementation"
```

Subagents must log events at minimum for: `started`, `completed`, `failed`, `blocked`.

### Progress Ledger

Create a progress ledger alongside the log for human-readable task tracking. Save it at:

```
docs/tasks/{NNNN-<feature-name>}/progress-ledger.md
```

Use the template at `templates/progress-ledger-template.md`. The ledger is a markdown table with columns: Task, Status, Commits, Report File, Review.

**When to update the ledger:**

- **After creating tasks.json** — initialize with all tasks set to ⏳ pending
- **After dispatching a subagent** — set status to 🔄 in progress
- **After review completes cleanly** — set status to ✅ complete, record commit range
- **After review finds issues** — set status to 🔁 needs-fix, record findings
- **After a subagent is BLOCKED** — set status to ❌ blocked
- **In Phase 7** — final status update for all tasks

The ledger survives context compaction. After context compaction, trust the ledger, the progress log, and `git log` over your own recollection. Never re-dispatch a task the ledger or log marks complete.

---

## Phase 5: Dispatch Subagents

### Model Selection

Use the least powerful model that can handle each role:

| Role                                                               | Model                                                | Why                                                               |
| ------------------------------------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Mechanical implementation (isolated, clear spec, 1-2 files)        | Cheap/fast                                           | Most implementation is mechanical when the plan is well-specified |
| Integration and judgment (multi-file, pattern matching, debugging) | Standard                                             | Needs context awareness across files                              |
| Architecture and design                                            | Most capable                                         | Requires broad reasoning                                          |
| Task review (spec compliance + quality)                            | Standard for small diffs, capable for subtle changes | Review is judgment work                                           |
| Final whole-branch review                                          | Most capable                                         | High-stakes, broad scope                                          |

**Always specify the model explicitly** when dispatching. An omitted model inherits the session's model — often the most expensive — which defeats this section.

**Turn count beats token price.** The cheapest models take 2-3× more turns on multi-step work, costing more overall. Use standard as the floor for reviewers and for implementers working from prose descriptions. Reserve the cheapest tier for implementers whose task JSON entry contains the complete code to write.

### Constructing the Dispatch Prompt

A dispatch prompt contains exactly five things — nothing more:

1. **One line of context:** Where this task fits in the project
2. **The task registry path:** "Read the task entry in `tasks.json` first — it is your requirements"
3. **Interfaces and decisions** from earlier tasks that the JSON entry cannot know
4. **Your resolution** of any ambiguity you noticed in the task entry
5. **The report-file path** and report contract

Use the minimal template at `prompts/worker-prompt-template.md` as the starting point. Copy it, fill the placeholders, and dispatch.

### Report File Convention

Every implementer must write a full report to a file in the task directory. The orchestrator decides the exact path, but the default convention is:

```
docs/tasks/{NNNN-<feature-name>}/task-{task-id}-report.md
```

Example for task `Task-A-0001` under plan `0003-auth-middleware`:

```
docs/tasks/0003-auth-middleware/task-Task-A-0001-report.md
```

The subagent returns only a one-line status to the orchestrator. Detail lives in the report file.

**Do NOT:**

- Paste the entire plan into every dispatch (that's the context bloat this skill exists to prevent)
- Paste accumulated prior-task summaries into later dispatches
- Include process narration or history
- Give the subagent access to your session's context

### Sequential Dispatch

For each task:

1. Read the task entry from `docs/tasks/{NNNN-<feature-name>}/tasks.json`
2. Dispatch one implementer subagent with the task JSON entry + scene-setting context
3. If the subagent asks questions, answer before letting it proceed
4. When the subagent returns, generate a review package and dispatch a reviewer
5. If the reviewer finds issues, dispatch a fix subagent and re-review
6. Append a `completed` log entry via `log-task.sh` and update the JSON status

### Parallel Dispatch

For independent tasks with no file conflicts:

1. Extract all task entries from tasks.json at once
2. Dispatch ALL subagents in ONE message (parallel tool calls)
3. Wait for all to return
4. Review all results
5. Dispatch fix subagents for any that need fixes
6. Integrate all changes onto the working branch
7. Append `completed` log entries via `log-task.sh` and update the JSON status for all tasks in the wave

**Critical:** Multiple dispatch calls in one response = parallel execution. One per response = sequential. The dispatch pattern controls parallelism, not the tasks themselves.

**Worktree isolation for parallel mode:** When the platform supports it, use `isolation: "worktree"` so each parallel subagent works in its own git worktree. This prevents index-lock races and file conflicts.

**Practical limit:** Dispatch 2-4 subagents per wave. More than that adds coordination overhead that outweighs the parallelism gains. If you have 8 independent tasks, use 2-3 waves of 3 rather than one wave of 8.

### Wave-Based Execution

When tasks have partial dependencies, organize them into waves:

1. **Foundation wave** — infrastructure, types, shared utilities (must complete first)
2. **Core wave** — primary business logic (may depend on foundation)
3. **Surface wave** — UI, API endpoints, integration tests (depends on core)

Tasks within a wave can run in parallel if they don't conflict on files. Waves run sequentially. Each wave boundary is a natural checkpoint for integration testing.

### Common Mistakes in Dispatch Prompts

| Mistake                                          | Fix                                                  |
| ------------------------------------------------ | ---------------------------------------------------- |
| Too broad: "Fix all the tests"                   | Focused: "Fix agent-tool-abort.test.ts failures"     |
| No context: "Fix the race condition"             | Paste error messages and test names                  |
| No constraints: Agent refactors everything       | "Do NOT change production code" or "Fix tests only"  |
| Vague output: "Fix it"                           | "Return summary of root cause and changes"           |
| Pasting the whole plan into dispatch             | Hand only the task entry from tasks.json              |
| Accumulating prior summaries in later dispatches | Each dispatch is self-contained; never carry forward |

### When NOT to Use Parallel Mode

Parallel dispatch is not always the right choice. Use sequential when:

- **Failures are related** — fixing one might fix others; investigate together first
- **Need full system context** — understanding requires seeing the entire system
- **Exploratory debugging** — you don't yet know what's broken
- **Shared state** — tasks modify the same database tables or global config
- **Uncertain file isolation** — you're not sure tasks can avoid touching the same files

When in doubt, run sequentially. Parallel mode is an optimization, not a default.

**Practical limit:** Effective parallel dispatch caps at 2-4 subagents. Beyond that, coordination overhead and integration risk outweigh speed gains. If you have more independent tasks, batch them into sequential waves of 2-4.

### Scope Violation Detection

After each subagent returns, check that its changes stay within the declared scope:

- **File scope:** If a task declares specific files in its Files block, the resulting commit should not touch files outside that list (infrastructure files like `package.json` or lockfiles are acceptable)
- **If scope is violated:** Reject the task, re-dispatch with tighter constraints or a smaller scope

### Spawning Scale

Choose the right isolation level for the number of parallel subagents:

| Scale                                         | Isolation                           | Use Case                    |
| --------------------------------------------- | ----------------------------------- | --------------------------- |
| **Virtual File Isolation** (2-4 subagents)    | Same process, explicit file passing | Context management          |
| **Git Worktree Isolation** (10-100 subagents) | Filesystem-level, git worktrees     | Code migrations             |
| **Cloud Worker Spawning** (100+ agents)       | Container/VM isolation              | Enterprise-scale processing |

**Trade-offs:** More parallelism = faster wall time but higher coordination cost, increased token spend, harder debugging, and risk of merge conflicts. Start with 2-4 parallel subagents and scale up only when the tasks are truly independent.

### Implementer Guidance

When constructing dispatch prompts for implementers, include the expectations from `prompts/implementer-guidance.md`. Key points:

- **Ask before starting** if anything is unclear — don't guess
- **Follow the plan's file structure** and established codebase patterns
- **Stop and escalate** (BLOCKED / NEEDS_CONTEXT) when in over your head
- **Self-review** before reporting: completeness, quality, discipline (YAGNI), testing
- **TDD evidence** when required: show RED then GREEN, not just "tests pass"
- **Scope violation detection:** verify commits stay within the task's declared Files section

### Investigator Guidance

When you need to locate symbols, trace dependencies, verify facts, or explore the codebase without making changes, dispatch an investigator subagent instead of an implementer. Use an investigator when:

- A reviewer flags a concern that requires checking other parts of the codebase
- You need to verify that an interface contract matches what a consuming task expects
- You need to trace the impact of a proposed change before dispatching an implementer
- A subagent returns BLOCKED and you need to gather context before re-dispatching

An investigator is **read-only** — it must not modify any files. It returns a structured summary using the investigator compressed output format (see Context Compression below). Use a standard model for investigators.

### Pre-Flight Checks

Before dispatching any subagent, verify:

1. **Repository state:** Clean working tree, correct base branch checked out
2. **Tooling available:** Test runner, linter, and build commands are accessible and work
3. **Task registry written:** `docs/tasks/{NNNN-<feature-name>}/tasks.json` exists with all tasks defined and set to `pending`
4. **Progress log initialized:** `docs/tasks/{NNNN-<feature-name>}/progress.log` exists and is empty; `log-task.sh` is present and executable

If any check fails, fix it before dispatching. A subagent dispatched into a dirty repo or broken test environment will waste context.

### Subagent Status Handling

Subagents report one of four statuses:

| Status                 | Meaning                        | Action                                                                                              |
| ---------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------- |
| **DONE**               | Completed the work, tests pass | Proceed to review                                                                                   |
| **DONE_WITH_CONCERNS** | Completed but flagged doubts   | Read concerns, decide whether to address before review                                              |
| **NEEDS_CONTEXT**      | Missing information to proceed | Provide context and re-dispatch                                                                     |
| **BLOCKED**            | Cannot complete the task       | Assess: provide context (re-dispatch), upgrade model, break into smaller tasks, or escalate to user |

**Never** ignore an escalation or force the same model to retry without changes.

### Branch Strategy

Never start implementation on `main` or `master` without explicit user consent. Create a feature branch for the plan:

- **Branch name:** Use the plan number and name: `NNNN-<feature-name>` (e.g., `0003-auth-middleware`)
- **Base branch:** Check out from the default branch (usually `main` or `master`)
- **Parallel subagents:** When using worktree isolation, each subagent works on a branch derived from the feature branch (e.g., `0003-auth-middleware/Task-A-0001`)
- **Integration:** After each task review, merge the task branch into the feature branch. After Phase 7, the feature branch is ready for a PR or merge

If the user does not specify a branch strategy, propose one before Phase 5 dispatch.

### Error Recovery

See the **Error Recovery** section below for the full retry process, failure categories, and task status transitions.

---

## Phase 6: Review Gates

Two-stage review after each task (or after all tasks in parallel mode):

### Stage 1: Spec Compliance

Does the implementation match the requirements?

- **Missing:** requirements skipped or missed
- **Extra:** features not requested (overbuilding)
- **Misunderstood:** right feature, wrong approach

If a requirement cannot be verified from the diff alone, flag it as ⚠️ and verify it yourself.

### Stage 2: Code Quality

Is it well-built?

- Clean separation of concerns?
- Proper error handling?
- DRY without premature abstraction?
- Edge cases handled?
- Tests verify real behavior (not mocks)?
- Each file has one clear responsibility?

### Reviewer Dispatch

The reviewer gets three things:

1. The task entry from `tasks.json` (same one the implementer used)
2. The implementer's report file
3. The review package (diff file generated via git)

**Do NOT** give the reviewer:

- Open-ended directives like "check all uses"
- Instructions to ignore or not flag specific issues
- The entire plan file (only their task's entry from `tasks.json`)

**Do NOT** skip review. Both spec compliance AND code quality are required. Self-review by the implementer does not replace an independent review.

### Reviewer Guidance

When dispatching a reviewer, include the expectations and output format defined in `prompts/reviewer-guidance.md`. Key principles:

- **Do Not Trust the Report:** Treat the implementer's report as unverified claims; verify against the diff
- **Scope-Limited:** Only review the task's changes, not the whole branch
- **Tests:** Don't re-run the suite; run a test only when reading the code raises a specific doubt
- **Calibrated Severity:** Critical = must fix before proceeding, Important = blocks merge, Minor = nice to have
- **Strengths:** Capture what's well done, not just issues
- **Every finding** needs a concrete `file:line` location, what's wrong, why it matters, and how to fix it

### Handling Review Findings

| Severity      | Meaning                    | Action                                                    |
| ------------- | -------------------------- | --------------------------------------------------------- |
| **Critical**  | Must fix before proceeding | Dispatch fix subagent, re-review                          |
| **Important** | Should fix, blocks merge   | Dispatch fix subagent, re-review                          |
| **Minor**     | Nice to have               | Record in progress ledger, point final review at the list |

For the final whole-branch review, dispatch ONE fix subagent with ALL findings — not one fixer per finding.

---

## Phase 7: Integrate and Finish

After all tasks are reviewed and complete:

1. **Run the full test suite** once
2. **Dispatch a final whole-branch review** using the most capable model
3. **Address any remaining findings** from the final review
4. **Update the progress ledger** with final status
5. **Offer next steps:** merge, PR, or keep working

---

## Context Compression

Subagent tool results get injected verbatim into your context. Across many delegations this fills the window. Mitigate:

### File-Based Handoffs

Everything you paste into a dispatch prompt — and everything a subagent prints back — stays resident in your context for the rest of the session. Hand artifacts over as files instead:

- **Task entry** → `tasks.json` (subagent reads its entry, you don't carry it)
- **Report** → file (subagent writes it, you get a one-line summary)
- **Review package** → file (reviewer reads the diff from a file, you don't paste it)

### Compressed Output

When the platform supports it, configure subagents to return compressed output (~60% less context than prose). Use the role-specific formats defined in the dispatch prompt templates:

- **Implementer output:** see `prompts/implementer-guidance.md` → Compressed Output Format
- **Reviewer output:** see `prompts/reviewer-guidance.md` → Compressed Reviewer Output
- **Investigator output:** used when dispatching an investigation subagent to locate symbols, trace dependencies, or verify facts:
  ```
  <path:line> — `symbol` — short note
  totals: <counts>.
  ```
  Or `No match.` Always file-path-first, line-number-attached, backticked symbols.

**General principles:**

- Structured formats over prose
- One-line verdicts instead of explanations
- Each subagent's report file holds the detail; the controller gets only the structured summary

### Narration Discipline

Between tool calls, narrate at most one short line. The ledger and tool results carry the record. Progress summaries waste the user's time — they asked you to execute the plan, so execute it.

---

## Continuous Execution

Do not pause to check in between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are:

- **BLOCKED** status you cannot resolve
- Ambiguity that genuinely prevents progress
- All tasks complete

"Should I continue?" prompts waste time. If there's a genuine decision point, present it. Otherwise, keep going.

---

## Error Recovery

When a subagent fails or gets blocked, follow a structured retry process:

### Retry Limits

Each task has a `tryCount` in `tasks.json`. The default maximum is **3 attempts**. After 3 failures on the same task:

1. **Stop retrying** — do not dispatch a 4th attempt with the same approach
2. **Assess the root cause** — re-read the task entry, the subagent's report, and the diff
3. **Change something before re-dispatching:**
   - **More context** — add missing information to the task entry or dispatch prompt
   - **Better model** — upgrade from cheap to standard, or standard to capable
   - **Smaller scope** — split the task into two or more smaller tasks
   - **Different approach** — rewrite the steps in the task entry
4. **If none of these help** — escalate to the user with a clear description of what failed and what was tried

### Failure Categories

| Failure Type | Response |
|---|---|
| Lint/type errors | Fix in same task, re-dispatch |
| Test failures | Fix in same task, re-dispatch |
| Scope violation | Reject, re-dispatch with tighter constraints |
| BLOCKED (missing context) | Provide context, re-dispatch |
| BLOCKED (architectural decision) | Escalate to user |
| Repeated failures (3+) | Assess root cause, change approach or split task |

### Task Status Transitions

```
pending → in-progress → completed (after clean review)
pending → in-progress → failed → in-progress (retry with fixes)
pending → in-progress → blocked → in-progress (after context provided)
                                            → split into smaller tasks
                                            → escalated to user
```

A task can only move to `completed` after both spec compliance and code quality reviews pass. The orchestrator updates `tasks.json` after every state change.

---

## Plan Modification

During implementation, you may need to modify the plan. Follow these rules:

### Adding Tasks

When a gap is discovered during implementation:

1. Add the new task to `tasks.json` with the next available ID and appropriate batch
2. Set its `dependencies` to any tasks it depends on
3. Update the plan file's File Structure section if the new task touches files not previously listed
4. Dispatch the new task in the next wave

### Removing Tasks

When a task becomes unnecessary:

1. Set its status to a terminal state (do not delete it — keep the record)
2. Update any tasks that depended on it
3. Record the removal in the progress log

### Changing Task Dependencies

When dependencies change mid-flight:

1. Update `dependencies` in the affected task entries
2. If a task was in a later batch but now depends on a task in the same batch, move it to the next batch
3. Do not change batch assignments of tasks that are already `in-progress` or `completed`

### When the Spec Changes

If the user requests a spec change during implementation:

1. **Pause dispatching** — do not start new tasks that may be affected
2. **Assess impact** — which tasks are affected? Which are already complete?
3. **Update the spec** — incorporate the change and re-approve with the user
4. **Update the plan and `tasks.json`** — modify affected tasks, add new tasks if needed
5. **Re-review completed tasks** — if a spec change affects already-completed work, flag it for re-review
6. **Resume dispatching** — continue from where you left off

---

## Red Flags

**Never:**

- Skip task review, or accept a report missing either verdict (spec compliance AND code quality are both required)
- Proceed with unfixed Critical/Important issues
- Dispatch multiple implementation subagents in parallel without file isolation
- Make a subagent read the whole plan file (hand it its task entry from tasks.json instead)
- Skip scene-setting context (subagent needs to understand where its task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance
- Dispatch a task reviewer without a diff file
- Move to the next task while the review has open Critical/Important issues
- Re-dispatch a task the progress ledger already marks complete
- Start implementation on main/master without explicit user consent
- Tell a reviewer what not to flag (the reviewer's job is independent assessment)

**If a subagent asks questions:** Answer clearly. Provide context. Don't rush them.

**If a reviewer finds issues:** Dispatch a fix subagent. Re-review. Don't skip the loop.

**If a subagent is BLOCKED:** Change something before re-dispatching — more context, a better model, or a smaller task scope.

---

## Integration with Other Skills

| Skill              | When to use                                                            |
| ------------------ | ---------------------------------------------------------------------- |
| **brainstorming**  | Before this skill — refine the idea into a spec first                  |
| **commit-changes** | After this skill — commit the final changes                            |
| **plan-with-subagents** | This skill itself — use for any implementation plan that delegates work to subagents |

---

## Sources

Key patterns in this skill were consolidated from:

| Source                                                | Key Contribution                                                                                                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| obra/superpowers `writing-plans`                      | Plan structure, task sizing, no-placeholders rule, self-review checklist, file structure, global constraints, interfaces block |
| obra/superpowers `subagent-driven-development`        | Fresh subagent per task, two-stage review, status signals, progress ledger, model selection, never start on main/master        |
| obra/superpowers `dispatching-parallel-agents`        | When/how to dispatch parallel subagents, independence criteria, common dispatch mistakes                                       |
| obra/superpowers `executing-plans`                    | Sequential execution with checkpoints, when to stop and ask for help                                                           |
| juliusbrussee/caveman (cavecrew)                      | Compressed output format per subagent role, ~60% context reduction per delegation                                              |
| obra/superpowers `implementer-prompt`                 | Template for implementer dispatch: before-you-begin, code organization, escalation, self-review                                |
| obra/superpowers `task-reviewer-prompt`               | Template for reviewer dispatch: do-not-trust-report, scope-limited, calibrated severity, output format                         |
| nibzard/awesome-agentic-patterns `sub-agent-spawning` | Three scales of spawning, practical 2-4 limit, trade-offs of parallelism                                                       |
| kaicianflone/parallel-orchestrate                     | Wave-based execution, pre-flight checks, scope violation detection, checkpoint recovery                                       |
