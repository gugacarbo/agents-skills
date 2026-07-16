# Phase 3: Plan and independent review

From `stage:needs-plan`, dispatch `agents/plan-writer.md`. It creates one append-only plan cycle with immutable source links, base SHA, spec impact, stable task IDs, ownership, dependencies, acceptance criteria, verification/TDD, parallel safety, EARS cases, risks, rollback, and binary DoD. Its complete eight-field envelope accompanies the plan comment or direct-mode delivery-record section.

In issue mode, publish `templates/issue-plan-comment.md` and set `stage:needs-plan-review`. In direct mode, append to the versioned delivery record at the approved documentation path; do not create GitHub state or a local registry.

Immediately dispatch a fresh `agents/plan-reviewer.md` with the literal snapshot. It publishes `templates/issue-plan-review-comment.md` or the equivalent delivery-record section with all eight fields and one literal verdict:

| Result | Action |
| --- | --- |
| `APROVO` / `APROVO COM RESSALVAS` | Issue: set `stage:approved`; direct: append approval and continue. |
| `PEÇO AJUSTES` | Issue: return to `stage:needs-plan`; at cycle 3 block + `needs-human`. Direct: append stop/resume and start a new cycle. |
| `NÃO APROVO`, error, absent verdict, or product/access decision | Issue: `stage:blocked` + `needs-human`; direct: append blocker and stop. |

Never ask for another human approval between plan and independent review; source-set approval is the human gate before planning.
