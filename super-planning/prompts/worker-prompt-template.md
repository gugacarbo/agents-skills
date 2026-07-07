---
name: worker-prompt-template
description: Minimal dispatch prompt template for subagents. Copy, fill the placeholders, dispatch.
---

# Worker Dispatch Prompt

> Copy this file, fill the placeholders, and pass to a subagent.
> This template is intentionally minimal — the subagent reads `super-plan.json` for the rest.

---

## Context (one line)

You are implementing [Task-X-NNNN] for [Project Name]. This is part of the [NNNN-<feature-name>] plan: `docs/plans/NNNN-<feature-name>.md`.

## Working Directory

`[absolute/path/to/workspace/root]`

All file operations must use absolute paths.

## Your Task

Read the task entry in `docs/tasks/[NNNN-<feature-name>]/super-plan.json` with `id: [Task-X-NNNN]`. That entry contains the complete requirements: files, interfaces, requirements, steps, acceptanceCriteria, and notes. You do not need to read any other file in the plan to do your work.

## Logging

Use the task-local logging wrapper to record every state change. The script is at:

`docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/log-task.sh`

If the orchestrator has already materialized Phase 6 task artifacts, use the absolute path it provided. That wrapper delegates to the shared helper path chosen by the orchestrator, with the shared plan/task/log-dir arguments already filled in. If not, return your status and report content so the orchestrator can persist them during Phase 6.

### Log on these events

| Event flag         | When                                        |
| ------------------ | ------------------------------------------- |
| `started`          | Right before you begin work                 |
| `ready_for_review` | After your last command and self-review     |
| `failed`           | After the last retry of a recoverable error |
| `blocked`          | When you cannot proceed and need help       |

### Usage

```sh
# At the start
bash /absolute/path/to/docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/log-task.sh --event started --try 1 --max-tries 3 --message "Starting implementation"

# When ready for review
bash /absolute/path/to/docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/log-task.sh --event ready_for_review --try 1 --max-tries 3 --message "All acceptance criteria met; commit abc1234"

# On failure (final retry)
bash /absolute/path/to/docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/log-task.sh --event failed --try 3 --max-tries 3 --message "Persistent import error after 3 tries"

# When blocked
bash /absolute/path/to/docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/log-task.sh --event blocked --try 1 --max-tries 3 --message "Missing database schema from Task-A-0003"
```

When present, the script appends a timestamped line to `docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/progress.log`. Adjust the try count to your actual current attempt.

## Hard Constraints

- Do **not** edit `docs/tasks/[NNNN-<feature-name>]/super-plan.json`. The orchestrator owns that file.
- Stay within the `filesTouched` and `files` block from your task entry.
- Do not run the full test suite unless your task entry requires it.
- Do not read the rest of the plan. You have everything you need in your task entry.

## What to Return

Return a one-line status to the orchestrator:

- `DONE` — all acceptance criteria met, code committed, `ready_for_review` log written
- `DONE_WITH_CONCERNS` — implemented but flag specific issues
- `NEEDS_CONTEXT` — describe what you need
- `BLOCKED` — describe the blocker

Then write or return the full report for `docs/tasks/[NNNN-<feature-name>]/[Task-X-NNNN]/report.md` with the following sections:

1. **What you implemented** (or what you attempted, if blocked)
2. **What you tested** and test results
3. **TDD Evidence** (if required by the task): RED command + failing output, GREEN command + passing output
4. **Files changed** (list of created, modified, deleted)
5. **Self-review findings** (if any)
6. **Issues or concerns**

---
