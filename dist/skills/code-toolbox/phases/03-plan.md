# Phase 3: Plan and Independent Review

In issue mode, dispatch `agents/plan-author.md` from `stage:needs-plan`; the orchestrator does not write the plan. The planner reads accepted ADRs/specs, current behavior, investigation evidence, and the issue body when present.

The plan must include: source links at immutable commits, `Spec impact`, a base SHA, stable task IDs, ownership, dependencies, acceptance criteria, verification, parallel safety, EARS edge cases, TDD scenarios where relevant, risks, rollback, and Definition of Done.

## Publication

- **Issue mode:** post the complete plan using [`templates/issue-plan-comment.md`](../templates/issue-plan-comment.md), set `stage:needs-plan-review`, and retain its comment URL as cycle `k`.
- **Repository mode:** create or extend one versioned delivery record using [`templates/repository-delivery-record.md`](../templates/repository-delivery-record.md) at the repository's established documentation path. If the repository has no convention, ask the user to select its tracked Markdown path. Append the plan snapshot and record its full commit SHA/immutable URL; do not create a registry, job file, or progress log.

Plans are append-only. Never edit a submitted/approved issue plan. Any material change posts a new cycle, removes `stage:approved`, and returns to `stage:needs-plan`.

## Review loop

Immediately dispatch a fresh `agents/plan-reviewer.md` with the literal plan comment URL/text or repository delivery-record revision. In issue mode, the issue remains at `stage:needs-plan-review` until a literal verdict exists. The reviewer must not be the plan author and must declare that independence in its review evidence.

| Result | Action |
| --- | --- |
| `APROVO` / `APROVO COM RESSALVAS` | In issue mode set `stage:approved`; in repository mode append an approval review with its immutable revision. Retain nits in the review evidence. |
| `PEÇO AJUSTES` | In issue mode return to `stage:needs-plan` and repeat; at cycle 3, block with `needs-human`. In repository mode append the rejection and required changes to the delivery record, stop execution, and resume only at a new plan cycle. |
| `NÃO APROVO`, product/access decision, error, empty output, or missing literal verdict | In issue mode set `stage:blocked` plus `needs-human`; stop. In repository mode append the rejection/blocker and exact human decision needed to the delivery record, then stop with no GitHub labels, stages, or comments. |

Do not ask for another human approval between plan publication and its independent review. The only human gate here is source-set approval—either a required ADR/spec or an explicit no-spec rationale—before planning.
