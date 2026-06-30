# Sub-Agent Spawning Pattern

> Source: https://github.com/nibzard/awesome-agentic-patterns/blob/main/patterns/sub-agent-spawning.md
> Status: validated-in-production
> Authors: Nikola Balic (@nibzard), based on Quinn Slack, Thorsten Ball, Will Larson

## Problem

Large multi-file tasks blow out the main agent's context window and reasoning budget. You need a way to delegate work to specialized agents with isolated contexts and tools.

## Solution

Let the main agent **spawn focused sub-agents**, each with its own fresh context, to work in parallel on shardable subtasks. Aggregate their results when done.

**Critical requirement**: Each subagent invocation must have a clear, specific task subject for traceability. Empty or generic subjects make parallel work untraceable and synthesis difficult.

## Key Principles

1. **Context isolation**: Each subagent has clean context window — no pollution from prior tasks
2. **Parallelization**: Reduce workflow latency through concurrent execution
3. **Specialization**: Different subagent types for different tasks (planning, thinking, analysis)
4. **Virtual files**: Precise control over what each subagent can see
5. **Tool scoping**: Limit subagent capabilities for security/simplicity

## Declarative YAML Configuration

Define subagent types with their own system prompts, allowed tools, and context windows:

```yaml
subagents:
  planning:
    system_prompt: "Break down complex tasks into steps..."
    tools: [list_files, read_file]

  implementer:
    system_prompt: "Implement exactly what the task specifies..."
    tools: all
```

## Dynamic Spawning for Parallel Execution

```pseudo
files = glob("**/*.md")
batches = chunk(files, 9)

for batch in batches:
    spawn_subagent(
        task="Update YAML front-matter in markdown files",
        files=batch,
        context=instructions
    )
```

**Parallel delegation best practices:**

- **Launch independent tasks simultaneously**: Don't explore A, then B, then C sequentially
- **Use clear task subjects**: Each subagent needs a traceable identity
- **Plan synthesis upfront**: Define how main agent will combine subagent findings
- **Limit to 2-4 subagents**: Observed maximum in effective sessions; more adds coordination overhead

## Three Scales of Spawning Architecture

| Scale                                         | Isolation                           | Use Case                    |
| --------------------------------------------- | ----------------------------------- | --------------------------- |
| **Virtual File Isolation** (2-4 subagents)    | Same-process, explicit file passing | Context management          |
| **Git Worktree Isolation** (10-100 subagents) | Filesystem-level, git worktrees     | Code migrations             |
| **Cloud Worker Spawning** (100+ agents)       | Container/VM isolation              | Enterprise-scale processing |

## When Subagents Matter Most

- Context window management (large file processing)
- I/O-bound workflows (network API calls)
- Code-driven workflows needing LLM delegation
- Massive parallelization needs (10+ concurrent agents)

## Trade-offs

**Pros:**

- Context isolation, parallelization, specialization, virtual files, declarative config

**Cons:**

- Spawning overhead, increased token cost, coordination complexity, latency visibility

## Production Implementations

- **Cursor AI**: Hierarchical spawning (Planner → Sub-Planners → Workers) with hundreds of concurrent agents
- **GitHub Agentic Workflows**: Event-driven agent spawning within CI infrastructure
- **Anthropic Claude Code**: 10x+ speedup on framework migrations using map-reduce over subagents

> Boris Cherny (Anthropic): "The main agent makes a big to-do list for everything and map reduces over a bunch of subagents. You instruct Claude like start 10 agents and then just go 10 at a time and just migrate all the stuff over."
