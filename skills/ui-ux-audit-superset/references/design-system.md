# Design-System Compliance

Use this module when a component library, Storybook, Figma library, token system, registry, or documented UI standard exists.

## 1. Establish the source of truth

Identify:

- Figma library;
- Dev Mode specs;
- Storybook;
- component documentation;
- package/registry;
- theme/token files;
- brand rules.

If sources disagree, record the conflict rather than guessing which is canonical.

## 2. Component reuse

For each reviewed pattern:

1. check whether a canonical component exists;
2. verify the implementation uses it when appropriate;
3. verify correct variant/size/state;
4. inspect custom wrappers that fork behavior;
5. identify duplicated one-off implementations.

Do not force a canonical component when it cannot meet the product requirement.

## 3. Tokens

Inspect use of:

- color;
- typography;
- spacing;
- radius;
- border;
- shadow/elevation;
- z-index;
- motion;
- breakpoints where tokenized.

Flag repeated raw values that bypass an existing semantic token system.

A single hard-coded value is not automatically a Major issue. Consider intent, repetition, and whether a token exists.

## 4. Semantic tokens

Prefer semantic concepts such as:

- surface;
- foreground;
- muted;
- primary;
- danger;
- warning;
- success;
- focus;
- border;
- selected;

over component-specific raw colors when the design system supports them.

## 5. Variants and states

Compare:

- default;
- hover;
- focus;
- active;
- selected;
- disabled;
- loading;
- error;
- success;
- destructive;
- dark theme;
- high contrast where relevant.

Look for a component that visually matches but behaves differently from the canonical version.

## 6. Figma alignment

When Figma Dev Mode/specs are available, compare:

- spacing;
- measurements;
- typography;
- component properties;
- tokens;
- variants;
- responsive rules.

Do not rely on visual approximation when exact specs are available.

## 7. Exceptions

When implementation deviates from the system:

- determine whether the deviation is intentional;
- identify why the existing system cannot express the requirement;
- recommend documenting the exception;
- if repeated, recommend promoting it into the design system.

## 8. Missing component workflow

If no canonical component exists:

1. check whether an existing primitive can be composed safely;
2. avoid inventing a new one-off pattern when reuse is possible;
3. if genuinely new, define the required states/accessibility/responsive behavior;
4. recommend adding documentation/tests if the pattern becomes shared.

## 9. Drift detection

Look for:

- multiple “primary button” implementations;
- parallel form controls;
- competing modal components;
- inconsistent badge semantics;
- local CSS overrides;
- duplicate icon families;
- copied token values;
- route-specific spacing scales.

Report the root system drift once with representative affected surfaces.

## 10. Design-system accessibility

Verify canonical components actually provide:

- correct semantics;
- keyboard support;
- focus-visible treatment;
- disabled/read-only semantics;
- accessible names/descriptions;
- ARIA only when necessary;
- appropriate announcements for dynamic states.

A design-system component being “official” does not prove it is accessible.
