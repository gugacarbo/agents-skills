# Phase 6: Verify, approve PR, and offer integration

After clean task/range reviews, dispatch a fresh `agents/delivery-reviewer.md` for final audit. This instance must not have reviewed any task/range and is distinct from plan-writer and every executor. It audits accepted ADR/spec (or approved plan), every task envelope/review, final range, DoD, and closure matrix.

Run required suites, verify every DoD item, resolve Critical/Important or cannot-verify findings, and publish `templates/issue-integration-comment.md` in issue mode or the equivalent eight-field delivery-record section in direct mode. The closure matrix maps every task to commit/PR, executor evidence, delivery review, and DoD status.

In issue mode, obtain required PR approval but never merge automatically. After approval, keep `stage:needs-task-review`, add `needs-human`, and offer integration/merge as an explicit optional user decision. Only after the user requests integration may the approved PR be merged, the target verified, and the issue closed with stages removed.

Direct mode creates no issue, labels, stages, or GitHub comments. It may complete after the recorded final audit and DoD; if it has a PR, offer merge only after PR approval and explicit user confirmation.
