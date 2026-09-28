---
name: orchestrate-implementation
description: Use only when the user explicitly invokes `$orchestrate-implementation` to execute a multi-task implementation plan in the current session. Do not activate automatically for ordinary implementation requests or plans.
---

# Orchestrate Implementation

Execute a written multi-task implementation plan in this session. Use fresh,
focused implementers, execute sequentially by default, review each task, then
review the complete branch.

## Invariants

- Never dispatch an agent with an omitted model or `model: inherit`. Every role
  uses an exact concrete model approved by the user and recorded in the ledger.
- Run every validation requested by the user, plan, or Spec. Do not claim
  completion until it passes on the relevant result. Record failures and fix
  them when a viable implementation or environment-repair path remains.
- Keep durable progress, approvals, commit boundaries, findings, and rulings in
  this plan's ledger. The ledger is the recovery source after context compaction.
- Implementers do not spawn agents. Reviewers are read-only and do not spawn
  agents. Keep each dispatch scoped to its task and hand off artifacts by path.
- After the configuration gate is approved, keep executing without progress
  check-ins between tasks. Report blockers and required user decisions
  immediately; provide the ordinary completion summary at batch end.
- Resolve ambiguity with a recorded ruling when a viable path remains. Stop
  only for destructive or irreversible work, security-sensitive actions,
  external side effects requiring authorization, a plan with no grounded path,
  or a required validation failure with no viable remedy.

## Use This Skill

Use it only when the user explicitly invokes `$orchestrate-implementation`, a
written plan has executable task boundaries, and execution stays in this
session. For a separate execution session, use
`references/executing-plans/SKILL.md`. If no executable plan exists, use manual
implementation or clarify the plan first.

## Workflow

1. **Prepare and approve.** Read
   [`controller-setup.md`](references/controller-setup.md) at the start. Create
   or recover the isolated integration worktree and plan ledger, review the
   plan and Spec, prepare the concise configuration, and wait for its explicit
   approval before dispatching any agent. The pre-gate scope comes from the
   plan; do not estimate indirect file writes there. Execution is sequential
   unless a later wave passes its eligibility check.
2. **Implement and review.** After approval, read
   [`controller-task-loop.md`](references/controller-task-loop.md). Implement
   and review each task or coherent batch in plan order. Before proposing a
   parallel wave, load [`parallel-waves.md`](references/parallel-waves.md) and
   establish its complete write sets and isolation immediately before dispatch.
   When review feedback is unclear or contestable, load
   [`receiving-code-review/SKILL.md`](references/receiving-code-review/SKILL.md).
3. **Finish.** After task reviews are final, read
   [`controller-finish.md`](references/controller-finish.md), complete the
   whole-branch review, report ledger rulings, clean up this plan's artifacts,
   and follow the local branch-finishing guidance.

## Tooling

- `scripts/plan-workspace PLAN_FILE` resolves the plan's private artifact
  directory.
- `scripts/task-brief PLAN_FILE N` extracts one task's requirements.
- `scripts/review-package PLAN_FILE BASE HEAD` creates a reviewer-ready diff.

Read detailed references when their phase begins, not all at skill activation.
Do not edit `dist/`; it is generated.
