# Start message

After verifying target/workspace and resolving models, immediately before dispatch,
send this in the user's language. Continue without an approval gate.

```text
Starting review.
Target: <PR/branch/range/scope>; <base> → <head>; <uncommitted changes included>
Workspace: <absolute path>; <branch/detached>; <checkout or linked worktree>
Strategy: <coverage and parallel/sequential execution>

| Reviewer / mode | Profile | Requested model | Effort | Status |
| --- | --- | --- | --- | --- |
| <one row per selected agent> | <fast/strong> | <ID or inherited/unknown> | <supported/default> | Selected |

Final pass: <not indicated / conditional question / planned critical invariant>.
Limitations: <actual limitations only; omit if none>.
```

Verify workspace type; do not create a worktree for this message. Mark unknown
revisions explicitly. Identify different agent workspaces beside their rows.
Requested models are not verified execution; disclose unavailable controls.
After tool success, briefly confirm started/queued/failed agents and any confirmed
model difference. Never claim startup before dispatch succeeds.

Before additions, escalation or FINAL_PASS, announce role/model/effort and concrete
question; mention target/workspace changes, then dispatch and confirm. Reconciliation
is continuation. Without agents, state sequential review and lost independence;
do not simulate dispatch. If discovery is lengthy, acknowledge it before this template.
