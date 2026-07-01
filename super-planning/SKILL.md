---
name: super-planning
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature spec or requirements for a multi-step task, before touching code. Covers plan writing, task decomposition, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression."
---

# super-planning

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** Fresh context per task. They don't inherit your session history, preventing context pollution and keeping you free to coordinate.

**Core principle:** One subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

**Scope:** Use this skill for implementation planning and execution. Use `brainstorming` upstream to refine requirements; use `commit-changes` downstream to commit final work.

## Quick Start

1. **Announce:** "I'm using the super-planning skill to create and execute this implementation plan."
2. **Route through the phases below** — the agent must load the referenced file before executing a phase.

## Phase Router

| Phase          | Purpose                                                | Load This                                            |
| -------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| 1 — BRAINSTORM | Refine the idea into requirements and design decisions | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 2 — SPEC       | Write the feature spec and get user approval           | [`phases/02-spec.md`](phases/02-spec.md)             |
| 3 — PLAN       | Write the implementation plan                          | [`phases/03-plan.md`](phases/03-plan.md)             |
| 4 — DECOMPOSE  | Break the plan into atomic tasks in a JSON registry    | [`phases/04-decompose.md`](phases/04-decompose.md)   |
| 5 — DISPATCH   | Send subagents (sequential or parallel)                | [`phases/05-dispatch.md`](phases/05-dispatch.md)     |
| 6 — REVIEW     | Spec compliance + code quality gates                   | [`phases/06-review.md`](phases/06-review.md)         |
| 7 — INTEGRATE  | Merge results, final review, finish                    | [`phases/07-integrate.md`](phases/07-integrate.md)   |

**Always run Phase 1 first;** never skip to planning without first invoking the `brainstorming` skill (or its fallback).

## Decision Flow

```
Have a feature idea or requirements for a multi-step task?
├─ No → Single trivial task? → Yes → Just do it inline, no skill needed
├─ Yes → Approved spec already in docs/specs/?
│   ├─ Yes → Skip to Phase 3 (PLAN), reference the spec number
│   └─ No → Phase 1 (BRAINSTORM) → Phase 2 (SPEC)
│       └─ After spec approval → Phase 3 (PLAN)
│           └─ Tasks mostly independent AND no file conflicts?
│               ├─ Yes → PARALLEL MODE (dispatch all in one message)
│               └─ No  → SEQUENTIAL MODE (one at a time, review after each)
```

## Shared Rules

- **Sequential mode:** one implementer + one reviewer per task, in order. Best for dependent tasks or overlapping files.
- **Parallel mode:** dispatch 2–4 subagents simultaneously, then review together. Requires file-level isolation.
- **File-based handoffs:** task requirements live in `tasks.json`; subagents write reports to files; progress lives in `progress.log` and `progress-ledger.md`.
- **Never start implementation on `main`/`master`** without explicit user consent.
- **Never re-dispatch a task** the ledger or log already marks complete.

## Outputs & Conventions

| Artifact        | Path                                                | Template                                                                         |
| --------------- | --------------------------------------------------- | -------------------------------------------------------------------------------- |
| Spec            | `docs/specs/NNNN-<feature-name>-spec.md`            | [`templates/spec-template.md`](templates/spec-template.md)                       |
| Plan            | `docs/plans/NNNN-<feature-name>.md`                 | [`templates/plan-template.md`](templates/plan-template.md)                       |
| Task registry   | `docs/tasks/NNNN-<feature-name>/tasks.json`         | [`templates/tasks-template.json`](templates/tasks-template.json)                 |
| Progress log    | `docs/tasks/NNNN-<feature-name>/progress.log`       | [`templates/progress-template.txt`](templates/progress-template.txt)             |
| Progress ledger | `docs/tasks/NNNN-<feature-name>/progress-ledger.md` | [`templates/progress-ledger-template.md`](templates/progress-ledger-template.md) |

## Prompt Library

| Prompt                                                                   | Use When                            |
| ------------------------------------------------------------------------ | ----------------------------------- |
| [`prompts/pre-write-approval.md`](prompts/pre-write-approval.md)         | Before writing the spec             |
| [`prompts/post-write-approval.md`](prompts/post-write-approval.md)       | After writing the spec              |
| [`prompts/worker-prompt-template.md`](prompts/worker-prompt-template.md) | Building a subagent dispatch prompt |
| [`prompts/implementer-guidance.md`](prompts/implementer-guidance.md)     | Dispatching an implementer subagent |
| [`prompts/reviewer-guidance.md`](prompts/reviewer-guidance.md)           | Dispatching a reviewer subagent     |

## See Also

- **Full visual flows:** [`README.md`](README.md)
- **Progress logging helper:** [`scripts/log-task.sh`](scripts/log-task.sh)
