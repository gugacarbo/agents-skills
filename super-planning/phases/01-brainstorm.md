# Phase 1: Brainstorm

<HARD-GATE>
Do NOT write the spec or start implementation until you have refined the idea into concrete requirements, constraints, and design decisions. Do not skip this step, even if the feature seems simple or well-understood.
</HARD-GATE>

Phase 1 now embeds the `brainstorming` workflow directly inside `super-planning`. Use this phase to turn a rough request into spec-ready inputs.

## Workflow

1. **Explore project context first** — inspect the relevant files, docs, and recent changes before asking detailed questions.
2. **Assess scope early** — if the request actually contains multiple independent systems, stop and decompose it into sub-projects before refining details.
3. **Ask clarifying questions one at a time** — prefer multiple choice when possible; focus on purpose, constraints, success criteria, and non-goals.
4. **Offer a visual companion only just-in-time** — only if a mockup, diagram, or visual comparison would genuinely make the next question easier to understand. If the user agrees, load [`01_1-visual-companion.md`](01_1-visual-companion.md) before launching it.
5. **Propose 2-3 approaches** — include trade-offs, lead with your recommendation, and explain why.
6. **Validate the direction** — make sure the user agrees with the chosen approach before carrying it into the spec.
7. **Collect phase outputs** — requirements, constraints, assumptions, non-goals, risks, and design decisions.
8. **Offer an optional decisions file at the pre-spec gate** — when Phase 2 asks for approval before writing the spec, the user may also ask for a durable decisions file named `docs/specs/{feature_number}_{feature_name}_decisions.md`.
9. **Carry the outputs into the spec** — use them as the foundation for the spec summary in Phase 2 and, if requested, for the optional decisions file.

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

Before leaving Phase 1, have enough material to write a solid spec summary and, if requested, a decisions file:

- Problem statement
- User goal or business outcome
- Scope and non-goals
- Constraints and compatibility requirements
- Chosen approach and why
- Known risks or open questions
- Explicit assumptions to carry into the spec
- Enough context to populate `docs/specs/{feature_number}_{feature_name}_decisions.md` if the user opts in at the pre-write approval gate
