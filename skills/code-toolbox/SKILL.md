---
name: code-toolbox
description: "Coordinate non-trivial repository changes through independent subagents, ADR/spec-aware planning, GitHub issue stages, review gates, and PR evidence. Use for an existing delivery issue, several issues in parallel, or a repository-only plan that needs investigation, a conditional spec, planning, execution, review, and integration. Start from a named phase when requested."
metadata:
  user-invocable: true
---

# code-toolbox

Use this skill to coordinate work; do not self-author a plan, self-review it, or implement a dispatched task. The central orchestrator owns dispatch, label transitions, gates, and the final status only.

## Invocation and router

| Invocation | Entry | Behavior |
| --- | --- | --- |
| `/code-toolbox` | default | Repository mode: resume the earliest unmet phase. |
| `/code-toolbox issue create` | create | Run pre-issue investigation and spec gate, then create one delivery issue at `stage:spec-approval` + `needs-human`. |
| `/code-toolbox issue <#N\|URL> [phase]` | issue | Validate the issue, then resume its stage or start at the named phase. |
| `/code-toolbox batch <#N\|URL>... --from <phase>` | batch | Run one isolated issue trail per existing delivery/bug issue. |
| `/code-toolbox <brainstorm\|spec\|plan\|dispatch\|review\|integrate>` | phase | Repository mode: start there and continue. |
| `/code-toolbox tool <doctor\|bootstrap\|review-package>` | tool | Run exactly one helper and stop. |

A named phase starts there and continues forward, but never bypasses an unmet gate. `/code-toolbox issue create` is the sole creation route: it is available only after pre-issue investigation and the spec gate prepare an ADR/spec or explicit no-spec rationale, and it creates no code change. In issue mode, first verify that the issue is an eligible delivery/bug issue. Only then may a missing, multiple, or inconsistent `stage:*` label be treated as drift: apply `stage:blocked` plus `needs-human`, explain the evidence, and stop. Never apply a delivery stage to an umbrella, audit, or tracking issue. The exact state machine is in [`references/github-flow.md`](references/github-flow.md): `spec-approval`, `needs-plan`, `needs-plan-review`, `approved`, `in-progress`, `needs-task-review`, and `blocked`. `batch` accepts only existing delivery/bug issues; never creates an issue. `direct` repository mode and issue creation are separate, incompatible routes.

Load the named phase, then the relevant references:

| Phase | Purpose | Load |
| --- | --- | --- |
| 0 — ISSUE CONTEXT | Validate issue state and repository links | [`phases/00-issue-context.md`](phases/00-issue-context.md) |
| 1 — INVESTIGATE | Explore context and refine requirements | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 1.1 — VISUAL COMPANION | Optional visual exploration | [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md) |
| 2 — SPEC GATE | Decide whether an ADR/spec is required | [`phases/02-spec.md`](phases/02-spec.md) |
| 3 — PLAN AND REVIEW | Publish a plan and obtain independent approval | [`phases/03-plan.md`](phases/03-plan.md) |
| 4 — DISPATCH | Choose execution mode and dispatch implementers | [`phases/04-dispatch.md`](phases/04-dispatch.md) |
| 5 — CODE REVIEW | Independently review implementation evidence | [`phases/05-review.md`](phases/05-review.md) |
| 6 — INTEGRATE | Audit, verify DoD, and close | [`phases/06-integrate.md`](phases/06-integrate.md) |

## Source precedence

1. Accepted ADRs and specs define intent and contract.
2. Code and tests describe current behavior and reveal drift; they do not silently override accepted ADRs/specs.
3. The issue holds delivery scope, append-only plan/review snapshots, and task evidence.
4. Exactly one `stage:*` label plus optional `needs-human` is the observable delivery state. The linked PR proves delivered code and DoD evidence.

If an accepted ADR/spec conflicts with code or an issue plan, stop the plan: update the repository document first, obtain the required approval, publish a new plan snapshot, and repeat independent review.

## Hard gates

- A spec is required only for a new/changed contract, observable behavior, or durable architectural decision. Otherwise record `Spec impact: not required`, its concrete reason, and obtain the same human source-set approval before planning; do not create a decisions file merely to satisfy the workflow.
- A required ADR/spec is written by `spec-author` and needs human approval before planning. The planner receives the approved repository path and immutable blob URL/commit link.
- `plan-author` and `plan-reviewer` are different fresh subagents. A code reviewer is also distinct from the plan author and every executor whose work is in its reviewed range; the final auditor is distinct from planner, executors, and task reviewers. The central orchestrator maps only the reviewer’s literal verdict.
- A newly created issue starts at `stage:spec-approval` plus `needs-human`. Source-set approval (required ADR/spec or no-spec rationale) sets `stage:needs-plan`; plan publication sets `stage:needs-plan-review`; a valid approving plan review sets `stage:approved`; accepted execution starts `stage:in-progress`; complete, non-blocked task evidence sets `stage:needs-task-review`. `PEÇO AJUSTES` returns to `stage:needs-plan`; a third such cycle becomes `stage:blocked` plus `needs-human`. Empty, failed, or verdict-less review and any product/access decision also block; never self-approve.
- Issue execution is worktree-only: do not implement until `stage:approved`, an explicit user request, and a `worktree` choice. `later` leaves the issue approved with `needs-human`. `direct` belongs only to repository mode: it creates no issue and uses no labels or GitHub comments. Parallel implementation requires a worktree, branch, and PR per issue.
- Every planned task has a stable ID and an executor-evidence row. `BLOCKED` evidence never advances to review: it blocks the issue with `needs-human`. Executors publish evidence, independent reviewers record verdicts, and Phase 6 publishes the closure matrix. No local task registry, `docs/jobs`, task brief, report, or `progress.log` is a workflow input.

## Subagent topology

The orchestrator dispatches one focused agent per role and issue: `investigator`, `spec-author` when needed, `plan-author`, `plan-reviewer`, `general-executor` or `deep-executor`, `code-reviewer`, and `spec-compliance-auditor`.

Plan/review work may run in parallel across issues. Within one issue, dispatch tasks sequentially by default. Parallel task work requires plan-confirmed disjoint ownership, a worktree/branch per task, and an explicit assembly branch and order. Assemble task branches onto that issue branch, resolve conflicts, and independently re-review the assembled diff before opening its PR. File overlap, dependency, or rebase conflict blocks the affected issue until resolved and re-reviewed.

## Durable evidence

In issue mode, plans and reviews are append-only comments using [`references/github-flow.md`](references/github-flow.md). Never edit an approved snapshot. Each replacement is a new cycle and revokes `stage:approved`. The plan comment records task IDs, base SHA, immutable ADR/spec URLs, verification, ownership, and parallel safety. Task, review, and closure comments follow [`references/evidence-contract.md`](references/evidence-contract.md).

Repository mode uses a versioned Markdown delivery record at the repository's established documentation path (or a user-approved path when no convention exists). Its append-only plan, independent plan review, per-task evidence, code reviews, and DoD closure are linked by immutable commit URLs/SHAs. It has the same source and independence gates but no GitHub issue, labels, comments, or generated/local progress registry. A rejected plan/code review or `BLOCKED` task is appended there with a stop/resume instruction; it never writes GitHub state. `direct` is allowed only in this mode and cannot later create an issue.

## Non-goals

Do not redesign `bootstrap` or the visual companion. Watchdogs are not part of this skill. Do not create a dashboard, JSON registry, or generated progress ledger.
