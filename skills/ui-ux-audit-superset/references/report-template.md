# UI/UX Audit Report Template

# UI/UX Audit — <Product>

## 1. Scope

**Audit mode:** Full / Scoped / PR / Accessibility / Design-system / Quick  
**Environment:**  
**Roles tested:**  
**Browsers/devices:**  
**Viewports:**  
**Themes:**  
**Accessibility baseline:** WCAG 2.2 AA unless overridden

### Evidence sources

- running application
- source
- Figma
- Storybook
- screenshots
- automated scans
- other

### Verified

- ...

### Not verified

- ...

### Assumptions

- ...

## 2. Executive assessment

State:

- overall task usability;
- highest-impact issue;
- strongest systemic issue;
- accessibility condition;
- responsive/theme condition;
- design-system condition;
- recommended first remediation.

Avoid vague praise or generic criticism.

## 3. Critical flows reviewed

| Flow    | Result                  | Highest severity | Evidence/notes |
| ------- | ----------------------- | ---------------: | -------------- |
| Sign in | Pass / Issues / Blocked |            Major | ...            |

## 4. Strengths worth preserving

Only list concrete strengths supported by inspection.

Examples:

- coherent form infrastructure;
- excellent focus treatment;
- consistent responsive navigation;
- strong use of design tokens;
- clear destructive confirmations.

## 5. Findings overview

| Severity    | Count |
| ----------- | ----: |
| Blocker     |     0 |
| Critical    |     0 |
| Major       |     0 |
| Minor       |     0 |
| Opportunity |     0 |

## 6. Detailed findings

### <ID> — <Concise title>

**Category:**  
**Severity:**  
**Confidence:**  
**Affected:**

**Evidence**

- route/state/viewport
- reproduction steps
- screenshot or source location when available

**User impact**
Explain the consequence in user terms.

**Rationale**
Reference:

- WCAG criterion;
- design-system rule;
- product requirement;
- platform convention;
- usability heuristic;
- implementation rule;

only when applicable.

**Recommendation**
Describe the desired corrected behavior.
Prefer root-cause/system-level correction.

**Verification**
State how to confirm the fix.

## 7. Systemic/root-cause findings

Group issues caused by:

- shared component;
- token;
- layout primitive;
- form infrastructure;
- navigation;
- content pattern;
- interaction model.

Include affected finding IDs/surfaces.

## 8. Accessibility summary

Report:

- automated tooling used;
- keyboard coverage;
- zoom/reflow;
- high contrast;
- screen-reader coverage;
- recurring WCAG failures;
- highest-impact barrier.

Do not claim full conformance from partial testing.

## 9. Design-system summary

Report:

- component reuse;
- token adherence;
- Figma/Storybook alignment;
- variant/state drift;
- one-off patterns;
- highest-leverage shared fixes.

## 10. Responsive/theme summary

Report:

- viewport coverage;
- breakpoint defects;
- tables/forms/dialogs;
- dark mode;
- high contrast;
- safe-area/mobile issues.

## 11. Source-level web-quality summary

If code was reviewed, summarize:

- semantics;
- focus;
- forms;
- motion;
- URL state;
- locale;
- images;
- hydration;
- performance risks;
- anti-patterns.

Do not dump every low-value lint-style detail into the executive summary.

## 12. Recommended remediation order

Example:

1. fix keyboard blocker in shared dialog;
2. fix systemic form error association;
3. correct mobile table behavior;
4. consolidate primary button variants;
5. address minor visual/content drift.

## 13. Verification gaps

List anything that could materially change conclusions:

- admin route unavailable;
- screen reader unavailable;
- Safari unavailable;
- production data unavailable;
- dark theme not accessible;
- payment sandbox unavailable.

## Appendix — Evidence map

| Finding  | Surface | Evidence         |
| -------- | ------- | ---------------- |
| A11Y-001 | Dialog  | Runtime + source |
