# Implementer Subagent Prompt Template

Use this template for implementation units and correction work. The controller
fills every placeholder before dispatch.

```text
Subagent:
  description: "Implement <UNIT_ID>: <OBJECTIVE>"
  model: <IMPLEMENT_MODEL>
  effort: <IMPLEMENT_EFFORT>
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

    Fix only the listed material findings. Do not apply non-blocking
    suggestions.

    Report:
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created (SHA + subject)
    - Files changed
    - Validations run: exact command, exit status, and relevant result line
      for each (the controller relies on this instead of re-running them)
    - Concise implementation summary
    - Remaining concerns/blockers

    If requirements are materially ambiguous, scope must expand, or a safe
    implementation path is unavailable, stop and report rather than guessing.
```

## Deferred-findings consolidation

Use once at the end of the run when the deferred-findings log is not empty.

```text
Subagent:
  description: "Consolidate deferred findings"
  model: <IMPLEMENT_MODEL>
  effort: <IMPLEMENT_EFFORT>
  prompt: |
    Consolidate findings that were deliberately not fixed during this run.
    Work read-only: do not modify code, do not commit, and do not spawn
    subagents.

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

    Final head:
    <HEAD_SHA>

    Deferred findings:
    <DEFERRED_FINDINGS>

    For each finding, check it against the final head and drop it if it is
    resolved or no longer applies. Merge duplicates. Group the rest by area or
    category.

    Report:
    - Dropped: <count and one-line reason each>
    - Groups:
      - <group name>
        - <file:line> — <summary>
        - Suggested next step: open an issue | ignore
```

The controller must never fill `<IMPLEMENT_MODEL>` or `<IMPLEMENT_EFFORT>` with
`auto`, `inherit`, an omitted value, or an unapproved model.
Use `n/a` for `<IMPLEMENT_EFFORT>` only when the harness has no effort control.
