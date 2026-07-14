# Task Completion Notifier

An opt-in completion-notification skill for Codex, Cursor, GitHub Copilot, and
OpenCode. It deliberately distinguishes verified completion from progress and
uses a privacy-safe desktop summary.

## Supported delivery

| Platform | Manual notification                    | Lifecycle integration                              |
| -------- | -------------------------------------- | -------------------------------------------------- |
| Linux    | `notify-send`, graphical D-Bus session | Cursor, GitHub Copilot, OpenCode                   |
| macOS    | `osascript`                            | GitHub Copilot and hosts that can run Python hooks |
| Windows  | PowerShell toast                       | GitHub Copilot PowerShell hook                     |

The lifecycle mode is at-least-once until its state acknowledgment. A process
crash after a desktop notification can cause a later retry and duplicate.

## Manage an integration

```sh
# Preview a repository installation.
sh scripts/install-hooks.sh --repo /path/to/repo --targets cursor,copilot

# Apply the preview after approval.
sh scripts/install-hooks.sh --repo /path/to/repo --targets cursor,copilot --apply

# Update only files still matching their managed-install checksums.
sh scripts/install-hooks.sh --repo /path/to/repo --targets cursor,copilot --update --apply

# Inspect the installed runtime and desktop prerequisites.
sh scripts/install-hooks.sh --repo /path/to/repo --targets cursor,copilot --doctor

# Preview removal; use --apply to perform it.
sh scripts/install-hooks.sh --repo /path/to/repo --targets cursor,copilot --uninstall
```

For a GitHub Copilot user-level hook, use `--scope user --targets copilot`.
The repository still identifies the pending-delivery state; the copied runtime
lives under `XDG_DATA_HOME` or `~/.local/share`.

## Troubleshooting

- Linux requires `notify-send`, `DISPLAY` or `WAYLAND_DISPLAY`, and
  `DBUS_SESSION_BUS_ADDRESS`.
- macOS requires `osascript`.
- Windows requires a PowerShell runtime that can access the Windows toast API.
- Use `--doctor` before debugging a hook payload.
- Use `session-state.py gc --repo-root <repo>` to remove expired pending
  deliveries without removing an installed integration.
