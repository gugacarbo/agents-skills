# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate a single machine-readable registry that is the source of truth for the plan and every task.

## Bootstrap Repo-Local Helpers First

Before using the registry script, ensure the target repository has a `.super-planning/` directory with the full helper stack copied into it. If the directory or any dependency is missing, recreate or refresh it before proceeding.

Required files in the target repo:

- `.super-planning/super-plan.sh`
- `.super-planning/render-progress-ledger.sh`
- `.super-planning/super-plan.schema.json`

The goal is for Phase 4 to be executable from inside the target repo without depending on the skill source tree staying at the same path.

## Unified Registry (`super-plan.json`)

Create the registry in the plan's task directory with the repo-local `.super-planning/super-plan.sh`:

```
docs/tasks/{NNNN-<feature-name>}/super-plan.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/super-plan.json
```

The generator script materializes the file from the repo-local schema copy at `.super-planning/super-plan.schema.json`.

`super-plan.json` is the orchestrator-owned structured source of truth. It combines:

- plan governance and execution settings that used to live in `plan.json`
- requirements coverage and plan metadata
- the executable task registry that used to live in `tasks.json`

Run the generator first:

```bash
mkdir -p /absolute/path/to/workspace/.super-planning
cp /absolute/path/to/skills/super-planning/scripts/super-plan.sh /absolute/path/to/workspace/.super-planning/super-plan.sh
cp /absolute/path/to/skills/super-planning/scripts/render-progress-ledger.sh /absolute/path/to/workspace/.super-planning/render-progress-ledger.sh
cp /absolute/path/to/skills/super-planning/interfaces/super-plan.schema.json /absolute/path/to/workspace/.super-planning/super-plan.schema.json

sh /absolute/path/to/workspace/.super-planning/super-plan.sh \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --output docs/tasks/0003-auth-middleware/super-plan.json
```

Then make every later change through `.super-planning/super-plan.sh update`. Do not edit `super-plan.json` by hand.

Structure and field definitions live in `.super-planning/super-plan.schema.json`. All required fields must be present, including:

- `source.spec` and `source.plan`
- `goal`, `architectureSummary`, `techStack`
- `globalConstraints`, `fileStructure`, `requirementsChecklist`
- `reviewCadence`
- `taskDirectory`, `executionMode`, `branchStrategy`, `worktree`
- `tasks`

## Review Cadence Decision

Before finalizing `super-plan.json`, the orchestrator must explicitly ask the user when independent review should happen:

1. after each completed task
2. after each completed batch
3. only at the end of implementation

Persist the answer in `reviewCadence` using one of these values:

- `per_task`
- `per_batch`
- `final_only`

This field is required because it changes the dispatch and review loops in later phases. Do not guess unless the user has already made the preference explicit in the current planning flow.

Each task entry must still include:

- `batch` — execution batch label such as `A`, `B`, `C`
- `phase` — work classification such as `foundation`, `core`, `surface`, `final`

**Rules for status:**

- Set all tasks to `pending` when creating the registry.
- Update status after each dispatch/review cycle.
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `needs_fix`, `blocked`, `completed`.
- A task cannot move to `completed` until its review is clean.

**Ownership rule:** Subagents must not edit `super-plan.json`. Only the orchestrator updates it, and every orchestrator write must go through the script so the ledger stays synchronized.

**Execution rule:** `reviewCadence` controls when reviewer subagents launch:

- `per_task` — review starts as soon as a task reaches `ready_for_review`
- `per_batch` — review waits until the whole current batch reaches `ready_for_review`
- `final_only` — independent review is deferred to final integration

## Deferred Task Artifacts

Do not create per-task directories or `progress.log` in Phase 4.

Phase 4 defines the executable registry in `super-plan.json` and also materializes `progress-ledger.md` from that registry. Phase 6 is still responsible for materializing:

- `docs/tasks/{NNNN-<feature-name>}/{task-id}/`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/progress.log`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/log-task.sh`

Until Phase 6, treat only the per-task paths as planned artifact locations owned by later phases.
