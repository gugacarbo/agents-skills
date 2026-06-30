# parallel-orchestrate

**Source:** [kaicianflone/parallel-orchestrate](https://github.com/kaicianflone/parallel-orchestrate)

**Key contributions:**

- Wave-based execution: shred a plan into parallelizable subtasks, dispatch wave-by-wave
- Git worktree isolation per subagent to prevent file conflicts
- Pre-flight checks (repo state, base branch, tooling) before any dispatch
- Model selection heuristic: haiku for mechanical tasks (≤2 files, no UI), sonnet as default, opus only when explicitly requested
- Result JSON schema per task: status, commit SHA, base SHA, files changed, tests, lint
- Scope violation detection: if a commit modifies files outside declared Touches, reject
- Base lineage check: if commit parent ≠ integration point, re-dispatch rather than patch
- Checkpoint state in JSONL for crash recovery and resume
- Cross-task integration review after all parallel waves complete

**Relevant patterns for this skill:**

- The wave concept (foundation → core → surface) for ordering parallel execution
- Scope isolation via declared file Touches (writeable) and Forbidden lists
- Defensive reads of result JSON with jq fallbacks
- Fix-up subagent dispatch when suite fails at wave boundary
- Telemetry and duration tracking per wave

**Full SKILL.md:** see the GitHub repository for the complete skill (very long, gstack-specific).
