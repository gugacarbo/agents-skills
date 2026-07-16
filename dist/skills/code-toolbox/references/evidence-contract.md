# Evidence Contract

Evidence is append-only and does not replace accepted repository ADRs/specs.
In issue mode, comments retain exact agent and task status while the stage label
names the next coordination gate. In direct mode, append the same evidence to
the versioned delivery record; never create an issue or use GitHub comments,
labels, or stages.

## Universal agent envelope

Every execution and outcome from `issue-writer`, `issue-reviewer`,
`plan-writer`, `plan-reviewer`, `executor`, and `delivery-reviewer` records
these eight fields in this order, including no-change, `BLOCKED`, error,
missing-evidence, and rejection outcomes:

```text
Agent: <agent>
Phase/scope: <phase, cycle, task, or range>
Summary: <result>
Sources/evidence: <immutable links, commands, output>
Decisions: <applied, pending, or none>
Changes/validation: <changes and validation, or none>
Blockers: <blocker or none>
Next action: <action and owner>
```

In issue mode, publish one new comment before the orchestrator changes state.
In direct mode, append an equivalent section to the delivery record before
stopping or proceeding.

## Task evidence

An executor posts one eight-field comment per task attempt with the plan-cycle
URL and stable task ID; branch, base SHA, commits, and PR URL when available;
changed files and allowed-scope deviations; verification commands/results; TDD
RED/GREEN evidence where required; and `DONE`, `DONE_WITH_CONCERNS`, or
`BLOCKED` with the exact blocker.

Only `DONE` and `DONE_WITH_CONCERNS` evidence is review-ready. In issue mode,
`BLOCKED` requires a recorded resolution or documented user cancellation before
the issue can reach task review. In direct mode, append the blocker and
`Resume: <phase/task>` to the delivery record, then stop without GitHub state.

## Review evidence

In issue mode, an independent `delivery-reviewer` posts one eight-field
comment per task/range. In direct mode, append the equivalent review to the
delivery record and never post a GitHub comment or alter GitHub state. Each
review references the task ID, evidence, review-package range, and a literal
verdict. The `delivery-reviewer` is distinct from the plan-writer and every
executor in the reviewed range. Each Critical/Important finding includes
`file:line`, impact, required action, and `Resume: <phase/task>` when it
rejects work. A clean review links the reviewed commit/PR. Parallel task
branches additionally require an independent review of the assembled range
before its PR opens.

## Closure matrix

Phase 6 posts one final table before closure:

| Task | Commit / PR | Executor evidence | Independent review | DoD evidence | Status |
| --- | --- | --- | --- | --- | --- |

Every planned task must have a row and executor evidence. A cancelled task
retains its row with an immutable user-cancellation decision as its evidence
and `review: not applicable`; no row may be silently omitted. A blocked task
requires its exact recorded decision before it can advance. In direct mode,
append this matrix to the versioned delivery record with immutable commit
URLs/SHAs. The final `delivery-reviewer` outcome also uses the eight-field
envelope.
