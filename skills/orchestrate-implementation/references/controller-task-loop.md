# Task Execution and Review

Load this reference after the configuration gate is approved. For the exact
parallel isolation and integration protocol, also load `parallel-waves.md`
before dispatching a parallel wave.

## Select Tasks

Run ready tasks sequentially by default. Batch small same-shape edits into one
brief and one implementation/review unit, while keeping one ledger status row
per original plan task. Tasks needing separate judgment, tests, or review
surfaces stay separate.

Immediately before a proposed wave, inspect only its ready tasks. Establish
complete write sets, generated outputs, shared interfaces and mutable
resources, testing side effects, and Git isolation; record the evidence in the
ledger. Do not estimate these indirect writes during the pre-gate plan review.
If any candidate's scope or shared state is uncertain, run it sequentially.
Parallel dispatch timing never changes task review gates or validation.

## Dispatch an Implementer

Use [`implementer-prompt.md`](../implementer-prompt.md) as the dispatch
template. Fill its placeholders from the approved configuration, task brief,
ledger dispatch row, and relevant project context.

For a sequential task, record its base commit. For a wave, record `WAVE_BASE`
and verify each task worktree and branch start there. Before dispatch, append a
ledger dispatch row with the exact model, task number, absolute brief/report
paths, worktree/branch, approved write set (or `not restricted`), and base
commit. Stable plan values and role model defaults stay in the approved
configuration; record only exceptions here.

Run `scripts/task-brief PLAN_FILE N`. The brief is the source of requirements;
do not make the implementer read the whole plan. Name the report after the
brief, for example `task-2-brief.md` and `task-2-report.md`. The dispatch gives
the task's project context, brief path, relevant earlier interfaces/decisions,
any resolution of ambiguity, and report path/contract. Do not paste session
history.

The implementer works alone, asks about unclear requirements, follows existing
patterns, writes tests (TDD when required), runs focused checks and requested
validations, runs the full suite before committing, commits only on its task
branch, self-reviews, and writes a detailed report. It never dispatches helper
or reviewer agents. For a wave it cannot write outside the approved set except
its report; unexpected writes require `NEEDS_CONTEXT`.

Implementers return one status: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`,
or `BLOCKED`. Handle them as follows:

- `DONE`: verify/integrate a wave result in plan order, then generate a review
  package with `scripts/review-package PLAN_FILE BASE HEAD` and dispatch the
  reviewer. Use the exact integration base before the task, never `HEAD~1` for
  a multi-commit task.
- `DONE_WITH_CONCERNS`: resolve correctness or scope concerns before review;
  record observations and proceed.
- `NEEDS_CONTEXT`: provide missing context and dispatch again with the
  approved model.
- `BLOCKED`: change what caused the block: add context, escalate the model,
  divide the task, or rule on a plan correction. Do not repeat the same attempt
  without a change.

Answer implementer questions before implementation resumes. A requested test
failure is not automatically `BLOCKED`: record its command and full output,
diagnose and fix it where viable, then rerun the covering validation.

## Review Each Task

Use [`task-reviewer-prompt.md`](../task-reviewer-prompt.md) for the task-scoped
review dispatch. Fill its placeholders with the brief, report, binding
constraints, and generated diff package.

Every task or coherent batch gets a task-scoped review for both Spec compliance
and code quality. The final whole-branch review is separate. Give the reviewer
the brief, implementer report, binding Global Constraints, and one diff-package
file containing commits, stat, and full diff. The reviewer works read-only,
does not dispatch agents, verifies the report's claims, and does not rerun tests
already evidenced by the implementer.

Keep review scope concrete: inspect outside the diff only for a named risk; do
not pre-judge findings or tell the reviewer to ignore a concern. Resolve every
"cannot verify from diff" item before completing the task. If feedback is
unclear or contestable, follow `receiving-code-review/SKILL.md` before acting.

## Corrections: Two Rounds Maximum

The loop starts for failed Spec compliance, Critical/Important findings, or a
confirmed real gap. Record Minor findings for the final review. Rule on any
finding that conflicts with the plan, using the Spec as authority, and record
the ruling before changing code.

Each round is one fix dispatch plus one scoped re-review:

1. **Round 1:** resume the original implementer with the open findings
   verbatim. If it cannot be resumed, dispatch a fresh implementer with the
   brief, report, and findings using the approved model.
2. **Round 2:** dispatch a fresh implementer on the pre-approved model at least
   one tier above the original. Include the brief, report, open findings, and
   what was tried. This is the last fix round.

For either round, require the implementer to fix the findings, run tests that
cover the amended code, append the command and output to the same report, and
return the short status contract. Confirm that evidence before dispatching one
scoped re-review over `scripts/review-package PLAN_FILE FIX_BASE HEAD`.
The re-reviewer marks each finding `ADDRESSED` or `NOT ADDRESSED` and checks
new breakage in the fix diff only. New Critical/Important breakage joins the
open list. Out-of-scope observations are deferred minors.

For a wave fix, verify and integrate commits before re-review. If the fix
overlaps a pending task or changes an interface it uses, mark that result stale
and rerun it sequentially from the updated integration head.

After round 2, stop dispatching fixes and adjudicate each open finding:

- If technically wrong or contestable, park it with a reason in the ledger.
- If real but not load-bearing, park it as deferred with a reason.
- If real and load-bearing, rule on the smallest correction that unblocks
  dependent work, record the decision, and carry it into the next task.
- Stop only if the defect makes every path forward a guess.

Never fix findings in the controller session. After each round, append:
`Task <N>: fix round <R>/2 (<X> addressed, <Y> open; commits <base>..<head>)`.
Complete a task only after clean review or adjudication at the two-round cap.
Record its completion and parked count in the ledger before moving on.

## User-Facing Reporting

For ordinary task results, update the ledger without a separate progress
message. If the implementer needs context, is blocked, or a stop condition
arises, report the specific issue immediately. When a batch has no pending
implementation work and all its task reviews/fix loops have final results,
show one concise table with `Task`, `Result`, `Tests`, `Commits`, `Review`, and
`Notes`, one row per original task plus a summary row with completion totals.
A sequential single-task batch gets the same one-row summary. Do not report a
parallel wave complete while any result is unintegrated, unreviewed, or stale.

Keep dispatch prompts and agent replies short; use the brief, report, and diff
package files for detailed handoffs. While agents work, continue local ledger
and review preparation. When idle, wait in bounded stretches and reconcile
agents that completed without reporting.
