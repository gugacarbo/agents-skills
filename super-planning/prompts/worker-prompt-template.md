---
name: worker-prompt-template
description: Minimal dispatch prompt template for subagents. Copy, fill the placeholders, dispatch.
---

# Worker Dispatch Prompt

> Copy this file, fill the placeholders, and pass to a subagent.
> This template is intentionally minimal — the subagent reads `tasks.json` for the rest.

---

## Context (one line)

You are implementing [Task-X-NNNN] for [Project Name]. This is part of the [NNNN-<feature-name>] plan: `docs/plans/NNNN-<feature-name>.md`.

## Working Directory

`[absolute/path/to/workspace/root]`

All file operations must use absolute paths.

## Your Task

Read the task entry in `docs/tasks/[NNNN-<feature-name>]/tasks.json` with `id: [Task-X-NNNN]`. That entry contains the complete requirements: files, interfaces, requirements, steps, acceptanceCriteria, and notes. You do not need to read any other file in the plan to do your work.

## Logging

Use the logging script to record every state change. The script is at `[path/to/scripts/log-task.sh]`.

It is also available relative to the skill at: `.agents/skills/super-planning/scripts/log-task.sh`.

### Log on these events

| Event flag | When |
|---|---|
| `started` | Right before you begin work |
| `completed` | After your last command and self-review |
| `failed` | After the last retry of a recoverable error |
| `blocked` | When you cannot proceed and need help |

### Usage

```sh
# At the start
bash scripts/log-task.sh --plan [NNNN-<feature-name>] --task [Task-X-NNNN] --event started --try 1 --max-tries 3 --message "Starting implementation"

# On success
bash scripts/log-task.sh --plan [NNNN-<feature-name>] --task [Task-X-NNNN] --event completed --try 1 --max-tries 3 --message "All acceptance criteria met; commit abc1234"

# On failure (final retry)
bash scripts/log-task.sh --plan [NNNN-<feature-name>] --task [Task-X-NNNN] --event failed --try 3 --max-tries 3 --message "Persistent import error after 3 tries"

# When blocked
bash scripts/log-task.sh --plan [NNNN-<feature-name>] --task [Task-X-NNNN] --event blocked --try 1 --max-tries 3 --message "Missing database schema from Task-A-0003"
```

The script auto-detects the workspace root and appends a timestamped line to `docs/tasks/[NNNN-<feature-name>]/progress.log`. The `3 3` in the examples means `try=3`, `maxTries=3`. Adjust the try count to your actual current attempt.

## Hard Constraints

- Do **not** edit `docs/tasks/[NNNN-<feature-name>]/tasks.json`. The orchestrator owns that file.
- Stay within the `filesTouched` and `files` block from your task entry.
- Do not run the full test suite unless your task entry requires it.
- Do not read the rest of the plan. You have everything you need in your task entry.

## What to Return

Return a one-line status to the orchestrator:

- `DONE` — all acceptance criteria met, code committed, log written
- `DONE_WITH_CONCERNS` — completed but flag specific issues
- `NEEDS_CONTEXT` — describe what you need
- `BLOCKED` — describe the blocker

Then write the full report to `docs/tasks/[NNNN-<feature-name>]/task-[Task-X-NNNN]-report.md` with the following sections:

1. **What you implemented** (or what you attempted, if blocked)
2. **What you tested** and test results
3. **TDD Evidence** (if required by the task): RED command + failing output, GREEN command + passing output
4. **Files changed** (list of created, modified, deleted)
5. **Self-review findings** (if any)
6. **Issues or concerns**

---
