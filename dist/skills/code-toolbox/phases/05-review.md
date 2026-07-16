# Phase 5: Code Review

For every completed task, dispatch a fresh `code-reviewer` that did not implement that task. In issue mode, the issue remains at `stage:needs-task-review` while independent task review, DoD, and final audit are pending. Give it the plan snapshot, task ID, executor evidence, relevant ADR/spec links, PR/range, and a package from `scripts/review-package.sh`.

The reviewer posts an append-only verdict with `APROVO`, `APROVO COM RESSALVAS`, `PEÇO AJUSTES`, or `NÃO APROVO` using [`templates/issue-review-comment.md`](../templates/issue-review-comment.md). It checks scope, contract compliance, tests, error handling, and ownership.

- Critical/Important finding or `NÃO APROVO`: return only the affected task to an executor, collect new evidence, and re-review.
- Minor finding: record it in the review comment and closure matrix.
- A clean review maps the task ID to its commit/PR and review URL. When all planned task reviews are clean, proceed directly to Phase 6 while retaining `stage:needs-task-review` until closure. It does not mark the entire issue closed.

Do not treat an implementer report, a green test, or a PR as independent review.
