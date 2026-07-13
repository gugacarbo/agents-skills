---
name: task-completion-notifier
description: Use only when the user explicitly asks to be notified on the desktop or system when a task finishes, including phrases such as "me avise quando terminar", "manda uma notificacao", "notify me when done", or "desktop alert on completion". Send one notification attempt only after verified completion; never infer this preference or notify plans, progress, questions, cancellations, or blocked work.
metadata:
  compatibility: Python 3.9+; Linux with notify-send and a graphical D-Bus session, macOS with osascript, or Windows with PowerShell toast support.
---

# Task Completion Notifier

Activate only for the task or conversation scope the user explicitly selected.
If the user does not specify a scope, notify once for the current request only.

## Delivery contract

Use **manual delivery** by default. After verification and before the completed
final response, make one attempt:

```sh
python3 "<skill-root>/scripts/notify.py" \
  --message "<concise, non-sensitive completed-task summary>"
```

Wait for the command. If it fails, say that no OS notification was delivered
and include the error while still returning the task result unless delivery was
an explicit completion requirement.

Use a **lifecycle hook** only when the user explicitly requested installation
and the selected host provides the current session ID. Do not send a manual
notification in this mode. Arm a delivery after verification:

```sh
python3 "<skill-root>/scripts/session-state.py" arm \
  --repo-root "<repository-root>" \
  --agent "<github-copilot|cursor|opencode>" \
  --session-id "<host-session-id>" \
  --delivery-id "<stable-id-for-this-completed-task>" \
  --message "<concise, non-sensitive completed-task summary>"
```

Hook delivery is **at-least-once until acknowledgment**. A crash after the OS
notification but before its acknowledgment can produce a later duplicate; do
not claim confirmed delivery in the final response. If confirmation before the
final response matters, use manual delivery instead.

## Installation and lifecycle management

Ask whether the user wants repository or supported user-level integration;
never create configuration without consent. Preview first:

```sh
sh "<skill-root>/scripts/install-hooks.sh" \
  --repo "<repository-root>" --targets "<comma-separated-targets>"
```

Show listed conflicts, obtain explicit approval, then rerun with `--apply`.
Use `--scope user --targets copilot` for the supported Copilot user-level
installation. Cursor and GitHub Copilot hook entries are merged; modified
dedicated runtime, OpenCode, or Codex files are never overwritten.

```sh
# Safely update an unmodified managed installation.
sh "<skill-root>/scripts/install-hooks.sh" \
  --repo "<repository-root>" --targets "<targets>" --update --apply

# Diagnose dependencies, managed version, and selected configuration.
sh "<skill-root>/scripts/install-hooks.sh" \
  --repo "<repository-root>" --targets "<targets>" --doctor

# Preview removal; add --purge-state only when pending local state should go too.
sh "<skill-root>/scripts/install-hooks.sh" \
  --repo "<repository-root>" --targets "<targets>" --uninstall
```

Pending summaries live under `XDG_STATE_HOME` (or `~/.local/state`) and have a
one-hour expiry. The Codex target is a manual skill plugin, not a lifecycle
hook: after registration in a repository marketplace, install or reinstall it
there to activate changes.

## Privacy and boundaries

- Use a generic completion summary; never include secrets, tokens, private
  prompts, or sensitive paths. The notifier also shortens messages and redacts
  common token and user-path patterns.
- Never invoke `notify-send`, `osascript`, or PowerShell directly; use the
  bundled notifier.
- Do not notify a cancelled or blocked task, even if the user previously opted
  into notifications.
