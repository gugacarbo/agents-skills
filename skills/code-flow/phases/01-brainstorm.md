# Phase 1: Brainstorm and approve the design

Turn the request into an approved delivery design before creating an issue, writing a formal ADR/spec, planning, or implementing.

1. Start from the Phase 0 repository context. If the request has multiple independent outcomes, pause for the Epic decision before refining a child.
2. Ask as many clarifying questions as needed to avoid inventing decisions about purpose, constraints, success criteria, scope, or ownership. Ask only one question per message; prefer concise choices when they help.
3. Offer the visual companion only when the next question is genuinely clearer as a mockup, diagram, or comparison. Make the offer its own message and wait for an answer; if accepted, load [`01_1-visual-companion.md`](01_1-visual-companion.md).
4. Propose 2–3 approaches with trade-offs and a recommendation. Keep the design scoped to the delivery; include architecture, boundaries, data/error flow when relevant, verification, and exclusions.
5. Present the design in sections sized to its complexity and obtain explicit user approval. Revise or ask the next single question until it is approved.

Do not create GitHub state, write a formal ADR/spec, create a plan, or start implementation in this phase. The approved design is carried to Phase 2, where the `issue-writer` records it in the GitHub proposal or direct-mode delivery record. Do not create a separate design document, progress log, or commit just for this phase.
