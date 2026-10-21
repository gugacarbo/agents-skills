# Visual Critique

Evaluate the rendered UI with the critique framework: look at the interface as a person sees it, then explain findings through code. Use this in every Mode 1 (Design Review) where visual evidence is available — and proactively try to obtain that evidence.

## Evidence Capture (try in this order)

1. **Live app or URL + browser automation** (preferred): navigate with Playwright (or the available browser tools) and screenshot:
   - the primary route/view of the reviewed scope;
   - one desktop and one mobile width (add intermediate widths near actual breakpoints when relevant);
   - key states that are safe to reach (hover/focus where feasible; empty/error when safely reproducible);
   - light and dark theme when both exist.
2. **Locally runnable app**: start the dev server when the repo makes it cheap and safe, then capture as above.
3. **User-supplied screenshots or prints**: ask for or use attached captures when there is no runnable target.
4. **Figma link**: pull the design as the intended visual reference and compare against the rendered UI.

When none of these is available, review the code and clearly label the visual assessment as **code-only inference** — never present it as runtime-verified.

Rules:

- Never interact destructively with a live target; prefer read-only navigation on test/staging URLs.
- Capture the minimum evidence needed; do not copy secrets or personal data into the report.
- Record what could not be captured (viewport, theme, state) as **Not verified**.

## Critique Framework

Apply each dimension to the captured/rendered UI:

### 1. First Impression (2 seconds)

- What draws the eye first? Is that correct?
- What's the emotional reaction?
- Is the purpose immediately clear?

### 2. Usability

- Can the user accomplish their goal?
- Is the navigation intuitive?
- Are interactive elements obvious?
- Are there unnecessary steps?

### 3. Visual Hierarchy

- Is there a clear reading order?
- Are the right elements emphasized?
- Is whitespace used effectively?
- Is typography creating the right hierarchy?

### 4. Consistency

- Does it follow the design system?
- Are spacing, colors, and typography consistent?
- Do similar elements behave similarly?

### 5. Accessibility (quick pass)

- Color contrast ratios
- Touch target sizes
- Text readability
- Alternative text for images

For a dedicated deep dive, use the Accessibility Audit modifier instead.

## Feedback Principles

- **Be specific**: "The CTA competes with the navigation" not "the layout is confusing"
- **Explain why**: connect feedback to design principles or user needs
- **Suggest alternatives**: don't just identify problems, propose solutions
- **Acknowledge what works**: good feedback includes positive observations
- **Match the stage**: early exploration gets direction feedback; refinement gets consistency feedback; final polish gets detail feedback

## Merging with Code Findings

- Anchor every visual finding in evidence: describe what the capture shows and point to the code location that explains it.
- Prefer root-cause findings that join both views (e.g., "CTA blends into the nav: both use `--color-primary` at the same visual weight — `Header.tsx:42`").
- Merge duplicate visual symptoms into one finding against the shared component/token.
- Keep strengths listed so remediation does not accidentally degrade them.
