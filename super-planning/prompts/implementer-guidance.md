# Implementer Guidance

Include these expectations when constructing dispatch prompts for implementers.

## Before Starting Work

If anything in your task entry from `tasks.json` is unclear — requirements, approach, dependencies, assumptions — ask questions before proceeding. Don't guess or make assumptions.

## Task Registry (`tasks.json`)

- Do **not** create, modify, or delete the `tasks.json` registry file. It is owned and updated by the orchestrator.
- Read the relevant task entry from `tasks.json` as your source of requirements.
- Report status and outcomes in your report file; the orchestrator will update `tasks.json` based on your report.

## Code Organization

- Follow the file structure defined in the plan
- Each file should have one clear responsibility with a well-defined interface
- If a file you're creating is growing beyond the plan's intent, stop and report it as DONE_WITH_CONCERNS — don't split files on your own without plan guidance
- In existing codebases, follow established patterns

## When You're in Over Your Head — STOP and Escalate When

- The task requires architectural decisions with multiple valid approaches
- You need to understand code beyond what was provided and can't find clarity
- You feel uncertain about whether your approach is correct
- You've been reading file after file trying to understand the system without progress

Escalate with BLOCKED or NEEDS_CONTEXT status, describing specifically what you're stuck on, what you've tried, and what kind of help you need.

## Self-Review Before Reporting Back

- **Completeness:** Did I fully implement everything in the spec? Missed requirements? Edge cases?
- **Quality:** Is this my best work? Names clear and accurate? Code clean and maintainable?
- **Discipline:** Did I avoid overbuilding (YAGNI)? Did I only build what was requested?
- **Testing:** Do tests verify behavior (not just mock behavior)? Comprehensive? Output pristine?

## TDD Evidence (When Task Specifies TDD)

- RED: show the failing test command and its output
- GREEN: show the passing test command and its output
- Not just "tests pass" — prove they failed first

## Compressed Output Format

```
<path:line-range> — <change in ≤10 words>.
verified: <re-read OK | mismatch @ path:line>.
```

Or one of: `too-big.` / `needs-confirm.` / `ambiguous.` / `regressed.` (terminal first token).

## Report Format

Write your full report to the report file path provided in the dispatch prompt:

- What you implemented (or what you attempted, if blocked)
- What you tested and test results
- TDD Evidence (if required): RED command + failing output, GREEN command + passing output
- Files changed
- Self-review findings (if any)
- Any issues or concerns

## Progress Logging

You must log task lifecycle events using the helper script provided by the orchestrator. Do **not** write to `progress.log` directly.

Call the script at minimum for these events:

- `started` — when you begin working on the task
- `completed` — when the task passes acceptance criteria
- `failed` — when the task fails and cannot proceed without intervention
- `blocked` — when you cannot continue and need context/help

Example:

```bash
bash .agents/skills/super-planning/scripts/log-task.sh \
  --plan 0003-auth-middleware \
  --task Task-A-0001 \
  --event started \
  --try 1 \
  --max-tries 3 \
  --message "Beginning implementation"
```

Then report back with ONLY (under 15 lines — detail lives in the report file):

- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line test summary
- Your concerns, if any
- The report file path
