---
name: super-planning
description: "Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent. Use when you have a feature idea, loose requirements, or an approved spec for a multi-step task, before touching code. Covers integrated brainstorming, spec writing, plan writing, task decomposition, optional Git worktree isolation, model selection, subagent prompt construction, parallel dispatch, review gates, progress tracking, and context compression. If the user invokes a named super-planning phase, start there and continue forward."
metadata:
  user-invocable: true
---

# super-planning

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

**Why subagents:** Fresh context per task. They don't inherit your session history, preventing context pollution and keeping you free to coordinate.

**Core principle:** One subagent per task + review gates + file-based handoffs = high quality, low context, fast iteration.

**Scope:** Use this skill for end-to-end pre-implementation shaping and execution. Phase 1 includes the requirement-refinement work that used to live in `brainstorming`; use `commit-changes` downstream to commit final work.

## Phase Entry Router

Treat this file as an explicit, expandable router for entry phases.

| Invocation                    | Entry Phase  | Behavior                                                                                                                                                          | Load This First                                                                        |
| ----------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `/super-planning`             | `default`    | Run the standard end-to-end workflow. Start at Phase 1 unless there is already an approved spec in the repo.                                                      | This file, then follow the phase router below                                          |
| `/super-planning brainstorm`  | `brainstorm` | Start at Phase 1 and continue forward from there.                                                                                                                 | [`phases/01-brainstorm.md`](phases/01-brainstorm.md)                                   |
| `/super-planning spec`        | `spec`       | Start at Phase 2 and continue forward from there. Use only when brainstorm outputs already exist or the request is already well-defined enough to write the spec. | [`phases/02-spec.md`](phases/02-spec.md)                                               |
| `/super-planning plan`        | `plan`       | Start at Phase 3 and continue forward from there. Use only when there is already an approved spec.                                                                | [`phases/03-plan.md`](phases/03-plan.md)                                               |
| `/super-planning decompose`   | `decompose`  | Start at Phase 4 and continue forward from there. Use only when the implementation plan already exists.                                                           | [`phases/04-decompose.md`](phases/04-decompose.md)                                     |
| `/super-planning dispatch`    | `dispatch`   | Start at Phase 5 and continue forward from there. Use only when tasks are already decomposed and ready to execute.                                                | [`phases/05-dispatch.md`](phases/05-dispatch.md)                                       |
| `/super-planning review`      | `review`     | Start at Phase 6 and continue forward from there. Use only when implementation outputs already exist and are ready for review gates.                              | [`phases/06-review.md`](phases/06-review.md)                                           |
| `/super-planning integrate`   | `integrate`  | Start at Phase 7 and continue forward from there. Use only when reviewed outputs are ready to merge and finish.                                                   | [`phases/07-integrate.md`](phases/07-integrate.md)                                     |
| `/super-planning stats`       | `stats`      | Print a progress summary across all task registries. Aliases: `progress`, `task-stats`, `task-progress`.                                                          | This file, then run [`scripts/summarize-all-tasks.sh`](scripts/summarize-all-tasks.sh) |
| `/super-planning tool <name>` | `tool`       | Run one toolbox helper and stop. Does not enter a workflow phase.                                                                                                 | Toolbox routing below                                                                  |

**Routing rule:** If no subcommand is provided, always choose `default`.

**No-command orientation rule:** When the skill is invoked without a subcommand, do not silently enter the default workflow. First show the user a concise summary of the available entry options and what each one starts:

```text
Available super-planning entry points:
- default: full workflow; starts at Phase 1 unless an approved spec already exists
- brainstorm: start at Phase 1 — refine requirements and decisions
- spec: start at Phase 2 — write and approve the specification
- plan: start at Phase 3 — write the implementation plan
- decompose: start at Phase 4 — create the executable task registry
- dispatch: start at Phase 5 — dispatch implementation tasks
- review: start at Phase 6 — run review gates
- integrate: start at Phase 7 — run final verification and close the plan
- stats/progress: summarize task progress
- tool <name>: run one standalone helper without starting a phase
```

After presenting this summary, continue with the normal routing rule: use `default`, and resolve whether to begin at Phase 1 or Phase 3 based on the presence of an approved spec. The summary is informational; do not pause for a choice unless the user explicitly asks to choose an entry phase.

**Stats rule:** When the user invokes `/super-planning stats`, `/super-planning progress`, `/super-planning task-stats`, or `/super-planning task-progress`, run the active `summarize-all-tasks.sh` helper. Prefer the in-repo script at `super-planning/scripts/summarize-all-tasks.sh` when the skill is vendored; otherwise use the repo-local `.super-planning/summarize-all-tasks.sh` copied by Phase 4. Default scan directory is `docs/jobs`. Accept optional flags exactly as the script does: `--base-dir`, `--plan-id`, `--task-id` (requires `--plan-id`), `--json`. Produce only the script output plus a one-line note about the command used.

## Toolbox Router

`/super-planning tool <name>` runs exactly one named capability and then stops.
It never invokes the forward-only phase workflow. Resolve helpers from the
vendored skill first; otherwise use the complete `.super-planning/` bootstrap
manifest created by Phase 4.

| Toolbox command  | Purpose                                                                                                                                                        | Active helper / contract                                                                                                                    |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `doctor`         | Check Git, Python, Bash, Node (when visual companion is requested), worktree support, helper manifest, provenance, and schema availability before work begins. | `doctor.sh`; report actionable failures and do not mutate the registry.                                                                     |
| `bootstrap`      | Materialize or refresh the complete non-vendored helper manifest and provenance file.                                                                          | `bootstrap.sh --target-dir <repo>/.super-planning`.                                                                                         |
| `validate`       | Validate a registry or proposed task payload before it is persisted.                                                                                           | `super-plan.sh validate` / `append-task --validate-only` as available.                                                                      |
| `transition`     | Make one lifecycle transition through the helper guardrail.                                                                                                    | `super-plan.sh transition-task`, `transition-plan`, `complete-task`, or `complete-plan`; all validate the prior state and completion gates. |
| `render-task`    | Render one human-readable task brief.                                                                                                                          | `render-task-md.sh`.                                                                                                                        |
| `review-package` | Generate one review package from a recorded base commit.                                                                                                       | `review-package.sh`.                                                                                                                        |
| `stats`          | Summarize registries and task state.                                                                                                                           | `summarize-all-tasks.sh`.                                                                                                                   |

If the requested helper is unavailable, say which manifest item is missing and
run `tool bootstrap`; do not silently substitute a hand-written artifact.

**Forward-only rule:** When a phase name is provided, start at that phase and execute the remaining phases in order unless the user explicitly asks to stop earlier.

**Expansion rule:** Add new entry points to this table with four things only: invocation, entry phase, behavior, and the file to load first. Keep the default behavior unchanged unless the user explicitly asks for a different default.

## Quick Start

1. **If no subcommand was provided, show the available entry options summary** defined by the no-command orientation rule above.
2. **Announce the selected entry phase:** for example, "I'm using the super-planning skill starting at Phase 3: PLAN."
3. **Resolve the entry through the router above** before loading any phase file.
4. **Load the matching phase file first**, then continue through the remaining phases in order.
5. **Default entry:** if no subcommand is provided, use the normal workflow selection and start at Phase 1 unless there is already an approved spec.
6. **If Phase 1 becomes visual:** load [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md) before launching the companion.
7. **If Phase 4 records worktree isolation:** load [`phases/04_1-using-git-worktrees.md`](phases/04_1-using-git-worktrees.md) and complete it before Phase 5.

## Phase Router

| Phase          | Purpose                                                          | Load This                                            |
| -------------- | ---------------------------------------------------------------- | ---------------------------------------------------- |
| 1 — BRAINSTORM | Refine the idea into requirements and design decisions           | [`phases/01-brainstorm.md`](phases/01-brainstorm.md) |
| 2 — SPEC       | Write the feature spec and get user approval                     | [`phases/02-spec.md`](phases/02-spec.md)             |
| 3 — PLAN       | Write the implementation plan                                    | [`phases/03-plan.md`](phases/03-plan.md)             |
| 4 — DECOMPOSE  | Fill `super-plan.json` with atomic tasks and task-state metadata | [`phases/04-decompose.md`](phases/04-decompose.md)   |
| 4.1 — WORKTREE | Create or reuse the approved isolated implementation workspace   | [`phases/04_1-using-git-worktrees.md`](phases/04_1-using-git-worktrees.md) |
| 5 — DISPATCH   | Send subagents (sequential or parallel)                          | [`phases/05-dispatch.md`](phases/05-dispatch.md)     |
| 6 — REVIEW     | Spec compliance + code quality gates                             | [`phases/06-review.md`](phases/06-review.md)         |
| 7 — INTEGRATE  | Merge results, final review, finish                              | [`phases/07-integrate.md`](phases/07-integrate.md)   |

**Default rule:** Always run Phase 1 first when the user starts from an idea, request, or loose requirements. Skip it only when there is already an approved spec in the repo or when the user explicitly invoked a later phase.

> **Note:** `metadata.user-invocable: true` marks this skill as a direct entry point for the planning workflow, invocable by users via `/super-planning` and its phase subcommands.

## Decision Flow

```
Want progress stats?
├─ Yes → Run `scripts/summarize-all-tasks.sh`
└─ No → Have a feature idea or requirements for a multi-step task?
    ├─ No → Single trivial task? → Yes → Just do it inline, no skill needed
    └─ Yes → Approved spec already in docs/specs/?
        ├─ Yes → Skip to Phase 3 (PLAN), reference the spec number
        └─ No → Phase 1 (BRAINSTORM) → Phase 2 (SPEC)
            └─ After spec approval → Phase 3 (PLAN)
                └─ Tasks mostly independent AND no file conflicts?
                    ├─ Yes → PARALLEL MODE (dispatch all in one message)
                    └─ No  → SEQUENTIAL MODE (one at a time, review after each)
                        └─ Phase 7 (INTEGRATE) → All tasks done?
                            ├─ Yes → Done
                            └─ No  → Return to Phase 3 (PLAN) → Rerun remaining phases
```

## Shared Rules

- **Sequential mode:** one implementer + one reviewer according to `reviewCadence` (defined in [Phase 5 — DISPATCH](phases/05-dispatch.md)). Best for dependent tasks or overlapping files.
- **Parallel mode:** dispatch 2–4 subagents simultaneously. Review timing is controlled by `reviewCadence`; with `per_task`, launch all finished-task reviewers immediately after the implementer wave returns. Requires file-level isolation.
- **File-based handoffs:** task requirements live in `super-plan.json`; Phase 4 uses the helper stack in-place when the target repo already contains this `super-planning` skill, otherwise it bootstraps the complete manifest in `.super-planning/`: `super-plan.sh`, `super-update.sh`, `render-progress-ledger.sh`, `log-task.sh`, `review-package.sh`, `render-task-md.sh`, `summarize-all-tasks.sh`, and `super-plan.schema.json`. It also writes `super-planning-reference.json` from explicitly captured source-skill provenance (repository, ref, commit), never from the target application remote. Every later registry mutation must go through the active helper path, which regenerates the ledger immediately. Phase 5 materializes task directories, logging wrappers, and `progress.log`; Phase 6 materializes reports and review packages.
- **Branch/worktree decision gate** — before defining or changing the implementation branch, ask the user whether implementation should use a Git worktree. Do not infer consent from parallel mode, repository support, or a default value. Persist the answer in the plan handoff and `super-plan.json`. If the answer is yes, run the built-in [Phase 4.1 worktree workflow](phases/04_1-using-git-worktrees.md); if no, persist `worktree.enabled=false` and continue in the current checkout.
- **Never start implementation on `main`/`master`** without explicit user consent, always ask for permission.
- **Never re-dispatch a task** the ledger or log already marks complete.
- **Status lifecycle** — use one state machine everywhere: `pending → in_progress → ready_for_review → reviewing → needs_fix|blocked|completed|cancelled`. Only the orchestrator may mark `completed`, and only after review is clean.
- **Output summary** — after creating artifacts for the current phase, print a one-line summary showing each file path so the user knows what was produced. Phase 5 summaries include the task directory, logging files, and `progress-ledger.md`; Phase 6 summaries include the report and review package. Example: `Created: docs/specs/0001-auth-spec.md, docs/plans/0001-auth.md, docs/jobs/0001-auth/super-plan.json, docs/jobs/0001-auth/Task-A-1/log-task.sh, docs/jobs/0001-auth/progress-ledger.md`
- **Generated-document header** — every generated Markdown or text artifact must begin with a visible `Process: super-planning` marker and point the reader back to this skill and the active phase instructions. Preserve the marker when updating the artifact.
- **Testing strategy** — Phase 2 asks whether TDD is required for behavior changes, records the decision in the spec, and resolves the repository's `testing-anti-patterns.md` guidance file. Later phases propagate that decision and guidance path into task rules, acceptance criteria, dispatch, review, and final verification.
- **Pre-dispatch conflict gate** — before decomposition, scan task dependencies, global constraints, acceptance criteria, and parallel file ownership for contradictions. Resolve real conflicts in one batched user question before dispatch.
- **Review package** — record each task's base commit before dispatch and generate its package with `scripts/review-package.sh`; use the same base for fixes and `git merge-base` for the final branch audit.
- **Review closure** — unresolved `⚠️ Cannot verify` items and plan-mandated reviewer conflicts block completion until the orchestrator verifies them or gets a user decision.

### Portable watchdogs

- **Provider-neutral core:** use the optional `continuation` policy only to
  select `provider` and `watchdogProfile`; host APIs and IDs stay inside that
  provider's adapter folder.
- **Phase 4 materialization:** generate provider config below
  `.super-planning/watchdogs/`. Codex writes
  `codex-watchdogs.json` and independent prompts below `prompts/`.
- **Explicit opt-in:** before Phase 5 creates or updates automations, ask the
  user whether to enable watchdogs and which valid profile to use. Default is
  disabled; the Codex `default` profile uses continuation every 2 minutes and
  read-only status every 15 minutes.
- **Codex roles:** both `continuation` and `status` are heartbeats targeting
  the current thread. Status may interrupt an active run, but must only report
  evidenced state; it never edits files, changes lifecycle state, dispatches
  work, or creates automations. Do not substitute a cron, which opens another
  chat.
- **Cleanup:** pause every role on a human block and disable every role when a
  plan is completed or cancelled. Store automation/thread IDs only in ignored
  `.super-planning/continuations/<plan-id>.json` metadata.

## Outputs & Conventions

| Artifact             | Path                                                               | Template                                                                                                                                                                                          |
| -------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Brainstorm decisions | `docs/spec-decisions/{feature_number}_{feature_name}_decisions.md` | [`templates/decisions-template.md`](templates/decisions-template.md)                                                                                                                              |
| Spec                 | `docs/specs/NNNN-<feature-name>-spec.md`                           | [`templates/spec-template.md`](templates/spec-template.md)                                                                                                                                        |
| Plan                 | `docs/plans/NNNN-<feature-name>.md`                                | [`templates/plan-template.md`](templates/plan-template.md)                                                                                                                                        |
| Super plan           | `docs/jobs/NNNN-<feature-name>/super-plan.json`                    | Created and later mutated only via the active helper path: the in-repo skill scripts when available, otherwise the repo-local `.super-planning/super-plan.sh`, backed by the matching schema file |
| Task directory       | `docs/jobs/NNNN-<feature-name>/<task-id>/`                         | Contains task report, review package, local logger, and task progress log                                                                                                                         |
| Task progress log    | `docs/jobs/NNNN-<feature-name>/<task-id>/progress.log`             | [`templates/progress-template.txt`](templates/progress-template.txt)                                                                                                                              |
| Progress ledger      | `docs/jobs/NNNN-<feature-name>/progress-ledger.md`                 | Regenerated from `super-plan.json` and task logs by the active helper path after every registry write                                                                                             |
| Repo helpers         | `.super-planning/`                                                 | Only created when the target repo does not already contain this `super-planning` skill; holds the complete bootstrap helper manifest and schema                                                   |
| Skill reference      | `.super-planning/super-planning-reference.json`                    | Created from source-skill provenance; records source repository, ref, and exact helper commit                                                                                                     |
| Watchdog config      | `.super-planning/watchdogs/<provider>-watchdogs.json`              | Materialized provider profile and independent prompt files; never stores host IDs                                                                                                                  |

## Prompt Library

| Prompt                                                                   | Use When                                                          |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| [`prompts/pre-write-approval.md`](prompts/pre-write-approval.md)         | Before writing the spec                                           |
| [`prompts/post-write-approval.md`](prompts/post-write-approval.md)       | After writing the spec                                            |
| [`prompts/find-docs.md`](prompts/find-docs.md)                           | Verifying library/framework documentation during Phase 3          |
| [`agents/spec-document-reviewer.md`](agents/spec-document-reviewer.md)   | Reviewing spec readiness                                          |
| [`agents/general-executor.md`](agents/general-executor.md)               | Dispatching normal implementation tasks                           |
| [`agents/deep-executor.md`](agents/deep-executor.md)                     | Dispatching difficult or cross-cutting implementation tasks       |
| [`agents/investigator.md`](agents/investigator.md)                       | Dispatching read-only repository investigation                    |
| [`agents/code-reviewer.md`](agents/code-reviewer.md)                     | Dispatching a Phase 6 per-task reviewer                           |
| [`agents/spec-document-reviewer.md`](agents/spec-document-reviewer.md)   | Dispatching a Phase 2 spec document review before planning        |
| [`agents/spec-compliance-auditor.md`](agents/spec-compliance-auditor.md) | Dispatching a final whole-branch spec compliance audit in Phase 7 |
| [`platforms/continuation/`](platforms/continuation/)                     | Generic watchdog contract/template and provider-specific adapters |

## Dependencies

| Dependency | Version         | Required For                                                                                      | Notes                                                                                               |
| ---------- | --------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `python3`  | ≥ 3.9           | All scripts (super-plan.sh, render-progress-ledger.sh, summarize-all-tasks.sh, render-task-md.sh) | Required by the helper implementation and modern built-in generic typing                            |
| `bash`     | any modern Bash | Task lifecycle logging                                                                            | `log-task.sh` uses Bash and is intentionally a Bash helper; core registry scripts remain POSIX `sh` |
| `node`     | ≥ 18            | Visual companion (start-server.sh, stop-server.sh)                                                | Optional — only needed when using Phase 1 visual companion                                          |
| `git`      | any             | Review packages, spec-compliance auditor                                                          | Required for Phase 6 review gates and Phase 7 audit                                                 |

## See Also

- **Full visual flows:** [`README.md`](README.md)
- **Phase 1 visual companion:** [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md)
- **Phase 4.1 worktree setup:** [`phases/04_1-using-git-worktrees.md`](phases/04_1-using-git-worktrees.md)
- **Super-plan generator:** [`scripts/super-plan.sh`](scripts/super-plan.sh)
- **Helper updater:** [`scripts/super-update.sh`](scripts/super-update.sh)
- **Progress-ledger renderer:** [`scripts/render-progress-ledger.sh`](scripts/render-progress-ledger.sh)
- **Super-plan interface:** [`interfaces/super-plan.schema.json`](interfaces/super-plan.schema.json)
- **Progress logging helper:** [`scripts/log-task.sh`](scripts/log-task.sh)
- **Review package helper:** [`scripts/review-package.sh`](scripts/review-package.sh)
- **Task brief renderer:** [`scripts/render-task-md.sh`](scripts/render-task-md.sh)
- **All-tasks summarizer:** [`scripts/summarize-all-tasks.sh`](scripts/summarize-all-tasks.sh)
- **Environment doctor:** [`scripts/doctor.sh`](scripts/doctor.sh)
- **Non-vendored bootstrap:** [`scripts/bootstrap.sh`](scripts/bootstrap.sh)
