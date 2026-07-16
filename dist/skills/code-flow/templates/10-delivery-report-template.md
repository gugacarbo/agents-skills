---
process: code-flow
base-sha: <full-sha>
sources: []
---

# <Delivery title>

This is one versioned delivery record, not a generated registry. Keep every
snapshot below append-only and commit each material update. Link every source,
review, evidence, and DoD result to a full SHA or immutable repository URL.
Every agent execution/outcome uses the ordered eight-field envelope: `Agent`,
`Phase/scope`, `Summary`, `Sources/evidence`, `Decisions`,
`Changes/validation`, `Blockers`, and `Next action`. This record is the only
coordination surface in direct mode: never create an issue or use GitHub
comments, labels, or stages.

## Agent execution envelope

Append this section once for every agent outcome, including no-change,
`BLOCKED`, rejected review, error, or missing verdict. Do not replace a prior
section.

Agent: `<role>`
Phase/scope: `<phase, cycle, task, range, or audit>`
Summary: `<concise result>`
Sources/evidence: `<immutable source, commit, command, output, or none>`
Decisions: `<applied, pending, or none>`
Changes/validation: `<files/effect and validation, or none>`
Blockers: `<blocker and required human decision, or none>`
Next action: `<action and owner>`

## ADR/spec proposal approval

- **Accepted ADR/spec or approved no-spec rationale:** …
- **Proposal / no-spec rationale:** …
- **Human approval evidence:** …
- **Materialized ADR/spec immutable link:** …
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
append the exact blocker and `Resume: <phase/task>` here.

## DoD and final audit

- **Audit revision and independence:** …
- **DoD command/result:** …
- **Optional PR merge decision:** `not applicable | awaiting explicit request | merged at <SHA>`
