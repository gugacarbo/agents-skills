# Phase 2: Conditional spec gate

The `issue-writer` classifies the work before planning:

| Result | Use when | Required action |
| --- | --- | --- |
| `create` | New contract, observable behavior, or durable decision | Create the repository ADR/spec using local convention. |
| `update` | An accepted ADR/spec governs changed behavior | Update that document. |
| `not required` | Internal refactor, documented restoration, tests, docs, config, or no observable change | Record the exact reason; do not create a spec merely for the workflow. |

Accepted ADRs/specs define intent. If a source conflicts with code or issue scope, stop and resolve the source before planning. The issue-writer records an eight-field source-set envelope using `templates/issue-source-set-comment.md`; direct mode appends the equivalent section to the delivery record.

Only `/code-toolbox issue create` creates the delivery issue. It links the prepared ADR/spec or no-spec rationale, applies exactly `stage:spec-approval` and `needs-human`, then dispatches a fresh `issue-reviewer`. The issue-reviewer records `templates/issue-source-set-review-comment.md` but cannot advance the stage: human approval of the source set alone moves it to `stage:needs-plan`.

In direct repository mode, no issue, labels, or GitHub comments exist. The same human approval is recorded in the delivery record before planning.
