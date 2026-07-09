# Phase 6: Review Gates

Two-stage review according to `reviewCadence`: after each task, after each batch, or during final integration on a per-batch basis.

> **Ownership:** Review package generation is owned by Phase 6. Phase 5 may prepare the inputs (diff, worktree) but the actual packaging (creating `review-package.json`, assembling artifacts) happens here.

## Review Cadence Routing

Read `reviewCadence` from `super-plan.json` before dispatching reviewers:

- `per_task` — review each task as soon as it reaches `ready_for_review`; set status to `reviewing` when review begins
- `per_batch` — review all tasks in the batch together once the batch is `ready_for_review`; set each task to `reviewing` when review begins
- `final_only` — materialize per-task artifacts normally during implementation, but defer reviewer dispatch to Phase 7; tasks stay at `ready_for_review` until final integration

In parallel execution with `reviewCadence=per_task`, Phase 6 begins for individual tasks in the response immediately following the implementer batch return, even if sibling tasks in the same batch are still being reviewed.

## Materialize Task Artifacts Before Review

Phase 5 already materialized the task directory, logging wrapper, and empty `progress.log`. Phase 6 materializes the remaining per-task artifacts **regardless of `reviewCadence`** — even in `final_only` mode, these artifacts must exist before Phase 7 can review them:

- `docs/jobs/{NNNN-<feature-name>}/{task-id}/report.md`
- `docs/jobs/{NNNN-<feature-name>}/{task-id}/review-package.diff.md`

Use [`templates/progress-template.txt`](../templates/progress-template.txt) for the task log format. The ledger itself is a generated artifact produced by the active `render-progress-ledger.sh` helper path, not a hand-maintained template.

The ledger should already exist from Phase 4. Regenerate it through the `super-plan.json` script path after every registry update, then keep it synchronized through review, fixes, and final integration.

The task-local `log-task.sh` is now a thin wrapper generated from the shared helper resolved in Phase 5. If the skill was bootstrapped into `.super-planning/`, the orchestrator should call:

```bash
bash /absolute/path/to/workspace/.super-planning/log-task.sh materialize-task-logger \
  --plan 0003-auth-middleware \
  --task Task-A-1 \
  --output /absolute/path/to/workspace/docs/jobs/0003-auth-middleware/Task-A-1/log-task.sh
```

That wrapper must delegate back to the shared `.super-planning/log-task.sh` while prefilling the shared arguments for the plan, task, and task directory.

If the skill already exists inside the target repository, generate the wrapper from `super-planning/scripts/log-task.sh` instead and keep that path as the wrapper's root script.

## Stage 1: Spec Compliance

Does the implementation match the requirements?

- **Missing:** requirements skipped or missed
- **Extra:** features not requested (overbuilding)
- **Misunderstood:** right feature, wrong approach

If a requirement cannot be verified from the diff alone, flag it as ⚠️ and verify it yourself.

## Stage 2: Code Quality

Is it well-built?

- Clean separation of concerns?
- Proper error handling?
- DRY without premature abstraction?
- Edge cases handled?
- Tests verify real behavior (not mocks)?
- Each file has one clear responsibility?

## Reviewer Dispatch

The reviewer gets three things:

1. The task entry from `super-plan.json` (same one the implementer used)
2. The implementer's report file from `docs/jobs/{plan}/{task-id}/report.md`
3. The review package from `docs/jobs/{plan}/{task-id}/review-package.diff.md`

**Do NOT** give the reviewer:

- Open-ended directives like "check all uses"
- Instructions to ignore or not flag specific issues
- The entire plan file (only their task's entry from `super-plan.json`)

**Do NOT** skip review when the configured cadence says review is due. Both spec compliance AND code quality are required. Self-review by the implementer does not replace an independent review.

## Reviewer Guidance

When dispatching a reviewer, use the [`agents/code-reviewer.md`](../agents/code-reviewer.md) agent. Key principles:

- **Do Not Trust the Report:** Treat the implementer's report as unverified claims; verify against the diff
- **Scope-Limited:** Only review the task's changes, not the whole branch
- **Tests:** Don't re-run the suite; run a test only when reading the code raises a specific doubt
- **Calibrated Severity:** Critical = must fix before proceeding, Important = blocks merge, Minor = nice to have
- **Strengths:** Capture what's well done, not just issues
- **Every finding** needs a concrete `file:line` location, what's wrong, why it matters, and how to fix it

## Handling Review Findings

| Severity      | Meaning                    | Action                                                    |
| ------------- | -------------------------- | --------------------------------------------------------- |
| **Critical**  | Must fix before proceeding | Dispatch fix subagent, re-review                          |
| **Important** | Should fix, blocks merge   | Dispatch fix subagent, re-review                          |
| **Minor**     | Nice to have               | Record minor findings in the task's `progress.log` as an `info` event with the finding details. If the finding affects status, update the task's `status` in `super-plan.json`. |

For the final whole-branch review, dispatch ONE fix subagent with ALL findings — not one fixer per finding.

## Completion Rule

Only mark a task `completed` once its required independent review has happened and is clean for the configured `reviewCadence`. Set the task status to `reviewing` when review begins, then transition to `completed` (clean) or `needs_fix` (issues found).

- `per_task` — the task can be completed right after its own clean review
- `per_batch` — tasks in the batch can be completed after the batch review is clean
- `final_only` — tasks stay at `ready_for_review` until their batch is reviewed during final integration in Phase 7; artifacts are still materialized now so Phase 7 has them
