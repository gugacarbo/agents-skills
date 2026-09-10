# Perceived Performance and Web Quality

This is a UI/UX audit module, not a full performance-engineering benchmark.

## 1. Perceived responsiveness

Check:
- button/input feedback appears quickly;
- navigation does not look frozen;
- long operations communicate progress;
- stale content is not confused with current data;
- UI is not enabled before it can function.

## 2. Layout stability

Look for:
- image-induced layout shifts;
- fonts causing severe reflow;
- skeleton mismatch;
- late banners;
- content jumping during fetches.

## 3. Images

For normal image elements:
- provide intrinsic dimensions/aspect ratio to reduce layout shift;
- lazy-load below-fold images when appropriate;
- prioritize truly critical above-fold imagery.

Do not lazy-load the main LCP image blindly.

## 4. Animated media

For decorative looping imagery:
- compressed video is often more efficient than a large GIF;
- provide a still/reduced-motion alternative where appropriate;
- avoid autoplay behavior that harms accessibility or data usage.

## 5. Large collections

For very large rendered lists/tables:
- inspect actual DOM/rendering cost;
- consider virtualization or `content-visibility` when measurement shows value;
- do not apply a fixed item-count threshold as a universal rule.

Check whether virtualization harms:
- accessibility;
- browser find;
- print/export;
- focus retention.

## 6. Render-path implementation risks

Avoid layout measurement in the render path when it causes synchronous layout work.

When measuring:
- batch reads/writes where possible;
- avoid repeated read/write interleaving;
- prefer CSS layout when feasible.

## 7. Input performance

Controlled inputs are fine when inexpensive.

Flag:
- expensive recomputation on each keystroke;
- whole-page rerender;
- network calls without debounce/cancellation where inappropriate;
- lag that users can feel.

## 8. Connection hints

Preconnect/preload can help critical cross-origin assets/fonts, but they consume resources.

Use them intentionally, not automatically.

## 9. Fonts

For critical web fonts:
- avoid invisible text for long periods;
- use an appropriate `font-display` strategy;
- preload only genuinely critical font resources;
- minimize unnecessary variants.

## 10. Loading architecture

Check:
- route-level blocking vs local loading;
- repeated refetch flashes;
- optimistic updates with rollback;
- background refresh that resets scroll or selection;
- skeletons that preserve layout.

## 11. Hydration and SSR

Look for server/client mismatch risks:
- locale/time-dependent rendering;
- random values;
- browser-only data;
- controlled vs uncontrolled input differences.

Do not use hydration-warning suppression as a generic fix.

If suppression is present, verify that the mismatch is understood and intentional.

## 12. Browser-visible metadata

Where applicable inspect:
- theme-color;
- color-scheme;
- viewport configuration;
- PWA/fullscreen behavior;
- safe areas.

Never disable user zoom with viewport settings.

## 13. Core Web Vitals

If performance tooling is available, use metrics as supporting evidence.

Do not convert a Lighthouse score directly into a UX severity without observing the affected experience.

Differentiate:
- measured performance issue;
- observed perceived-performance issue;
- potential implementation risk.
