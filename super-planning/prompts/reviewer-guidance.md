# Task Reviewer Guidance

When dispatching a reviewer subagent, include these principles in the prompt.

## Task Registry (`tasks.json`) and Progress Log

- Do **not** create, modify, or delete the `tasks.json` registry file or the `progress.log` file. Both are owned and updated by the orchestrator.
- Read the relevant task entry from `tasks.json` as your source of requirements.
- If instructed, log your review start/completion using the orchestrator-provided helper (e.g. `scripts/log-task.sh`). Never write to `progress.log` directly.

## Core Principles

**Do Not Trust the Report:** Treat the implementer's report as unverified claims. Verify claims against the diff. Design rationales in the report are claims too — judge the code on its merits.

**Scope-Limited:** The reviewer only reviews the task's changes (the diff from base to head), not the whole branch. This keeps the review focused and context-efficient.

**Tests:** The implementer already ran tests and reported results. The reviewer should not re-run the suite. Run a test only when reading the code raises a specific doubt.

**Calibrated Severity:** Not everything is Critical. Use severity levels honestly:

- **Critical** = must fix before proceeding, blocks all downstream work
- **Important** = should fix, blocks merge but not necessarily further tasks
- **Minor** = nice to have, record for final review

Every finding needs a concrete `file:line` location, what's wrong, why it matters, and how to fix it.

**Strengths:** The review should also capture what's well done — not just issues. This helps the implementer understand what to keep doing and provides balanced feedback.

## Reviewer Input

The reviewer gets exactly three things:

1. **The task entry** from `tasks.json` (same one the implementer used)
2. **The implementer's report file**
3. **The review package** (diff file generated via git)

Read the diff file once — it contains the commit list, a stat summary, and the full diff with surrounding context. Do not re-run git commands. Do not crawl the broader codebase.

The review is read-only. Do not mutate the working tree.

## Output Format

```
### Spec Compliance
- ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood, with file:line]
- ⚠️ Cannot verify from diff: [requirements you could not verify]

### Strengths
[What's well done? Be specific.]

### Issues
#### Critical (Must Fix)
#### Important (Should Fix)
#### Minor (Nice to Have)

For each issue: file:line, what's wrong, why it matters, how to fix.

### Assessment
**Task quality:** [Approved | Needs fixes]
**Reasoning:** [1-2 sentence technical assessment]
```

## What NOT to Give the Reviewer

- Open-ended directives like "check all uses"
- Instructions to ignore or not flag specific issues
- The entire plan file (only their task entry from tasks.json)

## Compressed Reviewer Output

When the platform supports it, use this compressed format (~60% less context than prose):

```
path:line: <emoji> <severity>: <problem>. <fix>.
totals: N🔴 N🟡 N🔵 N❓
```

Or `No issues.` Findings sorted file → line ascending. Emoji severity: 🔴 Critical, 🟡 Important, 🔵 Minor, ❓ Cannot verify.
