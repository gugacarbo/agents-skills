# Visual Design and Aesthetic Quality

Review visual craft as a functional part of the product. Separate objective clarity/consistency issues from subjective taste.

## 1. Conceptual direction

Ask:

- Does the visual language fit the product, audience, and task?
- Is the interface intentionally minimal, dense, editorial, playful, industrial, luxurious, technical, etc.?
- Is that direction coherent across screens?

For creative or brand-forward products, flag generic, context-free visual choices when they undermine differentiation.

For enterprise/internal tools, do not demand novelty for its own sake.

## 2. Hierarchy

Check whether:

- page purpose is immediately clear;
- title and primary task dominate appropriately;
- primary actions are visually clear;
- secondary actions are quieter;
- statuses have appropriate emphasis;
- important data is scannable.

Flag emphasis that does not match importance.

## 3. Typography

Inspect:

- font family roles;
- size scale;
- weight scale;
- line-height;
- readable line length;
- heading/body distinction;
- numeric alignment;
- truncation and wrapping;
- localization expansion.

For brand-forward work, typography should feel intentional rather than like an unconsidered default.

Do not ban a common font simply because it is common. Judge whether the typography supports the product and design system.

## 4. Color and theme

Check:

- coherent palette;
- semantic color roles;
- appropriate contrast;
- stable meaning of success/warning/error/info;
- accent color not overused;
- dark theme is intentionally designed;
- design tokens/CSS variables when a token system exists.

Avoid using raw color differences as the only status cue.

## 5. Spatial composition

Inspect:

- grid;
- alignment;
- spacing rhythm;
- visual grouping;
- whitespace;
- density;
- container widths;
- balance;
- intentional asymmetry where part of the design direction.

Minimal interfaces require precise spacing and typography. Rich/maximal interfaces require disciplined layering rather than random decoration.

## 6. Components and surfaces

Check visual consistency of:

- buttons;
- inputs;
- cards;
- tables;
- dialogs;
- menus;
- tabs;
- badges;
- alerts;
- toasts;
- navigation;
- pagination.

Differences should correspond to semantic or interaction differences.

## 7. Iconography

Check:

- one coherent icon family or intentional combinations;
- consistent stroke/weight;
- consistent optical sizing;
- clear meaning;
- labels/tooltips for ambiguous actions where needed;
- accessible names for icon-only controls.

## 8. Motion as visual craft

Motion should:

- communicate cause/effect;
- orient users;
- reinforce hierarchy;
- feel coordinated.

Prefer a few intentional transitions over many unrelated animations.

Review motion accessibility separately in `interaction-states.md`.

## 9. Backgrounds and decorative detail

For expressive designs, evaluate whether:

- gradients;
- textures;
- layered transparency;
- illustration;
- shadows;
- patterns;
- depth

support the product's concept rather than merely decorate it.

Do not recommend decorative complexity for products where clarity and speed are the primary values.

## 10. Generic-interface warning signs

Treat these as aesthetic opportunities, not automatic defects:

- repetitive card grids without information hierarchy;
- arbitrary gradients;
- excessive rounded containers;
- generic “dashboard” composition unrelated to tasks;
- visual effects copied across unrelated contexts;
- decorative motion with no interaction purpose.

Only escalate when the lack of direction materially reduces clarity, trust, brand fit, or product quality.

## 11. Visual fidelity to design specs

When Figma or another source of truth exists:

- compare spacing;
- typography;
- color roles;
- dimensions;
- variants;
- states;
- responsive intent;
- icon treatment.

Distinguish:

- deliberate approved deviation;
- implementation drift;
- missing design-system capability.
