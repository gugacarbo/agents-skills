# Phase 2: Spec Gate

Classify the work before planning:

| Result | Use when | Required action |
| --- | --- | --- |
| `create` | New contract, observable behavior, or durable decision | Dispatch `spec-author`; create the repository document using local convention. |
| `update` | An accepted ADR/spec already governs changed behavior | Dispatch `spec-author`; update that document. |
| `not required` | Internal refactor, restoration of documented behavior, tests, docs, config, or no observable change | Record the concrete reason in the source-set approval and the later plan; do not create a spec just to satisfy the workflow. |

Accepted ADRs/specs define intent. Code/tests may expose drift but cannot override them. If a required document conflicts with code or the issue, stop and resolve the repository source first.

For `create` or `update`:

1. Before issue creation, dispatch `agents/spec-author.md` with repository evidence and the target convention.
2. Have the author self-check completeness, contracts, edge cases, DoD, and test strategy.
3. Prepare the ADR/spec for a possible issue and record its immutable path/URL in the plan input. Do not use an issue label for drafting this document.
4. Only `/code-toolbox issue create` may create the delivery issue. It creates it at `stage:spec-approval` plus `needs-human`; human approval of the prepared ADR/spec moves it to `stage:needs-plan`.
5. In repository mode, obtain the same human approval and initialize the versioned delivery record with the approved ADR/spec's immutable revision before planning.

For `not required`:

1. Record the exact unchanged contract/behavior and why no durable decision is introduced.
2. For an issue, `/code-toolbox issue create` creates the issue at `stage:spec-approval` plus `needs-human` and includes the rationale in its body; source-set approval moves it to `stage:needs-plan`. In repository mode, obtain human approval and initialize the versioned delivery record at the approved documentation path with its source-set approval section before planning.
3. Give the approved rationale and immutable source links to `plan-author`; a later plan comment cannot retroactively replace this gate.

Do not run `spec-document-reviewer` by default. It remains available for a user-requested additional audit of a required spec.

## Explicit issue creation

`/code-toolbox issue create` is valid only after this phase has produced one prepared source set: an immutable ADR/spec path for `create`/`update`, or a concrete `not required` rationale. Create one eligible delivery/bug issue whose body links that source set and the investigation summary, then apply exactly `stage:spec-approval` and `needs-human`. Stop for source-set approval; do not plan, dispatch work, or select `direct`.

This route is incompatible with repository `direct` mode. A repository-mode delivery record stays repository-only; do not create an issue later to represent or resume it.
