# Reference: super-planning

Extended guidance for context compression, continuous execution, plan modification, error recovery, and red flags.

## Context Compression

Subagent tool results get injected verbatim into your context. Across many delegations this fills the window. Mitigate:

### File-Based Handoffs

Everything you paste into a dispatch prompt — and everything a subagent prints back — stays resident in your context. Hand artifacts over as files instead:

- **Task entry** → `super-plan.json` (subagent reads its entry, you don't carry it)
- **Report** → `docs/jobs/<plan>/<task-id>/report.md` (materialized in Phase 6; subagent writes or returns it, you get a one-line summary)
- **Review package** → `docs/jobs/<plan>/<task-id>/review-package.diff.md` (materialized in Phase 6; reviewer reads the diff from a file, you don't paste it)
- **Progress log/helper** → each task owns `docs/jobs/<plan>/<task-id>/progress.log` and `log-task.sh`, both first materialized in Phase 6

### Compressed Output

When the platform supports it, configure subagents to return compressed output (~60% less context than prose). Use the role-specific formats defined in the dispatch prompt templates:

- **Implementer output:** see [`prompts/implementer-guidance.md`](../prompts/implementer-guidance.md) → Compressed Output Format
- **Reviewer output:** see [`agents/code-reviewer.md`](../agents/code-reviewer.md) → Compressed Output Format
- **Investigator output:** used when dispatching an investigation subagent:
  ```
  ## Output Format:
  - Problem: <description>
  - Root Cause: <analysis>
  - Fix: <recommendation>
  - Impact: <high/medium/low>
  - Evidence: <file:line references>
  ```
  Always file-path-first, line-number-attached, backticked symbols.

**General principles:**

- Structured formats over prose
- One-line verdicts instead of explanations
- Each subagent's report file holds the detail; the controller gets only the structured summary

### Narration Discipline

Between tool calls, narrate at most one short line. The ledger and tool results carry the record. Progress summaries waste the user's time — they asked you to execute the plan, so execute it.

> **Note:** This discipline applies to EXECUTION MODE (subagent dispatch, tool calls). During interactive planning phases with the user, maintain natural conversation.

## Continuous Execution

Do not pause to check in between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are:

- **BLOCKED** status you cannot resolve
- Ambiguity that genuinely prevents progress
- All tasks complete

"Should I continue?" prompts waste time. If there's a genuine decision point, present it. Otherwise, keep going.

## Error Recovery

### Retry Limits

Each task has a `tryCount` in `super-plan.json`. The schema includes `maxTries` (default 3). The error recovery loop will not exceed `maxTries` attempts per task. After reaching the maximum:

1. **Stop retrying** — do not dispatch a 4th attempt with the same approach
2. **Assess the root cause** — re-read the task entry, the subagent's report, and the diff
3. **Change something before re-dispatching:**
   - **More context** — add missing information to the task entry or dispatch prompt
   - **Better model** — upgrade from cheap to standard, or standard to capable
   - **Smaller scope** — split the task into two or more smaller tasks
   - **Different approach** — rewrite the steps in the task entry
4. **If none of these help** — escalate to the user with a clear description of what failed and what was tried

### Failure Categories

| Failure Type                     | Response                                         |
| -------------------------------- | ------------------------------------------------ |
| Lint/type errors                 | Fix in same task, re-dispatch                    |
| Test failures                    | Fix in same task, re-dispatch                    |
| Scope violation                  | Reject, re-dispatch with tighter constraints     |
| BLOCKED (missing context)        | Provide context, re-dispatch                     |
| BLOCKED (architectural decision) | Escalate to user                                 |
| Repeated failures (3+)           | Assess root cause, change approach or split task |

### Task Status Transitions

```
pending → in_progress → ready_for_review → reviewing → completed
                              ├──────────→ needs_fix → in_progress
                              ├──────────→ blocked
pending, in_progress ────────→ cancelled
```

A task can only move to `completed` after both spec compliance and code quality reviews pass. The orchestrator updates `super-plan.json` after every state change through the active `super-plan.sh update` helper path, which also regenerates the ledger.

Implementer subagents log `ready_for_review`; only the orchestrator logs `completed`.

## Plan Modification

### Adding Tasks

When a gap is discovered during implementation:

1. Add the new task to `super-plan.json` through the script with the next available ID, appropriate `batch`, and appropriate `phase`
2. Set its `dependencies` to any tasks it depends on
3. Update the plan file's File Structure section if the new task touches files not previously listed
4. Dispatch the new task in the next batch

### Removing Tasks

When a task becomes unnecessary:

1. Set its status to `cancelled` through the script (do not delete it — keep the record)
2. Update any tasks that depended on it
3. Record the removal in the affected task's progress log, or in the ledger if the task never had a directory

### Changing Task Dependencies

When dependencies change mid-flight:

1. Update `dependencies` in the affected task entries through the script
2. If a task was planned for parallel execution but now depends on a task in the same batch, move it to the next batch
3. Do not change batch assignments of tasks that are already `in_progress`, `completed`, or `cancelled`

### When the Spec Changes

If the user requests a spec change during implementation:

1. **Pause dispatching** — do not start new tasks that may be affected
2. **Assess impact** — which tasks are affected? Which are already complete?
3. **Update the spec** — incorporate the change and re-approve with the user
4. **Update the plan and `super-plan.json`** — modify affected tasks through the script, add new tasks if needed
5. **Re-review completed tasks** — if a spec change affects already-completed work, flag it for re-review
6. **Resume dispatching** — continue from where you left off

## Red Flags

**Never:**

- Skip task review, or accept a report missing either verdict (spec compliance AND code quality are both required)
- Proceed with unfixed Critical/Important issues
- Dispatch multiple implementation subagents in parallel without file isolation or a platform fallback
- Make a subagent read the whole plan file (hand it its task entry from `super-plan.json` instead)
- Skip scene-setting context (subagent needs to understand where its task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance
- Dispatch a task reviewer without a diff file
- Move to the next task while the review has open Critical/Important issues
- Re-dispatch a task the progress ledger already marks complete
- Start implementation on main/master without explicit user consent
- Tell a reviewer what not to flag (the reviewer's job is independent assessment)
- Edit `super-plan.json` by hand or leave `progress-ledger.md` stale after a registry change

**If a subagent asks questions:** Answer clearly. Provide context. Don't rush them.

**If a reviewer finds issues:** Dispatch a fix subagent. Re-review. Don't skip the loop.

**If a subagent is BLOCKED:** Change something before re-dispatching — more context, a better model, or a smaller task scope.

## Integration with Other Skills

| Skill                   | When to use                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------- |
| **commit-changes**      | After this skill — commit the final changes                                           |
| **super-planning**      | This skill itself — use for any implementation plan that delegates work to subagents  |

## Sources

Key patterns in this skill were consolidated from:

| Source                                                | Key Contribution                                                                                                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| obra/superpowers `writing-plans`                      | Plan structure, task sizing, no-placeholders rule, self-review checklist, file structure, global constraints, interfaces block |
| obra/superpowers `subagent-driven-development`        | Fresh subagent per task, two-stage review, status signals, progress ledger, model selection, never start on main/master        |
| obra/superpowers `dispatching-parallel-agents`        | When/how to dispatch parallel subagents, independence criteria, common dispatch mistakes                                       |
| obra/superpowers `executing-plans`                    | Sequential execution with checkpoints, when to stop and ask for help                                                           |
| juliusbrussee/caveman (cavecrew)                      | Compressed output format per subagent role, ~60% context reduction per delegation                                              |
| obra/superpowers `implementer-prompt`                 | Template for implementer dispatch: before-you-begin, code organization, escalation, self-review                                |
| obra/superpowers `task-reviewer-prompt`               | Template for reviewer dispatch: do-not-trust-report, scope-limited, calibrated severity, output format                         |
| nibzard/awesome-agentic-patterns `sub-agent-spawning` | Three scales of spawning, practical 2-4 limit, trade-offs of parallelism                                                       |
| kaicianflone/parallel-orchestrate                     | Wave-based execution, pre-flight checks, scope violation detection, checkpoint recovery                                        |
