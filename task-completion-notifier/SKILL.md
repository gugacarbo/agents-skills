---
name: task-completion-notifier
description: Use only when the user explicitly asks to enable task-completion system notifications. After completing and verifying each requested task, run the bundled notifier before the final response; do not infer this mode from a task or send notifications for progress updates.
compatibility: Ubuntu desktop only in v1; requires notify-send and an active graphical D-Bus session.
---

# Task Completion Notifier

Activate this skill only after the user explicitly requests completion
notifications. Do not activate it from an implied preference, a task title, or
an earlier unrelated request.

## Hook installation

At the start of an explicitly activated use, ask whether the user wants to
install repository hooks. If they decline, continue with the manual workflow
below and do not modify the repository.

If they accept, ask which integrations to install: Codex, GitHub Copilot,
OpenCode, Cursor, or any combination. Preview the selected changes with:

```sh
sh scripts/install-hooks.sh --repo "<repository-root>" --targets "<comma-separated-targets>"
```

When the preview reports an existing hook configuration or marketplace entry,
show the affected files and ask for explicit approval to merge. Only after the
user approves, rerun the same command with `--approve-merge`. Never overwrite
an existing runtime or unrelated hook entry automatically.

Installed templates all call the repository-local shared dispatcher at
`.task-completion-notifier/scripts/hook-dispatch.py`; they must never call
`notify-send` directly.

## When to notify

A task is complete only when the requested work and its appropriate verification
are complete. Progress updates, partial results, plans, and blocked work are
not completed tasks.

Before sending the final response for a completed task, run:

```sh
sh scripts/notify.sh --message "<concise completed-task summary>"
```

Use `--title` only when a task-specific title is clearer. Wait for the command
to finish successfully before the final response.

When hooks are installed, first activate the shared state before completing the
task:

```sh
python3 .task-completion-notifier/scripts/session-state.py activate \
  --state-dir .task-completion-notifier/state \
  --session-id default
```

The installed lifecycle hook then calls the dispatcher automatically when the
agent reaches its completion event. Deactivate the same `default` session when
the user explicitly turns notification mode off.

## Failure contract

If the notifier exits non-zero, tell the user that the operating-system
notification was not delivered and include the command error. Do not claim that
the notification was sent. Still provide the task result unless the user made
notification delivery a completion requirement.

## Boundaries

- The v1 script supports Ubuntu desktop only.
- Do not run the script for an intermediate commentary update.
- Do not run it after the final response.
- Do not replace the script with a hand-written notification command; the
  bundled dispatcher owns platform selection and capability checks.
