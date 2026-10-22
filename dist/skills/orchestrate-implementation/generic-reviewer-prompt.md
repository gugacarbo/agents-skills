# Generic Reviewer Fallback Prompt

Use this only when `orchestrate-review` is unavailable. It is intentionally
small: the orchestration skill owns flow, not a full review framework.

```text
Subagent:
  description: "Review <UNIT_OR_FINAL_SCOPE>"
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
    - maintainability problems that should block completion;
    - for final review, cross-unit integration and architectural regressions.

    Treat implementation reports as claims, not proof. Inspect the actual diff
    and relevant surrounding code when needed.

    Classify every finding as exactly one of:
    - material: completion must wait for a fix;
    - non-blocking: useful observation that does not block completion.

    Give file/line evidence when possible.

    Output:
    Verdict: PASS | CHANGES_REQUIRED
    Material findings:
    - <finding or none>
    Non-blocking findings:
    - <finding or none>
```

The reviewer is read-only. Reviewers never implement fixes and never spawn
other agents.
