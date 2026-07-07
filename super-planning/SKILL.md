---
name: super-planning
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature idea, loose requirements, or an approved spec for a multi-step task, before touching code. Covers integrated brainstorming, spec writing, plan writing, task decomposition, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression. If the user invokes `/super-planning <phase>`, start from that phase and continue forward from there."
user-invocable: true
---

# super-planning

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** Fresh context per task. They don't inherit your session history, preventing context pollution and keeping you free to coordinate.

**Core principle:** One subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

**Scope:** Use this skill for end-to-end pre-implementation shaping and execution. Phase 1 includes the requirement-refinement work that used to live in `brainstorming`; use `commit-changes` downstream to commit final work.

## Phase Entry Router

Treat this file as an explicit, expandable router for entry phases.

| Invocation                   | Entry Phase  | Behavior                                                                                                                                                          | Load This First                                                                        |
| ---------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `/super-planning`            | `default`    | Run the standard end-to-end workflow. Start at Phase 1 unless there is already an approved spec in the repo.                                                      | This file, then follow the phase router below                                          |
| `/super-planning brainstorm` | `brainstorm` | Start at Phase 1 and continue forward from there.                                                                                                                 | [`phases/01-brainstorm.md`](phases/01-brainstorm.md)                                   |
| `/super-planning spec`       | `spec`       | Start at Phase 2 and continue forward from there. Use only when brainstorm outputs already exist or the request is already well-defined enough to write the spec. | [`phases/02-spec.md`](phases/02-spec.md)                                               |
| `/super-planning plan`       | `plan`       | Start at Phase 3 and continue forward from there. Use only when there is already an approved spec.                                                                | [`phases/03-plan.md`](phases/03-plan.md)                                               |
| `/super-planning decompose`  | `decompose`  | Start at Phase 4 and continue forward from there. Use only when the implementation plan already exists.                                                           | [`phases/04-decompose.md`](phases/04-decompose.md)                                     |
| `/super-planning dispatch`   | `dispatch`   | Start at Phase 5 and continue forward from there. Use only when tasks are already decomposed and ready to execute.                                                | [`phases/05-dispatch.md`](phases/05-dispatch.md)                                       |
| `/super-planning review`     | `review`     | Start at Phase 6 and continue forward from there. Use only when implementation outputs already exist and are ready for review gates.                              | [`phases/06-review.md`](phases/06-review.md)                                           |
| `/super-planning integrate`  | `integrate`  | Start at Phase 7 and continue forward from there. Use only when reviewed outputs are ready to merge and finish.                                                   | [`phases/07-integrate.md`](phases/07-integrate.md)                                     |
| `/super-planning stats`      | `stats`      | Print a progress summary across all task registries. Aliases: `progress`, `task-stats`, `task-progress`.                                                          | This file, then run [`scripts/summarize-all-tasks.sh`](scripts/summarize-all-tasks.sh) |

**Routing rule:** If no subcommand is provided, always choose `default`.

**Stats rule:** When the user invokes `/super-planning stats`, `/super-planning progress`, `/super-planning task-stats`, or `/super-planning task-progress`, run the active `summarize-all-tasks.sh` helper. Prefer the in-repo script at `super-planning/scripts/summarize-all-tasks.sh` when the skill is vendored; otherwise use the repo-local `.super-planning/summarize-all-tasks.sh` copied by Phase 4. Default scan directory is `docs/tasks`. Accept optional flags exactly as the script does: `--base-dir`, `--plan-id`, `--task-id` (requires `--plan-id`), `--json`. Produce only the script output plus a one-line note about the command used.

**Forward-only rule:** When a phase name is provided, start at that phase and execute the remaining phases in order unless the user explicitly asks to stop earlier.

**Expansion rule:** Add new entry points to this table with four things only: invocation, entry phase, behavior, and the file to load first. Keep the default behavior unchanged unless the user explicitly asks for a different default.

## Quick Start

1. **Announce the selected entry phase:** for example, "I'm using the super-planning skill starting at Phase 3: PLAN."
2. **Resolve the entry through the router above** before loading any phase file.
3. **Load the matching phase file first**, then continue through the remaining phases in order.
4. **Default entry:** if no subcommand is provided, use the normal workflow selection and start at Phase 1 unless there is already an approved spec.
5. **If Phase 1 becomes visual:** load [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md) before launching the companion.

## Phase Router

| Phase          | Purpose                                                          | Load This                                            |
| -------------- | ---------------------------------------------------------------- | ---------------------------------------------------- |
| 1 — BRAINSTORM | Refine the idea into requirements and design decisions           | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 2 — SPEC       | Write the feature spec and get user approval                     | [`phases/02-spec.md`](phases/02-spec.md)             |
| 3 — PLAN       | Write the implementation plan                                    | [`phases/03-plan.md`](phases/03-plan.md)             |
| 4 — DECOMPOSE  | Fill `super-plan.json` with atomic tasks and task-state metadata | [`phases/04-decompose.md`](phases/04-decompose.md)   |
| 5 — DISPATCH   | Send subagents (sequential or parallel)                          | [`phases/05-dispatch.md`](phases/05-dispatch.md)     |
| 6 — REVIEW     | Spec compliance + code quality gates                             | [`phases/06-review.md`](phases/06-review.md)         |
| 7 — INTEGRATE  | Merge results, final review, finish                              | [`phases/07-integrate.md`](phases/07-integrate.md)   |

**Default rule:** Always run Phase 1 first when the user starts from an idea, request, or loose requirements. Skip it only when there is already an approved spec in the repo or when the user explicitly invoked a later phase.

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

- **Sequential mode:** one implementer + one reviewer according to `reviewCadence`. Best for dependent tasks or overlapping files.
- **Parallel mode:** dispatch 2–4 subagents simultaneously. Review timing is controlled by `reviewCadence`; with `per_task`, each finished task is reviewed immediately. Requires file-level isolation.
- **File-based handoffs:** task requirements live in `super-plan.json`; Phase 4 uses the helper stack in-place when the target repo already contains this `super-planning` skill, otherwise it creates `.super-planning/` in the target repo and copies the registry helper stack there (`super-plan.sh`, `render-progress-ledger.sh`, `super-plan.schema.json`); it then writes the first `super-plan.json` plus `progress-ledger.md`. Every later `super-plan.json` mutation must go through that active helper path, which regenerates the ledger immediately. Phase 5 uses the shared logging helper from the same active helper path and Phase 6 materializes each task directory plus task-local artifacts such as `report.md`, `review-package.diff.md`, wrapper `log-task.sh`, and `progress.log`.
- **Execution profiles:** Phase 4 must populate the root `agents` map with `general`, `deep`, and `quick` slots, using platform auto-discovery when possible and empty-string fallbacks when not. Every task must include `task_profile` set to one of those three categories.
- **User confirmation of discovered profiles:** after auto-discovery, the orchestrator must show the discovered agents/models plus its recommendation and ask the user what to do next. When the platform exposes a structured ask/confirm/question tool and the current mode/session allows using it, that tool is required; plain text is the fallback when the tool does not exist or is not callable in the current mode/session.
- **Validation before dispatch:** Phase 5 must re-check that any configured `agent/model` pair still exists on the current platform before calling a subagent. If validation or a lightweight probe fails, clear that profile back to empty strings in `super-plan.json` and fall back to platform defaults.
- **Never start implementation on `main`/`master`** without explicit user consent, always ask for permission.
- **Never re-dispatch a task** the ledger or log already marks complete.
- **Status lifecycle** — use one state machine everywhere: `pending → in_progress → ready_for_review → reviewing → needs_fix|blocked|completed|cancelled`. Only the orchestrator may mark `completed`, and only after review is clean.
- **Output summary** — after creating artifacts for the current phase, print a one-line summary showing each file path so the user knows what was produced. When Phase 6 materializes task artifacts, include the task directory, logging files, and `progress-ledger.md` in that summary. Example: `Created: docs/specs/0001-auth-spec.md, docs/plans/0001-auth.md, docs/tasks/0001-auth/super-plan.json, docs/tasks/0001-auth/Task-A-0001/log-task.sh, docs/tasks/0001-auth/progress-ledger.md`

## Outputs & Conventions

| Artifact                        | Path                                                      | Template                                                                                                                                                                                          |
| ------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Brainstorm decisions (optional) | `docs/specs/{feature_number}_{feature_name}_decisions.md` | [`templates/decisions-template.md`](templates/decisions-template.md)                                                                                                                              |
| Spec                            | `docs/specs/NNNN-<feature-name>-spec.md`                  | [`templates/spec-template.md`](templates/spec-template.md)                                                                                                                                        |
| Plan                            | `docs/plans/NNNN-<feature-name>.md`                       | [`templates/plan-template.md`](templates/plan-template.md)                                                                                                                                        |
| Super plan                      | `docs/tasks/NNNN-<feature-name>/super-plan.json`          | Created and later mutated only via the active helper path: the in-repo skill scripts when available, otherwise the repo-local `.super-planning/super-plan.sh`, backed by the matching schema file |
| Task directory                  | `docs/tasks/NNNN-<feature-name>/<task-id>/`               | Contains task report, review package, local logger, and task progress log                                                                                                                         |
| Task progress log               | `docs/tasks/NNNN-<feature-name>/<task-id>/progress.log`   | [`templates/progress-template.txt`](templates/progress-template.txt)                                                                                                                              |
| Progress ledger                 | `docs/tasks/NNNN-<feature-name>/progress-ledger.md`       | Regenerated from `super-plan.json` and task logs by the active helper path after every registry write                                                                                             |
| Repo helpers                    | `.super-planning/`                                        | Only created when the target repo does not already contain this `super-planning` skill; holds copied helper scripts and schema                                                                    |

## Prompt Library

| Prompt                                                                                 | Use When                            |
| -------------------------------------------------------------------------------------- | ----------------------------------- |
| [`prompts/pre-write-approval.md`](prompts/pre-write-approval.md)                       | Before writing the spec             |
| [`prompts/post-write-approval.md`](prompts/post-write-approval.md)                     | After writing the spec              |
| [`prompts/spec-document-reviewer-prompt.md`](prompts/spec-document-reviewer-prompt.md) | Reviewing spec readiness            |
| [`prompts/worker-prompt-template.md`](prompts/worker-prompt-template.md)               | Building a subagent dispatch prompt |
| [`prompts/implementer-guidance.md`](prompts/implementer-guidance.md)                   | Dispatching an implementer subagent |
| [`prompts/reviewer-guidance.md`](prompts/reviewer-guidance.md)                         | Dispatching a reviewer subagent     |

## See Also

- **Full visual flows:** [`README.md`](README.md)
- **Phase 1 visual companion:** [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md)
- **Super-plan generator:** [`scripts/super-plan.sh`](scripts/super-plan.sh)
- **Progress-ledger renderer:** [`scripts/render-progress-ledger.sh`](scripts/render-progress-ledger.sh)
- **Super-plan interface:** [`interfaces/super-plan.schema.json`](interfaces/super-plan.schema.json)
- **Progress logging helper:** [`scripts/log-task.sh`](scripts/log-task.sh)
