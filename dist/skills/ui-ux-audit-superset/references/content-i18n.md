# Content, Typography and Internationalization

## 1. Interface copy

Prefer:
- specific verbs;
- concrete outcomes;
- user/domain language;
- concise explanations;
- consistent terminology.

Examples:
- “Save API key” is clearer than “Continue” when the action truly saves the key.
- “Try again” is insufficient if users also need to know what failed.

## 2. Voice

Use the product's established voice.

For direct task instructions, active voice and direct address are often clearer.

Do not enforce a particular editorial style if the product already has documented content standards.

## 3. Errors

Error copy should say:
- what happened;
- where relevant, why;
- what to do next.

Avoid exposing stack traces or internal implementation language as the primary message.

## 4. Destructive copy

Name:
- the object;
- the action;
- whether it is permanent/reversible.

Avoid neutral “OK” for destructive confirmation.

## 5. Loading and status language

Use consistent status phrasing:
- Loading…
- Saving…
- Uploading…

Follow the project's language and punctuation conventions.

## 6. Typography punctuation details

Potential quality checks:
- real ellipsis glyph vs three periods in polished UI copy;
- typographic quotation marks in editorial text;
- non-breaking spaces where a unit/shortcut/brand token should stay together.

Treat these as style-system checks, not accessibility defects, unless they affect comprehension.

## 7. Numbers

For aligned number columns/comparisons, tabular numerals can improve scanability when the font supports them.

Use numerals/words according to product style and locale, not a universal English-only rule.

## 8. Wrapping

Headings and labels should wrap intentionally.

Use balanced/prettier wrapping when supported and useful, but do not rely on it for correctness.

Text containers must tolerate:
- short;
- average;
- very long;
- unbroken;
- user-generated values.

## 9. Truncation

Truncate only when:
- full text is not required for the immediate task;
- users have a way to access the full value when needed.

Avoid truncating unique identifiers, error details, or critical distinctions without a recovery path.

## 10. Localization

Use locale-aware formatting for:
- dates;
- times;
- currencies;
- numbers;
- pluralization.

Prefer platform localization APIs rather than hard-coded formatting.

## 11. Language detection

Do not infer language solely from IP address.

Prefer:
- user preference;
- account preference;
- browser language/Accept-Language;
- explicit locale selection.

## 12. Translation exclusions

Protect:
- brand names;
- code tokens;
- identifiers;
- technical literals

from automatic translation where appropriate.

## 13. Expansion

Test localized or simulated long text.

Look for:
- clipped buttons;
- fixed-height cards;
- nav overflow;
- table headers;
- dialog titles;
- form labels.

## 14. RTL

If right-to-left languages are supported:
- logical CSS properties;
- icon directionality;
- navigation order;
- charts;
- number/text mixing;
- form alignment;
- directional affordances.

## 15. Dates and time zones

Check:
- user timezone expectations;
- ambiguous date formats;
- relative time;
- DST-sensitive workflows;
- whether server/client rendering can disagree.

## 16. Sensory instructions

Avoid instructions that depend only on:
- “red”;
- “on the right”;
- shape;
- visual position;
- sound.

Use semantic labels as well.
