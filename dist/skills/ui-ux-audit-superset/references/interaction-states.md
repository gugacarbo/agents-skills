# Interaction, Focus, States, Touch and Motion

## 1. Native semantics first

Use:
- button for actions;
- link for navigation;
- native input/select/textarea when suitable.

Avoid click handlers on generic `div`/`span` when a native interactive element fits.

Custom interactive elements must reproduce appropriate keyboard, focus, name/role/state, and pointer behavior.

## 2. Focus-visible

Every keyboard-operable interactive element needs a perceivable focus indicator.

Avoid removing outlines without a clear replacement.

Prefer focus treatment that appears for keyboard-style focus rather than adding distracting rings to every pointer click when platform behavior supports the distinction.

Use focus-within treatment when a compound control needs a group-level focus affordance.

Ensure sticky/fixed overlays do not hide focused controls.

## 3. Hover, active, selected

Interactive controls should provide understandable state feedback.

Check:
- hover when hover is available;
- active/pressed;
- selected/current;
- disabled;
- loading.

Do not make hover the only way to discover essential actions on touch devices.

State contrast should generally become clearer, not more ambiguous.

## 4. Dialogs and drawers

Check:
- clear trigger;
- useful title;
- focus enters appropriately;
- focus remains constrained for true modal dialogs;
- Escape/close behavior;
- focus returns appropriately;
- background interaction is prevented when modal;
- content remains usable at short heights/narrow widths;
- scroll is contained intentionally;
- nested modals avoided where possible.

## 5. Popovers, menus, tooltips

Check:
- keyboard operation;
- dismissal;
- focus behavior;
- hover/focus persistence;
- placement does not cover the trigger/focus unexpectedly;
- tooltips are not the only source of essential instructions.

## 6. Destructive interactions

Never make a high-risk destructive action fire immediately if a reasonable confirmation or undo is needed.

Use proportional friction:
- low-risk reversible: undo may be enough;
- high-risk irreversible: clear confirmation;
- very high-risk: stronger verification may be justified.

Confirmation copy should name the consequence and affected object.

## 7. Touch

Inspect:
- target size and spacing;
- accidental activation risk;
- gesture alternatives;
- hit areas;
- visual feedback.

`touch-action` behavior may be tuned to improve responsiveness, but never use it to disable essential browser zoom/gestures without justification.

Set tap highlight behavior intentionally if customizing it.

## 8. Drag and gesture interactions

During custom drag:
- avoid accidental text selection;
- prevent unrelated interactive descendants from firing;
- make dragged state understandable;
- provide non-drag alternatives when accessibility requires them.

Do not make swipe/pinch/path gestures the only way to perform an action unless essential.

## 9. Autofocus

Use autofocus sparingly.

Good candidates:
- one obvious desktop task with a single primary input.

Risks:
- mobile keyboard opens unexpectedly;
- screen-reader context is skipped;
- focus steals control from users.

Avoid autofocus without clear task justification.

## 10. Loading and pending

Check:
- immediate acknowledgment;
- localized loading instead of blocking the entire app unnecessarily;
- no duplicate activation;
- progress for long operations;
- skeleton resembles final layout;
- layout does not jump excessively.

## 11. Empty states

Distinguish:
- no data exists yet;
- filters returned zero results;
- permission prevents visibility;
- network failed.

A useful empty state answers:
- what happened;
- whether it is expected;
- what the user can do next.

## 12. Errors and warnings

Differentiate:
- validation;
- transient network failure;
- permission failure;
- not found;
- conflict;
- expired session;
- server failure.

Provide recovery when possible.

## 13. Success states

Success should:
- be visible long enough;
- not rely solely on a disappearing toast for critical confirmation;
- update the underlying UI so users can see the result.

## 14. Motion

Honor reduced-motion preferences.

Prefer animations that are easy for the browser to render, commonly transform/opacity, unless another property is necessary.

Avoid broad “animate everything” transitions. Declare intended properties.

Ensure:
- transform origin matches the visual behavior;
- SVG transform behavior is predictable;
- animation can be interrupted by user input;
- decorative looping motion can be reduced/stopped;
- long auto-moving content has controls when accessibility requirements apply.

Motion should communicate relationships, not delay the task.

## 15. Scroll behavior

Check:
- modal/drawer overscroll does not leak into the page;
- anchor targets are not hidden under sticky headers;
- focus/scroll changes do not unexpectedly throw users around;
- programmatic scrolling respects reduced-motion when animated.

## 16. State completeness

For reusable components inspect as applicable:
- default;
- hover;
- focus;
- active;
- selected;
- disabled;
- read-only;
- loading;
- error;
- success;
- destructive;
- dark theme;
- high contrast.
