# Phase 2: Spec Gate

Classify the work before planning:

| Result | Use when | Required action |
| --- | --- | --- |
| `create` | New contract, observable behavior, or durable decision | Dispatch `spec-author`; create the repository document using local convention. |
| `update` | An accepted ADR/spec already governs changed behavior | Dispatch `spec-author`; update that document. |
| `not required` | Internal refactor, restoration of documented behavior, tests, docs, config, or no observable change | Record the reason in the plan and, in issue mode, the plan comment. |

Accepted ADRs/specs define intent. Code/tests may expose drift but cannot override them. If a required document conflicts with code or the issue, stop and resolve the repository source first.

For `create` or `update`:

1. Before issue creation, dispatch `agents/spec-author.md` with repository evidence and the target convention.
2. Have the author self-check completeness, contracts, edge cases, DoD, and test strategy.
3. Prepare the ADR/spec for the initial issue and record its immutable path/URL in the plan input. Do not use an issue label for drafting this document.
4. When an issue is created, it begins at `stage:spec-approval` plus `needs-human`; human approval of the prepared ADR/spec, or of the explicit no-spec rationale, moves it to `stage:needs-plan`.

Do not run `spec-document-reviewer` by default. It remains available for a user-requested additional audit of a required spec.
