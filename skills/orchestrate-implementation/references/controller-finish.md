# Final Review and Finish

Load this reference after all plan tasks have final task-review results.

## Whole-Branch Review

Create one package with `scripts/review-package PLAN_FILE MERGE_BASE HEAD`,
where `MERGE_BASE` is the branch's starting commit. Dispatch the reviewer using
the most capable approved model, the local guidance in
`requesting-code-review.md`, and the template in `code-reviewer.md`. Point the
reviewer to deferred-minor and parked ledger findings for triage.

If findings remain, dispatch one fixer with the complete list, then run exactly
one scoped re-review of that fix range using `re-review-prompt.md`. Adjudicate
residuals using the task-loop outcomes: park with a reason or rule on
load-bearing findings and record the decision. Do not start another final-fix
wave.

## Ledger and Cleanup

Before deleting any artifacts, collect every `Ruling:` entry from the ledger
and include them in the final response in order, each with its reason and cost
if wrong. Verify that every parallel task commit has a recorded integration
commit. Remove only this plan's task worktrees/branches and workspace; preserve
sibling plans and host-managed worktrees.

Follow `finishing-a-development-branch.md` for the final test run and branch
choice. Confirm the base branch before merge. Present its applicable options
and wait for the user's choice. Discard only after an explicit request and the
exact typed confirmation `discard`. Never force-remove a worktree with
uncommitted files; show the files and ask how to proceed.
