# Trust, Transparency and Safety in UI

This module covers interface trustworthiness. It is not a security audit or legal review.

## 1. Error transparency

Errors should:
- acknowledge failure;
- avoid implying success;
- explain the next step;
- distinguish recoverable vs permanent situations;
- avoid hiding important partial failure.

Do not expose unnecessary sensitive/internal details.

## 2. AI-generated content

When the product presents AI-generated or AI-transformed output and the context could reasonably cause users to mistake it for authoritative/human-reviewed content, evaluate whether:
- AI involvement is communicated appropriately;
- uncertainty/limitations are shown where material;
- users can identify or correct generated content;
- destructive/high-impact actions require meaningful user confirmation.

Do not require an “AI disclaimer” mechanically on every small AI feature. Judge user expectation and risk.

## 3. Destructive actions

Check:
- consequence is explicit;
- permanent vs reversible is clear;
- confirmation/undo proportional to risk;
- affected item is named;
- dangerous primary/secondary button hierarchy is not misleading.

## 4. Data-loss prevention

Inspect:
- unsaved changes;
- expired sessions;
- failed uploads;
- failed form submission;
- concurrent edits where relevant;
- optimistic updates.

Users should know whether their work was saved.

## 5. Permissions and unavailable actions

Avoid letting users invest significant effort before revealing that they lack permission.

When an action is unavailable:
- explain why when useful;
- distinguish permission from missing data or temporary failure.

## 6. Sensitive values

When relevant:
- avoid unnecessary exposure;
- make copy/reveal actions intentional;
- consider shared-screen/device risks;
- do not leak secrets in error messages.

## 7. Consent and coercion

If reviewing consent/choice UI:
- avoid misleading button hierarchy;
- avoid obscuring meaningful alternatives;
- make consequences understandable.

Do not make legal conclusions without the relevant policy/jurisdiction.

## 8. High-impact decisions

For financial, medical, educational, employment, legal, or similarly consequential interfaces:
- clearly identify source/status of important information;
- avoid ambiguous automated decisions;
- provide correction/review paths when product requirements call for them;
- make irreversible actions clear.

This skill evaluates interface behavior, not substantive domain correctness.
