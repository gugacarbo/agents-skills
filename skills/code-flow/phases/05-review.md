# Phase 5: Delivery review

For each `DONE` or `DONE_WITH_CONCERNS` task, dispatch a fresh `agents/06-delivery-reviewer.md` distinct from the executor and plan-writer. Give it the task/range, source set, plan, executor envelope, and review package. `BLOCKED` is never review-ready.

The reviewer posts `templates/08-task-review-template.md` in issue mode or appends the same ordered eight-field envelope to the direct-mode delivery record. It uses `APROVO`, `APROVO COM RESSALVAS`, `PEÇO AJUSTES`, or `NÃO APROVO` and checks scope, contract, validation, error paths, and ownership.

- Critical/Important finding or `NÃO APROVO`: return only the affected task to Phase 4. Issue mode returns to `stage:in-progress`; direct mode records `Resume: Phase 4 / <Task-ID>` and stops.
- Minor finding: retain it in the review and closure matrix.
- A clean review maps task ID to commit/PR and evidence. Parallel work also needs a fresh assembled-range review after assembly.

When all task/range reviews are clean, proceed to Phase 6 while retaining `stage:needs-task-review` for issue mode. Direct mode remains GitHub-free.
