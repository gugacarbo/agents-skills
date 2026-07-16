# GitHub Flow Contract

Use this reference only after an issue exists. Investigation, optional ADR/spec writing, and the spec-impact decision happen before issue creation.

## Issue eligibility and creation

Only an existing delivery issue or a bug issue with an implementation delivery may use this flow. Do not apply a delivery stage to an umbrella, audit, or generic tracking issue. `batch` receives existing issue numbers/URLs only.

When this workflow creates a delivery issue, prepare repository context and any required ADR/spec first. Create the issue at `stage:spec-approval` plus `needs-human`; its body must link to the prepared ADR/spec or state `Spec impact: not required` with the reason.

## Precise stages

Exactly one `stage:*` label applies to a delivery issue. It identifies the issue's next gate; append-only comments retain the exact status of parallel task agents.

| Label | Precise meaning | Next action |
| --- | --- | --- |
| `stage:spec-approval` | Initial source set is prepared: required ADR/spec is ready, or spec impact is explicitly not required | Human approves the source set before planning. |
| `stage:needs-plan` | Approved source set has no current plan snapshot | Dispatch/await plan-author. |
| `stage:needs-plan-review` | Current plan snapshot exists and has not received a valid independent verdict | Dispatch/await plan-reviewer. |
| `stage:approved` | Current plan has a literal approving verdict | Human selects `worktree`, `direct`, or `later`. |
| `stage:in-progress` | Approved tasks are implementing or being fixed | Await task evidence or blockers. |
| `stage:needs-task-review` | Task evidence is ready; independent task review, DoD, and final audit remain before closure | Dispatch/await reviewers and auditor. |
| `stage:blocked` | A human decision or external correction is required | Present the recorded blocker; do not guess. |

`needs-human` is orthogonal. Add it for `spec-approval`, `approved` + `later`, blocked decisions, review failure, and the third requested-change cycle. Before adding a stage, remove every existing `stage:*` label. After a closed delivery, remove both the stage and `needs-human` labels.

## Transition table

```text
pre-issue: investigate → decide spec impact → create/update ADR/spec when needed
create issue: spec-approval + needs-human
human source approval → needs-plan → needs-plan-review
  ├─ approves → approved → in-progress
  ├─ asks changes (cycle < 3) → needs-plan
  └─ rejects/errors/third change → blocked + needs-human
in-progress → needs-task-review → final audit/DoD → close
  └─ task review requests changes → in-progress
```

## Resume rules

| Observed state | Resume action |
| --- | --- |
| `stage:spec-approval` | Present the prepared ADR/spec or no-spec rationale for human approval; do not plan. |
| `stage:needs-plan` | Start or await Phase 3 plan-author work. |
| `stage:needs-plan-review` | Dispatch or await the current independent plan review. |
| `stage:approved` | Ask `worktree`, `direct`, or `later`; do not edit code yet. |
| `stage:in-progress` | Dispatch/resume the earliest task without evidence or resolve its blocker. |
| `stage:needs-task-review` | Dispatch/await independent task reviews, DoD, and final audit. |
| `stage:blocked` | Present the recorded human decision; do not guess. |
| Zero/multiple stages or comment drift | Set `stage:blocked` + `needs-human` and explain the mismatch. |

## Plan cycles

One cycle is one append-only plan comment plus one append-only review comment. The plan must identify `Plan cycle: k/3`, its repository base SHA, source links, and task IDs. The review must cite that plan comment URL and use a literal verdict:

`APROVO` | `APROVO COM RESSALVAS` | `PEÇO AJUSTES` | `NÃO APROVO`

Do not edit a submitted plan or review comment. A material plan change starts a new cycle, replaces `stage:approved` with `stage:needs-plan`, and requires a new reviewer. If a reviewer requires a product/access choice, use `NÃO APROVO` and block rather than consuming an adjustment cycle.

## Batch rules

Maintain a separate state row for every issue: URL, stage, plan cycle, base SHA, assigned agents, blockers, branch/worktree, PR, and next action. A blocked issue does not halt unrelated issues. Plan/review agents may run in parallel. Parallel implementation needs an isolated worktree, branch, and PR per issue; a direct batch is sequential.
