# Workflows

Detailed diagrams of super-planning decision, execution, and review flows.

## Decision Flow: When to Use

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

## 7-Phase Flow

```mermaid
flowchart LR
    P1[BRAINSTORM] --> P2[SPEC]
    P2 --> P3[PLAN]
    P3 --> P4[DECOMPOSE]
    P4 --> P5[DISPATCH]
    P5 --> P6[REVIEW]
    P6 --> P7[INTEGRATE]
```

## Sequential Dispatch Flow

```mermaid
flowchart TD
    T1[Task 1] --> D1[Dispatch Implementer]
    D1 --> RC1{reviewCadence}
    RC1 -->|per_task| R1[Review]
    RC1 -->|per_batch| H1[Hold review until batch gate]
    RC1 -->|final_only| H1A[Keep task ready_for_review<br/>queue batch review for Phase 7]
    R1 -->|Issues Found| F1[Fix Subagent]
    F1 --> RR1[Re-review]
    RR1 -->|Clean| C1[Mark Complete]
    R1 -->|Clean| C1
    H1 --> C1
    H1A --> T1[Do not mark completed yet]
    C1 --> T2[Task 2]
    T1 --> T2
    T2 --> D2[Dispatch Implementer]
    D2 --> RC2{reviewCadence}
    RC2 -->|per_task| R2[Review]
    RC2 -->|per_batch| H2[Hold review until batch gate]
    RC2 -->|final_only| H2A[Keep task ready_for_review<br/>queue batch review for Phase 7]
    R2 -->|Issues Found| F2[Fix Subagent]
    F2 --> RR2[Re-review]
    RR2 -->|Clean| C2[Mark Complete]
    R2 -->|Clean| C2
    H2 --> C2
    H2A --> T3[Do not mark completed yet]
    C2 --> TN[All Tasks Complete]
    T3 --> TN
    TN --> INTEGRATE[Phase 7:<br/>Integrate & Finish]
```

## Parallel Dispatch Flow

```mermaid
flowchart TD
    subgraph Batch A - Parallel Group
        A1[Task 1<br/>task_profile: quick<br/>layer: foundation]
        A2[Task 2<br/>task_profile: deep<br/>layer: foundation]
        A3[Validate quick/deep profiles<br/>then Dispatch All Parallel]
        A1 --> A3
        A2 --> A3
        A3 --> A4{reviewCadence}
        A4 -->|per_task| A5[Review each task in the<br/>response after implementers return]
        A4 -->|per_batch| A6[Review all after batch completes]
        A4 -->|final_only| A7[Defer review to Phase 7<br/>but review one batch at a time]
        A5 --> A8[Fix and re-review only affected tasks]
        A6 -->|Issues Found| A8
        A8 --> A9[Mark accepted tasks complete]
        A6 -->|Clean| A9
        A7 --> A10[Keep batch moving]
    end

    subgraph Batch B - Parallel Group
        B1[Task 3<br/>task_profile: general<br/>layer: core]
        B2[Task 4<br/>task_profile: deep<br/>layer: surface]
        B3[Validate general/deep profiles<br/>then Dispatch All Parallel]
        B1 --> B3
        B2 --> B3
        B3 --> B4{reviewCadence}
        B4 -->|per_task| B5[Review each task in the<br/>response after implementers return]
        B4 -->|per_batch| B6[Review all after batch completes]
        B4 -->|final_only| B7[Defer review to Phase 7<br/>but review one batch at a time]
        B5 --> B8[Fix and re-review only affected tasks]
        B6 -->|Issues Found| B8
        B8 --> B9[Mark accepted tasks complete]
        B6 -->|Clean| B9
        B7 --> B10[Keep batch moving]
    end

    A9 --> B9
    A10 --> B10
    B9 --> INTEGRATE[Phase 7:<br/>Integrate & Finish]
    B10 --> INTEGRATE
```

## Batch-Based Execution

```mermaid
flowchart TB
    subgraph Batch A
        WA[Task 1<br/>Task 2<br/>Run in parallel]
    end

    subgraph Batch B
        WB[Task 3<br/>Task 4<br/>Run in parallel after Batch A]
    end

    subgraph Layer Labels
        P1[foundation]
        P2[core]
        P3[surface]
        P4[final]
    end

    WA --> WB
```

## Review Gates Flow

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
        S6{Findings?} -->|Minor| FH3[Record in task progress.log<br/>final review triages]
        S6{Findings?} -->|No issues| FH4[Proceed]
        FH1 --> COMPLETE
        FH2 --> COMPLETE
        FH3 --> COMPLETE
        FH4 --> COMPLETE
    end
```

## Task Lifecycle

```mermaid
stateDiagram-v2
    [*] --> pending
    pending --> in_progress: Dispatch
    in_progress --> ready_for_review: Implementer done
    ready_for_review --> reviewing: Review begins
    reviewing --> completed: Review clean
    reviewing --> needs_fix: Fix needed
    needs_fix --> in_progress: Re-dispatch
    in_progress --> blocked: Cannot proceed
    blocked --> in_progress: Re-assess<br/>more context / better model / smaller scope
    ready_for_review --> cancelled: Orchestrator retires task
    completed --> [*]
    cancelled --> [*]
```

## Subagent Status Handling

```mermaid
flowchart TD
    S[Subagent Returns] --> ST{Status?}
    ST -->|DONE| P[Mark ready_for_review]
    ST -->|DONE_WITH_CONCERNS| C[Resolve correctness/scope<br/>or record observation before review]
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

## Sequential vs Parallel: When to Use

```mermaid
flowchart TD
    START{Task type?} -->|Dependent on each other| SEQ[SEQUENTIAL MODE]
    START -->|Independent, file-isolated| PAR[PARALLEL MODE]
    START -->|Failures are related| SEQ
    START -->|Need full context| SEQ
    START -->|Exploratory debugging| SEQ
    START -->|Shared state/modified<br/>same tables or config| SEQ

    PAR --> LIMIT{Check practical limit}
    LIMIT -->|2-4 subagents| GOOD[Execute parallel batch]
    LIMIT -->|>4 subagents| SPLIT[Split into batches of 2-4]
    SPLIT --> GOOD
    GOOD --> COMPLETE[Mark batch complete<br/>Proceed to next batch]
```

## Pre-Flight Checks

```mermaid
flowchart
    START[Before Dispatch] --> F1{Repository state<br/>clean working tree<br/>correct base branch?}
    F1 -->|No| FIX1[Fix repo state]
    F1 -->|Yes| F2{Tooling available<br/>test runner<br/>linter<br/>build commands?}
    FIX1 --> F1
    F2 -->|No| FIX2[Fix tooling]
    F2 -->|Yes| F3{super-plan.json written<br/>all tasks defined?}
    FIX2 --> F2
    F3 -->|No| FIX3[Write super-plan.json<br/>and generate ledger]
    F3 -->|Yes| READY[Ready to dispatch]
    FIX3 --> F3
```
