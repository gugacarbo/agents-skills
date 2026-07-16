---
name: code-flow
description: "Coordinate non-trivial repository changes through ADR/spec-aware planning, six independent subagent roles, GitHub issue stages, review gates, and PR evidence. Use for delivery issues, batches, or repository-only delivery records; start from a named phase when requested."
metadata:
  user-invocable: true
---

# code-flow

Coordinate the flow; dispatch the named roles instead of writing plans, reviews, or implementation yourself.

## Commands

| Invocation | Behavior |
| --- | --- |
| `/code-flow` | Repository mode: resume the earliest unmet phase. |
| `/code-flow issue create` | Run Phases 0–2, then create one delivery issue whose ADR/spec proposal awaits human approval at `stage:spec-approval` + `needs-human`. |
| `/code-flow issue <#N\|URL> [phase]` | Validate an existing eligible issue, then resume its stage or named phase. |
| `/code-flow batch <#N\|URL>... --from <phase>` | Run isolated trails for existing eligible delivery/bug issues. |
| `/code-flow <brainstorm\|create-issue\|plan\|dispatch\|review\|integrate>` | Start that repository phase and continue. |
| `/code-flow tool <doctor\|bootstrap\|review-package>` | Run one helper and stop. |

`issue create` is the only issue-creation route. Named phases never bypass gates; `batch` never creates issues; `direct` is repository-only and never changes GitHub state.

## Rules before writing

1. Classify the work. A delivery issue has one closable outcome. An initiative has multiple independently deliverable outcomes, owners, dependencies, or release decisions.
2. Before any `code-flow` template, find the repository's current pattern: guidance, forms, schemas, canonical documents, and recent accepted artifacts. Use a compatible local pattern as the base; add only fields the current gate needs. Record its source, absence, or adaptation in evidence.
3. Accepted ADRs/specs define intent. Code and tests reveal current behavior and drift; they do not silently replace accepted intent.

For an initiative, explain the signals and offer [`templates/01-epic.md`](templates/01-epic.md). Create an Epic only after the user explicitly selects it. It is tracking-only: no delivery stages, plans, or execution. Each child is one delivery/bug issue, written with [`templates/02-user-story.md`](templates/02-user-story.md), and follows this flow independently. GitHub subissues link Epic to delivery issues; implementation work remains stable plan task IDs.

## Delivery flow

1. **Phases 0–1:** establish repository context, scope, local patterns, risks, and unresolved user decisions.
2. **Phase 2:** prepare the source set, decide `create`, `update`, or `not required` for ADR/spec, and create the delivery issue containing the proposal or no-spec rationale at `stage:spec-approval` + `needs-human`; do not materialize the formal document yet.
3. **Human source approval:** materialize the approved ADR/spec when required, record its immutable link, and move to `stage:needs-plan`.
4. **Phase 3:** `plan-writer` posts the plan; `plan-reviewer` posts an independent verdict. An approving verdict still waits for human approval of that exact snapshot at `stage:needs-plan-review` + `needs-human`.
5. **Human plan approval:** move to `stage:approved`. Execution still needs an explicit request and `worktree` or `later` choice.
6. **Phases 4–6:** execute stable task IDs, review each range independently, verify the closure matrix and DoD, obtain PR approval, then offer integration only when requested.

In `direct` mode, use [`templates/10-delivery-report-template.md`](templates/10-delivery-report-template.md) for the same approvals and evidence, with no issue, label, stage, or GitHub comment. An existing Epic/umbrella issue is ineligible for delivery flow.

## Load for the active phase

| Phase | Load |
| --- | --- |
| 0 — ISSUE CONTEXT | [`phases/00-issue-context.md`](phases/00-issue-context.md) |
| 1 — BRAINSTORM | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 1.1 — VISUAL COMPANION | [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md) |
| 2 — CREATE ISSUE | [`phases/02-create-issue.md`](phases/02-create-issue.md) |
| 3 — PLAN AND REVIEW | [`phases/03-plan.md`](phases/03-plan.md) |
| 4 — DISPATCH | [`phases/04-dispatch.md`](phases/04-dispatch.md) |
| 5 — DELIVERY REVIEW | [`phases/05-review.md`](phases/05-review.md) |
| 6 — VERIFY AND INTEGRATE | [`phases/06-integrate.md`](phases/06-integrate.md) |

Read [`references/github-flow.md`](references/github-flow.md) before changing issue stages or resuming an issue. Read [`references/evidence-contract.md`](references/evidence-contract.md) before publishing evidence, reviewing task work, or closing delivery.

## Roles

Dispatch only these roles:

| Agent | Responsibility |
| --- | --- |
| `issue-writer` | Context, proposal, issue creation, and formal ADR/spec materialization after approval. |
| `issue-reviewer` | Optional independent source-set audit. |
| `plan-writer` | One append-only implementation plan. |
| `plan-reviewer` | Independent literal verdict on one plan snapshot. |
| `executor` | One approved stable task ID. |
| `delivery-reviewer` | Independent task/range review and fresh final audit. |

Keep plan writer/reviewer separate. A delivery reviewer is distinct from the executor and plan writer; the final auditor is also fresh.

Evidence is append-only. Record every outcome—including no change, `BLOCKED`, errors, and rejected reviews—before changing state. Do not create separate task trackers, progress logs, or workflow registries.
