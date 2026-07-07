# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate a single machine-readable registry that is the source of truth for the plan and every task.

## Resolve the Active Helper Path First

Before using the registry script, decide which helper path is active for this run:

1. **If the target repository already contains this `super-planning` skill**, do **not** create `.super-planning/`. Use the helper files directly from the skill directory already present in that repo.
2. **If the target repository does not contain this skill**, create `.super-planning/` and copy the helper stack there before proceeding.

Fallback helper files when bootstrap is required:

- `.super-planning/super-plan.sh`
- `.super-planning/render-progress-ledger.sh`
- `.super-planning/super-plan.schema.json`

The goal is to avoid a duplicate helper directory when the skill already lives in the repository, while still keeping the flow self-contained for repositories that do not vendor the skill.

## Unified Registry (`super-plan.json`)

Create the registry in the plan's task directory with the active helper path:

```
docs/tasks/{NNNN-<feature-name>}/super-plan.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/tasks/0003-auth-middleware/super-plan.json
```

The generator script materializes the file from the matching schema file in the active helper path.

`super-plan.json` is the orchestrator-owned structured source of truth. It combines:

- plan governance and execution settings that used to live in `plan.json`
- requirements coverage and plan metadata
- the executable task registry that used to live in `tasks.json`

Run the generator first.

When the skill is already inside the target repository:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --output docs/tasks/0003-auth-middleware/super-plan.json
```

When the skill is not inside the target repository:

```bash
mkdir -p /absolute/path/to/workspace/.super-planning
cp /absolute/path/to/skills/super-planning/scripts/super-plan.sh /absolute/path/to/workspace/.super-planning/super-plan.sh
cp /absolute/path/to/skills/super-planning/scripts/render-progress-ledger.sh /absolute/path/to/workspace/.super-planning/render-progress-ledger.sh
cp /absolute/path/to/skills/super-planning/interfaces/super-plan.schema.json /absolute/path/to/workspace/.super-planning/super-plan.schema.json

sh /absolute/path/to/workspace/.super-planning/super-plan.sh \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --output docs/tasks/0003-auth-middleware/super-plan.json
```

Then make every later change through that same active helper path. Do not edit `super-plan.json` by hand.

Structure and field definitions live in the schema file from the active helper path. All required fields must be present, including:

- `source.spec` and `source.plan`
- `goal`, `architectureSummary`, `techStack`
- `globalConstraints`, `fileStructure`, `requirementsChecklist`
- `reviewCadence`
- `agents.general|deep|quick` with `{ "model": "", "agent": "" }` defaults when discovery is unavailable
- `taskDirectory`, `executionMode`, `branchStrategy`, `worktree`
- `tasks`

## Subagent Profile Discovery

Before finalizing `super-plan.json`, the orchestrator must attempt platform-native auto-discovery for subagent execution profiles.

Discover three profiles:

- `general` — default/general-purpose subagent for most implementation tasks
- `deep` — best available profile for difficult, ambiguous, or architecture-heavy tasks
- `quick` — fastest/lightest profile for narrow, mechanical work

Use the tools available in the current platform to discover:

- subagents/agents that can be dispatched
- models that can be paired with those subagents

Use platform-native list/discovery tools first. When multiple discovery tools are available, prefer the ones that return callable/current options instead of static docs.

After collecting the discovery result, the orchestrator must present it to the user and ask them to choose how to proceed.

**Preferred interaction rule:** if the current platform exposes an ask/confirm/question tool for structured user input, including `request_user_input` / a request user input tool, and the current collaboration mode/session allows that tool to be called, the orchestrator must use that tool instead of a plain text question. Use the structured prompt to:

1. show the discovered agents and models
2. show the recommended `general`, `deep`, and `quick` configuration
3. let the user choose one of these paths:
   - accept the recommendation
   - provide a manual override
   - keep the configuration empty/default

**Fallback interaction rule:** if the current platform does not expose a structured ask/confirm/question tool such as `request_user_input`, or if the current collaboration mode/session does not allow calling it, the orchestrator must fall back to a normal text message asking the same question.

After discovery:

1. Recommend a configuration for `agents.general`, `agents.deep`, and `agents.quick`
2. Ask the user to choose recommendation, manual override, or empty/default config
3. Persist the user-approved result in `super-plan.json`
4. If no compatible options are discoverable, leave all `model` and `agent` fields empty unless the user provides a manual override

Required fallback behavior when discovery fails:

1. Tell the user that auto-discovery did not find subagent/model options on the current platform
2. Use the structured ask/confirm/question tool, including `request_user_input` when available, and allowed in the current mode/session to ask whether they want to provide a manual override
3. If the platform has no structured ask/confirm/question tool such as `request_user_input`, or the current mode/session disallows it, ask via plain text
4. If the user does not provide an override, keep the fields empty

Recommended structured prompt content:

- available agents
- available models
- recommended configuration
- a short note about platform limitations such as missing worktree isolation or missing explicit model selection

Recommended user choices:

- `Use Recommended`
- `Manual Override`
- `Use Defaults/Empty`

Required shape:

```json
{
  "agents": {
    "general": { "model": "", "agent": "" },
    "deep": { "model": "", "agent": "" },
    "quick": { "model": "", "agent": "" }
  }
}
```

## Review Cadence Decision

Before finalizing `super-plan.json`, the orchestrator must explicitly ask the user when independent review should happen:

1. after each completed task
2. after each completed batch
3. only at the end of implementation

Persist the answer in `reviewCadence` using one of these values:

- `per_task`
- `per_batch`
- `final_only`

This field is required because it changes the dispatch and review loops in later phases. Do not guess unless the user has already made the preference explicit in the current planning flow.

When presenting the options, make the dispatch behavior explicit:

- `per_task` — as soon as a task finishes, dispatch a reviewer subagent for that task
- `per_batch` — once the whole batch finishes, dispatch a reviewer subagent for the batch
- `final_only` — skip implementation-time review, but still dispatch one reviewer subagent per batch during final integration

Each task entry must still include:

- `task_profile` — one of `general`, `deep`, or `quick`
- `batch` — execution batch label such as `A`, `B`, `C`
- `phase` — work classification such as `foundation`, `core`, `surface`, `final`

`task_profile` is mandatory and represents the intended execution complexity/profile for that task:

- `quick` — narrow, mechanical, low-risk work
- `general` — normal implementation/debugging work
- `deep` — harder debugging, architecture, cross-file integration, or subtle reasoning

Do not leave tasks uncategorized. Every task in `super-plan.json` must have a `task_profile`.

**Rules for status:**

- Set all tasks to `pending` when creating the registry.
- Update status after each dispatch/review cycle.
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `needs_fix`, `blocked`, `completed`, `cancelled`.
- A task cannot move to `completed` until its review is clean.
- Use `cancelled` only when the orchestrator decides to retire a task while keeping the audit trail in the registry.

**Ownership rule:** Subagents must not edit `super-plan.json`. Only the orchestrator updates it, and every orchestrator write must go through the script so the ledger stays synchronized.

**Execution rule:** `reviewCadence` controls when reviewer subagents launch:

- `per_task` — dispatch a reviewer subagent as soon as a task reaches `ready_for_review`
- `per_batch` — dispatch a reviewer subagent once the whole current batch reaches `ready_for_review`
- `final_only` — defer independent review to final integration, but still dispatch one reviewer subagent per batch at that stage

## Deferred Task Artifacts

Do not create per-task directories or `progress.log` in Phase 4.

Phase 4 defines the executable registry in `super-plan.json` and also materializes `progress-ledger.md` from that registry. Phase 6 is still responsible for materializing:

- `docs/tasks/{NNNN-<feature-name>}/{task-id}/`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/progress.log`
- `docs/tasks/{NNNN-<feature-name>}/{task-id}/log-task.sh`

Until Phase 6, treat only the per-task paths as planned artifact locations owned by later phases.
