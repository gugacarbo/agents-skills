# Static Web Interface Code Review Rules

Use when frontend source code is available. These checks consolidate common implementation-level interface quality rules.

Report code findings with precise locations when possible.

## A. Semantics and accessibility

Check for:

- icon-only controls without accessible names;
- controls without labels;
- action behavior implemented with generic clickable elements instead of buttons;
- navigation implemented without links;
- custom controls without keyboard behavior;
- meaningful images without alternatives;
- decorative icons/images exposed unnecessarily;
- asynchronous status/error changes that need programmatic announcement;
- missing semantic tables/lists/headings/landmarks;
- heading order that does not reflect structure;
- repeated navigation without a practical bypass mechanism where needed;
- anchor destinations hidden under sticky headers;
- media without required accessible alternatives or keyboard-operable controls.

Important nuance:
Native buttons/links already provide keyboard activation; do not demand redundant key handlers on them.
Custom widgets need the expected keyboard model.

## B. Focus

Check for:

- focus outline removed without replacement;
- no visible focus;
- focus styling that is barely perceptible;
- fixed/sticky content fully hiding focused controls;
- compound controls that need group focus treatment;
- inconsistent focus across themes.

## C. Forms

Check for:

- missing `name`;
- missing/useful autocomplete;
- incorrect input type/inputmode;
- blocked paste;
- label not associated/clickable;
- inappropriate spellcheck/autocorrect on codes/emails/usernames;
- checkbox/radio label dead zones;
- duplicate submission risk;
- missing pending feedback;
- error far from the field;
- missing error association;
- no focus/error-summary strategy;
- unsaved changes discarded silently;
- placeholder used as label;
- authentication fields hostile to password managers.

## D. Motion

Check for:

- no reduced-motion handling;
- broad `transition: all`;
- animation of expensive layout properties without reason;
- wrong transform origin;
- SVG transforms that behave inconsistently;
- non-interruptible long transitions;
- decorative loops that cannot be reduced/stopped;
- long auto-moving content without controls where required.

## E. Typography and content

Check for:

- inconsistent punctuation/status copy;
- number columns with poor numeric alignment when comparisons matter;
- heading widows/awkward wrapping where easy to improve;
- technical/internal error language;
- vague action labels;
- terminology drift.

Treat editorial conventions as project-style checks rather than universal defects.

## F. Content robustness

Check:

- long strings;
- user-generated content;
- empty arrays/strings;
- `min-width` behavior inside flex/grid;
- truncation with no access to full value;
- overflow caused by IDs/URLs/filenames;
- missing zero-results state.

## G. Images/media

Check:

- images without dimensions/aspect ratio;
- non-critical below-fold images loading eagerly;
- critical hero images deprioritized;
- huge animated GIFs where video/still is a better fit;
- decorative motion ignoring reduced-motion.

## H. Performance risks

Check:

- massive non-virtualized DOM when actual size makes it expensive;
- synchronous layout reads during render;
- repeated DOM read/write thrashing;
- expensive controlled-input rerenders;
- overuse/misuse of preconnect/preload;
- web fonts with poor loading strategy.

Use measurement/context. Do not flag merely because a list has more than an arbitrary number of items.

## I. Navigation and URL state

Check:

- links replaced by onclick navigation;
- filters/tabs/pagination that should be shareable/restorable but exist only in transient component state;
- browser back not restoring meaningful state;
- inability to deep-link important UI states;
- destructive navigation/action with no confirmation/undo.

Not every accordion or ephemeral tooltip belongs in the URL. Use user value and shareability as criteria.

## J. Touch and gestures

Check:

- essential hover-only controls;
- gesture-only actions;
- drag-only operation;
- accidental text selection during drag;
- scroll chaining through modal sheets;
- tiny/tightly packed hit targets;
- autofocus causing disruptive mobile keyboard;
- browser gestures/zoom disabled without necessity.

## K. Safe areas and layout

Check:

- full-bleed fixed UI ignoring safe-area insets;
- overflow hidden masking layout bugs;
- JS layout measurement where CSS can express the layout;
- viewport-height issues on mobile;
- fixed footers covering content/focus.

## L. Themes

Check:

- dark theme without correct browser `color-scheme`;
- native controls unreadable in dark mode;
- theme-color inconsistent with surface;
- semantic tokens missing;
- focus/contrast broken in dark/high-contrast modes.

## M. Localization

Check:

- hard-coded date/time formats;
- hard-coded currency/number formatting;
- IP-only language detection;
- identifiers/brand/code accidentally auto-translated;
- text expansion not handled;
- RTL assumptions if RTL is supported.

Prefer locale APIs such as `Intl` where appropriate.

## N. Hydration and controlled inputs

Check:

- input has a controlled value without a matching update path;
- server/client date/time/locale mismatches;
- random/browser-only values rendered differently on server;
- suppression of hydration warnings used without understanding the mismatch.

## O. Hover and state feedback

Check:

- no hover feedback where pointer hover is available;
- active/focus less visible than resting state;
- clickable surface has no interaction affordance;
- disabled state indistinguishable or misleading.

## P. High-signal anti-pattern scan

Flag with context:

- user zoom disabled;
- paste intentionally prevented;
- generic clickable `div`/`span` for standard control behavior;
- navigation performed by non-link click handlers;
- focus outline removed without replacement;
- broad all-property transitions;
- images missing dimensions;
- form controls without persistent labels;
- icon-only buttons without accessible names;
- hard-coded locale formatting;
- unjustified autofocus;
- gesture-only operations;
- huge decorative GIFs where a smaller medium is suitable;
- source-level duplicated components/tokens that cause UI drift.

Do not merely list rules. Explain the runtime/user consequence for anything Major or above.
