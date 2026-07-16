# Phase 3: Plan and independent review

From `stage:needs-plan`, dispatch `agents/03-plan-writer.md`. It creates one append-only plan cycle with immutable source links, base SHA, spec impact, stable task IDs, ownership, dependencies, acceptance criteria, verification/TDD, parallel safety, EARS cases, risks, rollback, and binary DoD. Its complete eight-field envelope accompanies the plan comment or direct-mode delivery-record section.

In issue mode, publish `templates/05-plan-template.md` and set `stage:needs-plan-review`. In direct mode, append to the versioned delivery record at the approved documentation path; do not create GitHub state or a local registry.

Immediately dispatch a fresh `agents/04-plan-reviewer.md` with the literal snapshot. It publishes `templates/06-review-template.md` or the equivalent delivery-record section with all eight fields and one literal verdict:

| Result | Action |
| --- | --- |
| `APROVO` / `APROVO COM RESSALVAS` | Issue: retain `stage:needs-plan-review` + `needs-human` and present the reviewed snapshot for human approval; direct: append the verdict and await human approval. |
| `PEÇO AJUSTES` | Issue: return to `stage:needs-plan`; at cycle 3 block + `needs-human`. Direct: append stop/resume and start a new cycle. |
| `NÃO APROVO`, error, absent verdict, or product/access decision | Issue: `stage:blocked` + `needs-human`; direct: append blocker and stop. |

After an approving independent verdict, the human approves or rejects the exact plan-comment snapshot. Only human approval moves the issue to `stage:approved`; a rejection or requested change returns it to `stage:needs-plan` (or blocks it at cycle 3). The source-set approval and the plan approval are separate mandatory gates.
