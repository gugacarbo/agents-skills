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

    Workspace:
    <WORKTREE>

    Execution boundaries:
    - Use only tools exposed and authorized for this subagent role. Do not call
      controller-only planning, lifecycle or completion tools (for example,
      update_plan or wrap_up). Return progress, a local plan if useful, and the
      final result as ordinary messages to the controller instead.
    - Run commands in the assigned Workspace using the tool's working-directory
      parameter. Verify the effective directory/repository before Git or writes;
      do not assume a directory change persists between tool calls. If the harness
      lacks that parameter, use its supported directory selection and verify it.
    - Run one simple Git command per invocation from that directory. Avoid shell
      chains, wrappers, directory overrides such as git -C, and compound commands
      that obscure the target. Read-only roles must not mutate Git state or files.
    - A denied or unavailable operation is a boundary, not a retry strategy.
      Do not bypass guards, rewrite commands to evade them, or request broader
      privileges. Report the denied operation and blocker to the controller.

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

    Unit ranges and prior review status (for final review):
    <UNIT_RANGES_AND_REVIEW_STATUS_OR_NONE>
    Fully review deferred-to-final units. For passed units, check cross-unit
    integration without repeating individual review unless new evidence points
    to a material defect.

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

    Do not block on speculative issues or preferences. Zero findings is valid.
    Do not manufacture optional observations or report style preferences and
    unrelated pre-existing issues. Mention only a few useful non-blocking items.

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
Use `n/a` for `<REVIEW_EFFORT>` only when the harness has no effort control.
