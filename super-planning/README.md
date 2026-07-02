# super-planning

Create implementation plans decomposed into tasks and execute them via subagents — sequential or parallel — to reduce context pressure on the main agent.

> **Agent note:** Start at [`SKILL.md`](SKILL.md) for the routing entrypoint. The full decision trees below are the visual companion to that file; detailed phase instructions live in [`phases/`](phases/).

Phase 1 now includes the full brainstorming workflow and can optionally use the embedded visual companion documented in [`phases/01_1-visual-companion.md`](phases/01_1-visual-companion.md).

## Operation Flows

### Decision Flow: When to Use

```mermaid
flowchart TD
    START{Feature idea or<br/>multi-step task?}
    START -->|No| L{Single trivial task?}
    L -->|Yes| L1[Just do it inline,<br/>no skill needed]
    L -->|No| L2[End — no work to plan]
    START -->|Yes| D{Approved spec in<br/>docs/specs/?}
    D -->|Yes| E[Skip to Phase 3:<br/>PLAN]
    D -->|No| F[Phase 1: BRAINSTORM<br/>then Phase 2: SPEC]
    F -->|After spec approval| G[Phase 3: PLAN]
    G --> H{Tasks mostly<br/>independent?}
    H -->|Yes| I{Can run in parallel<br/>without file conflicts?}
    I -->|Yes| J[PARALLEL MODE<br/>dispatch all in one message]
    I -->|No| K[SEQUENTIAL MODE<br/>one at a time, review after each]
    H -->|No| K
```

### 7-Phase Workflow

```mermaid
flowchart LR
    P1[BRAINSTORM] --> P2[SPEC]
    P2 --> P3[PLAN]
    P3 --> P4[DECOMPOSE]
    P4 --> P5[DISPATCH]
    P5 --> P6[REVIEW]
    P6 --> P7[INTEGRATE]
```

### Sequential Dispatch Flow

```mermaid
flowchart TD
    T1[Task 1] --> D1[Dispatch Implementer]
    D1 --> R1[Review]
    R1 -->|Issues Found| F1[Fix Subagent]
    F1 --> RR1[Re-review]
    RR1 -->|Clean| C1[Mark Complete]
    R1 -->|Clean| C1
    C1 --> T2[Task 2]
    T2 --> D2[Dispatch Implementer]
    D2 --> R2[Review]
    R2 -->|Issues Found| F2[Fix Subagent]
    F2 --> RR2[Re-review]
    RR2 -->|Clean| C2[Mark Complete]
    R2 -->|Clean| C2
    C2 --> TN[All Tasks Complete]
    TN --> INTEGRATE[Phase 7:<br/>Integrate & Finish]
```

### Parallel Dispatch Flow

```mermaid
flowchart TD
    subgraph Wave A - Foundation
        A1[Task 1] --> A2[Task 2]
        A2 --> A3[Task 3]
        A3 --> A4[Dispatch All<br/>Parallel]
        A4 --> A5[Review All]
        A5 -->|Issues Found| A6[Fix Subagents]
        A6 --> A7[Re-review]
        A7 --> A8[Mark Wave A<br/>Complete]
        A5 -->|Clean| A8
    end

    subgraph Wave B - Core
        B1[Task 4] --> B2[Task 5]
        B2 --> B3[Task 6]
        B3 --> B4[Dispatch All<br/>Parallel]
        B4 --> B5[Review All]
        B5 -->|Issues Found| B6[Fix Subagents]
        B6 --> B7[Re-review]
        B7 --> B8[Mark Wave B<br/>Complete]
        B5 -->|Clean| B8
    end

    subgraph Wave C - Surface
        C1[Task 7] --> C2[Task 8]
        C2 --> C3[Dispatch All<br/>Parallel]
        C3 --> C4[Review All]
        C4 -->|Issues Found| C5[Fix Subagents]
        C5 --> C6[Re-review]
        C6 --> C7[Mark Wave C<br/>Complete]
        C4 -->|Clean| C7
    end

    A8 --> B8
    B8 --> C7
    C7 --> INTEGRATE[Phase 7:<br/>Integrate & Finish]
```

### Wave-Based Execution

```mermaid
flowchart TB
    subgraph Wave A - Foundation
        WA[Infrastructure<br/>Types<br/>Shared Utilities]
    end

    subgraph Wave B - Core
        WB[Primary Business Logic<br/>Depends on Foundation]
    end

    subgraph Wave C - Surface
        WC[UI<br/>API Endpoints<br/>Integration Tests<br/>Depends on Core]
    end

    subgraph Wave D - Final
        WD[Final Review<br/>Cleanup<br/>Documentation<br/>Merge Prep]
    end

    WA --> WB
    WB --> WC
    WC --> WD
```

### Review Gates Flow

```mermaid
flowchart TD
    subgraph Two-Stage Review
        S1[Stage 1:<br/>SPEC COMPLIANCE] --> S2{Does implementation<br/>match requirements?}
        S2 -->|Missing| M1[Requirements skipped<br/>or missed]
        S2 -->|Extra| M2[Features not requested<br/>overbuilding]
        S2 -->|Misunderstood| M3[Right feature<br/>wrong approach]
        M1 --> S3[Flag as ⚠️]
        M2 --> S3
        M3 --> S3

        S3 --> S4[Stage 2:<br/>CODE QUALITY]
        S4 --> S5{Is it well-built?}
        S5 -->|Separation of concerns?| Q1[✓/✗]
        S5 -->|Error handling?| Q2[✓/✗]
        S5 -->|DRY without premature<br/>abstraction?| Q3[✓/✗]
        S5 -->|Edge cases handled?| Q4[✓/✗]
        S5 -->|Tests verify real<br/>behavior?| Q5[✓/✗]
        S5 -->|Single responsibility<br/>per file?| Q6[✓/✗]
        Q1 --> S6
        Q2 --> S6
        Q3 --> S6
        Q4 --> S6
        Q5 --> S6
        Q6 --> S6
    end

    subgraph Findings Handling
        S6{Findings?} -->|Critical| FH1[Fix before proceeding<br/>re-review]
        S6{Findings?} -->|Important| FH2[Should fix<br/>blocks merge<br/>re-review]
        S6{Findings?} -->|Minor| FH3[Record in ledger<br/>final review addresses]
        S6{Findings?} -->|No issues| FH4[Proceed]
        FH1 --> COMPLETE
        FH2 --> COMPLETE
        FH3 --> COMPLETE
        FH4 --> COMPLETE
    end
```

### Task Lifecycle

```mermaid
stateDiagram-v2
    [*] --> pending
    pending --> in_progress: Dispatch
    in_progress --> ready_for_review: Implementer done
    ready_for_review --> completed: Review clean
    ready_for_review --> needs_fix: Fix needed
    needs_fix --> in_progress: Re-dispatch
    in_progress --> blocked: Cannot proceed
    blocked --> in_progress: Re-assess<br/>more context / better model / smaller scope
    pending --> cancelled: Never started
    completed --> [*]
    cancelled --> [*]
```

### Subagent Status Handling

```mermaid
flowchart TD
    S[Subagent Returns] --> ST{Status?}
    ST -->|DONE| P[Mark ready_for_review]
    ST -->|DONE_WITH_CONCERNS| C[Read concerns<br/>decide whether to address]
    ST -->|NEEDS_CONTEXT| CT[Provide context<br/>re-dispatch]
    ST -->|BLOCKED| B{Assess}
    B -->|Provide context| CT
    B -->|Upgrade model| RD[Re-dispatch]
    B -->|Break into smaller tasks| RD
    B -->|Escalate to user| U[Escalate]
    C --> P
    CT --> in_progress
    RD --> in_progress
    P --> REVIEW[Generate review package<br/>Review Gates]
```

### File Handoff Structure

```mermaid
flowchart TB
    subgraph docs/
        subgraph specs/
            SPEC[NNNN-<feature-name>-spec.md<br/>Spec - contract with user]
        end
        subgraph plans/
            PLAN[NNNN-<feature-name>.md<br/>Plan - linked to spec by number]
        end
        subgraph tasks/NNNN-<feature-name>/
            TASKS[tasks.json<br/>Machine-readable registry<br/>Single source of truth]
            LEDGER[progress-ledger.md<br/>Plan progress tracker]
            subgraph Task-A-0001/
                REPORT1[report.md<br/>Subagent output]
                REVIEW1[review-package.diff.md<br/>Reviewer input]
                LOG1[progress.log<br/>Task progress]
                HELPER1[log-task.sh<br/>Task-local logger]
            end
        end
    end
    SPEC --> PLAN
    PLAN --> TASKS
```

### When to Use Sequential vs Parallel

```mermaid
flowchart TD
    START{Task type?} -->|Dependent on each other| SEQ[SEQUENTIAL MODE]
    START -->|Independent, file-isolated| PAR[PARALLEL MODE]
    START -->|Failures are related| SEQ
    START -->|Need full context| SEQ
    START -->|Exploratory debugging| SEQ
    START -->|Shared state/modified<br/>same tables or config| SEQ

    PAR --> LIMIT{Check practical limit}
    LIMIT -->|2-4 subagents| GOOD[Execute parallel wave]
    LIMIT -->|>4 subagents| SPLIT[Split into waves of 2-4]
    SPLIT --> GOOD
    GOOD --> COMPLETE[Mark wave complete<br/>Proceed to next wave]
```

### Pre-Flight Checks

```mermaid
flowchart
    START[Before Dispatch] --> F1{Repository state<br/>clean working tree<br/>correct base branch?}
    F1 -->|No| FIX1[Fix repo state]
    F1 -->|Yes| F2{Tooling available<br/>test runner<br/>linter<br/>build commands?}
    FIX1 --> F1
    F2 -->|No| FIX2[Fix tooling]
    F2 -->|Yes| F3{tasks.json written<br/>all tasks defined?}
    FIX2 --> F2
    F3 -->|No| FIX3[Write tasks.json]
    F3 -->|Yes| F4{Progress ledger initialized<br/>all tasks pending?}
    FIX3 --> F3
    F4 -->|No| FIX4[Initialize progress ledger]
    F4 -->|Yes| READY[Ready to dispatch]
    FIX4 --> F4
```

## Quick Reference

| Phase               | Key Output                                  | Gate                                   |
| ------------------- | ------------------------------------------- | -------------------------------------- |
| Phase 1: Brainstorm | Requirements, constraints, design decisions | HARD: complete the integrated brainstorm flow |
| Phase 2: Spec       | `docs/specs/NNNN-<name>-spec.md`            | User approval (pre-write + post-write) |
| Phase 3: Plan       | `docs/plans/NNNN-<name>.md`                 | Self-review checklist                  |
| Phase 4: Decompose  | `docs/tasks/NNNN-<name>/tasks.json` + per-task directories | Tasks linked to plan number |
| Phase 5: Dispatch   | Subagent work                               | Pre-flight checks                      |
| Phase 6: Review     | Two-stage review                            | Critical/Important must be fixed       |
| Phase 7: Integrate  | Final review, merge prep                    | Full test suite passes                 |

## Red Flags

See the full list in `SKILL.md` → **Red Flags** section. Key rules:

- Never skip review or accept "close enough" on spec compliance
- Never dispatch parallel subagents without file isolation or a platform fallback
- Never start implementation on main/master without explicit consent
- Never re-dispatch a task the progress log or ledger marks complete

## Subagent Model Selection

See the model selection table and strategy in SKILL.md Phase 5.

## Context Compression

See SKILL.md for compressed output formats per role (implementer, reviewer, investigator).

```mermaid
flowchart LR
    subgraph Without Compression
        A[Controller] -->|paste everything| B[Subagent]
        B -->|full output| A
    end

    subgraph With Compression
        C[Controller] -->|task entry path| D[Subagent]
        D -->|report file path| E[Report file written]
        D -->|one-line summary| C
    end
```

Key principle: **File-based handoffs** — everything subagents produce goes to a file, not back into your context.
