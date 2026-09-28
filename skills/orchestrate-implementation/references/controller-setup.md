# Controller Setup and Approval

Load this reference when starting an orchestrated plan. The main `SKILL.md`
contains the dispatch and validation invariants.

## Isolate and Recover

- Work from an isolated integration worktree. Use `using-git-worktrees` to
  create or verify it; never implement on `main` or `master` without explicit
  consent.
- Run `scripts/plan-workspace PLAN_FILE` and keep this plan's ledger, briefs,
  reports, and review packages in its returned directory.
- Check `progress.md`. If its identity names this plan, completed tasks stay
  complete; resume at the first unfinished task. A final fix-round entry means
  resume the correction loop. Leave other plans' ledgers and directories alone.
- Create the ledger with `# Implementation ledger — plan: <plan file path>` as
  its first line. Treat it and `git log` as the recovery record after context
  compaction. Never use `git clean -fdx` on the workspace.
- The ledger is the required task-status source. UI todos are optional.

## Review the Plan

Read the plan once and its reachable Spec if named. The Spec is authoritative
when the plan conflicts with it. Record the plan's Global Constraints and
validation commands. If no Spec is reachable, record that fact; rulings without
one are provisional.

Before the approval gate, check that task boundaries are executable, declared
dependencies and ordering are clear, and the plan does not contradict its Spec
or Global Constraints. Record only paths and side effects the plan names. Do
not estimate indirect writes such as generated files, formatter outputs,
lockfiles, schemas, or migrations during this pass. Configure tasks to run
sequentially by default; potential parallel waves are conditional on the
post-gate check in `controller-task-loop.md`.

If an unclear requirement makes implementation a guess, record it and stop
under the main skill's stop conditions. Unknown write scope alone does not
block approval; start the task sequentially and resolve its scope at dispatch.

## Model Policy

Choose the least powerful model that can do each role well: cheap for mechanical
implementation, standard for integration and prose-based implementation, and
the most capable available model for architecture and the final whole-branch
review. Scale task reviewers to risk. Scoped re-reviews can use a cheaper model.

Before any agent dispatch, the approved configuration must name a concrete
user-approved model for that role. Never omit `model:` or use `model: inherit`.
Use a default mapping by role for tasks of similar complexity and list only
task-specific exceptions. The second fix round uses a fresh implementer on a
model at least one tier above the original implementer. Include that escalation
model in the approved mapping. A changed or unavailable model requires explicit
approval of the revised configuration before dispatch.

## Configuration Gate

Create an `Implementation configuration` section in the ledger immediately
after its identity line. Record its status, approval time, and revision, then
complete these fields:

```markdown
### Scope and validation

- PLAN_FILE: <absolute path>
- SPEC_FILE: <absolute path | none reachable>
- GLOBAL_CONSTRAINTS: <verbatim constraints or none>
- INTEGRATION_WORKTREE: <absolute path>
- INTEGRATION_BRANCH: <branch>
- MERGE_BASE: <SHA | pending>
- VALIDATION_COMMANDS: <commands>

### Planned execution and models

| Tasks        | Dependencies / declared scope | Mode                                        | Role-to-model mapping          | Exceptions  |
| ------------ | ----------------------------- | ------------------------------------------- | ------------------------------ | ----------- |
| <N>          | <plan-stated facts only>      | sequential by default; conditional parallel | <explicit model per role>      | <overrides> |
| Final branch | <whole branch>                | sequential                                  | <reviewer, fixer, re-reviewer> | <rationale> |
```

List every task, grouping only tasks with the same execution mode and model
mapping. Record exact model names. Approving the conditional parallel policy
does not waive its later eligibility check.

The initial approval summary should name the ledger path and revision, scope,
validation commands, sequential default, conditional parallel policy, model
mapping, and exceptions. Keep detailed variables in the ledger rather than
repeating them in the message. Wait for explicit approval before dispatching
any implementer, reviewer, or fixer.

## Ledger Records

Record stable plan values and the approved role-to-model mapping once. Use
append-only run records for dispatches and review boundaries; do not copy the
same values into a mutable Variables table before every dispatch.

```markdown
## Dispatches

| Task | Agent | Model | Brief / report | Worktree / branch | Write set | Base |
| ---- | ----- | ----- | -------------- | ----------------- | --------- | ---- |

## Boundaries

| Task / event | Base | Head | Diff package | Findings / round | Integration mapping |
| ------------ | ---- | ---- | ------------ | ---------------- | ------------------- |
```

Each dispatch row records exact values used, including absolute brief/report
paths and either the approved parallel write set or `not restricted`. Add
integration, fix-base, review-head, findings, diff-package, and round values
when they are allocated. Revisions to the approved config must remain visible
in the ledger; never replace an approval silently.
