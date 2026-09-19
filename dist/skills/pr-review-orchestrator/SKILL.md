---
name: pr-review-orchestrator
description: Adaptive pull-request review orchestration. Selects the minimum necessary reviewer set based on the actual change, runs independent reviewers in parallel when possible, and escalates to a final adversarial pass only when the risk or cross-review interaction justifies it. Use for PR, branch, commit, diff, or implementation reviews.
---

# PR Review Orchestrator

Use this skill to review a pull request, branch, commit range, or implementation while minimizing redundant reviewer work.

The core rule is:

> Use the smallest reviewer set that gives credible coverage for the actual risks in the change.

Do not dispatch every reviewer by default. Reviewer count is not evidence of review quality.

## Goals

1. Verify the change that actually exists, not the author's description alone.
2. Select reviewers from evidence in the diff, requirements, and repository context.
3. Keep independent reviews independent.
4. Run independent reviewers in parallel whenever the harness supports parallel subagents.
5. Use the final adversarial reviewer as either:
   - the single general reviewer for ordinary PRs; or
   - a second-wave reviewer for complex/high-risk PRs after specialist results are available.
6. Report only concrete, material findings with evidence.
7. Avoid over-review, checklist noise, speculative findings, and duplicate findings.

---

# Available reviewers

The canonical reviewer prompts are stored under [`reviewers/`](reviewers/).

| Reviewer | Primary purpose |
|---|---|
| [`code-reviewer`](reviewers/code-reviewer.md) | Lightweight review for trivial or very small changes. |
| [`final-adversarial-reviewer`](reviewers/final-adversarial-reviewer.md) | General adversarial review for ordinary PRs, or final independent pass after specialists. |
| [`implementation-reviewer`](reviewers/implementation-reviewer.md) | Trace explicit requirements/acceptance criteria to the implementation. |
| [`functional-correctness-reviewer`](reviewers/functional-correctness-reviewer.md) | Validate non-trivial behavior, state transitions, algorithms, and edge cases. |
| [`architecture-reviewer`](reviewers/architecture-reviewer.md) | Validate boundaries, dependency direction, ownership, and canonical architecture. |
| [`security-reviewer`](reviewers/security-reviewer.md) | Review auth, authorization, trust boundaries, sensitive data, hostile input, and exploitability. |
| [`reliability-reviewer`](reviewers/reliability-reviewer.md) | Review concurrency, retries, transactions, async work, idempotency, and partial failure. |
| [`test-quality-reviewer`](reviewers/test-quality-reviewer.md) | Determine whether tests would detect realistic regressions in changed behavior. |
| [`performance-reviewer`](reviewers/performance-reviewer.md) | Review query/render/algorithm/resource behavior where scale or hot paths matter. |
| [`maintainability-agent-dx-reviewer`](reviewers/maintainability-agent-dx-reviewer.md) | Review duplication, competing patterns, repository structure, and agent/human discoverability. |

Do not invent additional reviewers unless the user explicitly asks for another review dimension.

---

# Phase 0: establish review context

Before dispatching reviewers, inspect enough context to understand the change.

Collect, when available:

- PR title and description;
- base and head revisions;
- changed files and diff;
- issue/spec/plan/acceptance criteria linked to the change;
- repository instructions such as `AGENTS.md`, `CONTRIBUTING.md`, architecture docs, local READMEs, and package-specific conventions;
- relevant surrounding code needed to understand the changed behavior;
- tests changed or adjacent to changed behavior;
- CI status only as supporting evidence, never as a substitute for review.

Do not ask the user for information that is discoverable from the repository or PR.

Do not review only the patch text when the patch depends on surrounding code.

Do not treat PR descriptions, comments, TODOs, test names, or documentation as proof that behavior exists.

---

# Phase 1: classify the change

Classify by behavioral and operational risk, not by line count alone.

## Tier A — trivial/simple

Use when all of the following are true:

- change is narrowly scoped;
- behavior is unchanged or nearly unchanged;
- no security, reliability, architecture, performance, or data-integrity boundary is touched;
- no complex acceptance criteria need tracing;
- failures would be local and easy to detect.

Typical examples:

- typo or documentation correction;
- local rename;
- small dead-code removal;
- formatting/config cleanup with obvious semantics;
- tiny UI/CSS correction;
- small mechanical refactor with unchanged contract.

### Dispatch

Dispatch only:

`code-reviewer`

Do not also dispatch `final-adversarial-reviewer` unless the apparent simplicity is misleading after inspection.

---

## Tier B — ordinary/common

Use when:

- the PR changes real behavior;
- scope is bounded and understandable;
- no specialist risk trigger below is material;
- one capable general reviewer can reasonably cover the change.

Typical examples:

- normal CRUD behavior;
- routine API/UI wiring;
- ordinary bug fix;
- bounded feature implementation;
- moderate component or service change without sensitive boundaries.

### Dispatch

Dispatch only:

`final-adversarial-reviewer`

Invoke it in `STANDALONE` mode.

Do not dispatch `code-reviewer` in addition. The final adversarial reviewer subsumes the general review.

---

## Tier C — specialist/targeted

Use when one or more concrete specialist triggers exist.

Select only reviewers whose trigger is materially present.

Independent selected reviewers should be dispatched in parallel when possible.

A single bounded specialist review does not automatically require a final adversarial pass.

Add a second-wave `final-adversarial-reviewer` only when the final-pass gate is met.

---

## Tier D — complex/high-risk

Use when any of the following is true:

- multiple specialist domains interact;
- the change crosses several system boundaries;
- a failure can create serious security, money, tenant-isolation, data-integrity, or irreversible-state impact;
- requirements are broad and implementation spans multiple layers;
- there are meaningful async/external side effects;
- a large architectural/refactoring change makes correlated reviewer assumptions likely.

### Dispatch

1. Select the necessary first-wave specialist reviewers.
2. Dispatch all independent first-wave reviewers in parallel when possible.
3. Deduplicate and summarize their findings.
4. Dispatch `final-adversarial-reviewer` in `FINAL_PASS` mode with:
   - original requirements;
   - diff/relevant code context;
   - first-wave reports;
   - deduplicated findings.

The final reviewer must search for missed assumptions and integration failures, not vote on previous reports.

---

# Specialist trigger rules

A reviewer is selected only when at least one material trigger is present.

## `implementation-reviewer`

Select when explicit implementation obligations exist and tracing them matters, for example:

- issue with acceptance criteria;
- implementation plan/spec with multiple requirements;
- migration checklist;
- user-requested behavior spanning multiple files/layers;
- follow-up review whose main question is whether a prior correction plan was fully implemented.

Do not select merely because every PR has a description.

Do not select if the change is trivial and requirements are obvious from the diff.

---

## `functional-correctness-reviewer`

Select when correctness depends on non-trivial logic, for example:

- state machines or multi-step state transitions;
- complex conditional behavior;
- parsing/normalization/transformation logic;
- calculations or algorithms;
- pagination/order/filter semantics;
- date/time/timezone logic;
- non-trivial cache/state synchronization;
- substantial domain rules.

Do not select for straightforward wiring or mechanical changes.

---

## `architecture-reviewer`

Select when the PR changes architectural shape, for example:

- introduces a package/module/service boundary;
- adds or changes a shared/public API;
- changes dependency direction;
- moves responsibilities across layers;
- introduces a new repository-wide pattern;
- restructures significant portions of the codebase;
- adds a new persistence/domain/client-server boundary.

Do not select simply because multiple files changed.

---

## `security-reviewer`

Select when the PR touches a security or trust boundary, including:

- authentication/session/token handling;
- authorization, permissions, roles, ownership, tenancy;
- user-controlled input reaching sensitive sinks;
- secrets/credentials;
- file uploads/downloads;
- webhooks/signatures;
- cross-origin/cookie/CSRF behavior;
- redirects or callback URLs;
- sensitive data exposure;
- admin/privileged operations;
- payment or billing authorization surfaces.

A UI-only permission check still counts as a security trigger if it corresponds to a privileged action.

---

## `reliability-reviewer`

Select when correctness depends on time, ordering, retries, concurrency, or multi-system side effects, including:

- queues/jobs/events;
- retries/backoff;
- transactions;
- concurrent writes;
- idempotency;
- webhooks with side effects;
- external API side effects;
- eventual consistency;
- background processing;
- async workflows that can partially fail;
- cache invalidation where stale state can cause incorrect writes.

---

## `test-quality-reviewer`

Select when test credibility is itself a material risk, for example:

- substantial new behavior has weak, missing, or suspicious tests;
- the PR modifies the testing infrastructure;
- mocks replace important production semantics;
- a critical regression path needs explicit protection;
- the change claims a regression fix but the test does not clearly reproduce the bug;
- a refactor is expected to preserve behavior and tests are the main safety net.

Do not select merely because every PR should have tests.

---

## `performance-reviewer`

Select when changed code plausibly affects a hot path or scale behavior, including:

- database query shape/count;
- list/search endpoints over potentially large data sets;
- nested work over unbounded collections;
- rendering/subscription behavior in frequently updated UI;
- polling/streaming;
- cache strategy;
- large serialization/payloads;
- memory retention;
- repeated external/network work;
- algorithmic complexity on non-trivial input sizes.

Do not select for speculative micro-optimizations.

---

## `maintainability-agent-dx-reviewer`

Select when consistency/discoverability is materially affected, including:

- broad refactors;
- new canonical patterns;
- duplicated components/services/hooks/utilities;
- competing ways to perform the same recurring task;
- significant folder/module reorganization;
- generated/agent-authored code that introduces parallel abstractions;
- repository rules that need enforcement or documentation to prevent recurrence.

Do not select for minor naming/style concerns.

---

# Final-pass gate

After selecting first-wave specialists, dispatch `final-adversarial-reviewer` in `FINAL_PASS` mode if ANY of these are true:

1. Two or more materially different specialist domains are selected and interact.
2. The PR touches a high-impact boundary:
   - authentication/authorization;
   - tenant isolation;
   - money/billing/payment state;
   - destructive or irreversible data changes;
   - migrations with compatibility risk;
   - external side effects where duplicate/partial execution matters;
   - concurrency or distributed-state correctness.
3. The implementation spans three or more architectural layers and the correctness depends on their integration.
4. First-wave reviewers disagree materially.
5. First-wave findings reveal a shared assumption that deserves independent challenge.
6. The change is a broad refactor or cross-cutting feature where correlated reviewer blind spots are plausible.

Otherwise, do not add the final reviewer solely for ceremony.

---

# Reviewer budget and prioritization

The goal is not to maximize parallelism. The goal is to maximize independent useful coverage per reviewer.

Guidelines:

- Tier A: exactly 1 reviewer.
- Tier B: exactly 1 reviewer.
- Tier C: normally 1-3 reviewers.
- Tier D: normally 2-5 first-wave reviewers plus one final adversarial pass.

If more than five specialist reviewers appear relevant, prioritize the domains with the highest plausible impact and strongest evidence from the diff.

Suggested priority when constrained:

1. security;
2. reliability/data integrity;
3. implementation coverage;
4. functional correctness;
5. architecture;
6. test quality;
7. performance;
8. maintainability/agent-DX.

This ordering is a resource-allocation heuristic, not a severity ranking for findings.

---

# Parallel dispatch rules

When the harness supports parallel subagents, dispatch all independent first-wave reviewers in one parallel batch.

Good:

```text
parallel:
  - security-reviewer
  - reliability-reviewer
  - implementation-reviewer
```

Avoid unnecessary sequencing such as:

```text
security -> reliability -> implementation
```

unless one reviewer actually depends on another's output.

The following reviewers should normally be independent and can run in parallel:

- implementation;
- functional correctness;
- architecture;
- security;
- reliability;
- test quality;
- performance;
- maintainability/agent-DX.

`final-adversarial-reviewer` in `FINAL_PASS` mode is intentionally second-wave and must wait for first-wave outputs.

In `STANDALONE` mode it is the only reviewer and has no dependency.

If the harness cannot run subagents concurrently, execute the same selected set sequentially without changing the selection policy.

---

# Context isolation

Avoid anchoring independent reviewers on each other's conclusions.

First-wave reviewers receive:

- original requirements relevant to the change;
- PR/diff/repository context;
- their own role prompt.

They should NOT receive other first-wave reviewer findings.

Only the second-wave final adversarial reviewer receives previous reviewer reports.

---

# Required reviewer task envelope

For each dispatched reviewer, provide a task containing:

```text
MODE: <if applicable>
TARGET: <PR / branch / commit range>
BASE: <base revision if known>
HEAD: <head revision if known>

REVIEW OBJECTIVE:
<one sentence describing why this reviewer was selected>

REQUIREMENTS:
<only the relevant issue/spec/acceptance criteria, or 'none explicit'>

REPOSITORY RULES:
<relevant AGENTS.md / CONTRIBUTING / architecture constraints>

SCOPE:
<changed files plus permission to inspect surrounding code as necessary>

DO NOT:
- modify the implementation;
- report unrelated pre-existing issues;
- manufacture findings;
- treat stylistic preferences as defects;
- claim runtime validation that was not actually executed.

RETURN:
Only evidence-backed findings, validation performed, and residual uncertainty.
```

For `FINAL_PASS` mode additionally include:

```text
PRIOR REVIEW REPORTS:
<first-wave outputs>

DEDUPLICATED KNOWN FINDINGS:
<known root causes>

Your job is to find new material issues, deeper consequences, contradictions, or shared assumptions. Do not restate known findings.
```

---

# Orchestrator review procedure

## Step 1 — Inspect before routing

Read the diff and enough surrounding context to classify the PR.

Do not choose reviewers based only on PR title, labels, or file count.

## Step 2 — Mark risk signals

Internally mark only material signals:

```text
explicit_requirements
functional_complexity
architecture_change
security_boundary
reliability_concurrency
critical_test_risk
performance_scale
maintainability_pattern_change
high_impact_boundary
cross_layer_integration
```

## Step 3 — Choose the tier

Use this order:

1. If clearly trivial/simple and no risk signals -> Tier A.
2. Else if no specialist signal is material -> Tier B.
3. Else if specialist signals are bounded and mostly independent -> Tier C.
4. Else -> Tier D.

## Step 4 — Select reviewers

Tier A:

```text
code-reviewer
```

Tier B:

```text
final-adversarial-reviewer(STANDALONE)
```

Tier C/D:

Map material signals to specialists using the trigger rules.

Do not add `code-reviewer` to a specialist run.

Do not add a specialist merely to obtain another opinion.

## Step 5 — Parallel first wave

Dispatch selected independent specialists concurrently when possible.

## Step 6 — Normalize findings

Normalize each finding to:

- severity;
- root cause;
- exact location;
- triggering scenario;
- observed behavior;
- expected invariant/requirement;
- concrete impact;
- suggested correction;
- evidence/validation.

Reject findings that are purely speculative or stylistic.

## Step 7 — Deduplicate by root cause

Two findings are duplicates when the same underlying defect causes them, even if:

- symptoms differ;
- reviewers assign different severities;
- wording differs;
- one reviewer describes security impact and another correctness impact.

Keep the clearest evidence and preserve distinct impacts under one root cause.

## Step 8 — Decide final pass

Apply the final-pass gate.

If it is not met, stop after synthesis.

If it is met, run `final-adversarial-reviewer(FINAL_PASS)`.

## Step 9 — Validate findings when practical

When the environment allows it, verify material findings with the smallest useful command/test/reproduction.

Prefer targeted validation before broad test suites.

Do not change production code as part of review unless the user explicitly asks for fixes.

## Step 10 — Produce the final report

Use:

```markdown
# PR Review

## Result
PASS | CHANGES REQUIRED

## Review strategy
<one concise sentence stating which reviewers were used and why>

## Material findings

### [SEVERITY] Title
- Location:
- Trigger/scenario:
- Evidence:
- Impact:
- Recommended correction:

## Requirement coverage
<include only when implementation-reviewer was used or explicit requirements materially matter>

## Validation performed
<commands/checks actually executed>

## Residual risk
<only meaningful unverified areas>
```

Do not expose internal chain-of-thought or hidden scoring.

A clean review may simply state that no material issues were found, plus validation and residual risk.

---

# Severity model

Use one shared scale across reviewers.

## BLOCKER

The PR should not merge in its current form because a core requirement is absent/fundamentally broken or the change creates a severe correctness/security/data-integrity failure.

## HIGH

A realistic and important scenario produces substantial incorrect behavior, security impact, data inconsistency, or operational failure.

## MEDIUM

A concrete, reachable scenario produces meaningful but bounded impact.

## LOW

A concrete minor defect with limited impact. Do not use LOW for preferences, cleanup, or speculative improvements.

Do not inflate severity to make a review look useful.

---

# Anti-patterns

Never do the following:

### Fan-out by default

Bad:

```text
Run all reviewers on every PR.
```

Why: expensive, redundant, anchored, and noisy.

### General-review duplication

Bad:

```text
code-reviewer + final-adversarial-reviewer + functional-reviewer
```

for an ordinary bounded change with no specialist trigger.

Use only the final adversarial reviewer in standalone mode.

### Size-only routing

A 20-line authorization change can deserve more scrutiny than a 500-line generated snapshot update.

### Reviewer voting

Do not conclude correctness because several reviewers said PASS.

One reproducible counterexample outweighs multiple generic approvals.

### Checklist vulnerability spam

Do not report "possible SQL injection" unless a concrete untrusted path to a SQL sink exists.

### Finding quotas

Reviewers are allowed to return zero findings.

### Final-pass repetition

The final adversarial reviewer must not rephrase first-wave findings simply to produce output.

---

# Routing examples

| Change | Expected reviewers |
|---|---|
| README typo | `code-reviewer` |
| CSS spacing/token correction | `code-reviewer` |
| Mechanical local rename/refactor | `code-reviewer` |
| Ordinary bounded bug fix | `final-adversarial-reviewer(STANDALONE)` |
| Routine CRUD feature without sensitive boundaries | `final-adversarial-reviewer(STANDALONE)` |
| Complex parser/state transition | `functional-correctness-reviewer`; add final pass only if other gate conditions apply |
| Authorization/ownership change | `security-reviewer` + `final-adversarial-reviewer(FINAL_PASS)` |
| Queue worker with retry/idempotency change | `reliability-reviewer`; add `security-reviewer` only if trust/auth boundaries are touched; final pass when high-impact or cross-system |
| Payment webhook handling | `security-reviewer` + `reliability-reviewer` + `final-adversarial-reviewer(FINAL_PASS)` |
| Large feature with explicit spec, auth, async jobs | `implementation-reviewer` + `security-reviewer` + `reliability-reviewer` + relevant functional/test reviewer(s) in parallel, then `final-adversarial-reviewer(FINAL_PASS)` |
| New shared package and dependency boundaries | `architecture-reviewer`; add `maintainability-agent-dx-reviewer` if a new canonical pattern or duplication risk is introduced |
| Behavior-preserving broad refactor | `architecture-reviewer` + `test-quality-reviewer` + `maintainability-agent-dx-reviewer`, then final pass if cross-cutting |
| Query rewrite on a large listing endpoint | `performance-reviewer`; add `functional-correctness-reviewer` if result semantics also changed |
| Test harness/mocking infrastructure change | `test-quality-reviewer`; add architecture only if the testing architecture itself changes repository-wide boundaries |

---

# Completion criterion

The review is complete when:

- the change has been classified from evidence;
- only necessary reviewers were run;
- independent reviewers were parallelized where possible;
- material findings were normalized and deduplicated;
- a final adversarial pass was run only when justified;
- the final report distinguishes verified defects from residual uncertainty.

Do not run more reviewers merely because review capacity remains.
