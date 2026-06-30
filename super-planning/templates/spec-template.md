---
status: draft # draft | accepted | implemented | deprecated
date: YYYY-MM-DD
builds-on: [] # ADRs this spec relies on. The spec CONSUMES decisions, it does not redefine them.
implemented-by: [] # real paths (code, migrations, functions) — filled in at close
---

<!-- id is DERIVED from the filename (docs/specs/NNNN-title-kebab.md → SPEC-NNNN);
     title is DERIVED from the H1 below. -->

# <one-sentence behavior — becomes the derived title>

> Shared conventions (error envelope, authorization, data access):
> `docs/context/CONVENTIONS.md`. This spec does not repeat them — it only
> deviates from them explicitly when necessary.

## Objective

<!-- What the user/system can do once this is implemented. -->

## Flow

<!-- Step-by-step observable behavior. -->

## Contract

<!-- API/events/UI: inputs, outputs, formats. What is guaranteed. -->

## Edge cases

<!-- Enumerated and DECIDED. Suggested format: EARS, stack-agnostic.
     Undecided cases do NOT belong here — they go to Open questions. -->

| #   | WHEN ⟨trigger⟩ | the system MUST ⟨response⟩ |
| --- | -------------- | -------------------------- |
| 1   |                |                            |

## Open questions

<!-- Each item BLOCKS the corresponding implementation point —
     the agent must not improvise on an open question. -->

- [ ]

## Definition of Done

<!-- REQUIRED before leaving draft. Commands with a binary pass/fail criterion,
     runnable in the AGENTS.md environment. -->

```bash
npm run typecheck                 # exit 0
npm test -- --run <scope>         # N/N passing
```

## Human review

<!-- What requires human eyes and is NOT in the agent loop. -->

-

## Verification

<!-- Filled in at CLOSE (transition to implemented, same commit that
     fills implemented-by): DoD evidence — commands run + result. -->

```text
(fill in at close)
```

<!-- Close checklist (single commit):
     [ ] DoD green, evidence above
     [ ] status: implemented + implemented-by with real paths
     [ ] new gotchas → AGENTS.md
     [ ] new current state → relevant context chapter
     [ ] scripts/docs-check --emit-index (regenerated READMEs) -->
