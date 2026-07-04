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
    D -->|Yes| E["Warn about temporary .super-planning files and suggest .gitignore entry"]
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
    A["Scan workspace spec conventions"] --> B["Draft summary before writing file"]
    B --> C{"User approved pre-write summary?"}
    C -->|No| D["Revise summary and ask again"]
    D --> C
    C -->|Yes| E{"Create optional decisions file?"}
    E -->|Yes| F["Write decisions file from Phase 1 outputs"]
    E -->|No| G["Skip decisions file"]
    F --> H["Write spec file"]
    G --> H
    H --> I["Run self-review: placeholders, consistency, scope, ambiguity"]
    I --> J{"Spec is complex / risky / ambiguous?"}
    J -->|Yes| K["Run optional spec reviewer pass and fix blockers"]
    J -->|No| L["Send spec for post-write approval"]
    K --> L
    L --> M{"User approved spec?"}
    M -->|No| N["Update spec and ask again"]
    N --> L
    M -->|Yes| O["Mark spec accepted and proceed to Phase 3"]
```

## Phase 3: Plan

```mermaid
flowchart TD
    A["Write plan from approved spec"] --> B["Assign batch and phase for each task"]
    B --> C{"Spec covers multiple independent subsystems?"}
    C -->|Yes| D["Suggest separate plans"]
    C -->|No| E["Continue current plan"]
    D --> E
    E --> F["Right-size tasks to independent testable deliverables"]
    F --> G["Run self-review: coverage, placeholders, type consistency, dependency order, file conflicts, decomposition readiness"]
    G --> H{"Tasks in same batch are file-isolated and dependency-safe?"}
    H -->|Yes| I["Default toward subagent-driven execution with parallel batches"]
    H -->|No| J["Use sequential execution"]
    I --> K["Proceed to Phase 4"]
    J --> K
```

## Phase 4: Decompose

```mermaid
flowchart TD
    A["Resolve active helper path"] --> B{"Target repo already contains this skill?"}
    B -->|Yes| C["Use in-repo skill scripts directly"]
    B -->|No| D["Create or refresh .super-planning helper stack"]
    C --> E["Generate super-plan.json via active helper path"]
    D --> E
    E --> F["Populate plan metadata, requirements, file structure, execution settings, tasks"]
    F --> G["Set every task status to pending"]
    G --> H{"Need per-task directories or progress.log now?"}
    H -->|Yes| I["No: defer task artifacts to Phase 6"]
    H -->|No| J["Keep only registry and ledger for now"]
    I --> K["Proceed with registry as single source of truth"]
    J --> K
    K --> L{"Any future change to registry?"}
    L -->|Yes| M["Update only through the same active super-plan.sh helper path"]
    L -->|No| N["Proceed to Phase 5"]
    M --> N
```

## Phase 5: Dispatch

```mermaid
flowchart TD
    A["Choose role-specific model"] --> B{"Platform supports explicit model selection?"}
    B -->|No| C["Record limitation in super-plan.json and use session model"]
    B -->|Yes| D["Set explicit model per role"]
    C --> E["Check platform capabilities"]
    D --> E
    E --> F{"Parallel dispatch supported?"}
    F -->|No| G["Fallback to sequential wave"]
    F -->|Yes| H["Parallel remains possible"]
    G --> I
    H --> I{"Tasks are independent, file-isolated, and dependency-safe?"}
    I -->|No| J["Use sequential mode"]
    I -->|Yes| K{"Worktree isolation available if needed?"}
    K -->|No| L["Do not run parallel tasks with overlapping files"]
    K -->|Yes| M["Use parallel mode with isolated worktrees"]
    L --> J
    J --> N["Run pre-flight checks: repo state, tooling, registry and ledger"]
    M --> N
    N --> O{"Any pre-flight check failed?"}
    O -->|Yes| P["Fix before dispatching"]
    P --> N
    O -->|No| Q["Build minimal dispatch prompt"]
    Q --> R{"Implementer returned status?"}
    R -->|DONE| S["Mark ready_for_review and hand off to Phase 6"]
    R -->|DONE_WITH_CONCERNS| T["Read concerns, then mark ready_for_review or address first"]
    R -->|NEEDS_CONTEXT| U["Provide context and re-dispatch"]
    R -->|BLOCKED| V{"Can unblock with context, better model, or smaller scope?"}
    V -->|Yes| W["Change something and re-dispatch"]
    V -->|No| X["Escalate to user"]
    U --> Q
    W --> Q
    T --> S
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
    K -->|Yes| L["Record in ledger for final review"]
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
    A -->|Yes| C{"tryCount < 3?"}
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
    ready_for_review --> needs_fix: review found issues
    needs_fix --> in_progress: fix dispatched
    in_progress --> blocked: cannot proceed
    blocked --> in_progress: context/model/scope changed
    ready_for_review --> completed: review clean and orchestrator closes task
    ready_for_review --> cancelled: orchestrator retires task but keeps audit trail
    completed --> [*]
    cancelled --> [*]
```
