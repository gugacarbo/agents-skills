# Evidence Contract

Evidence is append-only and does not replace accepted ADRs/specs. In issue
mode, post it before a state change; in direct mode, append it to the versioned
delivery record without GitHub state.

## Envelope

Every outcome from every role uses these fields in this order, including no
change, `BLOCKED`, errors, missing evidence, and rejections:

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

## Task and review evidence

One executor comment covers one stable task ID and includes plan cycle, base
SHA, commits/PR when available, changed files, verification, and `DONE`,
`DONE_WITH_CONCERNS`, or `BLOCKED`. Only the first two are review-ready.
`BLOCKED` stops the flow until resolved or explicitly cancelled by the user.

An independent `delivery-reviewer` covers one task/range, cites its evidence
and review range, and gives a literal verdict. Critical/Important findings use
`file:line`, impact, required action, and `Resume: <phase/task>`. Parallel
branches also require a fresh assembled-range review before their PR.

## Closure matrix

Phase 6 posts:

| Task | Commit / PR | Executor evidence | Independent review | DoD evidence | Status |
| --- | --- | --- | --- | --- | --- |

Every planned task has a row. Cancelled work retains immutable user-cancellation
evidence; blocked work retains its resolution. In direct mode append the matrix
to the delivery record. The final audit also uses the envelope.
