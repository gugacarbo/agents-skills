# Accessibility Audit — WCAG 2.2 AA

Default technical baseline: **WCAG 2.2 Level AA** unless another target is specified.

This document is an operational audit guide, not a substitute for the normative WCAG specification.

## Core rule

Automated accessibility scanners find only a subset of accessibility issues.

Never conclude:

- “accessible”;
- “WCAG compliant”;
- “passes WCAG”

solely because an automated scan reports zero violations.

## 1. Automated pass

If available, run axe or an equivalent engine on representative routes and states.

Capture:

- rule;
- affected node;
- route/state;
- automated severity;
- reproduction evidence.

Reclassify final severity based on actual user impact.

Automated tools are useful for:

- missing accessible names;
- some label failures;
- invalid ARIA;
- some structural problems;
- some contrast problems.

They cannot reliably judge:

- meaningful alt text;
- logical focus order;
- cognitive clarity;
- quality of error recovery;
- whether a custom widget is understandable;
- complete screen-reader task usability.

## 2. Keyboard-only pass

Test important tasks without a pointing device.

Verify:

- all functions reachable;
- logical Tab/Shift+Tab order;
- clear focus indicator;
- Enter/Space behavior appropriate to control;
- menu, tabs, dialog, popover, combobox, date picker behavior;
- no keyboard traps;
- Escape behavior where expected;
- focus restoration after overlays;
- focus location after route/state changes;
- focus after validation failure.

## 3. Focus

Inspect:

- visible focus;
- focus indicator has enough contrast to be perceivable;
- author-created sticky headers/footers/overlays do not fully hide the focused control;
- focus does not disappear into non-interactive regions;
- focus is not reset unexpectedly.

WCAG 2.2 AA particularly adds focus-not-obscured requirements.

## 4. Structure and semantics

Check:

- page language;
- meaningful page title;
- landmark structure;
- heading hierarchy;
- list semantics;
- native buttons for actions;
- native links for navigation;
- correct table semantics;
- labels associated with controls;
- accessible name/role/value/state;
- dialogs identified as dialogs;
- expanded/selected/invalid state exposed when needed.

Prefer native HTML before recreating semantics with ARIA.

## 5. Non-text content

Images:

- meaningful images receive useful alternatives;
- decorative images are ignored appropriately;
- charts/diagrams provide equivalent information when necessary.

Icons:

- decorative icons should not clutter assistive technology;
- icon-only controls need an accessible name.

## 6. Audio/video/media

Where relevant:

- captions;
- transcripts;
- audio description or equivalent where required;
- keyboard-operable controls;
- no inaccessible autoplay behavior;
- pause/stop/hide for sufficiently long auto-moving content when required.

## 7. Contrast and color

Inspect:

- body text;
- large text;
- link distinction;
- controls/boundaries when necessary;
- charts;
- focus indicators;
- status colors;
- validation states.

Information must not depend on color alone.

## 8. Resize, zoom, reflow and spacing

Test where possible:

- 200% browser zoom;
- narrow reflow equivalent;
- enlarged text;
- increased text spacing;
- long content.

Look for:

- clipping;
- overlap;
- hidden controls;
- lost information;
- ordinary page content requiring two-dimensional scrolling;
- fixed UI hiding content.

Complex diagrams/data grids may legitimately need two-dimensional interaction; judge the requirement in context.

## 9. Target size

WCAG 2.2 AA introduces a minimum target-size requirement with exceptions.

Operationally:

- look for small, tightly packed controls;
- especially icon actions, pagination, chips, close buttons, row actions;
- verify spacing when targets are under the baseline size;
- use the normative WCAG rule when making a formal criterion claim.

Do not automatically require 44×44 CSS px for AA; that larger target is associated with a stronger criterion.

## 10. Pointer and gestures

Check:

- complex pointer gestures have simpler alternatives when required;
- drag-based actions have a non-drag alternative unless drag is essential;
- pointer-down does not trigger dangerous irreversible actions prematurely;
- functionality is not mouse-only.

Examples:

- sortable list should offer buttons/menu/keyboard alternative when appropriate;
- swipe-only action should have a visible alternative.

## 11. Forms and input assistance

Check:

- labels;
- instructions;
- required fields;
- input purpose;
- error identification;
- error suggestions where possible;
- error association;
- preserved data;
- consistent help;
- repeated data is not unnecessarily requested again when it could be reused and WCAG conditions apply.

## 12. Accessible authentication

Authentication must not unnecessarily require a cognitive function test without an allowed alternative/mechanism.

Inspect:

- paste is allowed in password/code fields;
- password managers can function;
- challenge flows have accessible alternatives where required;
- one-time-code workflows are operable.

Do not block password paste.

## 13. Status messages and dynamic updates

Check:

- async validation;
- save status;
- loading state;
- search result updates;
- toasts;
- progress;
- background operations;
- errors.

Where appropriate, status changes should be exposed programmatically without unexpectedly moving focus.

## 14. Content on hover/focus

If content appears on hover or focus:

- user can dismiss it when required;
- it remains available while interacting with it when necessary;
- it does not vanish before users can perceive/use it.

Do not make critical information hover-only.

## 15. Orientation and input

Do not unnecessarily lock orientation.

Do not restrict users to only one available input mechanism unless essential.

## 16. Motion and flashing

Check:

- flashing/seizure risk;
- motion triggered by interaction;
- reduced-motion preference;
- essential vs decorative movement.

## 17. Screen-reader pass

If a real screen reader environment is available, test representative critical flows.

Potential desktop combinations include:

- NVDA;
- JAWS;
- Narrator;
- VoiceOver on Apple platforms.

Check:

- control names;
- states;
- reading order;
- landmarks/headings;
- dialog entry/exit;
- form errors;
- dynamic announcements;
- tables;
- custom widgets.

If no real screen reader is available, state that screen-reader compatibility was **not verified**. Accessibility-tree inspection is useful but not equivalent.

## 18. High contrast / forced colors

When relevant and testable:

- verify focus remains visible;
- status is not color-only;
- essential boundaries/icons survive;
- custom controls remain understandable.

## 19. Useful WCAG 2.2 AA mappings

Use criterion mappings only when confident.

Common examples:

- 1.1.1 Non-text Content
- 1.3.1 Info and Relationships
- 1.3.2 Meaningful Sequence
- 1.3.5 Identify Input Purpose
- 1.4.1 Use of Color
- 1.4.3 Contrast (Minimum)
- 1.4.4 Resize Text
- 1.4.10 Reflow
- 1.4.11 Non-text Contrast
- 1.4.12 Text Spacing
- 1.4.13 Content on Hover or Focus
- 2.1.1 Keyboard
- 2.1.2 No Keyboard Trap
- 2.4.1 Bypass Blocks
- 2.4.2 Page Titled
- 2.4.3 Focus Order
- 2.4.4 Link Purpose (In Context)
- 2.4.6 Headings and Labels
- 2.4.7 Focus Visible
- 2.4.11 Focus Not Obscured (Minimum)
- 2.5.1 Pointer Gestures
- 2.5.2 Pointer Cancellation
- 2.5.3 Label in Name
- 2.5.4 Motion Actuation
- 2.5.7 Dragging Movements
- 2.5.8 Target Size (Minimum)
- 3.1.1 Language of Page
- 3.1.2 Language of Parts
- 3.2.3 Consistent Navigation
- 3.2.4 Consistent Identification
- 3.2.6 Consistent Help
- 3.3.1 Error Identification
- 3.3.2 Labels or Instructions
- 3.3.3 Error Suggestion
- 3.3.4 Error Prevention (Legal, Financial, Data)
- 3.3.7 Redundant Entry
- 3.3.8 Accessible Authentication (Minimum)
- 4.1.2 Name, Role, Value
- 4.1.3 Status Messages

Note: WCAG 2.2 removed 4.1.1 Parsing. Do not report it as a WCAG 2.2 success criterion.

## Reporting language

Prefer:

> Confirmed failure of WCAG 2.2 SC 2.4.7 in the tested dialog because keyboard focus has no visible indicator.

or:

> No failure was observed for this tested scenario.

Avoid:

> The site is WCAG compliant.

unless a complete conformance evaluation with proper scope has actually been performed.
