# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate a single machine-readable registry that is the source of truth for the plan and every task.

## Resolve the Active Helper Path First

Before using the registry script, decide which helper path is active for this run:

1. **If the target repository already contains this `super-planning` skill**, do **not** create `.super-planning/`. Use the helper files directly from the skill directory already present in that repo.
2. **If the target repository does not contain this skill**, create `.super-planning/` and copy the helper stack there before proceeding.

Fallback helper files when bootstrap is required:

- `.super-planning/super-plan.sh`
- `.super-planning/render-progress-ledger.sh`
- `.super-planning/super-plan.schema.json`

The goal is to avoid a duplicate helper directory when the skill already lives in the repository, while still keeping the flow self-contained for repositories that do not vendor the skill.

## Unified Registry (`super-plan.json`)

Create the registry in the plan's task directory with the active helper path:

```
docs/tasks/{NNNN-<feature-name>}/super-plan.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/super-plan.json
```

The generator script materializes the file from the matching schema file in the active helper path.

`super-plan.json` is the orchestrator-owned structured source of truth. It combines:

- plan governance and execution settings that used to live in `plan.json`
- requirements coverage and plan metadata
- the executable task registry that used to live in `tasks.json`

Run the generator first.

When the skill is already inside the target repository:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --output docs/tasks/0003-auth-middleware/super-plan.json
```

When the skill is not inside the target repository:

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

Then make every later change through that same active helper path. Do not edit `super-plan.json` by hand.

Structure and field definitions live in the schema file from the active helper path. All required fields must be present, including:

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
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `needs_fix`, `blocked`, `completed`, `cancelled`.
- A task cannot move to `completed` until its review is clean.
- Use `cancelled` only when the orchestrator decides to retire a task while keeping the audit trail in the registry.

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
