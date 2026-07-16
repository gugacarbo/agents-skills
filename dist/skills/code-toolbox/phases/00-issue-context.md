# Phase 0: Issue Context

Use this phase only for `/code-toolbox issue` and `/code-toolbox batch`.

## Validate before dispatch

1. Confirm that each target is an existing delivery/bug issue, not an umbrella or audit.
2. Read its body, labels, linked PRs, and prior plan/review comments.
3. List every `stage:*` label. Exactly one stage from `references/github-flow.md` is required for a resumable issue; `needs-human` is orthogonal.
4. Resolve the repository default branch and inspect linked ADR/spec paths at their recorded commits.
5. For batch, produce one independent state record per issue: issue URL, current stage, active plan cycle, source links, blockers, and next phase.

## Drift handling

Apply `stage:blocked` plus `needs-human` and stop the affected issue when any of these is true:

- zero or multiple `stage:*` labels;
- a plan/review comment conflicts with the stage or has no identifiable cycle;
- `stage:approved` lacks a literal approving review for the current plan snapshot;
- an issue is not a delivery/bug issue.

Never repair drift by inferring approval from history, a PR, or an implementer claim. A blocked issue does not stop unrelated batch issues.
