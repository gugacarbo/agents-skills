# Severity and Confidence

Severity represents user impact and urgency. Confidence represents evidence quality.

## Severity

### Blocker

Use when a meaningful user group cannot complete a critical task and no practical workaround exists, or when the UI creates an extreme accessibility/usability failure.

Examples:

- keyboard users cannot complete sign-in;
- primary submit is unreachable at common mobile widths;
- modal keyboard trap blocks completion;
- essential content is unavailable to assistive technology;
- destructive UI reliably causes irreversible loss.

### Critical

Use when a critical flow remains technically possible for some users but there is severe exclusion, confusion, incorrect-action risk, or data-loss risk.

Examples:

- save can fail silently;
- major form failure erases substantial work;
- systemic accessibility issue affects critical controls;
- critical action hierarchy is dangerously misleading.

### Major

Use when users can complete the task but the defect materially slows them, causes recurring mistakes, creates significant accessibility difficulty, or introduces systemic design inconsistency.

Examples:

- confusing validation;
- broken responsive table on an important flow with workaround;
- repeated focus-order issue;
- multiple competing primary-action implementations.

### Minor

Use for localized, low-impact quality defects.

Examples:

- isolated spacing drift;
- awkward wrapping at one uncommon width;
- small content inconsistency;
- low-impact icon mismatch.

### Opportunity

Use for an improvement that is not a confirmed defect against requirements, standards, or established system behavior.

Examples:

- simplify an already workable flow;
- improve an acceptable empty state;
- add tasteful visual differentiation.

Keep Opportunities separate from defect totals when useful.

## Confidence

### High

- directly reproduced;
- measured;
- confirmed in runtime;
- supported by source and behavior;
- clear standards mapping.

### Medium

- strong representative evidence;
- likely systemic;
- some environment/context missing.

### Low

- screenshot-only;
- behavior could not be reproduced;
- important assumptions;
- user intent/design requirement uncertain.

Never present Low-confidence inference as established fact.

## Priority within a severity

Consider:

1. critical-flow impact;
2. number of users affected;
3. encounter frequency;
4. accessibility impact;
5. data-loss/wrong-action risk;
6. systemic reach;
7. remediation leverage;
8. implementation risk.

Do not mechanically rank cosmetic defects above a lower-count accessibility barrier just because the cosmetic issue appears on more pages.
