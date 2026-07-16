# Phase 0: Issue Context

Use this phase only for `/code-toolbox issue` and `/code-toolbox batch`.

## Validate before dispatch

1. Confirm that each target is an existing delivery/bug issue, not an umbrella, audit, or tracking issue. This eligibility check comes before any label repair.
2. If it is ineligible, explain that it is outside this delivery flow and stop without adding, removing, or replacing labels.
3. Read an eligible issue's body, labels, linked PRs, and prior eight-field evidence, plan, and review comments.
4. List every `stage:*` label. Exactly one stage from `references/github-flow.md` is required for a resumable eligible issue; `needs-human` is orthogonal.
5. Resolve the repository default branch and inspect linked ADR/spec paths at their recorded commits.
6. For batch, retain an ephemeral per-issue dispatch view: issue URL, current stage, active plan cycle, source links, blockers, and next phase. Do not write a state file or registry.

## Drift handling

For an eligible issue only, apply `stage:blocked` plus `needs-human` and stop the affected issue when any of these is true:

- zero or multiple `stage:*` labels;
- a plan/review comment or required evidence envelope conflicts with the stage or has no identifiable cycle/scope;
- `stage:approved` lacks a literal approving review for the current plan snapshot;
- `stage:in-progress` has `BLOCKED` evidence or evidence for a task outside the current plan;
- `stage:needs-task-review` lacks non-blocked evidence for any planned task.

Never repair drift by inferring approval from history, a PR, or an implementer claim. Do not apply a delivery stage as a shortcut for an ineligible issue. A blocked issue does not stop unrelated batch issues.
