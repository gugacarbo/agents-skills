# Phase 7: Integrate and Finish

After implementation is done and the plan is ready for final closure.

## Pre-Flight Checks

Before starting integration, verify:

1. All tasks in `super-plan.json` have a terminal status (`completed`, `cancelled`, or `blocked` with a documented reason).
2. The feature branch is clean and all task branches have been merged.
3. The working tree has no uncommitted changes.

When these checks pass, transition the plan to `ready_for_review` through the
active helper. Immediately before the whole-branch audit, transition it to
`reviewing`. These transitions make the final `complete-plan` gate auditable:

```bash
sh "$ACTIVE_SUPER_PLAN_SCRIPT" transition-plan \
  --input docs/jobs/NNNN-<feature-name>/super-plan.json \
  --status ready_for_review

sh "$ACTIVE_SUPER_PLAN_SCRIPT" transition-plan \
  --input docs/jobs/NNNN-<feature-name>/super-plan.json \
  --status reviewing
```

## Step 1: Run the Full Test Suite

Run the project's full test suite once on the feature branch. Do not skip this step.

If tests fail, fix them before proceeding. If the failures are unrelated to this plan, document them and get user approval to proceed.

## Step 2: Run the Definition of Done from the Spec

Open the spec document (`source.spec` from `super-plan.json`) and locate its **Definition of Done** section. Verify every DoD item:

- For each item, confirm it is satisfied by the implementation.
- If a DoD item is not met, either fix it or document why it is deferred.
- Record the DoD verification result in the final review notes.

Also verify the spec's **Test Strategy**:

- the selected TDD/conventional mode was propagated to the task registry;
- the effective `testing-anti-patterns.md` file exists at the recorded path;
- required RED/GREEN evidence is present for behavior-changing tasks;
- the main test scenarios and regression tests are covered;
- unrelated or pre-existing failures are documented and approved before closure.

## Step 3: Final Whole-Branch Audit

Generate a final review package before dispatching the auditor:

```bash
BASE=$(git merge-base <base-branch> HEAD)
sh "$ACTIVE_REVIEW_PACKAGE_SCRIPT" "$BASE" HEAD \
  docs/jobs/{NNNN-<feature-name>}/final-review-package.diff.md
```

Dispatch a final whole-branch review using the most capable model. Use [`agents/spec-compliance-auditor.md`](../agents/spec-compliance-auditor.md) as the audit prompt, providing:

1. The full spec document
2. Access to the codebase on the feature branch
3. The final review package
4. `super-plan.json`, including `requirementsChecklist` and task review outcomes

The auditor produces a **Spec Compliance Audit Report** covering every checkable item from the spec.

## Step 4: File Map

Produce a File Map listing all files created or modified during implementation. Include this in the Output Format below.

## Step 5: Address Remaining Findings

Address any findings from the final audit. Dispatch ONE fix subagent with ALL
findings — not one fixer per finding. Require focused test evidence in its
report, regenerate the final package from the same merge base, and repeat the
audit until there are no Critical/Important findings and no unresolved
`⚠️ Cannot verify` items. Every unverifiable item must either be closed by a
focused read-only check or escalated with the relevant spec text and an
explicit user decision. Escalation alone is not resolution; pause integration
and leave the plan incomplete until that decision is recorded in the final
review notes.

## Step 6: Handle Non-Complete Tasks

For any task that is not `completed`:

- **`blocked`:** Document the blocker in the task's `notes`. The plan cannot be fully closed until the blocker is resolved or the task is `cancelled`.
- **`cancelled`:** Ensure the cancellation reason is recorded in the task's `notes`. Verify that no other task depends on the cancelled task's output.
- **`needs_fix`:** This should not happen at integration time — all tasks should have been reviewed. If a task is still `needs_fix`, dispatch a fix subagent and re-review.

## Step 7: Mark Plan as Completed

Update `super-plan.json` through the active helper path:

```bash
bash super-planning/scripts/super-plan.sh complete-plan \
  --input docs/jobs/NNNN-<feature-name>/super-plan.json
```

This regenerates the progress ledger automatically.

Set the plan's `status` field to `completed` in `super-plan.json`. Run `render-progress-ledger.sh` to generate the final progress ledger as a closing artifact.

## Step 8: Fill in `implemented-by` in the Spec

Open the spec document and fill in the `implemented-by` field with the real paths that deliver the spec. The `implemented-by` value comes from the `fileStructure` entries in `super-plan.json` — list the key files that were created or modified to implement the spec.

Example:

```markdown
implemented-by:

- src/auth/middleware.ts
- src/auth/token.ts
- tests/auth/middleware.test.ts
```

## Step 9: Commit the Final Work

Use the [`commit-changes`](../../commit-changes/SKILL.md) skill to commit the final work. The commit should include:

- All implementation files
- The updated `super-plan.json` (status: `completed`)
- The regenerated `progress-ledger.md`
- The updated spec document (with `implemented-by` filled in)

### Output Format

- File Map (list of files created/modified)
- Spec Compliance Audit Report
- DoD verification results
- Progress ledger (regenerated)

## Step 10: Offer Next Steps

Offer the user:

1. **Merge** — the feature branch is ready to merge into the base branch
2. **PR** — create a pull request for review
3. **Keep working** — continue with additional changes

## `final_only` Review Cadence

If `reviewCadence=final_only`, this phase must also perform the first independent review gate for the implementation before any task or requirement is considered fully accepted.

When `reviewCadence=final_only`, run that review batch by batch: for each batch that reached `ready_for_review` during implementation, dispatch one reviewer subagent for the batch, resolve findings, and only then append the `completed` log entries, transition the affected tasks from `ready_for_review` to `completed`, and regenerate the ledger before moving on.

Phase 5 already materialized task directories, logging wrappers, and `progress.log`; Phase 6 materialized `report.md` and `review-package.diff.md`. In `final_only` mode, only reviewer dispatch was deferred to this phase.
