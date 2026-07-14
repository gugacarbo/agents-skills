# Phase 1: Brainstorm

<HARD-GATE>
Do NOT write the spec or start implementation until you have refined the idea into concrete requirements, constraints, and design decisions. Do not skip this step, even if the feature seems simple or well-understood.
</HARD-GATE>

Phase 1 now embeds the `brainstorming` workflow directly inside `super-planning`. Use this phase to turn a rough request into spec-ready inputs.

## Workflow

1. **Explore project context first** — inspect the relevant files, docs, and recent changes before asking detailed questions.
2. **Assess scope early** — if the request actually contains multiple independent systems, stop and decompose it into sub-projects before refining details.
   > **Output:** Record sub-project decomposition in the brainstorm document (`.super-planning/brainstorm/BRAINSTORM-<date>.md`). Create one spec-per-sub-project if splitting.
3. **Ask clarifying questions one at a time** — prefer multiple choice when possible; focus on purpose, constraints, success criteria, and non-goals.
4. **Offer a visual companion only just-in-time** — only if a mockup, diagram, or visual comparison would genuinely make the next question easier to understand. If the user agrees, load [`01_1-visual-companion.md`](01_1-visual-companion.md) before launching it.
5. **Propose 2-3 approaches** — include trade-offs, lead with your recommendation, and explain why.
6. **Validate the direction** — make sure the user agrees with the chosen approach before carrying it into the spec.
   > **Recovery:** If the user disagrees with the direction, document their concerns in the decisions file (`docs/spec-decisions/NNNN_<feature_name>_decisions.md` once NNNN is allocated), return to step 2, and re-assess scope with the new constraints.
7. **Collect phase outputs** — requirements, constraints, assumptions, non-goals, risks, and design decisions.
8. **Save the decisions file before the spec gate** — before writing the spec in Phase 2, the agent must always save a durable decisions file at `docs/spec-decisions/<feature_name>_decisions.md` (no number yet — Phase 2 allocates the `NNNN` and renames the file).
9. **Carry the outputs into the spec** — use them as the foundation for the spec summary in Phase 2 and for the decisions file.

Do NOT proceed to Phase 2 until the brainstorm outputs are available.

## Interaction Rules

- Ask only one question per message.
- Prefer concise multiple-choice questions over broad open-ended ones.
- Stay ruthlessly within scope; remove nice-to-haves that are not needed for the first implementation.
- Follow existing repo patterns before proposing new abstractions.
- If existing code structure will directly hurt the work, include only the smallest refactor needed to support the feature cleanly.
- Present the chosen design in sections scaled to complexity and make sure the user agrees before moving on to the written spec.

## Fast Path

If the request is already well-defined after a quick repo review, keep Phase 1 short:

1. Summarize the problem and likely scope in 3-5 sentences.
2. Surface any assumptions that still matter.
3. Confirm the recommended approach with the user.
4. Move to Phase 2 once the direction is aligned.

## Required Outputs

Before leaving Phase 1, have enough material to write a solid spec summary and the decisions file:

- Problem statement
- User goal or business outcome
- Scope and non-goals
- Constraints and compatibility requirements
- Chosen approach and why
- Known risks or open questions
- Explicit assumptions to carry into the spec
- Enough context to populate `docs/spec-decisions/<feature_name>_decisions.md`

> **Visual companion flag:** Record whether the visual companion was used: set `visualCompanionUsed: true` in the output handoff document.
