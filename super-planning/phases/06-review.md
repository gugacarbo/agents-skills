# Phase 6: Review Gates

Two-stage review after each task (or after all tasks in parallel mode).

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

1. The task entry from `tasks.json` (same one the implementer used)
2. The implementer's report file from `docs/tasks/{plan}/{task-id}/report.md`
3. The review package from `docs/tasks/{plan}/{task-id}/review-package.diff.md`

**Do NOT** give the reviewer:

- Open-ended directives like "check all uses"
- Instructions to ignore or not flag specific issues
- The entire plan file (only their task's entry from `tasks.json`)

**Do NOT** skip review. Both spec compliance AND code quality are required. Self-review by the implementer does not replace an independent review.

## Reviewer Guidance

When dispatching a reviewer, include the expectations from [`prompts/reviewer-guidance.md`](../prompts/reviewer-guidance.md). Key principles:

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
| **Minor**     | Nice to have               | Record in progress ledger, point final review at the list |

For the final whole-branch review, dispatch ONE fix subagent with ALL findings — not one fixer per finding.
