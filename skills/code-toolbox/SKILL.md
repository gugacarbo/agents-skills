---
name: code-toolbox
description: "Coordinate non-trivial repository changes through ADR/spec-aware planning, six independent subagent roles, GitHub issue stages, review gates, and PR evidence. Use for delivery issues, batches, or repository-only delivery records; start from a named phase when requested."
metadata:
  user-invocable: true
---

# code-toolbox

Coordinate dispatch, labels, gates, and final status only. Never self-author a plan, self-review it, or implement a dispatched task.

## Router

| Invocation | Behavior |
| --- | --- |
| `/code-toolbox` | Repository mode: resume the earliest unmet phase. |
| `/code-toolbox issue create` | Run issue-writer preparation, then create one delivery issue at `stage:spec-approval` + `needs-human`. |
| `/code-toolbox issue <#N\|URL> [phase]` | Validate an existing eligible issue, then resume its stage or named phase. |
| `/code-toolbox batch <#N\|URL>... --from <phase>` | Run isolated trails for existing eligible delivery/bug issues. |
| `/code-toolbox <brainstorm\|spec\|plan\|dispatch\|review\|integrate>` | Start that repository phase and continue. |
| `/code-toolbox tool <doctor\|bootstrap\|review-package>` | Run one helper and stop. |

A named phase never bypasses an unmet gate. `issue create` is the sole creation route and cannot create code. `batch` never creates issues. `direct` is repository-only: it creates no issue, label, stage, or GitHub comment.

Load the named phase and its referenced sources:

| Phase | Load |
| --- | --- |
| 0 — ISSUE CONTEXT | [`phases/00-issue-context.md`](phases/00-issue-context.md) |
| 1 — SOURCE SET | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 1.1 — VISUAL COMPANION | [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md) |
| 2 — SPEC GATE | [`phases/02-spec.md`](phases/02-spec.md) |
| 3 — PLAN AND REVIEW | [`phases/03-plan.md`](phases/03-plan.md) |
| 4 — DISPATCH | [`phases/04-dispatch.md`](phases/04-dispatch.md) |
| 5 — DELIVERY REVIEW | [`phases/05-review.md`](phases/05-review.md) |
| 6 — VERIFY AND INTEGRATE | [`phases/06-integrate.md`](phases/06-integrate.md) |

## Sources, stages, and gates

1. Accepted ADRs/specs define intent.
2. Code/tests show current behavior and drift, never silently override accepted sources.
3. Issue comments hold delivery evidence; repository direct mode uses one versioned Markdown delivery record.
4. Exactly one `stage:*` label is the issue's operational state. See [`references/github-flow.md`](references/github-flow.md).

Spec is required only for a changed contract, observable behavior, or durable decision. `issue-writer` records a concrete no-spec rationale otherwise. An issue stays at `stage:spec-approval` + `needs-human` until a human approves its source set, even after `issue-reviewer` reviews it. Plan publication moves an issue to `stage:needs-plan-review`; a valid independent approval moves it to `stage:approved`; worktree execution moves it to `stage:in-progress`; complete non-blocked task evidence moves it to `stage:needs-task-review`. Invalid evidence, product/access decisions, blockers, and the third requested-change cycle use `stage:blocked` + `needs-human`.

Issue execution requires `stage:approved`, an explicit user request, and a worktree choice. Tasks are sequential by default. Parallel work needs disjoint ownership, a worktree/branch per task, an assembly branch/order, integration verification, and a fresh assembled-range review before PR.

## Exactly six agents

Dispatch only these roles:

| Agent | Responsibility |
| --- | --- |
| `issue-writer` | Investigation, conditional ADR/spec, user decisions, issue creation, initial evidence. |
| `issue-reviewer` | Independent issue/source-set review; never replaces human approval. |
| `plan-writer` | Append-only implementation plan. |
| `plan-reviewer` | Fresh literal plan verdict. |
| `executor` | One approved task, at the depth the task requires. |
| `delivery-reviewer` | Task/range review and, in a fresh instance, final DoD/contract audit. |

`plan-writer` and `plan-reviewer` are distinct. A range `delivery-reviewer` is distinct from its executor and plan-writer. The final-audit `delivery-reviewer` is a fresh instance distinct from all range reviewers, executors, and plan-writer.

## Universal evidence contract

Every outcome from every agent records an append-only envelope before the orchestrator transitions, blocks, or stops—even no-change, `BLOCKED`, errors, missing verdicts, and rejected reviews. Issue mode posts a new comment; direct mode appends a section to the delivery record. The fields and order are mandatory:

```text
Agent: <agent>
Phase/scope: <phase, cycle, task, or range>
Summary: <result>
Sources/evidence: <immutable links, commands, output>
Decisions: <applied, pending, or none>
Changes/validation: <changes and validation, or none>
Blockers: <blocker or none>
Next action: <action and owner>
```

Plans, reviews, and task evidence remain append-only. Every plan task has a stable ID. Phase 6 publishes the closure matrix. Do not create a local registry, `docs/jobs`, task brief, report, dashboard, or progress log.

## Non-goals

Do not redesign `bootstrap` or the visual companion. Watchdogs are not part of this skill. Integration/merge is optional only after PR approval and an explicit user request.
