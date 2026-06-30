---
name: plan-with-subagents
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature spec or requirements for a multi-step task, before touching code. Covers plan writing, task decomposition, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression."
---

# Plan With Subagents

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** You delegate tasks to agents with isolated context. By crafting their instructions precisely, they stay focused. They never inherit your session's context or history. This preserves your own context for coordination work and prevents context pollution between tasks.

**Core principle:** Fresh subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

## When to Use

```
Have a feature idea or requirements for a multi-step task?
├─ No → Use the brainstorming skill first, then come back
├─ Yes → Is there already an approved spec in docs/specs/?
│   ├─ Yes → Skip to Phase 1 (PLAN), reference the spec number
│   └─ No → Start at Phase 0 (SPEC), write the spec first
│       └─ After spec approval → Phase 1 (PLAN)
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
Phase 0: SPEC          Write the feature spec, get user approval
Phase 1: PLAN          Write the implementation plan (same numbering as spec)
Phase 2: DECOMPOSE     Break plan into atomic tasks with briefs
Phase 3: DISPATCH      Send subagents (sequential or parallel)
Phase 4: REVIEW        Spec compliance + code quality gates
Phase 5: INTEGRATE     Merge results, final review, finish
```

---

## Phase 0: Write the Spec

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
2. **Ask the user** for approval using the question/ask tool. Use the prompt template at `templates/pre-write-approval.md`

3. **If approved:** Write the spec file
4. **If changes requested:** Incorporate the feedback and present the summary again

### Post-Write Approval Gate

After writing the spec file, ask the user to review it before proceeding to planning. Use the prompt template at `templates/post-write-approval.md`

Do NOT proceed to Phase 1 (planning) until the spec is approved. If changes are requested, update the spec and ask again.

---

## Phase 1: Write the Plan

**Announce:** "I'm using the plan-with-subagents skill to create and execute this implementation plan."

**Save plans to:** `docs/plans/NNNN-<feature-name>.md` (same number as the spec)

### Plan Structure

Every plan MUST start with the header defined in `templates/plan-header-template.md`.

### Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh subagent. Rules:

- Fold setup, scaffolding, and docs into the task whose deliverable needs them
- Split only where a reviewer could meaningfully reject one task while approving its neighbor
- Each task ends with an independently testable deliverable
- Target 2-5 minutes of subagent work per task
- Each step within a task is ONE action (write test, run test, implement, verify, commit)

### Task Structure

Each task in the plan follows the template at `templates/task-template.md`.

### No Placeholders

These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" (without the actual code)
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the subagent may read tasks out of order)
- Steps that describe what to do without showing how

### Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

### Self-Review

After writing the complete plan, check it yourself:

1. **Spec coverage:** Can you point to a task for every requirement?
2. **Placeholder scan:** Any TBD/TODO patterns? Fix them.
3. **Type consistency:** Do signatures in later tasks match what earlier tasks define?
4. **Dependency order:** Can tasks in the same wave run without file conflicts?

---

## Phase 2: Decompose into Tasks

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

Format: see `templates/progress-ledger-template.md`

After context compaction, trust the ledger and `git log` over your own recollection. Never re-dispatch a task the ledger marks complete.

---

## Phase 3: Dispatch Subagents

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

## Phase 4: Review Gates

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

### Handling Review Findings

| Severity      | Meaning                    | Action                                                    |
| ------------- | -------------------------- | --------------------------------------------------------- |
| **Critical**  | Must fix before proceeding | Dispatch fix subagent, re-review                          |
| **Important** | Should fix, blocks merge   | Dispatch fix subagent, re-review                          |
| **Minor**     | Nice to have               | Record in progress ledger, point final review at the list |

For the final whole-branch review, dispatch ONE fix subagent with ALL findings — not one fixer per finding.

---

## Phase 5: Integrate and Finish

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

When the platform supports it, configure subagents to return compressed output:

- Structured formats over prose
- `path:line — symbol — short note` instead of paragraphs
- One-line verdicts instead of explanations
- Emoji severity markers: 🔴 Critical, 🟡 Important, 🔵 Minor

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

**If a subagent asks questions:** Answer clearly. Provide context. Don't rush them.

**If a reviewer finds issues:** Dispatch a fix subagent. Re-review. Don't skip the loop.

**If a subagent is BLOCKED:** Change something before re-dispatching — more context, a better model, or a smaller task scope.

---

## Integration with Other Skills

| Skill              | When to use                                                            |
| ------------------ | ---------------------------------------------------------------------- |
| **brainstorming**  | Before this skill — refine the idea into a spec first                  |
| **commit-changes** | After this skill — commit the final changes                            |
| **writing-plans**  | Alternative to Phase 1 — use if you prefer the superpowers plan format |

---

## References

The following references informed this skill and contain deeper details on specific patterns:

| Reference                                   | Key Contribution                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `references/writing-plans.md`               | Plan structure, task sizing, no-placeholders rule, self-review checklist                    |
| `references/subagent-driven-development.md` | Fresh subagent per task, two-stage review, status signals, progress ledger, model selection |
| `references/dispatching-parallel-agents.md` | When/how to dispatch parallel subagents, independence criteria, agent prompt structure      |
| `references/executing-plans.md`             | Sequential execution with checkpoints, when to stop and ask for help                        |
| `references/cavecrew.md`                    | Compressed output format for subagents, ~60% context reduction per delegation               |
| `references/implementer-prompt.md`          | Template for constructing implementer subagent prompts                                      |
| `references/task-reviewer-prompt.md`        | Template for constructing reviewer subagent prompts                                         |
| `references/sub-agent-spawning.md`          | Declarative subagent configuration, virtual file isolation, parallel delegation patterns    |
