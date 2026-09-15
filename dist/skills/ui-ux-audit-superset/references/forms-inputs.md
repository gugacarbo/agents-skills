# Forms and Data Entry

Forms concentrate accessibility, usability, browser-behavior, and error-recovery problems. Review them as complete tasks.

## 1. Labels and names

Every control should have:

- a persistent understandable label;
- a meaningful programmatic name;
- a meaningful `name` when submitted/stored by browser behavior.

Avoid placeholder-only labeling.

Make labels clickable by associating them with the control or wrapping the control appropriately.

For checkbox/radio rows, avoid “dead zones” between label and control when the whole row conceptually acts as one target.

## 2. Input type and input mode

Use appropriate HTML input types and input modes where useful:

- email;
- telephone;
- URL;
- number/decimal only when numeric semantics truly apply;
- date/time controls when suitable.

Do not use `type=number` for identifiers that happen to contain digits.

## 3. Autocomplete

Use autocomplete metadata when it improves:

- names;
- addresses;
- email;
- phone;
- authentication;
- one-time codes;
- payment or other recognized purposes.

Do not broadly disable autocomplete without a concrete reason.

If a non-auth field repeatedly triggers inappropriate password-manager behavior, a targeted mitigation may be justified, but do not sacrifice legitimate user-agent assistance casually.

## 4. Paste

Never block paste merely to force manual entry.

This is especially important for:

- passwords;
- one-time codes;
- account identifiers;
- long values.

## 5. Spellcheck and correction

Disable spellcheck/autocorrection where it creates incorrect transformations, such as:

- emails;
- usernames;
- codes;
- machine identifiers.

Keep it available for natural-language fields where it helps.

## 6. Instructions and examples

Make formatting expectations explicit.

Examples:

- expected date format;
- units;
- allowed characters;
- minimum/maximum constraints.

Placeholder examples should supplement, not replace, labels.

## 7. Required and optional

Users should understand what is required before submit.

Avoid:

- marking every field required if most are required and the distinction becomes noise;
- required state conveyed only by color or an unexplained symbol.

## 8. Validation timing

Validate at a useful moment.

Avoid aggressive error messages before a user has had a reasonable chance to enter data.

For dependent fields, make the dependency clear.

## 9. Submit behavior

Before request:

- primary submit remains operable unless submission is genuinely impossible.

During request:

- prevent duplicate submission;
- communicate pending state;
- preserve button meaning;
- use spinner/progress only when it helps.

After request:

- confirm success;
- keep user context;
- explain failures.

## 10. Errors

Errors should be:

- close to the field;
- understandable;
- programmatically associated;
- specific;
- actionable.

After failed submit:

- preserve values;
- identify all relevant errors;
- move or direct focus to the first/summary error appropriately;
- do not rely only on red outlines.

## 11. Multi-step forms

Check:

- progress;
- ability to go back;
- data retention;
- validation boundaries;
- summary before irreversible submission where useful;
- accessible step names.

## 12. Unsaved changes

When navigation would discard meaningful work:

- warn the user or preserve the draft;
- integrate with router/browser behavior;
- avoid warnings for trivial untouched forms.

## 13. Mobile form behavior

Inspect:

- keyboard type;
- viewport not obscured;
- submit action reachable when keyboard opens;
- fields do not zoom unexpectedly because text is too small;
- long forms remain navigable.

## 14. Disabled vs read-only

Use the right semantic concept.

Disabled:

- not currently operable;
- may be removed from keyboard focus depending on native behavior.

Read-only:

- value can be inspected/copied but not changed.

If users need to understand why an action is unavailable, provide the reason somewhere discoverable.

## 15. Authentication forms

Check:

- password manager support;
- paste allowed;
- show/hide password accessible;
- one-time-code autocomplete where suitable;
- errors do not reveal unnecessary security information;
- recovery is clear.
