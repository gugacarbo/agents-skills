# Implementer Subagent Prompt Template

Use this template for implementation units and correction work. The controller
fills every placeholder before dispatch.

```text
Subagent:
  description: "Implement <UNIT_ID>: <objective>"
  prompt: |
    Implement this execution unit. Do not work on other units and do not spawn
    subagents.

    Objective:
    <OBJECTIVE>

    Source tasks / requirements:
    <SOURCE_TASKS>

    Context:
    <CONTEXT>

    Relevant files / areas:
    <AREAS>

    Constraints:
    <CONSTRAINTS>

    Acceptance criteria:
    <ACCEPTANCE>

    Focused validation:
    <VALIDATION>

    Workspace:
    <WORKTREE>

    Branch:
    <BRANCH>

    Expected write set:
    <WRITE_SET_OR_UNKNOWN>

    Rules:
    - Confirm the worktree and branch before editing.
    - Stay inside this unit's scope.
    - For a parallel unit, do not intentionally write outside the approved
      write set. If an unexpected required write would make the unit conflict
      with another parallel unit, stop and report NEEDS_CONTEXT.
    - Do not pull, merge, rebase, cherry-pick, switch branches, or touch the
      controller's integration worktree.
    - Follow repository instructions and existing patterns.
    - Run every validation explicitly required for this unit. Prefer focused
      checks; do not run the full repository suite unless required.
    - Diagnose and fix viable validation failures before reporting.
    - Create one or more natural commits for the completed work.
    - Never spawn another agent or reviewer.

    If this is a correction round, also use:
    Findings:
    <FINDINGS>

    Previous attempt/evidence:
    <PREVIOUS_ATTEMPT>

    Report:
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created (SHA + subject)
    - Files changed
    - Validations run and results
    - Concise implementation summary
    - Remaining concerns/blockers

    If requirements are materially ambiguous, scope must expand, or a safe
    implementation path is unavailable, stop and report rather than guessing.
```

The controller must never replace `<APPROVED_CONCRETE_MODEL>` with `auto`,
`inherit`, an omitted model, or an unapproved model.
