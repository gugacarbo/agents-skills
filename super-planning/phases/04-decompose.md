# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate a single machine-readable registry that is the source of truth for the plan and every task.

## Unified Registry (`super-plan.json`)

Create the registry in the plan's task directory with [`scripts/super-plan.sh`](../scripts/super-plan.sh):

```
docs/tasks/{NNNN-<feature-name>}/super-plan.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/super-plan.json
```

The generator script materializes the file from the separate interface contract at [`interfaces/super-plan.schema.json`](../interfaces/super-plan.schema.json).

`super-plan.json` is the orchestrator-owned structured source of truth. It combines:

- plan governance and execution settings that used to live in `plan.json`
- requirements coverage and plan metadata
- the executable task registry that used to live in `tasks.json`

Run the generator first, then fill in the resulting file:

```bash
sh /absolute/path/to/super-planning/scripts/super-plan.sh \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --output docs/tasks/0003-auth-middleware/super-plan.json
```

Structure and field definitions live in [`interfaces/super-plan.schema.json`](../interfaces/super-plan.schema.json). All required fields must be present, including:

- `source.spec` and `source.plan`
- `goal`, `architectureSummary`, `techStack`
- `globalConstraints`, `fileStructure`, `requirementsChecklist`
- `taskDirectory`, `executionMode`, `branchStrategy`, `worktree`
- `tasks`

Each task entry must still include:

- `batch` — execution batch label such as `A`, `B`, `C`
- `phase` — work classification such as `foundation`, `core`, `surface`, `final`

**Rules for status:**

- Set all tasks to `pending` when creating the registry.
- Update status after each dispatch/review cycle.
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `needs_fix`, `blocked`, `completed`.
- A task cannot move to `completed` until its review is clean.

**Ownership rule:** Subagents must not edit `super-plan.json`. Only the orchestrator updates it.

## Deferred Task Artifacts

Do not create per-task directories, `progress.log`, or `progress-ledger.md` in Phase 4.

Phase 4 only defines the executable registry in `super-plan.json`. Phase 6 is responsible for materializing:

- `docs/tasks/{NNNN-<feature-name>}/{task-id}/`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/progress.log`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/log-task.sh`
- `docs/tasks/{NNNN-<feature-name>}/progress-ledger.md`

Until then, treat those paths as planned artifact locations owned by later phases.
