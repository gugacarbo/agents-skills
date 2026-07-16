# Evidence Contract

Issue comments provide durable delivery evidence. They are append-only snapshots, not a replacement for accepted repository ADRs/specs. The issue label names the next coordination gate; these comments retain exact per-task status while work is parallel.

## Task evidence

An executor posts one comment per task attempt with:

- plan cycle URL and stable task ID;
- branch, base SHA, commits, and PR URL when available;
- changed files and allowed-scope deviations;
- verification commands plus result;
- TDD RED/GREEN evidence where required;
- `DONE`, `DONE_WITH_CONCERNS`, or `BLOCKED` and the exact blocker.

## Review evidence

An independent reviewer posts one comment per task/range. It references the task ID, evidence comment, review package range, and a literal verdict. Each Critical/Important finding includes `file:line`, impact, and required action. A clean review links the reviewed commit/PR.

## Closure matrix

Phase 6 posts one final table before closure:

| Task | Commit / PR | Executor evidence | Independent review | DoD evidence | Status |
| --- | --- | --- | --- | --- | --- |

Every planned task must have a row. `blocked` or `cancelled` requires a documented user decision; no row may be silently omitted.
