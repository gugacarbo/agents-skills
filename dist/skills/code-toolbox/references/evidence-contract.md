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

Only `DONE` and `DONE_WITH_CONCERNS` evidence is review-ready. In issue mode, `BLOCKED` requires a recorded resolution or a documented user cancellation before the issue can reach task review. In repository mode, append the blocker and `Resume: <phase/task>` to the delivery record, then stop without GitHub labels, stages, or comments.

## Review evidence

In issue mode, an independent reviewer posts one comment per task/range. In repository mode, append the equivalent review to the delivery record and never post a GitHub comment or alter GitHub state. Each review references the task ID, evidence, review package range, and a literal verdict. The reviewer is distinct from the plan author and any executor in the reviewed range. Each Critical/Important finding includes `file:line`, impact, required action, and `Resume: <phase/task>` when it rejects work. A clean review links the reviewed commit/PR. Parallel task branches additionally require an independent review of the assembled range before its PR opens.

## Closure matrix

Phase 6 posts one final table before closure:

| Task | Commit / PR | Executor evidence | Independent review | DoD evidence | Status |
| --- | --- | --- | --- | --- | --- |

Every planned task must have a row and executor evidence. A cancelled task retains its row with an immutable user-cancellation decision as its evidence and `review: not applicable`; no row may be silently omitted. A blocked task requires its exact recorded decision before it can advance. For repository mode, append this same matrix to the versioned delivery record with immutable commit URLs/SHAs instead of issue comments.
