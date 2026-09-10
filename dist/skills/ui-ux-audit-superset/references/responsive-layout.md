# Responsive Layout, Safe Areas and Themes

## 1. Viewport coverage

If no product matrix exists, test:
- ~320–375 px;
- ~390–430 px;
- ~768–1024 px;
- ~1280 px;
- ~1440+ px.

Also test around actual breakpoint transitions.

## 2. Reflow

Look for:
- accidental horizontal page scrolling;
- clipped content;
- overlapping labels/actions;
- fixed-width forms;
- dialogs wider/taller than viewport;
- hidden primary actions;
- unreadable columns;
- broken sticky positioning.

Do not “solve” overflow by blindly hiding it. Fix the content/layout cause.

## 3. Layout implementation

Prefer CSS layout primitives such as flex/grid/container queries where they express the design.

Avoid JavaScript measurement for ordinary layout when CSS can solve it more robustly.

## 4. Flex/grid text behavior

Common implementation issue:
- flexible children refuse to shrink because minimum width constraints are not handled.

Inspect long labels, filenames, URLs, IDs, and localized text.

## 5. Tables

A mobile strategy may be:
- intentional horizontal scroll;
- column prioritization;
- responsive cards;
- detail drill-down;
- sticky key columns.

No one strategy is universally correct.

Verify:
- headers remain understandable;
- actions remain reachable;
- selection/sort/filter semantics survive;
- important data is not silently removed.

## 6. Full-bleed and safe areas

For mobile/full-screen layouts:
- account for display cutouts/home indicators when necessary;
- fixed bottom bars should not collide with safe areas;
- content should remain reachable.

## 7. Fixed and sticky UI

Inspect:
- header height;
- footer/action bars;
- keyboard focus visibility;
- mobile viewport height;
- virtual keyboard;
- nested scrolling.

## 8. Navigation adaptation

Mobile navigation should preserve the product's mental model.

Check:
- key destinations remain reachable;
- selected section remains clear;
- primary actions do not disappear;
- overflow menu does not absorb frequent tasks without reason.

## 9. Dark mode

If dark theme exists:
- set appropriate browser color-scheme behavior;
- verify native controls;
- verify select menus on major platforms;
- check contrast and elevation;
- avoid simply inverting colors;
- theme-color metadata should match intended browser chrome where relevant.

## 10. High contrast / forced colors

When relevant:
- ensure borders/focus/statuses survive;
- custom controls remain visible;
- icons do not disappear;
- selected/current states remain understandable.

## 11. Orientation

Do not unnecessarily require one orientation.

Test orientation changes for mobile/tablet products where landscape use is plausible.

## 12. Zoom and text scaling

Check at increased zoom/text size:
- navigation remains operable;
- dialogs can be completed;
- sticky regions do not consume most of the viewport;
- controls do not overlap;
- content is not clipped.

## 13. Intermediate and awkward sizes

Canonical device widths are not enough.

Specifically inspect:
- just before/after navigation collapse;
- just before/after multi-column forms collapse;
- table-to-mobile transitions;
- dialog width caps;
- long translated labels at breakpoints.
