# GitHub Flow Contract

Use this reference after a delivery issue exists. Phases 0–2 investigate and decide spec impact before creation; the resulting issue carries the ADR/spec proposal or no-spec rationale for human approval. Do not write or update the formal ADR/spec first.

## Issue eligibility and creation

Only an existing delivery issue or a bug issue with an implementation delivery may use this flow. An umbrella, audit, or generic tracking issue is ineligible: explain why and stop without adding, removing, or replacing any `stage:*` label. `batch` receives existing issue numbers/URLs only.

When this workflow creates a delivery issue, prepare repository context and a repository-pattern proposal first. Create the issue at `stage:spec-approval` plus `needs-human`; its body and source-set comment must include the proposed ADR/spec content or state `Spec impact: not required` with the reason, then explicitly request human approval. After that approval, materialize the ADR/spec (when required) and append its immutable link before planning.

## Precise stages

Exactly one `stage:*` label applies to a delivery issue. It identifies the issue's next gate; append-only comments retain the exact status of parallel task agents.

| Label | Precise meaning | Next action |
| --- | --- | --- |
| `stage:spec-approval` | Delivery issue contains a proposed ADR/spec or explicit no-spec rationale, awaiting human approval | Human approves the proposal; `issue-writer` materializes the approved ADR/spec when required, then moves to `stage:needs-plan`. |
| `stage:needs-plan` | Approved source set has no current plan snapshot | Dispatch/await plan-writer. |
| `stage:needs-plan-review` | Current plan snapshot awaits an independent verdict or human approval after an approving verdict | Dispatch/await plan-reviewer, then await human plan approval. |
| `stage:approved` | Current plan has a literal approving verdict and explicit human approval | Human selects `worktree` or `later`; issue execution never uses `direct`. |
| `stage:in-progress` | Approved tasks are implementing or being fixed | Await task evidence or blockers. |
| `stage:needs-task-review` | Every planned task has non-blocked evidence; independent task review, assembled-diff review when applicable, DoD, final `delivery-reviewer` audit, PR approval, and merge decision remain before closure | Dispatch/await `delivery-reviewer` instances, then present optional integration. |
| `stage:blocked` | A human decision or external correction is required | Present the recorded blocker; do not guess. |

`needs-human` is orthogonal. Add it for `spec-approval`, `needs-plan-review` after an approving verdict, `approved` + `later`, blocked decisions, review failure, the third requested-change cycle, and the optional post-PR integration decision. Before adding a stage, remove every existing `stage:*` label. After a merged/closed delivery, remove both the stage and `needs-human` labels.

## Transition table

```text
phase 0 → phase 1 → phase 2: investigate → decide spec impact → prepare issue proposal
create delivery issue: proposal/no-spec rationale + spec-approval + needs-human
human proposal approval → materialize ADR/spec when required → needs-plan → needs-plan-review
  ├─ independent reviewer approves → await human plan approval → approved → worktree in-progress
  ├─ asks changes (cycle < 3) → needs-plan
  └─ rejects/errors/third change → blocked + needs-human
in-progress → needs-task-review → task + assembled-diff review → final audit/DoD → PR approval
  └─ optional, user-confirmed integration/merge → close
  └─ task review requests changes → in-progress
```

## Resume rules

| Observed state | Resume action |
| --- | --- |
| `stage:spec-approval` | Present the issue's proposed ADR/spec or no-spec rationale for human approval; do not write the formal ADR/spec or plan. |
| `stage:needs-plan` | Start or await Phase 3 plan-writer work. |
| `stage:needs-plan-review` | Dispatch/await the current independent plan review, then present an approving snapshot for human plan approval. |
| `stage:approved` | Ask `worktree` or `later`; do not edit code yet. `direct` is repository-only. |
| `stage:in-progress` | Dispatch/resume the earliest planned task without `DONE`/`DONE_WITH_CONCERNS` evidence or resolve its blocker. |
| `stage:needs-task-review` | Dispatch/await independent `delivery-reviewer` task/range reviews, assembled-diff review when applicable, DoD, final audit, and PR approval. After approval, offer—not automatically perform—merge/integration. |
| `stage:blocked` | Present the recorded human decision; do not guess. |
| Eligible issue with zero/multiple stages or comment drift | Set `stage:blocked` + `needs-human` and explain the mismatch. |
| Ineligible issue | Explain that it is outside the delivery flow and stop without touching labels. |

## Plan cycles

One cycle is one append-only plan comment plus one append-only review comment. The plan must identify `Plan cycle: k/3`, its repository base SHA, source links, and task IDs. The review must cite that plan comment URL and use a literal verdict:

`APROVO` | `APROVO COM RESSALVAS` | `PEÇO AJUSTES` | `NÃO APROVO`

Do not edit a submitted plan or review comment. A material plan change, human rejection, or human request for changes starts a new cycle, replaces `stage:approved` or `stage:needs-plan-review` with `stage:needs-plan`, and requires a new reviewer. If a reviewer requires a product/access choice, use `NÃO APROVO` and block rather than consuming an adjustment cycle. The plan-reviewer must be distinct from the plan-writer. Every `delivery-reviewer` instance must also be distinct from the plan-writer and executors whose work is in its reviewed range.

## Batch rules

Maintain an ephemeral orchestration view for every issue: URL, observed stage, plan cycle, base SHA, assigned agents, blockers, branch/worktree, PR, and next action. Do not persist it as a registry or progress file; issue labels/comments and the PR are the durable evidence. A blocked issue does not halt unrelated issues. Plan/review agents may run in parallel. Parallel implementation needs an isolated worktree, branch, and PR per issue; batch has no direct mode.
