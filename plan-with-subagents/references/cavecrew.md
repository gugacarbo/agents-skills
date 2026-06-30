# Cavecrew — Compressed Subagent Output

Source: [juliusbrussee/caveman](https://github.com/JuliusBrussee/caveman) (78.3k stars, MIT license)

## Overview

Cavecrew defines three subagent presets (investigator, builder, reviewer) that return compressed "caveman" output (~60% less context) instead of prose. Subagent tool results get injected verbatim into the main context window, so compressing their output saves context budget across many delegations.

## When to Use Cavecrew vs Alternatives

| Task                                            | Use                                  |
| ----------------------------------------------- | ------------------------------------ |
| "Where is X defined / what calls Y"             | `cavecrew-investigator`              |
| Same but you also want architecture commentary  | Vanilla `Explore` agent              |
| Surgical edit, 1-2 files, scope obvious         | `cavecrew-builder`                   |
| New feature / 3+ files / cross-cutting refactor | Main thread or `plan-with-subagents` |
| Review diff, branch, or file for bugs           | `cavecrew-reviewer`                  |
| Deep code review with rationale                 | Vanilla `Code Reviewer`              |

**Rule of thumb:** If you'd want the subagent's output in 1/3 the tokens, pick cavecrew. If you'd want prose, pick vanilla.

## Output Contracts

**`cavecrew-investigator`:**

```
<path:line> — `symbol` — short note
totals: <counts>.
```

Or `No match.` Always file-path-first, line-number-attached, backticked symbols.

**`cavecrew-builder`:**

```
<path:line-range> — <change in ≤10 words>.
verified: <re-read OK | mismatch @ path:line>.
```

Or one of: `too-big.` / `needs-confirm.` / `ambiguous.` / `regressed.` (terminal first token).

**`cavecrew-reviewer`:**

```
path:line: <emoji> <severity>: <problem>. <fix>.
totals: N🔴 N🟡 N🔵 N❓
```

Or `No issues.` Findings sorted file → line ascending.

## Why This Matters for plan-with-subagents

When dispatching many subagents for implementation tasks, each subagent's report gets injected into your context. Using compressed output formats saves ~60% context per delegation. Over 10+ task delegations in a session, this is the difference between context exhaustion and completing the plan.

**Key insight for your prompts:** Require subagents to return structured, compressed reports instead of prose. A good report contract:

- Status (DONE/BLOCKED/NEEDS_CONTEXT)
- Commits (short SHA + subject)
- One-line test summary
- Path to detailed report file (the full report stays out of context)

This pattern comes from the superpowers `subagent-driven-development` skill, which uses file handoffs to keep bulk artifacts out of the controller's context.
