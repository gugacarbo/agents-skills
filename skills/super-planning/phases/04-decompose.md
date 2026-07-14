# Phase 4: Decompose into Tasks

Before dispatching any subagent, generate a single machine-readable registry that is the source of truth for the plan and every task.

## Resolve the Active Helper Path First

Before using the registry script, decide which helper path is active for this run:

1. **If the target repository already contains this `super-planning` skill**, do **not** create `.super-planning/`. Use the helper files directly from the skill directory already present in that repo.
2. **If the target repository does not contain this skill**, create `.super-planning/` and copy the helper stack there before proceeding.

Fallback helper files when bootstrap is required:

- `.super-planning/super-plan.sh`
- `.super-planning/super-update.sh`
- `.super-planning/render-progress-ledger.sh`
- `.super-planning/log-task.sh`
- `.super-planning/review-package.sh`
- `.super-planning/render-task-md.sh`
- `.super-planning/summarize-all-tasks.sh`
- `.super-planning/super-plan.schema.json`
- `.super-planning/super-planning-reference.json`

The goal is to avoid a duplicate helper directory when the skill already lives in the repository, while still keeping the flow self-contained for repositories that do not vendor the skill.

## Unified Registry (`super-plan.json`)

Create the registry in the plan's task directory with the active helper path:

```
docs/jobs/{NNNN-<feature-name>}/super-plan.json
```

Example for plan `docs/plans/0003-auth-middleware.md`:

```
docs/jobs/0003-auth-middleware/super-plan.json
```

`super-plan.json` is the orchestrator-owned structured source of truth. It combines:

- plan governance and execution settings that used to live in `plan.json`
- requirements coverage and plan metadata
- the executable task registry that used to live in `tasks.json`

### Build the registry incrementally via the helper script

You must construct `super-plan.json` through **multiple explicit invocations** of the active helper path. Do not create the whole file in a single call and do not edit `super-plan.json` by hand.

1. **Create the header / plan skeleton** with `super-plan.sh init`.
2. **Append each task one by one** with `super-plan.sh update --append tasks=<task-json-or-@file>`.
3. **Patch top-level fields** (goal, architectureSummary, techStack, constraints, fileStructure, requirementsChecklist, etc.) using `super-plan.sh update --set <path>=<json-or-string>`.
4. **Patch agent profiles and review cadence** using `super-plan.sh update --set ...` after user confirmation.

This incremental approach guarantees that every mutation goes through the helper, which validates the result and regenerates `progress-ledger.md` after each successful write.

### Step 1: create the skeleton

When the skill is already inside the target repository:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh init \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --worktree-enabled true \
  --execution-mode subagent-driven \
  --review-cadence per_task \
  --output docs/jobs/0003-auth-middleware/super-plan.json
```

When the skill is not inside the target repository:

```bash
# Capture this from the source skill installation, never from the target app.
SOURCE_SKILL_REPOSITORY="$(git -C /absolute/path/to/skills remote get-url origin)"
SOURCE_SKILL_REF="$(git -C /absolute/path/to/skills branch --show-current)"
SOURCE_SKILL_COMMIT="$(git -C /absolute/path/to/skills rev-parse HEAD)"

mkdir -p /absolute/path/to/workspace/.super-planning
# Preferred: copy the complete, versioned helper manifest and record source
# provenance in one operation.
sh /absolute/path/to/skills/super-planning/scripts/bootstrap.sh \
  --target-dir /absolute/path/to/workspace/.super-planning

# Manual fallback: keep this list in sync with bootstrap.sh.
cp /absolute/path/to/skills/super-planning/scripts/super-plan.sh /absolute/path/to/workspace/.super-planning/super-plan.sh
cp /absolute/path/to/skills/super-planning/scripts/super-update.sh /absolute/path/to/workspace/.super-planning/super-update.sh
cp /absolute/path/to/skills/super-planning/scripts/render-progress-ledger.sh /absolute/path/to/workspace/.super-planning/render-progress-ledger.sh
cp /absolute/path/to/skills/super-planning/scripts/log-task.sh /absolute/path/to/workspace/.super-planning/log-task.sh
cp /absolute/path/to/skills/super-planning/scripts/review-package.sh /absolute/path/to/workspace/.super-planning/review-package.sh
cp /absolute/path/to/skills/super-planning/scripts/render-task-md.sh /absolute/path/to/workspace/.super-planning/render-task-md.sh
cp /absolute/path/to/skills/super-planning/scripts/summarize-all-tasks.sh /absolute/path/to/workspace/.super-planning/summarize-all-tasks.sh
cp /absolute/path/to/skills/super-planning/scripts/doctor.sh /absolute/path/to/workspace/.super-planning/doctor.sh
cp /absolute/path/to/skills/super-planning/scripts/bootstrap.sh /absolute/path/to/workspace/.super-planning/bootstrap.sh
cp -R /absolute/path/to/skills/super-planning/scripts/visual-companion /absolute/path/to/workspace/.super-planning/visual-companion
cp /absolute/path/to/skills/super-planning/interfaces/super-plan.schema.json /absolute/path/to/workspace/.super-planning/super-plan.schema.json
cp /absolute/path/to/skills/super-planning/templates/.gitignore-template /absolute/path/to/workspace/.super-planning/.gitignore

sh /absolute/path/to/workspace/.super-planning/super-plan.sh init \
  --plan-id 0003-auth-middleware \
  --feature-name auth-middleware \
  --spec docs/specs/0003-auth-middleware-spec.md \
  --plan docs/plans/0003-auth-middleware.md \
  --worktree-enabled true \
  --execution-mode subagent-driven \
  --review-cadence per_task \
  --output docs/jobs/0003-auth-middleware/super-plan.json

sh /absolute/path/to/workspace/.super-planning/super-plan.sh reference \
  --output /absolute/path/to/workspace/.super-planning/super-planning-reference.json \
  --repo-url "$SOURCE_SKILL_REPOSITORY" \
  --ref "$SOURCE_SKILL_REF" \
  --commit "$SOURCE_SKILL_COMMIT"
```

For a detached source checkout, pass the intended published ref explicitly
instead of an empty branch name. If any value cannot be discovered, do not
guess from the target application's remote: obtain the skill source metadata
from its installer/release record or ask the user for the source repository and
ref before creating the reference.

`super-planning-reference.json` records the source skill name, source GitHub
remote, ref, full commit SHA, helper path, and generation timestamp. The
complete manifest is the copied helper set listed above. Provenance comes from
the source skill installation, not the target repository remote; otherwise
`super-update.sh` would attempt to download the skill from the application
repository. It remains visible as a runtime reference.

`init` produces a valid but empty registry with `tasks: []`, `requirementsChecklist: []`, placeholder agent profiles, and a generated `progress-ledger.md`.

### Testing rules for tasks

Use the spec's **Test Strategy** when filling `rules`, `acceptanceCriteria`, and `steps`:

- Behavior-changing tasks in TDD mode must include a rule to read the effective `testing-anti-patterns.md` before adding mocks or test utilities.
- Their acceptance criteria must require a focused RED test, the expected failure reason, the minimum implementation, GREEN verification, and the relevant broader suite.
- Bug-fix tasks must retain the reproduction as a regression test.
- Legacy areas without coverage must specify the approved integration test, critical unit coverage, and explicit untouched-legacy exclusions.
- Non-behavior tasks must not receive TDD requirements unless the user explicitly confirmed that scope.

Example task rules:

```json
[
  "TDD required for this behavior-changing task.",
  "Read docs/context/testing-anti-patterns.md before adding mocks, fakes, fixtures, or test-only helpers.",
  "Report RED and GREEN commands and results in the task report."
]
```

### Step 2: add tasks one by one

**Task ID naming convention:** `Task-[batch_id]-[task_batch_id]`

- `batch_id` — the batch letter (A, B, C, …) that groups tasks meant to run in parallel.
- `task_batch_id` — a sequential number **within that batch**, starting at 1.

| Batch | Task | ID         | Runs in parallel with    |
| ----- | ---- | ---------- | ------------------------ |
| A     | 1st  | `Task-A-1` | `Task-A-2`               |
| A     | 2nd  | `Task-A-2` | `Task-A-1`               |
| B     | 1st  | `Task-B-1` | `Task-B-2`               |
| B     | 2nd  | `Task-B-2` | `Task-B-1`               |
| C     | 1st  | `Task-C-1` | — (sole task in batch C) |

Do **not** embed the plan number in the task ID. The plan context is already carried by the directory structure (`docs/jobs/NNNN-<feature-name>/`).

For every task, build a JSON object matching the schema and append it with:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh update \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --append tasks='{"id":"Task-A-1","title":"...",...}'
```

Use an external JSON file for multi-line payloads when the shell becomes unwieldy:

```bash
cat > /tmp/task-a.json <<'EOF'
{
  "id": "Task-A-1",
  "title": "Implementar middleware de autenticação",
  "description": "...",
  "status": "pending",
  "tryCount": 1,
  "maxTries": 3,
  "task_profile": "general",
  "batch": "A",
  "layer": "foundation",
  "reportFile": "docs/jobs/0003-auth-middleware/Task-A-1/report.md",
  "reviewPackage": "docs/jobs/0003-auth-middleware/Task-A-1/review-package.diff.md",
  "progressLog": "docs/jobs/0003-auth-middleware/Task-A-1/progress.log",
  "logTaskScript": "docs/jobs/0003-auth-middleware/Task-A-1/log-task.sh",
  "baseCommit": "pending",
  "dependencies": [],
  "acceptanceCriteria": [],
  "requirements": [],
  "rules": [],
  "steps": [],
  "filesTouched": [],
  "files": {
    "created": [],
    "modified": [],
    "deleted": []
  },
  "notes": []
}
EOF

sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh update \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --append tasks=@/tmp/task-a.json

> **Forward-references:** The paths `reportFile`, `reviewPackage`, `progressLog`, and `logTaskScript` in the task JSON are forward-references — the files will be created in later phases (5-6). Do NOT create the directories now; just record the intended paths.
```

`tryCount` is the current attempt and must be between `1` and `maxTries`.
The helper rejects a task when this invariant is violated.

Minimum number of script invocations in this phase:

- **1 call to `init`** for the plan skeleton.
- **At least 1 call to `update --append tasks=...` per task.** Prefer exactly one call per task so that each task is explicitly and independently validated.

### Step 3: fill top-level plan fields

After all tasks are appended, set the remaining plan-level fields using `--set`:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh update \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --set goal='Validar tokens JWT em todas as rotas protegidas.' \
  --set architectureSummary='Middleware em camadas separando parsing, validação e refresh de token.' \
  --set techStack='["Node.js","Express","jsonwebtoken"]' \
  --set globalConstraints='["Máximo 1 query por request","Sem estado de sessão no servidor"]' \
  --set rules='["Nunca iniciar implementação na main sem permissão","Nunca redespachar tarefas completadas"]' \
  --set fileStructure='[{"path":"src/auth/middleware.ts","ownerTask":"Task-A-1","notes":"Entry point do middleware"}]'
```

Example — transitioning a task status:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh transition-task \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --task-id Task-A-1 \
  --status in_progress
```

Use the active helper's `transition-task` or `complete-task` command for all
lifecycle changes. The commands validate the prior state, allowed transition,
recorded base commit, and completion gate; never edit a status directly in JSON.

For large arrays or objects, prefer writing the JSON to a file and using `@file` syntax:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh update \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --set requirementsChecklist=@/tmp/requirements.json
```

### Step 4: set agents and review cadence after user confirmation

Run profile discovery and ask the user for the cadence first (see below). Then persist the choices:

```bash
sh /absolute/path/to/workspace/super-planning/scripts/super-plan.sh update \
  --input docs/jobs/0003-auth-middleware/super-plan.json \
  --set reviewCadence=per_task \
  --set agents='{"general":{"model":"gpt-5","agent":"general","effort":"medium"},"deep":{"model":"claude-opus-4","agent":"deep","effort":"high"},"quick":{"model":"gpt-5-mini","agent":"quick","effort":"low"}}'
```

Then make every later change through that same active helper path. Do not edit `super-plan.json` by hand.

Structure and field definitions live in the schema file from the active helper path. All required fields must be present, including:

- `source.spec` and `source.plan`
- `goal`, `architectureSummary`, `techStack`
- `globalConstraints`, `fileStructure`, `requirementsChecklist`
- `reviewCadence`
- `agents.general|deep|quick` with `{ "model": "", "agent": "", "effort": "" }` defaults when discovery is unavailable
- `taskDirectory`, `executionMode`, `branchStrategy`, `worktree`
- `tasks`

> **Worktree path:** Worktree path goes outside the main repo. Before enabling worktree mode, verify the repo supports worktrees (`git worktree list` should not error). Default `worktree.enabled=true` is safe only if the repo doesn't use submodules or hooks that break with worktrees.

## Subagent Profile Discovery

Before finalizing `super-plan.json`, the orchestrator must attempt platform-native auto-discovery for subagent execution profiles.

Discover three profiles:

- `general` — default/general-purpose subagent for most implementation tasks
- `deep` — best available profile for difficult, ambiguous, or architecture-heavy tasks
- `quick` — fastest/lightest profile for narrow, mechanical work

Use the tools available in the current platform to discover:

- subagents/agents that can be dispatched
- models and effort levels that can be paired with those subagents

Use platform-native list/discovery tools first. When multiple discovery tools are available, prefer the ones that return callable/current options instead of static docs.

After collecting the discovery result, the orchestrator must present it to the user and ask them to choose how to proceed.

**Preferred interaction rule:** if the current platform exposes an ask/confirm/question tool for structured user input, including `question` / a request user input tool, and the current collaboration mode/session allows that tool to be called, the orchestrator must use that tool instead of a plain text question. Use the structured prompt to:

1. show the discovered agents and models
2. show the recommended `general`, `deep`, and `quick` configuration
3. let the user choose one of these paths:
   - accept the recommendation
   - provide a manual override
   - keep the configuration empty/default

**Fallback interaction rule:** if the current platform does not expose a structured ask/confirm/question tool such as `question`, or if the current collaboration mode/session does not allow calling it, the orchestrator must fall back to a normal text message asking the same question.

After discovery:

1. Recommend a configuration for `agents.general`, `agents.deep`, and `agents.quick`
2. Ask the user to choose recommendation, manual override, or empty/default config
3. Persist the user-approved result in `super-plan.json`, including the effort level
4. If no compatible options are discoverable, leave all `model`, `agent`, and `effort` fields empty unless the user provides a manual override

Required fallback behavior when discovery fails:

1. Tell the user that auto-discovery did not find subagent/model options on the current platform
2. Use the structured ask/confirm/question tool, including `question` when available, and allowed in the current mode/session to ask whether they want to provide a manual override
3. If the platform has no structured ask/confirm/question tool such as `question`, or the current mode/session disallows it, ask via plain text
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
    "general": { "model": "", "agent": "", "effort": "" },
    "deep": { "model": "", "agent": "", "effort": "" },
    "quick": { "model": "", "agent": "", "effort": "" }
  }
}
```

## Review Cadence Decision

Before finalizing `super-plan.json`, the orchestrator MUST ask the user to choose `per_task`, `per_batch`, or `final_only`. Do NOT rely on the default — prompt explicitly. If the user has no preference, document `per_task` as default.

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
- `layer` — work classification such as `foundation`, `core`, `surface`, `final`

`task_profile` is mandatory and represents the intended execution complexity/profile for that task:

- `quick` — narrow, mechanical, low-risk work
- `general` — normal implementation/debugging work
- `deep` — harder debugging, architecture, cross-file integration, or subtle reasoning

Do not leave tasks uncategorized. Every task in `super-plan.json` must have a `task_profile`.

**Rules for status:**

- Set all tasks to `pending` when creating the registry.
- Update status after each dispatch/review cycle.
- Use only these status values: `pending`, `in_progress`, `ready_for_review`, `reviewing`, `needs_fix`, `blocked`, `completed`, `cancelled`.
- A task cannot move to `completed` until its review is clean.
- Use `cancelled` only when the orchestrator decides to retire a task while keeping the audit trail in the registry.

**Ownership rule:** Subagents must not edit `super-plan.json`. Only the orchestrator updates it, and every orchestrator write must go through the script so the ledger stays synchronized.

**Execution rule:** `reviewCadence` controls when reviewer subagents launch:

- `per_task` — dispatch a reviewer subagent as soon as a task reaches `ready_for_review`
- `per_batch` — dispatch a reviewer subagent once the whole current batch reaches `ready_for_review`
- `final_only` — defer independent review to final integration, but still dispatch one reviewer subagent per batch at that stage

## Deferred Task Artifacts

Do not create per-task directories or `progress.log` in Phase 4.

Phase 4 defines the executable registry in `super-plan.json` and also materializes `progress-ledger.md` from that registry. Phase 5 is responsible for materializing (before dispatching implementers):

- `docs/jobs/{NNNN-<feature-name>}/{task-id}/`
- `docs/jobs/{NNNN-<feature-name>}/{task-id}/progress.log`
- `docs/jobs/{NNNN-<feature-name>}/{task-id}/log-task.sh`

The remaining artifacts (`report.md`, `review-package.diff.md`) are still materialized in Phase 6.

Until Phase 5, treat only the per-task paths as planned artifact locations owned by later phases.
