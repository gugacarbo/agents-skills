# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate the task directory and a single machine-readable registry that is the source of truth for every task.

## Task Registry (JSON)

Create the registry in the plan's task directory:

```
docs/tasks/{NNNN-<feature-name>}/tasks.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/tasks.json
```

The registry is the implementer's single source of requirements. It contains the exact values, code, and acceptance criteria.

Structure and field definitions: see [`templates/tasks-template.json`](../templates/tasks-template.json). All required fields must be present.

**Rules for status:**

- Set all tasks to `pending` when creating the registry.
- Update status after each dispatch/review cycle.
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `needs_fix`, `blocked`, `completed`.
- A task cannot move to `completed` until its review is clean.

## Per-Task Directories

For every task, create a task-specific directory under the plan directory:

```
docs/tasks/{NNNN-<feature-name>}/{task-id}/
```

Example:

```
docs/tasks/0003-auth-middleware/Task-A-0001/
```

Each task directory contains the task's report, review package, local logging helper, and append-only progress log.

## Progress Log

Track progress in an append-only log file inside the task's own directory:

```
docs/tasks/{NNNN-<feature-name>}/{task-id}/progress.log
```

Format: see [`templates/progress-template.txt`](../templates/progress-template.txt).

The log is append-only. Subagents must NOT write to it directly. Copy [`scripts/log-task.sh`](../scripts/log-task.sh) into each task directory as `log-task.sh`, make it executable, and dispatch the subagent with the absolute path to that local helper:

```bash
bash /absolute/path/to/docs/tasks/0003-auth-middleware/Task-A-0001/log-task.sh \
  --plan 0003-auth-middleware \
  --task Task-A-0001 \
  --event started \
  --try 1 \
  --max-tries 3 \
  --message "Beginning implementation"
```

Subagents must log events at minimum for: `started`, `ready_for_review`, `failed`, `blocked`.

Only the orchestrator logs `completed`, after both spec compliance and code quality review are clean.

## Progress Ledger

Create a human-readable markdown table at:

```
docs/tasks/{NNNN-<feature-name>}/progress-ledger.md
```

Use [`templates/progress-ledger-template.md`](../templates/progress-ledger-template.md). Columns: Task, Status, Commits, Report File, Review.

**When to update the ledger:**

- **After creating tasks.json** — initialize all tasks as ⏳ pending
- **After dispatching a subagent** — set status to 🔄 in progress
- **After implementer returns DONE/DONE_WITH_CONCERNS** — set status to 🔎 ready_for_review
- **After review completes cleanly** — set status to ✅ complete, record commit range
- **After review finds issues** — set status to 🔁 needs-fix, record findings
- **After a subagent is BLOCKED** — set status to ❌ blocked
- **In Phase 7** — final status update for all tasks

The ledger survives context compaction. After compaction, trust the ledger, the progress log, and `git log` over your own recollection. Never re-dispatch a task the ledger or log marks complete.
