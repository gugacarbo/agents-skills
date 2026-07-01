---
name: worker-prompt-template
description: Minimal dispatch prompt template for subagents. Copy, fill the placeholders, dispatch.
---

# Worker Dispatch Prompt

> Copy this file, fill the placeholders, and pass to a subagent.
> This template is intentionally minimal — the subagent reads `tasks.json` and the `task-report-template.md` for the rest.

---

## Context (one line)

You are implementing [Task-X-NNNN] for [Project Name]. This is part of the [Plan Name] plan: [link to docs/plans/NNNN-plan-name.md].

## Working Directory

`[absolute/path/to/workspace/root]`

All file operations must use absolute paths.

## Your Task

Read the task entry in `docs/tasks/[NNNN-plan-name]/tasks.json` with `id: [Task-X-NNNN]`. That entry contains the complete requirements: files, interfaces, requirements, steps, acceptanceCriteria, and notes. You do not need to read any other file in the plan to do your work.

## Logging

Use the logging script to record every state change. The script is at `[path/to/scripts/log-task.sh]`.

It is also available relative to the skill at: `.agents/skills/super-planning/scripts/log-task.sh`.

### Log on these events

| Event | Status | When |
|---|---|---|
| `start` | STARTED | Right before you begin work |
| `success` | COMPLETED | After your last command and self-review |
| `fail` | FAILED | After the last retry of a recoverable error |
| `block` | BLOCKED | When you cannot proceed and need help |

### Usage

```sh
# At the start
bash scripts/log-task.sh [Task-X-NNNN] STARTED 1 3 "Starting implementation"

# On success
bash scripts/log-task.sh [Task-X-NNNN] COMPLETED 1 3 "All acceptance criteria met; commit abc1234"

# On failure (final retry)
bash scripts/log-task.sh [Task-X-NNNN] FAILED 3 3 "Persistent import error after 3 tries"

# When blocked
bash scripts/log-task.sh [Task-X-NNNN] BLOCKED 1 3 "Missing database schema from Task-A-0003"
```

The script auto-detects the workspace root and appends a timestamped line to `docs/tasks/[NNNN-plan-name]/progress.log`. The `3 3` in the examples means `try=3`, `maxTries=3`. Adjust the try count to your actual current attempt.

## Hard Constraints

- Do **not** edit `docs/tasks/[NNNN-plan-name]/tasks.json`. The orchestrator owns that file.
- Stay within the `filesTouched` and `files` block from your task entry.
- Do not run the full test suite unless your task entry requires it.
- Do not read the rest of the plan. You have everything you need in your task entry.

## What to Return

Return a one-line status to the orchestrator:

- `DONE` — all acceptance criteria met, code committed, log written
- `DONE_WITH_CONCERNS` — completed but flag specific issues
- `NEEDS_CONTEXT` — describe what you need
- `BLOCKED` — describe the blocker

Then write the full report to `docs/tasks/[NNNN-plan-name]/task-[Task-X-NNNN]-report.md` using the `task-report-template.md` format.

---
