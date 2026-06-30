---
name: super-planning
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature spec or requirements for a multi-step task, before touching code. Covers plan writing, task decomposition, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression."
---

# Plan With Subagents

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** You delegate tasks to agents with isolated context. By crafting their instructions precisely, they stay focused. They never inherit your session's context or history. This preserves your own context for coordination work and prevents context pollution between tasks.

**Core principle:** Fresh subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

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
Phase 4: DECOMPOSE     Break plan into atomic tasks with briefs
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

---

## Phase 2: Write the Spec

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

If no workspace pattern is found, use the template at `templates/spec-template.md`.

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

---

## Phase 3: Write the Plan

**Announce:** "I'm using the super-planning skill to create and execute this implementation plan."

**Save plans to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec)

### Plan Structure

Every plan MUST start with the header defined in `templates/plan-template.md`. Key points:

- **Global Constraints** bind every task without repetition. Copy version floors, naming conventions, platform requirements, and dependency limits verbatim from the spec so each subagent inherits them automatically.
- **File Structure** must be mapped before defining tasks. See the template for details on decomposition and file responsibility.
- **Task Structure** follows the template in `templates/task-template.md`. The **Interfaces** block (Consumes/Produces) is critical for parallel dispatch: implementers see only their own task brief, so they learn about neighboring tasks' APIs through these declarations. Without exact signatures, parallel tasks will produce incompatible interfaces.

### Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh subagent. Rules:

- Fold setup, scaffolding, and docs into the task whose deliverable needs them
- Split only where a reviewer could meaningfully reject one task while approving its neighbor
- Each task ends with an independently testable deliverable
- Target 2-5 minutes of subagent work per task
- Each step within a task is ONE action (write test, run test, implement, verify, commit)

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

After writing the complete plan, check it yourself:

1. **Spec coverage:** Can you point to a task for every requirement?
2. **Placeholder scan:** Any TBD/TODO patterns? Fix them.
3. **Type consistency:** Do signatures in later tasks match what earlier tasks define?
4. **Dependency order:** Can tasks in the same wave run without file conflicts?

### Execution Handoff

After saving the plan, offer the user an execution choice:

1. **Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks, fast iteration
2. **Sequential** — Execute tasks one at a time with review after each

If the user chose parallel dispatch during decomposition, default to subagent-driven with parallel waves.

---

## Phase 4: Decompose into Tasks

Before dispatching any subagent, extract each task into a **brief file** and a **report file contract**:

### Task Brief

Extract the full task text (everything from `### Task N` to the end of that task) into a uniquely named file:

```
.plan/task-N-brief.md
```

The brief is the subagent's single source of requirements. It contains the exact values, code, and acceptance criteria.

### Report Contract

Name the subagent's report file after the brief:

```
.plan/task-N-report.md
```

The subagent writes their full report there and returns only: status, commits, one-line test summary, and concerns.

### Progress Ledger

Track progress in a durable file that survives context compaction:

```
.plan/progress.md
```

Format: see `prompts/progress-ledger-template.md`

After context compaction, trust the ledger and `git log` over your own recollection. Never re-dispatch a task the ledger marks complete.

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

**Turn count beats token price.** The cheapest models take 2-3× more turns on multi-step work, costing more overall. Use standard as the floor for reviewers and for implementers working from prose descriptions. Reserve the cheapest tier for implementers whose task brief contains the complete code to write.

### Constructing the Dispatch Prompt

A dispatch prompt contains exactly five things — nothing more:

1. **One line of context:** Where this task fits in the project
2. **The brief path:** "Read this first — it is your requirements"
3. **Interfaces and decisions** from earlier tasks that the brief cannot know
4. **Your resolution** of any ambiguity you noticed in the brief
5. **The report-file path** and report contract

**Do NOT:**

- Paste the entire plan into every dispatch (that's the context bloat this skill exists to prevent)
- Paste accumulated prior-task summaries into later dispatches
- Include process narration or history
- Give the subagent access to your session's context

### Sequential Dispatch

For each task:

1. Extract task brief to `.plan/task-N-brief.md`
2. Dispatch one implementer subagent with brief + report paths + scene-setting context
3. If the subagent asks questions, answer before letting it proceed
4. When the subagent returns, generate a review package and dispatch a reviewer
5. If the reviewer finds issues, dispatch a fix subagent and re-review
6. Mark the task complete in the progress ledger

### Parallel Dispatch

For independent tasks with no file conflicts:

1. Extract all task briefs at once
2. Dispatch ALL subagents in ONE message (parallel tool calls)
3. Wait for all to return
4. Review all results
5. Dispatch fix subagents for any that need fixes
6. Integrate all changes onto the working branch
7. Mark all tasks complete in the progress ledger

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
| Pasting the whole plan into dispatch             | Hand only the task brief — that's what it's for      |
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

### Pre-Flight Checks

Before dispatching any subagent, verify:

1. **Repository state:** Clean working tree, correct base branch checked out
2. **Tooling available:** Test runner, linter, and build commands are accessible and work
3. **Brief files written:** All task briefs exist at `.plan/task-N-brief.md`
4. **Progress ledger initialized:** `.plan/progress.md` exists with all tasks listed as pending

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

1. The task brief file (same one the implementer used)
2. The implementer's report file
3. The review package (diff file generated via git)

**Do NOT** give the reviewer:

- Open-ended directives like "check all uses"
- Instructions to ignore or not flag specific issues
- The entire plan file (only their task's brief)

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

- **Task brief** → file (subagent reads it, you don't carry it)
- **Report** → file (subagent writes it, you get a one-line summary)
- **Review package** → file (reviewer reads the diff from a file, you don't paste it)

### Compressed Output

When the platform supports it, configure subagents to return compressed output (~60% less context than prose). Use role-specific formats:

**Implementer output:**

```
<path:line-range> — <change in ≤10 words>.
verified: <re-read OK | mismatch @ path:line>.
```

Or one of: `too-big.` / `needs-confirm.` / `ambiguous.` / `regressed.` (terminal first token).

**Reviewer output:**

```
path:line: <emoji> <severity>: <problem>. <fix>.
totals: N🔴 N🟡 N🔵 N❓
```

Or `No issues.` Findings sorted file → line ascending. Emoji severity: 🔴 Critical, 🟡 Important, 🔵 Minor, ❓ Cannot verify.

**Investigator output:**

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

## Dependency Analysis for Parallel Mode

Before dispatching in parallel, analyze task dependencies:

1. **File conflicts:** Two tasks must not write the same file
2. **API dependencies:** Task B consumes what Task A produces → sequential
3. **Shared state:** Tasks modifying shared database tables or global config → sequential
4. **Independent modules:** Tasks touching different files with no shared interfaces → parallel

When in doubt, run sequentially. Parallel mode is an optimization, not a default.

---

## Red Flags

**Never:**

- Skip task review, or accept a report missing either verdict (spec compliance AND code quality are both required)
- Proceed with unfixed Critical/Important issues
- Dispatch multiple implementation subagents in parallel without file isolation
- Make a subagent read the whole plan file (hand it its task brief instead)
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
| **writing-plans**  | Alternative to Phase 3 — use if you prefer the superpowers plan format |

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
| kaicianflone/parallel-orchestrate                     | Wave-based execution, pre-flight checks, scope violation detection                                                             |
| `references/parallel-orchestrate.md`                  | Wave-based execution, pre-flight checks, scope violation detection, checkpoint recovery                                        |
