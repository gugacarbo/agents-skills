---
process: code-toolbox
base-sha: <full-sha>
sources: []
---

# <Delivery title>

This is one versioned delivery record, not a generated registry. Keep every
snapshot below append-only and commit each material update. Link every source,
review, evidence, and DoD result to a full SHA or immutable repository URL.

## Source-set approval

- **Accepted ADR/spec or approved no-spec rationale:** …
- **Human approval evidence:** …
- **Source revision:** `<full SHA / immutable URL>`

## Plan snapshot — cycle `<k>/3`

- **Plan revision:** `<full SHA / immutable URL>`
- **Task IDs, ownership, dependencies, acceptance, verification, parallel safety, and DoD:** …

## Independent plan review

- **Review revision:** `<full SHA / immutable URL>`
- **Reviewer independence:** …
- **Verdict:** `APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO`
- **Resume:** `<Phase 3 | stop pending human decision>`

## Task evidence and code reviews

| Task | Status | Commit/range | Evidence revision | Independent review revision |
| --- | --- | --- | --- | --- |
| Task-A-1 | `DONE | DONE_WITH_CONCERNS | BLOCKED | CANCELLED` | | | |

`CANCELLED` requires the immutable user-cancellation decision in the evidence
column and `review: not applicable`; never remove its task row.

For every `BLOCKED`, rejected review, audit failure, or unresolved DoD item,
append the exact blocker and `Resume: <phase/task>` here. This record is the
only coordination surface in repository mode: never add GitHub labels/stages
or post GitHub comments.

## DoD and final audit

- **Audit revision and independence:** …
- **DoD command/result:** …
- **Optional PR merge decision:** `not applicable | awaiting explicit request | merged at <SHA>`
