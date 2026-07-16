# Execution Reference

Load [`../references/github-flow.md`](../references/github-flow.md) for issue labels, router recovery, and plan/review cycles. Load [`../references/evidence-contract.md`](../references/evidence-contract.md) for the durable task evidence and closure matrix.

## Non-negotiable checks

- ADR/spec intent precedes issue plans; code/tests reveal drift only.
- Exactly one `stage:*` applies to an issue delivery at a time.
- `stage:approved` requires the literal verdict for the current plan cycle.
- No implementation before explicit mode selection.
- No task is accepted without independent code review.
- No issue closes without the final closure matrix and DoD evidence.

Do not create local task trackers, briefs, reports, or progress logs. Issue comments, labels, linked pull requests, and repository documents are the durable workflow evidence.
