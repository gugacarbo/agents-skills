# Phase 2: Create the issue

Use the approved Phase 1 design to prepare the source set and create the GitHub delivery issue or, after an explicit Epic choice, the tracking Epic.

Run the execution preflight and repository-template discovery in `SKILL.md`. Continue only with one delivery issue; an initiative needs an explicit Epic decision and a narrowed child. Before writing, find the repository pattern for the artifact and carry its source and adaptations into the proposal. A delivery issue uses `templates/02-user-story.md` only when it complements the local pattern; implementation work remains plan task IDs.

Dispatch `agents/01-issue-writer.md` to investigate the focused repository area, accepted ADRs/specs, code/tests, conventions, ownership, dependencies, risks, and unresolved product decisions. It prepares the proposal; it does not create or update a formal ADR/spec before human approval. Refine only facts left open by the approved design; do not reopen approved product choices without new evidence.

The `issue-writer` classifies the spec impact:

| Result | Use when | Required action |
| --- | --- | --- |
| `create` | New contract, observable behavior, or durable decision | Embed a repository-pattern ADR/spec draft in the new issue and request human approval before creating the formal document. |
| `update` | An accepted ADR/spec governs changed behavior | Embed the proposed repository-pattern update in the new issue and request human approval before changing the formal document. |
| `not required` | Internal refactor, documented restoration, tests, docs, config, or no observable change | Put the exact no-spec rationale in the new issue and request human approval; do not create a spec merely for the workflow. |

Accepted ADRs/specs define intent. If a source conflicts with the approved design or code, stop and resolve it before planning. The `issue-writer` creates the delivery issue at `stage:spec-approval` plus `needs-human`, using the repository issue/ADR/spec pattern and `templates/03-issue-template.md` as the append-only proposal and approval request. It includes the approved design, ADR/spec draft or no-spec rationale; do not materialize the formal ADR/spec yet.

Only `/code-flow issue create` creates the delivery issue. Human approval authorizes `issue-writer` to materialize the approved ADR/spec exactly as approved (or retain the no-spec rationale), append its immutable source link, and set `stage:needs-plan`. Do not dispatch `plan-writer` before that evidence exists. `issue-reviewer` is optional and never replaces the human gate.

After the user explicitly selects an Epic, create it in GitHub from the local pattern and `templates/01-epic.md`. It is tracking-only: no delivery stage or plan. Each selected child delivery issue follows this phase independently. In direct mode, record the same proposal, approval, and materialized ADR/spec in the delivery record without GitHub state.
