# Phase 6: Verify, Approve PR, and Offer Integration

In issue mode, Phase 6 starts from `stage:needs-task-review` after task reviews are clean. Before a PR can be approved, verify every planned task has executor evidence, an independent review verdict, and a commit/PR; parallel work also needs the reviewed assembly range. Dispatch `spec-compliance-auditor` with the approved ADR/spec when one exists; otherwise give it the approved plan and issue acceptance criteria.

1. Run the relevant full suite on the issue branch and record unrelated failures separately.
2. Verify every DoD item against concrete output.
3. Resolve Critical/Important findings and every `Cannot verify` item; re-audit changed code.
4. Publish the append-only closure matrix using [`templates/issue-integration-comment.md`](../templates/issue-integration-comment.md), including the PR-review result.
5. Obtain the required PR approval. Do not merge automatically.
6. After PR approval, publish a final suggestion: integration/merge is optional and requires an explicit user request. Keep `stage:needs-task-review` and add `needs-human` while that decision is pending; do not close the issue or remove labels merely because the PR is approved.
7. Only when the user requests integration, merge the approved PR using the repository policy, verify the merged target as required, then close the issue and remove `stage:*` and `needs-human`.

Repository mode uses the same verification and auditor gates, but appends every task-evidence link, code review, audit, DoD result, and optional merge decision to its versioned delivery record. A failed audit, `Cannot verify`, or unresolved DoD item appends the exact blocker and `Resume: <phase/task>` there, then stops. Repository mode creates no issue, labels, stages, or GitHub comments. A direct repository-mode change may be complete after its recorded DoD/audit; if it has a PR, offer merge only after that PR's approval.

Do not close an issue with a missing task-evidence row, review, DoD result, final audit verdict, or required merge verification.
