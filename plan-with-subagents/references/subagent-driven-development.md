# Subagent-Driven Development (Reference)

Source: obra/superpowers — https://github.com/obra/superpowers/tree/main/skills/subagent-driven-development

This is a reference copy. The canonical version lives in the superpowers repository.

## Key Concepts

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

### Core Principle

Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration.

### Why Subagents

You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

### Model Selection

Use the least powerful model that can handle each role:

- **Mechanical tasks** (isolated functions, clear specs, 1-2 files): fast, cheap model
- **Integration/judgment tasks** (multi-file coordination, pattern matching): standard model
- **Architecture/design tasks**: most capable model
- **Review tasks**: scale to the diff's size, complexity, and risk

Always specify the model explicitly when dispatching a subagent.

### Handling Implementer Status

- **DONE**: Proceed to review
- **DONE_WITH_CONCERNS**: Read concerns before proceeding
- **NEEDS_CONTEXT**: Provide missing context and re-dispatch
- **BLOCKED**: Assess blocker, escalate if needed

### File Handoffs

- **Task brief**: Extract task text to a uniquely named file
- **Report file**: Implementer writes full report to a file, returns only status + summary
- **Reviewer inputs**: Brief file + report file + review package + global constraints

### Durable Progress

Track progress in a ledger file, not only in todos. Tasks listed as complete are DONE — do not re-dispatch them. After compaction, trust the ledger and git log over your own recollection.

### Red Flags

- Never start implementation on main/master without explicit consent
- Never skip task review
- Never dispatch multiple implementation subagents in parallel on the same branch
- Never make a subagent read the whole plan file — hand it its task brief instead
- Never accept "close enough" on spec compliance
- Never tell a reviewer what not to flag

## Prompt Templates

See `implementer-prompt.md` and `task-reviewer-prompt.md` in this references directory for the dispatch templates.
