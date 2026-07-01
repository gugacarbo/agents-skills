# Phase 1: Brainstorm

<HARD-GATE>
You MUST invoke the `brainstorming` skill before writing the spec. Do not skip this step, even if the feature seems simple or well-understood.
</HARD-GATE>

## Flow

1. **Invoke the `brainstorming` skill** — present the feature idea and let it guide exploration.
2. **Collect outputs** — requirements, constraints, non-goals, and design decisions.
3. **Carry the outputs into the spec** — use them as the foundation for the spec summary (Phase 2).

Do NOT proceed to Phase 2 until the `brainstorming` skill has been invoked and its outputs are available.

## Fallback When Brainstorming Skill Is Unavailable

If the skill is not present, do **not** skip Phase 1. Perform a lightweight manual brainstorm. **The default behavior is to make assumptions and proceed immediately — do not wait for user confirmation.**

1. **Quick assessment** — identify the core problem, goal, and likely scope (3–5 sentences).
2. **Make reasonable default assumptions** — based on the user's prompt, determine the likely tech stack, scope, constraints, and design approach. Document them in the spec's assumptions section.
3. **Proceed to Phase 2 immediately** — do NOT wait for confirmation. Write the spec with your assumptions clearly noted.
4. **Briefly mention your assumptions** to the user in one sentence (e.g., "Assumed Node/Express with PostgreSQL — noted in spec"). This lets them correct you if needed. If the user responds with corrections, incorporate them and continue.

The reason for proceeding immediately: a spec built on documented assumptions can be corrected later, but a stalled process produces nothing. Default assumptions are better than no output.
