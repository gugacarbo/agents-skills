---
name: orchestrate-implementation
description: Use only when the user explicitly invokes `$orchestrate-implementation` to execute a multi-task implementation plan in the current session. Do not activate automatically for ordinary implementation requests or plans.
---

# Orchestrate Implementation

Execute a plan with fresh implementer subagents. Run tasks in a parallel wave only when their writes and operational state are provably disjoint; otherwise run them sequentially. Integrate and review each task separately, then run a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Prove independence, isolate every concurrent writer, integrate deterministically, review each task, then review the whole branch.

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** After the required Implementation Configuration Gate
below is approved, do not pause to check in with your human partner between
tasks. Execute all tasks from the plan without stopping. The only reasons to
stop are the four named below, a change to the approved model configuration,
or all tasks complete. "Should I continue?" prompts and progress summaries
waste their time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects, a cap you would have asked to exceed — decide
them. The spec is the binding authority, the plan is its argument, and your
judgment settles what neither answers. Record every decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For those,
stop and ask.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Task boundaries executable?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "orchestrate-implementation" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Task boundaries executable?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Task boundaries executable?" -> "Stay in this session?" [label="yes"];
    "Task boundaries executable?" -> "Manual execution or brainstorm first" [label="no"];
    "Stay in this session?" -> "orchestrate-implementation" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - separate session"];
}
```

**vs. Executing Plans (separate session):**

- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Review after each task (spec compliance + code quality), broad review at the end
- Faster iteration (no human-in-loop between tasks)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Select next sequential task or parallel-safe wave" [shape=box];
        "Dispatch implementer(s) (./implementer-prompt.md)" [shape=box];
        "Integrate one completed task in plan order" [shape=box];
        "Implementer asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer implements, tests, commits, self-reviews" [shape=box];
        "Generate review package, dispatch task reviewer (./task-reviewer-prompt.md)" [shape=box];
        "Spec ✅ and quality approved?" [shape=diamond];
        "Finding conflicts with plan text?" [shape=diamond];
        "Rule on the conflict, ledger the ruling" [shape=box];
        "Fix round R of 5: R≤3 resume implementer; R≥4 fresh implementer, more capable model" [shape=box];
        "Dispatch scoped re-review (./re-review-prompt.md)" [shape=box];
        "All findings addressed?" [shape=diamond];
        "R = 5?" [shape=diamond];
        "Adjudicate each open finding" [shape=box];
        "Any load-bearing finding?" [shape=diamond];
        "Rule and continue; stop only if every path forward is a guess" [shape=box];
        "Park findings in ledger with rulings" [shape=box];
        "Append completion to ledger, mark todo complete" [shape=box];
    }

    "Setup: worktree, ledger check, read plan, pre-flight review" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer (references/code-reviewer.md)" [shape=box];
    "Final findings? ONE fix dispatch, one scoped re-review, adjudicate residuals" [shape=box];
    "Final review clean: delete this plan's workspace" [shape=box];
    "Follow local branch-finishing guidance (references/finishing-a-development-branch.md)" [shape=box style=filled fillcolor=lightgreen];

    "Setup: worktree, ledger check, read plan, pre-flight review" -> "Select next sequential task or parallel-safe wave";
    "Select next sequential task or parallel-safe wave" -> "Dispatch implementer(s) (./implementer-prompt.md)";
    "Dispatch implementer(s) (./implementer-prompt.md)" -> "Implementer asks questions?";
    "Implementer asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Implementer implements, tests, commits, self-reviews";
    "Implementer asks questions?" -> "Implementer implements, tests, commits, self-reviews" [label="no"];
    "Implementer implements, tests, commits, self-reviews" -> "Integrate one completed task in plan order";
    "Integrate one completed task in plan order" -> "Generate review package, dispatch task reviewer (./task-reviewer-prompt.md)";
    "Generate review package, dispatch task reviewer (./task-reviewer-prompt.md)" -> "Spec ✅ and quality approved?";
    "Spec ✅ and quality approved?" -> "Append completion to ledger, mark todo complete" [label="yes"];
    "Spec ✅ and quality approved?" -> "Finding conflicts with plan text?" [label="no"];
    "Finding conflicts with plan text?" -> "Rule on the conflict, ledger the ruling" [label="yes"];
    "Rule on the conflict, ledger the ruling" -> "Fix round R of 5: R≤3 resume implementer; R≥4 fresh implementer, more capable model";
    "Finding conflicts with plan text?" -> "Fix round R of 5: R≤3 resume implementer; R≥4 fresh implementer, more capable model" [label="no"];
    "Fix round R of 5: R≤3 resume implementer; R≥4 fresh implementer, more capable model" -> "Dispatch scoped re-review (./re-review-prompt.md)";
    "Dispatch scoped re-review (./re-review-prompt.md)" -> "All findings addressed?";
    "All findings addressed?" -> "Append completion to ledger, mark todo complete" [label="yes"];
    "All findings addressed?" -> "R = 5?" [label="no"];
    "R = 5?" -> "Fix round R of 5: R≤3 resume implementer; R≥4 fresh implementer, more capable model" [label="no - next round"];
    "R = 5?" -> "Adjudicate each open finding" [label="yes - breaker trips"];
    "Adjudicate each open finding" -> "Any load-bearing finding?";
    "Any load-bearing finding?" -> "Rule and continue; stop only if every path forward is a guess" [label="yes"];
    "Any load-bearing finding?" -> "Park findings in ledger with rulings" [label="no"];
    "Park findings in ledger with rulings" -> "Append completion to ledger, mark todo complete";
    "Append completion to ledger, mark todo complete" -> "More tasks remain?";
    "More tasks remain?" -> "Select next sequential task or parallel-safe wave" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer (references/code-reviewer.md)" [label="no"];
    "Dispatch final code reviewer (references/code-reviewer.md)" -> "Final findings? ONE fix dispatch, one scoped re-review, adjudicate residuals";
    "Final findings? ONE fix dispatch, one scoped re-review, adjudicate residuals" -> "Final review clean: delete this plan's workspace";
    "Final review clean: delete this plan's workspace" -> "Follow local branch-finishing guidance (references/finishing-a-development-branch.md)";
}
```

## Setup

Ensure the controller works from an isolated **integration worktree**: use the
`using-git-worktrees` skill to create one or verify the existing one.
Never start implementation on a main/master branch without your human
partner's explicit consent.

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences — the single most expensive failure observed. Track progress in
a ledger file, not only in todos.

- Each plan owns a workspace: at skill start, run this skill's
  `scripts/plan-workspace PLAN_FILE` — it prints the plan's git-ignored
  directory (`<repo-root>/.orchestrate-implementation/<plan-basename>/`), home to
  every artifact for THIS plan: ledger, briefs, reports, review packages.
  Another plan's directory is never yours to read or write.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first
  line names your plan file, tasks with a `Task <N>: complete` line are DONE
  — do not re-dispatch them; resume at the first task without one. A task
  whose last line is a fix round is mid-loop: resume the loop at the next
  round. A ledger whose first line names a different plan file — or a stray
  ledger at a legacy shared path — is another
  plan's progress: leave it in place and start your own, fresh.
- Create the ledger with its identity as the first line:
  `# Implementation ledger — plan: <plan file path>`.
- The ledger is your recovery map: the commits it names exist in git even
  when your context no longer remembers creating them. After compaction,
  trust the ledger and `git log` over your own recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if
  that happens, recover from `git log`.

## Implementation Configuration Gate

After completing the plan reading, preflight scan, and model selection below —
but before dispatching an implementer, reviewer, or fixer, and therefore
before any task implementation starts — prepare the complete implementation
configuration, write it to the ledger, show it to the human partner, and wait
for explicit approval. This is a configuration approval, not a progress
check-in. Do not dispatch implementation work until it is approved.

The confirmation must contain every decision needed to audit the planned work:

- plan path, reachable spec (or its absence), Global Constraints, integration
  worktree and branch, MERGE_BASE, and the plan's validation commands;
- every task/batch in plan order: name, dependencies, expected write set,
  shared interfaces/resources, proposed sequential task or parallel wave, and
  the evidence for that classification;
- the selected explicit model for each task's implementer, task reviewer, and
  scoped re-reviewer, with a short rationale; the named model for fix rounds
  1-3; and the named, higher-tier replacement model for rounds 4-5;
- the explicit models for the final whole-branch reviewer, its one final-fix
  implementer, and its scoped re-reviewer;
- the variables section recorded in the ledger, including paths or commit SHAs
  already known and `pending` for values that are allocated only at dispatch or
  integration time.

Ask for approval of this configuration in one concise message. A reply that
approves it authorizes dispatches using exactly the recorded models. If a
BLOCKED result, model availability, or new task classification requires a
different model, update the ledger with the reason and obtain explicit approval
of the changed model configuration before dispatching that agent. The
pre-approved round 4-5 replacement model does not need another approval when
the normal escalation rule selects it.

Create this section immediately after the ledger identity with `Status:
drafting`; populate it after the preflight and model selection, then present
it for approval:

```markdown
## Implementation configuration

### Approval

- Status: drafting | pending approval | approved
- Approved at: <timestamp or pending>
- Approved configuration revision: <integer>

### Scope and validation

- PLAN_FILE: <absolute path>
- SPEC_FILE: <absolute path | none reachable>
- GLOBAL_CONSTRAINTS: <verbatim constraints or none>
- INTEGRATION_WORKTREE: <absolute path>
- INTEGRATION_BRANCH: <branch>
- MERGE_BASE: <SHA | pending>
- VALIDATION_COMMANDS: <commands from plan/repo>

### Planned execution and models

| Unit | Dependencies / write-set evidence | Mode | Role | MODEL | Why |
| --- | --- | --- | --- | --- | --- |
| Task <N> | <summary> | sequential / wave <W> | implementer | <explicit model> | <rationale> |
| Task <N> | <summary> | sequential / wave <W> | task reviewer | <explicit model> | <rationale> |
| Task <N> | <summary> | sequential / wave <W> | re-reviewer and fix rounds 1-3 | <explicit model> | <rationale> |
| Task <N> | <summary> | sequential / wave <W> | fix rounds 4-5 | <explicit higher-tier model> | escalation |
| Final branch | <whole branch> | sequential | reviewer / final fixer / re-reviewer | <explicit models> | <rationale> |

### Variables

| Scope | Variable | Value |
| --- | --- | --- |
| plan | PLAN_FILE | <absolute path> |
| plan | WORKSPACE | <absolute path> |
| plan | N | <task number / pending> |
| integration | MERGE_BASE | <SHA / pending> |
| task | MODEL | <role-specific approved model> |
| task | BRIEF_FILE | <absolute path / pending> |
| task | REPORT_FILE | <absolute path / pending> |
| task | WORKTREE | <absolute path / pending> |
| task | TASK_BRANCH | <branch / pending> |
| task | WRITE_SET | <paths / pending> |
| task | GLOBAL_CONSTRAINTS | <verbatim constraints / none> |
| task | BASE_SHA | <SHA / pending> |
| wave | WAVE_BASE | <SHA / pending> |
| integration | INTEGRATION_BASE | <SHA / pending> |
| review | HEAD_SHA | <SHA / pending> |
| fix | FIX_BASE_SHA | <SHA / pending> |
| fix | FINDINGS | <verbatim findings / pending> |
| review | DIFF_FILE | <absolute path / pending> |
| fix | R | <round number / pending> |
```

Keep this section complete throughout the run: append the resolved value and
its relevant scope whenever a pending variable is allocated, a model is
dispatched, a commit boundary changes, or findings are opened. Never replace
the approved configuration silently; record revisions so recovery after
compaction can reconstruct both the chosen models and every dispatch boundary.

Read the plan once, note its context and Global Constraints, and create a
todo per task. If the plan names a Spec, read that too: the spec is the
authority the plan argues from, and conflicts inside the plan resolve
against it. A plan with no reachable spec gets a ledger note saying so —
rulings made without one are provisional.

Before dispatching Task 1, scan the plan once for conflicts and parallel-safe
waves, writing down what you checked as you check it:

- task dependencies and tasks that contradict each other or the plan's Global Constraints
- each task's complete expected write set, including generated files, lockfiles,
  snapshots, manifests, migrations, and formatter side effects
- shared interfaces or mutable resources even when source-file writes differ
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

The scan's output is a table, not a verdict. Give every task a row with its
dependencies, expected write set, shared interfaces/resources, proposed wave,
and the evidence for parallel or sequential execution. Add one row for every
pair that shares a file or interface: what one produces against what the other
consumes, and what you found. Also record whether each task's own text agrees
with itself — the tests it specifies against the code it specifies, the files
it creates against the files it later touches. "The scan is clean" without
those rows is not a scan you ran.

Write the table to the ledger. Rule on everything you find before execution
begins — each finding against the plan text that mandates it — and record
each ruling in the ledger. If the scan is clean, proceed without comment.
Rule on each conflict it surfaces — the spec is the binding authority, the
plan is its argument — record the ruling beside its row, and dispatch
Task 1. The review loop remains the net for conflicts that only emerge from
implementation.

Classify parallelism conservatively. Different named source files are not
enough: generated outputs, shared contracts, lockfiles, schemas, migrations,
ports, databases, and the Git checkout are shared state. Uncertain write scope
means sequential execution. For the complete eligibility test, isolated
worktree protocol, deterministic integration order, and fallback behavior,
read [parallel-waves.md](references/parallel-waves.md) before dispatching any
parallel implementation wave.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture and design tasks**: use the most capable available model.
The final whole-branch review is one of these — dispatch it on the most
capable available model, not the session default.

**Review tasks**: choose the model with the same judgment, scaled to the
diff's size, complexity, and risk. A small mechanical diff does not need the
most capable model; a subtle concurrency change does. Scoped re-reviews of
small fix diffs take a cheap-to-mid tier.

**Fix-loop escalation (rounds 4-5)**: use a model at least one tier above
the implementer that got stuck.

**Always specify the model explicitly when dispatching a subagent.** An
omitted model inherits your session's model — often the most capable and
most expensive — which silently defeats this section.

Select these exact model names during preflight and include them in the
Implementation Configuration Gate. A selected model is not authorized for
dispatch until that gate is approved and recorded in the ledger.

**Turn count beats token price.** Wall-clock and context cost scale with how
many turns a subagent takes, and the cheapest models routinely take 2-3× the
turns on multi-step work — costing more overall. Use a mid-tier model as the
floor for reviewers and for implementers working from prose descriptions.
When the task's plan text contains the complete code to write, the
implementation is transcription plus testing: use the cheapest tier for
that implementer. Single-file mechanical fixes also take the cheapest tier.

**Task complexity signals (implementation tasks):**

- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## The Task Loop

### Select the execution mode

At each dependency boundary, choose one mode from observable facts recorded in
the preflight table:

- **Parallel wave:** two or more ready tasks pass every eligibility check in
  [parallel-waves.md](references/parallel-waves.md). Dispatch them together in
  separate task worktrees, never in the integration worktree.
- **Sequential task:** any dependency, overlapping or uncertain write set,
  shared interface/resource, or lack of isolated task worktrees. Run the next
  ready task alone in the integration worktree.

Parallelism changes dispatch timing, not quality gates. Integrate completed
parallel tasks one at a time in plan order and complete that task's review/fix
loop before integrating the next result. After the whole wave is integrated,
run the plan's integration test command. An integration-only failure belongs
to one sequential diagnosis/fix task; never fan out speculative fixers.

**Batch small same-shape work.** When the plan lists several tasks that are
each a small, independent edit of the same kind — the same one-line fix,
constant change, or field addition repeated across files — do not dispatch
one subagent per task. Compose ONE dispatch brief listing every file and
its change, send the whole batch to a single subagent, and review its diff
as one unit. Reserve one-dispatch-per-task for work that needs its own
judgment, its own tests, or its own review surface.

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files.

**Waiting on dispatched subagents:** never poll a wait interface with
short timeouts, and never sit in one silent, open-ended wait either.
While you have local work — ledger updates, packaging the next review,
reading reports — keep working; child results arrive on their own.
When you are genuinely idle, wait in bounded stretches (five to ten
minutes, where your platform allows), and between stretches post one
line of status and reconcile your live children: list them, and chase
any that finished without reporting. A bounded stretch keeps nearly
all of a long wait's efficiency while guaranteeing a stuck or lost
child is noticed within minutes, not at the end of the session.

### 1. Dispatch the implementer

For a sequential task, record BASE (`git rev-parse HEAD`) before dispatching.
For a parallel wave, record WAVE_BASE before dispatch and record a fresh
INTEGRATION_BASE immediately before integrating each task. Review and fix diffs
depend on these exact boundaries.

Before every dispatch, update the ledger's Variables table with the exact
values in scope: `N`, `MODEL`, `BRIEF_FILE`, `REPORT_FILE`, `WORKTREE`,
`TASK_BRANCH`, `WRITE_SET`, `GLOBAL_CONSTRAINTS`, and `BASE_SHA` or
`WAVE_BASE`. When integrating or reviewing, append the resolved
`INTEGRATION_BASE`, `HEAD_SHA`, `FIX_BASE_SHA`, `FINDINGS`, `DIFF_FILE`, and
`R`. The ledger must contain the value actually used, not only the planned
placeholder, before the corresponding agent is dispatched.

- **Task brief:** before dispatching an implementer, run this skill's
  `scripts/task-brief PLAN_FILE N` — it extracts the task's full text to a
  uniquely named file and prints the path. Compose the dispatch so the
  brief stays the single source of
  requirements. Your dispatch should contain: (1) one line on where this
  task fits in the project; (2) the brief path, introduced as "read this
  first — it is your requirements, with the exact values to use verbatim";
  (3) interfaces and decisions from earlier tasks that the brief cannot
  know; (4) your resolution of any ambiguity you noticed in the brief;
  (5) the report-file path and report contract. Exact values (numbers,
  magic strings, signatures, test cases) appear only in the brief. Never
  make a subagent read the whole plan file.
- **Report file:** name the implementer's report file after the brief
  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
  the dispatch prompt. The implementer writes the full report there and
  returns only status, commits, a one-line test summary, and concerns.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches — a real session's dispatch hit 42k chars of which 99%
  was pasted history. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- The dispatch carries the no-subagents contract (it is in the
  implementer template): the implementer never dispatches subagents —
  not helpers, and never a reviewer. Review arrives from you, after the
  report. In real sessions, every reviewer a worker spawned duplicated
  the task review the controller dispatched anyway — a full extra
  review seat per task.
- If an earlier task parked a finding in the area this task touches, carry
  a pointer to that ledger entry in the dispatch.
- Record the implementer's agent identity from the dispatch result —
  fix-loop rounds 1-3 resume this agent.
- In a parallel wave, also pass the task's isolated worktree, task branch, and
  approved write set. Dispatch every implementer in the wave before waiting.
- A task that discovers it must write outside its approved set stops and
  reports `NEEDS_CONTEXT`; do not let it silently invalidate the independence
  proof.

Template: [implementer-prompt.md](implementer-prompt.md)

### 2. Handle the report

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** For a sequential task already running on the integration branch,
generate the review package directly. For a parallel task, first verify and
integrate its task-branch commits using
[parallel-waves.md](references/parallel-waves.md). Then run
`scripts/review-package PLAN_FILE INTEGRATION_BASE HEAD` from this skill's
directory — it prints the unique file path it wrote; INTEGRATION_BASE is the
integration-branch head immediately before this task was integrated, never
`HEAD~1`, which silently drops all but the last commit of a multi-commit task.
Dispatch the task reviewer with the printed path.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:

1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, rule on the correction, ledger it, and re-dispatch with the ruling carried in the dispatch

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

If the implementer asks questions — before starting or mid-task — answer
clearly and completely, provide additional context if needed, and don't
rush it into implementation.

### 3. Review the task

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. Never skip the task review, and never accept a
report missing either verdict — spec compliance AND task quality are both
required. Implementer self-review never replaces the task review; both are
needed.

- Hand the reviewer its diff as a file: run this skill's
  `scripts/review-package PLAN_FILE BASE HEAD` and pass the reviewer the file path
  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
  and `git diff -U10` for the range, redirected to one uniquely named
  file). The output never enters your own context, and the reviewer sees
  the commit list, stat summary, and full diff with context in one Read
  call. For a sequential task, use the BASE recorded before dispatch. For a
  parallel task, use the integration head recorded immediately before that
  task's commits were cherry-picked. Never use `HEAD~1`, which silently
  truncates multi-commit tasks. Never dispatch a task reviewer without a diff
  file.
- **Reviewer inputs:** the task reviewer gets three paths — the same brief
  file, the report file, and the review package — plus the global
  constraints that bind the task.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the plan's Global
  Constraints section or the spec: exact values, exact formats, and the
  stated relationships between components ("same layout as X", "matches
  Y"). The reviewer's template already carries the process rules (YAGNI,
  test hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.

The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
that live in unchanged code or span tasks. These do not block the rest of the
review, but you must resolve each one yourself before marking the task
complete: you hold the plan and cross-task context the reviewer
lacks. If you confirm an item is a real gap, treat it as a failed spec
review — it enters the fix loop with the other findings.

When a reviewer finding is technically unclear or appears contestable, use the
`receiving-code-review` skill to evaluate it. This never authorizes silently
dismissing a finding or bypassing the fix loop.

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. The fix loop

The loop triggers when the review reports spec ❌, any Critical or Important
finding, or a ⚠️ item you confirmed as a real gap.

Before the loop starts, two routes leave it immediately:

- Record Minor findings in the progress ledger as you go
  (`Task <N>: minor (deferred): <one-liner>`), and point the final
  whole-branch review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard. Minor findings
  never enter the loop.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is yours to rule on: weigh the finding
  against the plan text, decide with the spec as the binding authority, and
  ledger the ruling before you act on it. Do not dismiss the finding because
  the plan mandates it, and do not dispatch a fix that contradicts the plan
  without a recorded ruling.

Everything else enters the loop. A fix round is one fix dispatch plus one
scoped re-review. Five rounds maximum per task:

**Rounds 1-3 — resume the original implementer.** Send it the open findings
verbatim. Its context is intact: it knows the task, the code, and its own
choices. If your harness cannot send another message to a live subagent,
dispatch a fresh implementer carrying the brief path, the report-file path,
and the findings — the report file is the persistent memory either way.

**Rounds 4-5 — dispatch a fresh implementer on a more capable model** (per
Model Selection), with the brief path, the report-file path, the open
findings, and this framing: "A prior implementer attempted this task
[N] times; you own it now. Read the report file for what was tried." A loop
that survives three resumes usually means the implementer cannot see its
own problem — fresh eyes and a capability bump in one move.

**Every round, either way:** the implementer fixes, re-runs the tests
covering the amended code, appends its fix report to the same report file,
and returns the short contract. Before re-dispatching the reviewer, confirm
the fix report contains the covering tests, the command run, and the
output; dispatch the re-review once all three are present. Name the
covering test files in the fix message — a one-line fix does not need the
whole suite.

For a task from a parallel wave, the implementer makes the fix in its task
worktree. Verify and integrate the new commits before creating the fix review
package. If a fix touches a pending task's write set, that pending result is
stale: do not integrate it; re-run it sequentially from the new integration
head and record the reclassification in the ledger.

**The re-review is scoped.** Run `scripts/review-package PLAN_FILE FIX_BASE HEAD`
where FIX_BASE is the head the previous review saw, and dispatch
[re-review-prompt.md](re-review-prompt.md) with the findings list, the
brief, the report file, and the printed diff path. The re-reviewer verdicts
each finding ADDRESSED or NOT ADDRESSED and flags new breakage in the fix
diff only. New Critical/Important breakage in the fix diff joins the open
findings list. Out-of-scope observations go to the ledger as deferred
minors — they never extend the loop.

**After each round,** append to the ledger:
`Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`

Never fix findings yourself in the controller session — your context stays
clean for coordination, and controller fixes skip review.

**The breaker.** When round 5's re-review still leaves findings open, stop
dispatching. Adjudicate each open finding yourself — you hold the plan and
the cross-task context the reviewer lacks:

- **The reviewer is wrong, or the point is contestable:** park it —
  `Task <N>: parked — <finding> — Ruling: <why the code stands>`. The final
  review sees both sides.
- **Real, but nothing downstream builds on it:** park it the same way, with
  a ruling that says it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a
  plan defect: rule on the smallest change that unblocks the dependent work,
  ledger it as `Task <N>: Ruling: <finding> — <what you decided and why>`,
  and carry it into the next task's dispatch. Parking a structural failure
  silently lets every dependent task build on it. Stop only when the defect
  leaves every path forward a guess.

Adjudicate only at the cap. Adjudicating earlier to end a loop is
pre-judging with a different name. Every adjudication is a ledger entry —
a silent discard is forbidden.

### 5. Complete the task

When the review comes back clean — or every open finding is parked with a
ruling at the cap — append the completion line to the ledger in the same
message as your other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked)` after a
  tripped breaker

Then mark the todo complete and move on. Never move to the next task while
the review has open Critical/Important issues that are neither fixed nor
parked-with-ruling at the cap.

For a parallel task, remove its task worktree and branch only after every source
commit has a recorded cherry-picked integration commit, the approved paths
match, and its review is complete. Preserve the worktree while its fix loop may
still resume the original implementer.

## Final Review

The final whole-branch review gets a package too: run
`scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = the commit the
branch started from, e.g. `git merge-base main HEAD`) and include the
printed path in the final review dispatch, so the final reviewer reads
one file instead of re-deriving the branch diff with git commands. Dispatch
on the most capable available model (see Model Selection), following the local
[code-review guidance](references/requesting-code-review.md) and its
[reviewer template](references/code-reviewer.md). Point
it at the ledger's deferred-minor and parked lines so it can triage which must
be fixed before merge.

If the final whole-branch review returns findings, dispatch ONE fix subagent
with the complete findings list — not one fixer per finding.
Per-finding fixers each rebuild context and re-run suites; a real
session's final-review fix wave cost more than all its tasks combined.
Then run exactly one scoped re-review of the fix wave
(`scripts/review-package PLAN_FILE FIX_BASE HEAD` over the fix range,
[re-review-prompt.md](re-review-prompt.md)).
Adjudicate any residual findings as in the task loop's breaker: park with
rulings, or rule on the load-bearing ones and ledger what you decided. Only
the four classes above stop you here. There is no second fix wave —
residual load-bearing findings surface to your human partner when
finishing-a-development-branch presents the options.

## Finish

Before you delete anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list is the only place the decisions you
took on your human partner's behalf reach them — they read it and rework
whatever you got wrong. A ruling that dies with the workspace was a decision
made in secret.

When the final whole-branch review is clean and its fixes are merged, verify no
task worktree contains an unmapped or unintegrated commit, remove this plan's
task worktrees, then delete this plan's workspace (`rm -rf <workspace>`) — the
git history is the record now. Sibling directories belong to other plans;
leave them alone.

Follow the local
[branch-finishing guidance](references/finishing-a-development-branch.md).

## Common Rationalizations

| Excuse                                                            | Reality                                                                                                                                                                       |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Close enough on spec compliance"                                 | Reviewer found spec gaps = not done. Fix or hit the cap and adjudicate — those are the only exits.                                                                            |
| "I'll fix it myself, dispatching is overhead"                     | Controller fixes pollute your context and skip review. Resume the implementer.                                                                                                |
| "One more round will converge"                                    | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route.                                                                                        |
| "The reviewer will just find something new anyway"                | Scoped re-reviews verify fixes; they cannot wander. New findings on untouched code go to the ledger, not the loop.                                                            |
| "This finding is obviously wrong, I'll drop it"                   | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden.                                                                            |
| "The fix was small, skip the re-review"                           | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review.                                                                                          |
| "Reviews slow the loop down"                                      | The loop without reviews is just unverified churn. Reviews are the loop's brakes and steering.                                                                                |
| "Ledger bookkeeping is overhead"                                  | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed task sequences.                                                           |
| "The implementer spawned its own reviewer — free extra assurance" | It's a duplicate seat reviewing the same diff; the task review is the gate. A worker-spawned reviewer is a defect to flag, not rigor.                                         |
| "The tasks name different files, so they are safe to parallelize" | Named source files omit generated outputs, lockfiles, shared interfaces, runtime resources, and Git state. Prove the complete write and state sets, then isolate each writer. |
| "The cherry-pick conflict is small; resolve it and keep the wave" | A conflict disproves the independence classification. Abort that integration and re-run the affected task sequentially from the current integration head.                     |

## Example Workflow

```
You: I'm using orchestrate-implementation to execute this plan.

[Setup: worktree verified]
[Read plan file once: docs/plans/feature-plan.md]
[Resolve workspace: scripts/plan-workspace docs/plans/feature-plan.md — no ledger inside, fresh start]
[Create todos for all tasks]

Task 1: Hook installation script (sequential example; no parallel-safe wave)

[Run task-brief for Task 1; dispatch implementer with brief + report paths + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/agent-hooks/)"

Implementer: [Later]
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[Run review-package PLAN_FILE BASE HEAD; dispatch task reviewer with the printed path]
Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.

[Ledger: Task 1: complete (commits a1b2c3d..d4e5f6a, review clean)]

Task 2: Recovery modes

[Run task-brief for Task 2; dispatch implementer with brief + report paths + context]

Implementer: [No questions]
  - Added verify/repair modes
  - 8/8 tests passing
  - Committed

[Run review-package PLAN_FILE BASE HEAD; dispatch task reviewer with the printed path]
Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  Issues (Important): Magic number (100)

[Fix round 1: resume the implementer with both findings]
Implementer: Added progress reporting, extracted PROGRESS_INTERVAL constant.
  Re-ran test/recovery.test.js — 10/10 passing. Fix report appended.

[Run review-package PLAN_FILE FIX_BASE HEAD; dispatch scoped re-review]
Re-reviewer: Missing progress reporting — ADDRESSED (src/recovery.js:41).
  Magic number — ADDRESSED (src/recovery.js:7). New breakage: none.
  Verdict: all findings addressed.

[Ledger: Task 2: fix round 1/5 (2 addressed, 0 open; commits d4e5f6a..b7c8d9e)]
[Ledger: Task 2: complete (commits d4e5f6a..b7c8d9e, review clean)]

...

[After all tasks]
[Run review-package PLAN_FILE MERGE_BASE HEAD; dispatch final code-reviewer, most capable model]
Final reviewer: All requirements met. Deferred minors triaged: none block merge.

[Delete this plan's workspace — the record now lives in git]

Done! Follow the local branch-finishing guidance.
```
