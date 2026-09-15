---
name: ui-ux-audit-superset
description: >-
  Use when auditing or reviewing an existing web application's UI/UX: full-product review, scoped flow, PR/UI diff, accessibility/WCAG 2.2 AA, keyboard/focus, responsive/theme behavior, forms, interaction states, design-system/Figma compliance, visual craft, content/i18n, perceived performance, or implementation quality. Also use for UX review, usability evaluation, interface quality checks, or prioritized evidence-based UI findings. Audits the running product and source when available; audit-only by default. Do not use to create or redesign UI from scratch, review backend/non-UI code, or implement fixes unless explicitly requested.
---

# UI/UX Audit

Perform a comprehensive audit of an existing user interface.

This skill is intentionally **standalone**. Do not require another UI/UX skill, remote checklist, or external guideline fetch in order to perform the audit. External standards or project documentation may be consulted when available, but the core audit procedure and rules are contained in this skill package.

The audit should answer:

- Can users understand what the product does and what to do next?
- Can they complete important tasks efficiently and safely?
- Does the implementation follow its design system and intended visual language?
- Does it work across relevant viewports, input methods, themes, content lengths, states, and roles?
- Is it accessible against the requested baseline?
- Does the frontend follow robust web-interface conventions?
- Which defects are systemic, which are isolated, and what should be fixed first?

## Non-negotiable operating rules

1. **Audit before remediation**
   - Do not change source code, styles, tokens, copy, Figma, or assets during the initial audit unless the user explicitly asks for fixes.
   - If remediation is requested after an audit, fix root causes before repeated symptoms and re-test affected flows.

2. **Prefer the running product**
   - A source-only review is not a complete UI/UX audit.
   - Interact with the application through a browser, browser automation, screenshots, or supplied captures whenever possible.
   - Use source review to explain and generalize runtime defects, not to replace runtime inspection.

3. **Use evidence, not taste**
   - Distinguish standards failures, usability defects, design-system deviations, implementation risks, and subjective aesthetic opportunities.
   - Avoid vague findings such as “improve UX”, “modernize”, or “looks inconsistent” without evidence.

4. **Audit systems, not screenshots**
   - Look for shared components, tokens, layout primitives, form infrastructure, state patterns, navigation patterns, and repeated content behavior.
   - De-duplicate repeated symptoms into root-cause findings.

5. **Do not overclaim conformity**
   - Technical review can identify evidence of meeting or failing specific requirements.
   - Do not claim legal compliance solely from this audit.
   - WCAG conformance requires appropriate scope and complete testing; an automated scan never establishes conformance.

6. **Do not invent requirements**
   - Audit against known product requirements, Figma, Storybook, design tokens, component libraries, brand guidance, accessibility targets, and platform conventions when available.
   - Label assumptions when context is missing.

7. **Prioritize user impact**
   - Critical-task blockers, data-loss risk, inaccessible controls, and misleading behavior outrank cosmetic inconsistencies.

8. **Treat heuristics as heuristics**
   - “Few clicks”, list-size thresholds, typography conventions, and aesthetic preferences are context-dependent.
   - Do not turn a heuristic into a standards violation.

9. **Preserve strengths**
   - Record successful patterns worth keeping so remediation does not accidentally degrade them.

10. **Be explicit about verification gaps**
    - If a route, role, theme, browser, screen reader, device class, or state could not be tested, say so.

---

# Audit modes

Select the narrowest mode that satisfies the user.

## Full Product Audit

Use for “audit the app”, “review the whole UI/UX”, “check everything”, or equivalent.

Inspect:

- representative routes and all critical flows;
- desktop + mobile;
- relevant themes;
- keyboard and focus;
- accessibility;
- design-system consistency;
- forms, tables, dialogs, states, content, and responsive behavior;
- source-level web-interface rules when code is available.

## Scoped Flow Audit

Use when the user names a flow, route, feature, component family, or role.

Inspect the complete task, including entry, success, errors, recovery, and responsive/accessibility behavior.

## PR / UI Code Review

Use when reviewing a change set.

Prioritize:

- changed UI behavior;
- design-system component/token usage;
- semantics and accessibility;
- variants/states;
- responsive regressions;
- implementation anti-patterns;
- mismatch with Figma or existing component APIs.

## Accessibility Deep Dive

Use when accessibility is the primary request.

Use `references/accessibility-wcag22.md` and perform manual testing where possible.

## Design-System Compliance Audit

Use when conformity with Figma/Storybook/tokens/components is primary.

Use `references/design-system.md`.

## Creative / Aesthetic Quality Review

Use when the user explicitly asks whether a design feels distinctive, intentional, polished, generic, or appropriate to a brand.

Use `references/visual-design.md`.
Do not penalize a conventional enterprise interface merely for not being visually experimental.

## Quick Audit

Use only when the user explicitly wants a fast review.

Minimum:

- primary route/flow;
- one desktop and one mobile width;
- keyboard/focus smoke test;
- basic accessibility semantics;
- top-impact findings only.

Label it as a quick audit. Do not generalize it to the whole product.

---

# Default baseline

Unless project-specific requirements override it:

- accessibility: **WCAG 2.2 Level AA**;
- desktop and mobile inspection;
- keyboard operation for interactive workflows;
- light/dark themes if both exist;
- high-contrast/forced-colors behavior when relevant and testable;
- reduced-motion behavior where motion exists;
- zoom/reflow checks;
- representative success/loading/empty/error/disabled/focus/selected/destructive states;
- current mainstream web conventions;
- audit-only, no implementation changes.

---

# Phase 0 — Establish context and evidence sources

Determine, when possible:

- product purpose;
- primary users and roles;
- primary tasks;
- business-critical or safety-critical workflows;
- expected platforms and browsers;
- device/viewport range;
- supported languages/locales;
- design system, Storybook, component registry, Figma, tokens, brand rules;
- accessibility target;
- organizational or regulatory requirements;
- authentication/permissions;
- whether the audit is production, staging, local, screenshot-only, or source-only.

Evidence sources may include:

1. running application;
2. browser accessibility tree;
3. screenshots/video;
4. source code;
5. route definitions;
6. Storybook/component docs;
7. Figma/design specs;
8. design tokens/theme files;
9. product requirements;
10. automated accessibility/performance results;
11. test suites;
12. analytics or user research supplied by the user.

Rank direct reproduction above inference.

Document:

- **Verified**
- **Not verified**
- **Assumptions**

If important context is missing, proceed with reasonable assumptions instead of blocking unless the missing information makes the requested conclusion impossible.

---

# Phase 1 — Inventory surfaces and critical flows

Build a compact product map before deep review.

Discover as applicable:

- routes/pages;
- global shell/navigation;
- auth/onboarding;
- dashboards;
- search/filter/sort;
- CRUD forms;
- data tables/lists;
- detail pages;
- dialogs/drawers/popovers;
- settings;
- upload/download;
- notifications;
- empty/loading/error states;
- destructive actions;
- role-specific surfaces;
- mobile-specific navigation;
- offline/network failure behavior;
- AI-generated-content surfaces if present.

Group repeated UI into pattern families rather than auditing each route as if unique.

Examples:

- app shell;
- form pattern;
- table pattern;
- detail pattern;
- modal pattern;
- search/filter pattern;
- notification pattern.

Mark a flow **critical** when failure can:

- block the main task;
- cause data loss or irreversible change;
- expose sensitive information;
- cause a materially wrong decision;
- prevent sign-in, saving, submission, purchase, approval, or other core completion;
- exclude users because of accessibility barriers.

---

# Phase 2 — Run the multi-layer audit

## Runtime evidence procedure

When a running product is available:

1. Establish a safe test URL, credentials/role, and allowed data before interacting.
2. Exercise the actual task; do not stop at page screenshots.
3. Record route, state, viewport/theme, input method, and reproduction steps for material findings.
4. Use the browser accessibility tree, DOM state, console errors, network behavior, or automated tooling as supporting evidence.
5. Capture only the minimum screenshots/transcripts needed. Do not copy secrets, personal data, or customer data into the report; redact when necessary.
6. If runtime access fails, downgrade the engagement to source-only/capture-only and state that limitation in the report.

Use the references below. Load only the files relevant to the current audit phase; a full audit still needs every applicable domain.

## Product usability and IA

Read:

- `references/usability-ia.md`

## Visual quality and aesthetic direction

Read:

- `references/visual-design.md`

## Design-system and Figma/component conformity

Read:

- `references/design-system.md`

## Accessibility

Read:

- `references/accessibility-wcag22.md`

## Forms and data entry

Read:

- `references/forms-inputs.md`

## Interaction, focus, states, dialogs, touch, motion

Read:

- `references/interaction-states.md`

## Responsive layout, tables, safe areas, themes

Read:

- `references/responsive-layout.md`

## Content, typography, localization

Read:

- `references/content-i18n.md`

## Images, perceived performance, rendering/hydration

Read:

- `references/performance-web-quality.md`

## Static implementation/code rules

Read:

- `references/code-review-rules.md`

## Trust, AI disclosure, destructive/error transparency

Read:

- `references/trust-safety-ui.md`

## Full-audit coverage check

Before reporting a Full Product Audit, read
`references/coverage-matrix.md` and account for every applicable row. Mark
unavailable rows explicitly as **Not verified** rather than inventing evidence
or silently narrowing the audit.

---

# Phase 3 — Exercise representative states

Do not judge only the default happy path.

Where applicable inspect:

- default;
- hover;
- focus-visible;
- pressed/active;
- selected/current;
- disabled;
- read-only;
- pending/loading;
- skeleton;
- empty;
- no search results;
- partial data;
- warning;
- validation error;
- server/network error;
- success;
- offline;
- permission denied;
- session expired;
- destructive confirmation;
- long labels;
- long user content;
- large datasets;
- slow response;
- reduced motion;
- dark mode;
- high contrast / forced colors.

Use test data or existing state controls when safely available.

---

# Phase 4 — Responsive and input-method matrix

Test representative widths and transitions.

If no product matrix exists, use approximately:

- 320–375 CSS px: small phones;
- 390–430 CSS px: larger phones;
- 768–1024 CSS px: tablet;
- 1280 CSS px: laptop;
- 1440+ CSS px: desktop.

Also test **intermediate widths around actual breakpoints**, because many layout defects occur between canonical device sizes.

Input methods where relevant:

- keyboard only;
- mouse/trackpad;
- touch;
- screen reader when available;
- zoomed text/reflow;
- reduced motion.

Do not assume responsiveness because media queries exist.

---

# Phase 5 — Compare implementation with design intent

When Figma, Storybook, a component library, tokens, or documented patterns exist:

1. identify the canonical component/pattern;
2. compare implementation structure and behavior;
3. compare variants/states;
4. compare spacing, typography, color roles, radius, iconography, and motion;
5. check token/component reuse;
6. identify hard-coded or one-off values that bypass the system;
7. document intentional deviations separately from accidental drift.

When no component exists:

- first check whether an existing primitive can express the need;
- treat a justified new pattern as a design-system extension, not automatically a defect;
- recommend documenting the exception or adding a canonical component when repetition warrants it.

---

# Phase 6 — Static implementation review

If source is available, inspect the relevant UI files.

Use `references/code-review-rules.md`.

Prefer location-aware findings:

- file path;
- line number or smallest useful code span;
- affected component;
- runtime effect.

Do not report a static “violation” if runtime evidence shows the pattern is correct in context.

Conversely, do not dismiss a runtime defect because code appears plausible.

---

# Phase 7 — De-duplicate and find root causes

Before reporting:

1. merge duplicate symptoms;
2. identify shared components/tokens/layout primitives;
3. distinguish systemic vs isolated issues;
4. identify whether a single component fix resolves multiple surfaces;
5. separate root cause from downstream symptoms;
6. avoid dozens of repeated findings for the same pattern.

Prefer:

> Shared `Dialog` focus restoration fails after close, affecting 8 flows.

over:

> Focus is lost on page A, page B, page C...

---

# Phase 8 — Classify findings

Read:

- `references/severity-confidence.md`

Each finding must contain:

- ID;
- concise title;
- category;
- severity;
- confidence;
- affected surface(s);
- evidence;
- reproduction context when useful;
- user impact;
- rationale / applicable standard or design rule;
- recommendation;
- verification method.

Suggested prefixes:

- `A11Y` accessibility
- `UX` usability/interaction
- `IA` information architecture
- `VIS` visual design
- `DS` design system
- `RESP` responsive/layout
- `FORM` forms
- `STATE` states/feedback
- `COPY` content
- `PERF` perceived/web performance
- `WEB` frontend implementation
- `TRUST` trust/transparency

Do not use severity to encode aesthetic preference.

---

# Phase 9 — Produce the report

Read:

- `references/report-template.md`

A source-only or capture-only review must be labeled as such and must not present inferred behavior as runtime-verified.

A full report should make clear:

1. scope and assumptions;
2. evidence sources;
3. critical flows reviewed;
4. executive assessment;
5. strengths worth preserving;
6. findings ordered by severity and impact;
7. systemic/root-cause issues;
8. accessibility summary;
9. design-system summary;
10. responsive/theme summary;
11. source-level web-quality summary when code was reviewed;
12. recommended remediation order;
13. verification gaps.

## Numeric scores

Do not fabricate precision.

Only provide `x/100` category scores when:

- the user asks for scoring; or
- a defined organizational rubric exists.

If the user asks for scores without a rubric:

1. define the dimensions, weights, evidence limits, and scoring scale first;
2. label every numeric score and the overall score as **heuristic**;
3. state that scores do not establish conformance; and
4. keep confirmed standards findings separate from score deductions for subjective quality.

---

# Remediation mode

Only enter remediation mode when explicitly requested.

Order:

1. Blockers;
2. Criticals;
3. systemic/root-cause Majors;
4. isolated Majors;
5. Minors;
6. Opportunities.

During remediation:

- prefer canonical design-system primitives;
- preserve successful patterns;
- avoid unrelated redesign;
- keep semantics native where possible;
- fix accessibility at the shared component level when systemic;
- retest critical flows and affected breakpoints/states.

After changes, update each finding:

- Fixed
- Partially fixed
- Not fixed
- Unable to verify

Never silently expand the scope.

---

# Completion criteria

A full audit is not complete until it states:

- what was tested;
- what could not be tested;
- which flows matter most;
- which issues can block completion;
- which accessibility failures are confirmed;
- which problems are systemic;
- which issues are standards-based vs heuristic vs aesthetic;
- what evidence supports each major conclusion;
- what should be fixed first;
- how fixes can be verified.
