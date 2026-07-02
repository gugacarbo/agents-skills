---
status: draft
# allowed values: draft | accepted | implemented | deprecated
# do not skip states; only move to implemented after Phase 7 closes.
date: YYYY-MM-DD
builds-on: []
# List ADRs/decisions this spec relies on. The spec CONSUMES decisions;
# it does not redefine them here.
implemented-by: []
# Filled in at close: real paths (code, migrations, functions) that deliver this spec.
---

<!-- id is DERIVED from the filename: docs/specs/NNNN-title-kebab.md → SPEC-NNNN
     title is DERIVED from the H1 below -->

# <one-sentence behavior — becomes the derived title>

> Shared conventions: identify any existing project conventions this spec builds on.
> If the repo has no shared conventions document, state the relevant assumptions here.

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
<typecheck command>               # exit 0
<focused test command>            # N/N passing
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
     [ ] new gotchas → project guidance if needed
     [ ] new current state → relevant docs/context if needed
     [ ] generated docs/indexes refreshed if the repo requires it -->
