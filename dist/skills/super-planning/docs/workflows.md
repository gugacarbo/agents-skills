# Workflows

> Process: super-planning — this is the operational map. The authoritative
> rules remain in [`super-planning/SKILL.md`](../SKILL.md) and the linked files
> under [`super-planning/phases/`](../phases/).

These diagrams include the actions, gates, artifacts, decisions, recovery
paths, and handoffs required by the current skill. Labels point to the source
file when a rule is too detailed to duplicate safely in a diagram.

Path convention: `super-planning/...` means this skill directory;
`<repo>/...` means the target project; `.super-planning/...` means the helper
copy created inside `<repo>` when the skill is not vendored there.

## Complete End-to-End Flow

```mermaid
flowchart TD
    A["Receive /super-planning invocation"] --> B{"Subcommand"}
    B -->|stats, progress, task-stats, task-progress| S1["Resolve super-planning/scripts/summarize-all-tasks.sh or <repo>/.super-planning/summarize-all-tasks.sh"]
    S1 --> S2["Run with --base-dir / --plan-id / --task-id / --json"] --> S3["Return script output only + one-line command note"]
    B -->|phase name| R1["Load super-planning/phases/<NN>-<phase>.md"]
    B -->|none| R2["Show entry-point orientation"]
    R2 --> R3{"Approved spec exists?"}
    R3 -->|yes| R4["Enter Phase 3"]
    R3 -->|no| R5["Enter Phase 1"]
    R1 --> P["Run selected phase and every later phase"]
    R4 --> P
    R5 --> P

    P --> P1["1. Brainstorm"] --> P2["2. Spec"] --> P3["3. Plan"]
    P3 --> P4["4. Decompose: ask worktree choice before branch"] --> W{"Worktree approved?"}
    W -->|yes| P41["4.1 Set up isolated workspace"] --> P5["5. Dispatch"]
    W -->|no| P5
    P5 --> C{"reviewCadence"}
    C -->|per_task / per_batch| P6["6. Review"]
    C -->|final_only| P7["7. Integrate; review batches here"]
    P6 --> P7
    P7 --> Q{"All gates clean?"}
    Q -->|no: blocker or user decision| X["Stop, document, and escalate"]
    Q -->|yes| Y["Mark plan completed, update spec, commit, offer merge/PR/next work"]
```

## Cross-Phase Invariants

```mermaid
flowchart LR
    A["super-planning/SKILL.md router"] --> B["super-planning/phases/<NN>-<phase>.md is authoritative"]
    B --> C["Artifacts are file-based handoffs"]
    C --> D["<repo>/docs/jobs/<NNNN>-<feature>/super-plan.json is registry source of truth"]
    D --> E["Mutate registry only via super-planning/scripts/super-plan.sh or <repo>/.super-planning/super-plan.sh"]
    E --> F["Regenerate <repo>/docs/jobs/<NNNN>-<feature>/progress-ledger.md"]
    F --> G["Never edit registry by hand"]
    G --> H["Never dispatch completed task"]
    H --> I["Ask worktree choice before defining implementation branch"]
    I --> J["Never start implementation on main/master without consent"]
```

## Phase 1: Brainstorm — Complete Flow

```mermaid
flowchart TD
    A["Read relevant files, docs, recent changes"] --> B{"Multiple independent systems?"}
    B -->|yes| C["Split into sub-projects"]
    C --> C1["Write <repo>/.super-planning/brainstorm/BRAINSTORM-<date>.md"]
    C1 --> C2["Create one <repo>/docs/specs/<NNNN>-<sub-project>-spec.md per sub-project"] --> D
    B -->|no| D["Keep one focused scope"]
    D --> E["Ask one scoped question at a time"]
    E --> F["Clarify purpose, constraints, success criteria, non-goals"]
    F --> G{"Next question is genuinely visual?"}
    G -->|yes| H["Offer Phase 1.1 in a separate message"]
    H --> I{"User accepts?"}
    I -->|yes| J["Load super-planning/phases/01_1-visual-companion.md and run visual loop"]
    I -->|no| K["Continue in terminal; do not offer again"]
    G -->|no| K
    J --> L["Return to text brainstorm and merge visual feedback"]
    K --> L
    L --> M["Propose 2–3 approaches with recommendation and trade-offs"]
    M --> N{"User agrees with direction?"}
    N -->|no| O["Record concerns in <repo>/docs/spec-decisions/<feature_name>_decisions.md"]
    O --> E
    N -->|yes| P["Collect requirements, constraints, assumptions, non-goals, risks, decisions"]
    P --> Q["Record visualCompanionUsed when applicable"]
    Q --> R["Save <repo>/docs/spec-decisions/<feature_name>_decisions.md before spec gate"]
    R --> S{"Required outputs complete?"}
    S -->|no| E
    S -->|yes| T["Handoff: decisions + context to Phase 2"]
```

## Phase 1.1: Visual Companion — Complete Flow

```mermaid
flowchart TD
    A["Visual need approved"] --> B["Warn about temporary files and token cost"]
    B --> C{"node available?"}
    C -->|no| D["Skip companion; continue text-only"]
    C -->|yes| E["Start super-planning/scripts/visual-companion/start-server.sh --project-dir <repo> --open"]
    E --> F["Capture JSON: url, screen_dir=<repo>/.super-planning/brainstorm/<session>/content, state_dir=<repo>/.super-planning/brainstorm/<session>/state"]
    F --> G["Share complete URL including ?key=..."]
    G --> H["Confirm server is alive"]
    H --> I["Write a fresh HTML fragment into <repo>/.super-planning/brainstorm/<session>/content"]
    I --> J["Tell user what is shown; request terminal feedback"]
    J --> K["Read state_dir/events as JSONL when present"]
    K --> L["Read <repo>/.super-planning/brainstorm/<session>/state/events as JSONL and merge with terminal feedback"]
    L --> M{"Another visual iteration?"}
    M -->|yes| N["Write a new filename; never reuse prior file"]
    N --> H
    M -->|no| O["Push waiting screen when returning to text-only"]
    O --> P["Run super-planning/scripts/visual-companion/stop-server.sh and clean up process"]
    P --> Q["Return to Phase 1"]
```

## Phase 2: Spec — Complete Flow

```mermaid
flowchart TD
    A["Read Phase 1 handoff"] --> B["Scan <repo>/docs/specs, <repo>/specs, <repo>/docs, and templates for naming/format"]
    B --> C["Find testing-anti-patterns.md or infer repo convention"]
    C --> D{"Guidance exists?"}
    D -->|no| E["Copy super-planning/templates/testing-anti-patterns.md to <repo>/docs/context/testing-anti-patterns.md or the repo convention"]
    D -->|yes| F["Use existing guidance without overwriting"]
    E --> G
    F --> G["Ask whether behavior changes require TDD"]
    G --> H["Allocate next NNNN and canonical spec/decision paths"]
    H --> I["Rename <repo>/docs/spec-decisions/<feature_name>_decisions.md to <repo>/docs/spec-decisions/NNNN_<name>_decisions.md"]
    I --> J["Draft summary: problem, goal, requirements, non-goals, approach, tests, open questions"]
    J --> K{"Pre-write approval?"}
    K -->|no| L["Incorporate feedback and redraft summary"]
    L --> J
    K -->|yes| M["Write <repo>/docs/specs/NNNN-<feature>-spec.md"]
    M --> N["Self-review: placeholders, consistency, scope, ambiguity"]
    N --> O["Append # Self-Review with verdict and date"]
    O --> P{"Optional spec reviewer requested?"}
    P -->|yes| Q["Dispatch super-planning/agents/spec-document-reviewer.md"]
    Q --> R{"Critical issue?"}
    R -->|yes| S["Fix spec and repeat self-review"]
    S --> P
    R -->|no| T["Continue"]
    P -->|no| T
    T --> U{"Post-write user approval?"}
    U -->|no| V["Update spec and ask again"]
    V --> U
    U -->|yes| W["Transition draft → accepted"]
    W --> X["Handoff: approved spec, decisions, TDD mode, guidance path to Phase 3"]
```

## Phase 3: Plan — Complete Flow

```mermaid
flowchart TD
    A["Read approved spec and decisions"] --> B["Extract requirements, constraints, technology choices"]
    B --> C["Search manifests, lockfiles, imports, adapters, tests, nearby features"]
    C --> D{"Repository pattern fully covers each choice?"}
    D -->|yes| E["Record repository-pattern and source paths"]
    D -->|no| F["Load super-planning/prompts/find-docs.md"]
    F --> G["Resolve library in Context7; query one focused decision"]
    G --> H{"Context7 authoritative and version-matched?"}
    H -->|no| I["Use official docs/repository/spec web fallback"]
    H -->|yes| J["Record Context7 source"]
    I --> K
    J --> K["Compare docs with installed version and app context"]
    K --> L{"Architecture or task boundaries invalidated?"}
    L -->|yes| M{"Product decision needed?"}
    M -->|yes| N["Stop and ask user"]
    M -->|no| O["Update architecture and task split"]
    O --> P
    L -->|no| P["Write Documentation Verification section"]
    E --> P
    P --> Q["Write summary, design, references, task intent, verification, risks, handoff"]
    Q --> R["Define execution mode, batches, delivery layers, task sizing"]
    R --> S["Remove placeholders; run scope and no-overbuild checks"]
    S --> T["Run plan self-review for coverage, ordering, conflicts, ownership"]
    T --> U{"Conflicting task/dependency/global rule?"}
    U -->|yes| V["Ask one batched conflict question and resolve"]
    V --> T
    U -->|no| W["Handoff: <repo>/docs/plans/NNNN-<feature>.md to Phase 4"]
```

## Phase 4: Decompose — Complete Flow

```mermaid
flowchart TD
    A["Read <repo>/docs/plans/NNNN-<feature>.md and testing handoff"] --> A1["Ask worktree choice before defining branch"]
    A1 --> A2["Select base/feature branches and record the answer"]
    A2 --> B["Resolve active helper: super-planning/scripts/ or <repo>/.super-planning/"]
    B --> C{"Target repo already contains super-planning?"}
    C -->|yes| D["Use in-repo scripts and schema"]
    C -->|no| E["Capture source skill repository/ref/commit; bootstrap complete helpers + reference"]
    D --> F["Initialize <repo>/docs/jobs/NNNN-<feature>/super-plan.json"]
    E --> F
    F --> G["Build task entries incrementally through helper"]
    G --> H["Populate requirementsChecklist, fileStructure, dependencies, batches, layers, maxTries"]
    H --> I["Set every task pending; set plan metadata and source paths"]
    I --> J["Discover executor, reviewer, investigator, spec-reviewer, and auditor role profiles"]
    J --> K["Run pre-dispatch dependency, acceptance, and ownership conflict scan"]
    K --> L{"Conflict found?"}
    L -->|yes| M["Resolve in one batched user question"]
    M --> K
    L -->|no| N["Persist branchStrategy, executionMode, worktree, profiles, and reviewCadence"]
    N --> O{"reviewCadence"}
    O -->|per_task| P["Review after each ready task"]
    O -->|per_batch| Q["Review after each ready batch"]
    O -->|final_only| R["Defer reviewer dispatch to Phase 7; still materialize artifacts"]
    P --> S
    Q --> S
    R --> S
    S["Generate <repo>/docs/jobs/NNNN-<feature>/progress-ledger.md through active helper"] --> T["Persist statuses only via super-planning/scripts/super-plan.sh update or <repo>/.super-planning/super-plan.sh update"]
    T --> U{"worktree.enabled?"}
    U -->|yes| V["Run Phase 4.1: detect/reuse/create workspace, sync planning handoff, setup, baseline"]
    U -->|no| W["Handoff directly to Phase 5"]
    V --> W
```

## Phase 5: Dispatch — Complete Flow

```mermaid
flowchart TD
    A["Select next pending task or ready batch"] --> B["Read task entry and task_profile only"]
    B --> C["Resolve general/deep task profile to its executor role"]
    C --> D{"Profile valid and capability available?"}
    D -->|no| E["Fallback to platform default; record fallback"]
    D -->|yes| F["Use configured profile"]
    E --> G
    F --> G["Apply capability adapter: worktree, file handoff, compressed output"]
    G --> H["Resolve super-planning/scripts/log-task.sh and super-planning/scripts/review-package.sh, or their <repo>/.super-planning copies"]
    H --> I["Materialize <repo>/docs/jobs/<NNNN>-<feature>/<Task-ID>/task-brief.md, log-task.sh, progress.log"]
    I --> J["Build prompt from the resolved super-planning/agents/*-executor.md contract"]
    J --> K["Prompt contains task, context, working dir, constraints, tests, report, status format"]
    K --> L["Run pre-flight: branch, ownership, scope, dependencies, guidance path"]
    L --> M{"Pre-flight clean?"}
    M -->|no| N["Resolve or escalate before dispatch"]
    N --> L
    M -->|yes| O["Update task pending → in_progress via helper"]
    O --> P["Dispatch implementer; require started log event"]
    P --> Q{"Returned status"}
    Q -->|DONE| R["Verify report, tests, commit, ready_for_review log"]
    Q -->|DONE_WITH_CONCERNS| S["Resolve concerns or carry them into review"]
    Q -->|NEEDS_CONTEXT| T["Add context and re-dispatch"]
    Q -->|BLOCKED| U{"Blocker removable?"}
    U -->|yes| T
    U -->|no| V["Document blocker and escalate to user"]
    T --> J
    S --> R
    R --> W["Update task in_progress → ready_for_review"]
    W --> X{"Review cadence"}
    X -->|per_task| Y["Phase 6 now: review this task"]
    X -->|per_batch| Z["Wait until all tasks in batch are ready"]
    X -->|final_only| AA["Keep ready_for_review; defer reviewer to Phase 7"]
    Z --> Y
    Y --> AB{"Review clean?"}
    AB -->|no| AC["needs_fix → one fix subagent with all Critical/Important findings"]
    AC --> AD["Regenerate package from original base and re-review"]
    AD --> AB
    AB -->|yes| AE["Log completed with BASE..HEAD; set task completed via helper"]
```

## Phase 6: Review — Complete Flow

```mermaid
flowchart TD
    A["Receive ready task/batch from Phase 5"] --> B["Read <repo>/docs/jobs/<NNNN>-<feature>/super-plan.json task entry and reviewCadence"]
    B --> C["Materialize <repo>/docs/jobs/<NNNN>-<feature>/<Task-ID>/report.md and <repo>/docs/jobs/<NNNN>-<feature>/<Task-ID>/review-package.diff.md"]
    C --> D["Ensure <repo>/docs/jobs/<NNNN>-<feature>/<Task-ID>/log-task.sh and progress.log exist"]
    D --> E["Set ready_for_review → reviewing via helper"]
    E --> F["Dispatch reviewer with task entry from <repo>/docs/jobs/<NNNN>-<feature>/super-plan.json, report.md, and review-package.diff.md"]
    F --> G["Do not pass whole plan, open-ended directives, or suppressed findings"]
    G --> H["Stage 1: spec compliance"]
    H --> I{"Complete, in scope, correctly interpreted?"}
    I -->|no| J["Record file:line findings"]
    I -->|yes| K["Stage 2: code quality"]
    J --> K
    K --> L{"Severity"}
    L -->|Critical / Important| M["Set needs_fix; dispatch ONE fix subagent with all findings"]
    M --> N["Require focused test evidence in report"]
    N --> O["Regenerate package from original task base"]
    O --> F
    L -->|Minor| P["Append info event to progress.log; update status if needed"]
    L -->|none| Q["Record review clean with BASE..HEAD"]
    P --> Q
    Q --> R{"final_only?"}
    R -->|yes| S["Keep ready_for_review; Phase 7 owns completion"]
    R -->|no| T["Append completed log event; set task completed via helper"]
    S --> U["Handoff: reviewed artifacts and outcomes to Phase 7"]
    T --> U
```

## Phase 7: Integrate — Complete Flow

```mermaid
flowchart TD
    A["Read <repo>/docs/jobs/NNNN-<feature>/super-plan.json and <repo>/docs/jobs/NNNN-<feature>/progress-ledger.md"] --> B["Verify all tasks terminal: completed/cancelled/blocked with reason"]
    B --> C{"Branch clean and task branches merged?"}
    C -->|no| D["Merge/clean or stop and document blocker"]
    C -->|yes| E{"final_only batches pending?"}
    E -->|yes| F["Review each ready batch; resolve findings; then complete tasks"]
    F --> E
    E -->|no| G["Run full test suite once"]
    G --> H{"Tests fail?"}
    H -->|related| I["Fix before continuing"]
    I --> G
    H -->|unrelated/pre-existing| J["Document failure and obtain user approval"]
    J --> K
    H -->|pass| K["Read spec Definition of Done and Test Strategy"]
    K --> L["Verify every DoD item, TDD mode, guidance path, RED/GREEN evidence, scenarios"]
    L --> M{"DoD and test strategy pass?"}
    M -->|no| N["Fix or document deferred item; re-run verification"]
    N --> K
    M -->|yes| O["Compute BASE=git merge-base base HEAD"]
    O --> P["Generate final review package"]
    P --> Q["Dispatch super-planning/agents/spec-compliance-auditor.md with <repo>/docs/specs/NNNN-<feature>-spec.md, code, package, registry"]
    Q --> R{"Critical/Important or Cannot verify findings?"}
    R -->|yes| S["Dispatch ONE fix subagent with all findings"]
    S --> P
    R -->|no| T["Build complete File Map"]
    T --> U["Resolve blocked/cancelled/needs_fix task consequences and dependencies"]
    U --> V["Update status via super-planning/scripts/super-plan.sh or <repo>/.super-planning/super-plan.sh; regenerate ledger"]
    V --> W["Fill <repo>/docs/specs/NNNN-<feature>-spec.md implemented-by from fileStructure"]
    W --> X["Commit implementation, <repo>/docs/jobs/NNNN-<feature>/super-plan.json, progress-ledger.md, and updated spec"]
    X --> Y["Output File Map, audit report, DoD results, <repo>/docs/jobs/NNNN-<feature>/progress-ledger.md"]
    Y --> Z["Offer merge, PR, or additional work"]
```

## Phase 8: Reference, Recovery, and Modification — Complete Flow

```mermaid
flowchart TD
    A["Need guidance during execution"] --> B{"Situation"}
    B -->|context pressure| C["Use <repo>/docs/jobs/<NNNN>-<feature>/super-plan.json, <Task-ID>/report.md, review-package.diff.md, and progress.log"]
    C --> C1["Use formats in the resolved executor prompt and super-planning/agents/code-reviewer.md"] --> R
    B -->|retryable failure| D["Classify: lint/type, test, scope, missing context, architecture"]
    D --> E{"tryCount < maxTries?"}
    E -->|yes| F["Fix in task or add context and retry"] --> R
    E -->|no| G["Stop same approach; change context/model/scope/approach"]
    G --> H{"Still blocked?"}
    H -->|yes| I["Escalate with evidence"]
    H -->|no| R
    B -->|new task discovered| J["Add task through helper; set batch, layer, maxTries, dependencies"] --> R
    B -->|task no longer needed| K["Set cancelled; preserve record; update dependents and log"] --> R
    B -->|dependency changed| L["Update dependencies; move only pending tasks between batches"] --> R
    B -->|spec changed| M["Pause dispatch; assess impact; update and re-approve spec"]
    M --> N["Update plan/registry; re-review affected completed tasks; resume"] --> R
    B -->|red flag or safety issue| O["Stop: never skip review, isolation, ledger update, or user decision"]
    O --> I
    R["Resume current phase"]
```
