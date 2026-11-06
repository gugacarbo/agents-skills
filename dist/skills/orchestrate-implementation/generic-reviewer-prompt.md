# Generic Reviewer Prompt

The default reviewer for unit and final reviews. Use `orchestrate-review`
instead only when the user explicitly asks for it or for a full code review. It
is intentionally small: the orchestration skill owns flow, not a review
framework.

```text
Subagent:
  description: "Review <UNIT_OR_FINAL_SCOPE>"
  model: <REVIEW_MODEL>
  effort: <REVIEW_EFFORT>
  prompt: |
    Review the supplied implementation read-only. Do not modify code and do not
    spawn subagents.

    Scope:
    <UNIT_OR_FINAL_SCOPE>

    Requirements:
    <REQUIREMENTS>

    Base:
    <BASE_SHA>

    Head:
    <HEAD_SHA>

    Validation evidence:
    <VALIDATION_EVIDENCE>

    For a scoped re-review, also use:
    Previous material findings:
    <PREVIOUS_FINDINGS>

    Fix range:
    <FIX_BASE>..<FIX_HEAD>

    In a scoped re-review, only confirm each previous material finding is
    resolved and check the fix range for new material problems. Do not
    re-review the rest of the scope.

    Review for:
    - correctness and requirement coverage;
    - regressions or unsafe edge cases;
    - materially inadequate or misleading tests;
    - for final review, cross-unit integration and architectural regressions.

    Review changed behavior, not a hypothetical ideal design. Treat
    implementation reports as claims, not proof. Inspect the actual diff and
    relevant surrounding code when needed.

    Classify every finding as exactly one of:
    - material: a correctness, security, or data-integrity defect, or a
      violated requirement/acceptance criterion, introduced or worsened by
      this change;
    - non-blocking: everything else, including style, refactors, alternative
      abstractions, optional improvements, and pre-existing issues this change
      did not worsen.

    Every material finding must include:
    - exact location (file:line);
    - the violated requirement or invariant;
    - a reachable triggering scenario;
    - actual versus expected behavior;
    - the evidence supporting it.

    Do not block on speculative issues or preferences. Do not try to reach a
    report with zero observations.

    Output:
    Verdict: PASS | CHANGES_REQUIRED
    Material findings:
    - <finding or none>
    Non-blocking findings:
    - <file:line> | <category: correctness | tests | maintainability | style | pre-existing> | <summary>
```

The reviewer is read-only. Reviewers never implement fixes and never spawn
other agents. The controller must never fill `<REVIEW_MODEL>` or
`<REVIEW_EFFORT>` with `auto`, `inherit`, an omitted value, or an unapproved
model; use the `task review` model for unit reviews and the `final review`
model for the final review.
