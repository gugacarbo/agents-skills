# Phase 3: Plan and Independent Review

In issue mode, dispatch `agents/plan-author.md` from `stage:needs-plan`; the orchestrator does not write the plan. The planner reads accepted ADRs/specs, current behavior, investigation evidence, and the issue body when present.

The plan must include: source links at immutable commits, `Spec impact`, a base SHA, stable task IDs, ownership, dependencies, acceptance criteria, verification, parallel safety, EARS edge cases, TDD scenarios where relevant, risks, rollback, and Definition of Done.

## Publication

- **Issue mode:** post the complete plan using [`templates/issue-plan-comment.md`](../templates/issue-plan-comment.md), set `stage:needs-plan-review`, and retain its comment URL as cycle `k`.
- **Repository mode:** write the plan at the repository's `docs/plans/` convention and identify the committed revision under review.

Plans are append-only. Never edit a submitted/approved issue plan. Any material change posts a new cycle, removes `stage:approved`, and returns to `stage:needs-plan`.

## Review loop

Immediately dispatch a fresh `agents/plan-reviewer.md` with the literal plan comment URL/text or repository plan revision. In issue mode, the issue remains at `stage:needs-plan-review` until a literal verdict exists. The reviewer must not be the plan author.

| Result | Action |
| --- | --- |
| `APROVO` / `APROVO COM RESSALVAS` | In issue mode set `stage:approved`; retain nits in the review comment. |
| `PEÇO AJUSTES` | Return to `stage:needs-plan` and repeat. At cycle 3, block with `needs-human`. |
| `NÃO APROVO`, product/access decision, error, empty output, or missing literal verdict | Set `stage:blocked` plus `needs-human`; stop. |

Do not ask for another human approval between plan publication and its independent review. The only human gate here is approval of a required ADR/spec before planning.
