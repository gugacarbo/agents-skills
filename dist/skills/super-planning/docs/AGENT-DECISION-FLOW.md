# Super-Planning Agent Decision Flow

This document maps the decision points the `super-planning` agent follows from entry routing through each execution phase.

## Global Router

```mermaid
flowchart TD
    A["Invocation received"] --> B{"Explicit phase subcommand?"}
    B -->|No| C{"Approved spec already exists in repo?"}
    C -->|Yes| P3["Start at Phase 3: PLAN"]
    C -->|No| P1["Start at Phase 1: BRAINSTORM"]
    B -->|brainstorm| P1
    B -->|spec| P2["Start at Phase 2: SPEC"]
    B -->|plan| P3
    B -->|decompose| P4["Start at Phase 4: DECOMPOSE"]
    B -->|dispatch| P5["Start at Phase 5: DISPATCH"]
    B -->|review| P6["Start at Phase 6: REVIEW"]
    B -->|integrate| P7["Start at Phase 7: INTEGRATE"]

    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5
    P5 --> P6
    P6 --> P7
```

## Phase 1: Brainstorm

```mermaid
flowchart TD
    A["Inspect project context first"] --> B{"Request spans multiple independent systems?"}
    B -->|Yes| C["Decompose into sub-projects before refining details"]
    B -->|No| D["Refine request in current scope"]
    C --> D
    D --> E{"Would the next question be easier visually?"}
    E -->|Yes| F["Offer Phase 1.1 visual companion"]
    E -->|No| G["Stay in terminal"]
    F --> H{"User approved visual companion?"}
    H -->|Yes| I["Load Phase 1.1 and continue visually"]
    H -->|No| G
    I --> J["Propose 2-3 approaches with recommendation"]
    G --> J
    J --> K{"User agrees with direction?"}
    K -->|No| L["Clarify constraints / ask next scoped question"]
    L --> E
    K -->|Yes| M["Collect outputs: requirements, constraints, assumptions, non-goals, risks, design decisions"]
    M --> N{"Enough material for spec summary?"}
    N -->|No| L
    N -->|Yes| O["Proceed to Phase 2"]
```

## Phase 1.1: Visual Companion

```mermaid
flowchart TD
    A{"Next question is truly visual?"}
    A -->|No| B["Do not offer companion"]
    A -->|Yes| C["Offer companion in its own message"]
    C --> D{"User approved?"}
    D -->|No| B
    D -->|Yes| E["Warn about temporary .super-planning files"]
    E --> F["Start visual companion server"]
    F --> G{"Startup info captured?"}
    G -->|Yes| H["Save URL, screen_dir, state_dir"]
    G -->|No| I["Read server-info from state dir"]
    I --> H
    H --> J["Confirm server is alive"]
    J --> K["Write fresh HTML file to screen_dir"]
    K --> L["Tell user what is on screen and ask for terminal feedback"]
    L --> M{"Another visual iteration needed?"}
    M -->|Yes| N["Read events, merge with terminal feedback, write a new file"]
    N --> L
    M -->|No| O["Push waiting screen when returning to text-only flow"]
```

## Phase 2: Spec

```mermaid
flowchart TD
    A["Scan workspace spec conventions"] --> B["Resolve testing-anti-patterns.md guidance path"]
    B --> C{"Ask whether TDD is required for behavior changes"}
    C --> D["Record testing mode and main scenarios"]
    D --> E["Draft summary before writing file"]
    E --> F{"User approved pre-write summary?"}
    F -->|No| G["Revise summary and ask again"]
    G --> F
    F -->|Yes| H["Save decisions file from Phase 1 outputs"]
    H --> I["Write spec file"]
    I --> J["Run self-review: placeholders, consistency, scope, ambiguity, test strategy"]
    J --> K{"Spec is complex / risky / ambiguous?"}
    K -->|Yes| L["Run optional spec reviewer pass and fix blockers"]
    K -->|No| M["Send spec for post-write approval"]
    L --> M
    M --> N{"User approved spec?"}
    N -->|No| O["Update spec and ask again"]
    O --> M
    N -->|Yes| P["Mark spec accepted and proceed to Phase 3"]
```

## Phase 3: Plan

```mermaid
flowchart TD
    A["Write plan from approved spec"] --> B["Search repository patterns first"]
    B --> C{"Suitable local pattern exists?"}
    C -->|Yes| D["Record repository-pattern and source paths"]
    C -->|No / new or ambiguous| E["Verify current docs with Context7"]
    E --> F{"Context7 available and authoritative?"}
    F -->|No| G["Fetch official documentation via web"]
    F -->|Yes| H["Compare documented APIs with app context"]
    G --> H
    D --> I["Record versions, sources, contracts, and context mapping"]
    H --> J{"Finding changes architecture or task boundaries?"}
    J -->|Yes| K["Update plan or ask user for product decision"]
    J -->|No| I
    K --> I
    I --> L["Assign batch and layer for each task"]
    L --> M{"Spec covers multiple independent subsystems?"}
    M -->|Yes| N["Suggest separate plans"]
    M -->|No| O["Continue current plan"]
    N --> O
    O --> P["Right-size tasks to independent testable deliverables"]
    P --> Q["Run self-review: coverage, docs verification, placeholders, type consistency, dependency order, file conflicts, decomposition readiness"]
    Q --> R{"Tasks in same batch are file-isolated and dependency-safe?"}
    R -->|Yes| S["Default toward subagent-driven execution with parallel batches"]
    R -->|No| T["Use sequential execution"]
    S --> U["Proceed to Phase 4"]
    T --> U
```

## Phase 4: Decompose

```mermaid
flowchart TD
    A["Ask whether implementation should use a worktree before defining branch"] --> A1{"User selects worktree?"}
    A1 -->|Yes| A2["Record approval; run built-in Phase 4.1 worktree setup"]
    A1 -->|No| A3["Record worktree.enabled=false and empty path"]
    A2 --> B["Select and persist base and feature branches"]
    A3 --> B
    B --> C["Resolve active helper path"]
    C --> D{"Target repo already contains this skill?"}
    D -->|Yes| E["Use in-repo skill scripts directly"]
    D -->|No| F["Create or refresh .super-planning helper stack"]
    E --> G["Generate super-plan.json via active helper path"]
    F --> G
    G --> H["Populate plan metadata, requirements, file structure, execution settings, tasks"]
    H --> I["Set every task status to pending"]
    I --> J{"Need per-task directories or progress.log now?"}
    J -->|Yes| K["Defer report and review package to Phase 6; Phase 5 owns logger/progress"]
    J -->|No| L["Materialize artifacts now"]
    K --> M["Proceed with registry as single source of truth"]
    L --> M
    M --> N{"Any future change to registry?"}
    N -->|Yes| O["Update only through the same active super-plan.sh helper path"]
    N -->|No| P["Proceed to Phase 5"]
    O --> P
```

## Phase 5: Dispatch

```mermaid
flowchart TD
    A["Verify recorded worktree decision before branch or dispatch"] --> A1{"Worktree approved?"}
    A1 -->|Yes| A2["Complete built-in Phase 4.1; persist actual path and branch"]
    A1 -->|No| A3["Use current checkout and empty worktree path"]
    A2 --> B["Read dispatch role or task_profile from super-plan.json"]
    A3 --> B
    B --> C["Map task general/deep to generalExecutor/deepExecutor; use direct role otherwise"]
    C --> D{"Configured agent/model present?"}
    D -->|No| E["Use platform defaults"]
    D -->|Yes| F["Re-discover current platform options"]
    F --> G{"Configured agent/model still available?"}
    G -->|No| H["Clear profile in super-plan.json and fall back to defaults"]
    G -->|Yes| I{"Platform supports explicit model selection?"}
    I -->|No| J["Record limitation in super-plan.json and use session model/default agent"]
    I -->|Yes| K["Run lightweight probe with configured agent/model"]
    K --> L{"Probe succeeded?"}
    L -->|No| H
    L -->|Yes| M["Use explicit agent/model for dispatch"]
    E --> N["Check platform capabilities"]
    H --> N
    J --> N
    M --> N
    N --> O{"Parallel dispatch supported?"}
    O -->|No| P["Fallback to sequential wave"]
    O -->|Yes| Q["Parallel remains possible"]
    P --> R
    Q --> R{"Tasks are independent, file-isolated, and dependency-safe?"}
    R -->|No| S["Use sequential mode"]
    R -->|Yes| T{"Worktree isolation available if needed?"}
    T -->|No| U["Do not run parallel tasks with overlapping files"]
    T -->|Yes| V["Use parallel mode with isolated worktrees"]
    U --> S
    S --> W["Run pre-flight checks: repo state, tooling, registry, ledger, validated profiles"]
    V --> W
    W --> X{"Any pre-flight check failed?"}
    X -->|Yes| Y["Fix before dispatching"]
    Y --> W
    X -->|No| Z["Build minimal dispatch prompt from the implementer prompt"]
    Z --> AA{"Implementer returned status?"}
    AA -->|DONE| AB["Mark ready_for_review and hand off to Phase 6"]
    AA -->|DONE_WITH_CONCERNS| AC["Resolve correctness/scope concerns<br/>or record observation before review"]
    AA -->|NEEDS_CONTEXT| AD["Provide context and re-dispatch"]
    AA -->|BLOCKED| AE{"Can unblock with context, better model, or smaller scope?"}
    AE -->|Yes| AF["Change something and re-dispatch"]
    AE -->|No| AG["Escalate to user"]
    AD --> Z
    AF --> Z
    AC --> AB
```

## Phase 6: Review

```mermaid
flowchart TD
    A["Materialize task directory and review artifacts"] --> B["Generate task-local logger wrapper and review package"]
    B --> C["Dispatch reviewer with task entry, report, and diff package"]
    C --> D["Stage 1: spec compliance"]
    D --> E{"Missing, extra, or misunderstood requirements?"}
    E -->|Yes| F["Create findings"]
    E -->|No| G["Continue to code quality"]
    F --> G
    G --> H["Stage 2: code quality"]
    H --> I{"Critical or important findings?"}
    I -->|Yes| J["Set needs_fix, dispatch fix subagent, then re-review"]
    I -->|No| K{"Minor findings only?"}
    K -->|Yes| L["Record in task progress.log for final triage"]
    K -->|No| M["Review is clean"]
    J --> C
    L --> N["Mark task completed through orchestrator after clean review state unless reviewCadence=final_only"]
    M --> N
```

## Phase 7: Integrate

```mermaid
flowchart TD
    A["All tasks reviewed and complete"] --> B["Run full test suite once"]
    B --> C["Dispatch final whole-branch review with strongest model"]
    C --> D{"Final review found issues?"}
    D -->|Yes| E["Address findings and repeat final review as needed"]
    D -->|No| F["Update final status in super-plan.json"]
    E --> C
    F --> G["Regenerate ledger"]
    G --> H["Transition spec status to implemented and fill implemented-by"]
    H --> I["Offer next steps: merge, PR, or continue working"]
```

## Cross-Phase Error Recovery

```mermaid
flowchart TD
    A{"Task failed or came back blocked?"}
    A -->|No| B["Continue normal flow"]
    A -->|Yes| C{"tryCount < maxTries?"}
    C -->|Yes| D["Change something before retrying"]
    D --> E{"Best intervention?"}
    E -->|More context| F["Update prompt or task context"]
    E -->|Better model| G["Upgrade model"]
    E -->|Smaller scope| H["Split task"]
    E -->|Different approach| I["Rewrite steps"]
    F --> J["Re-dispatch"]
    G --> J
    H --> J
    I --> J
    C -->|No| K["Stop retrying same approach"]
    K --> L{"Any viable change remains?"}
    L -->|Yes| D
    L -->|No| M["Escalate clearly to user"]
```

## Status Lifecycle

```mermaid
stateDiagram-v2
    [*] --> pending
    pending --> in_progress: dispatch
    in_progress --> ready_for_review: implementer done
    ready_for_review --> reviewing: review begins
    reviewing --> needs_fix: review found issues
    needs_fix --> in_progress: fix dispatched
    in_progress --> blocked: cannot proceed
    blocked --> in_progress: context/model/scope changed
    reviewing --> completed: review clean and orchestrator closes task
    pending --> cancelled: orchestrator retires task but keeps audit trail
    in_progress --> cancelled: orchestrator retires task but keeps audit trail
    completed --> [*]
    cancelled --> [*]
```
