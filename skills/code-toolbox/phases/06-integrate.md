# Phase 6: Integrate and Finish

In issue mode, Phase 6 starts from `stage:needs-task-review` after task reviews are clean. Before closure, verify each plan task has executor evidence, an independent review verdict, and a commit/PR. Dispatch `spec-compliance-auditor` with the approved ADR/spec when one exists; otherwise give it the approved plan and issue acceptance criteria.

1. Run the relevant full suite on the issue branch and record unrelated failures separately.
2. Verify every DoD item against concrete output.
3. Resolve Critical/Important findings and every `Cannot verify` item; re-audit changed code.
4. Publish the append-only closure matrix using [`templates/issue-integration-comment.md`](../templates/issue-integration-comment.md).
5. Link the PR. After merge/approved closure, close the issue and remove `stage:*` and `needs-human`.

Do not close an issue with a missing task-evidence row, review, DoD result, or final audit verdict.
