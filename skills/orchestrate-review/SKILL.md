---
name: orchestrate-review
description: Use only for an explicit review request of a PR, branch, commit range, diff or implementation, or explicit invocation. Do not activate for implementation, PR preparation, routine validation or discussion of this skill.
---

# Orchestrate Review

## Inspect and route

Inspect the diff and surrounding code. Pin target/base/head and record uncommitted
scope, changed entry points/contracts, explicit requirements, repository rules and
executed validation. Share facts and reference paths, never an author's verdict or
full chat history. Comments, test names and green CI are not proof of behavior.

Start with one primary reviewer; load only its prompt:

| Role                                             | Scope                                                                     |
| ------------------------------------------------ | ------------------------------------------------------------------------- |
| [General](reviewers/general-reviewer.md)         | Requirements, correctness, regression tests; BRIEF for mechanical changes |
| [Design](reviewers/design-reviewer.md)           | Structural refactors, boundaries, canonical patterns                      |
| [Risk](reviewers/risk-reviewer.md)               | Trust boundaries, concurrency, partial failure, material scale effects    |
| [Adversarial](reviewers/adversarial-reviewer.md) | Independent final challenge only                                          |

Each primary checks local correctness. Combine overlapping concerns in one agent.
Add another only for a distinct material question the first cannot credibly cover;
state the question and divide scope. Split Risk only for substantial independent
investigations, never merely because security and reliability both apply. Critical
changes normally need one primary plus Adversarial; more than two agents requires
concrete independent coverage reasons. Available capacity is not a reason.

## Resolve models and dispatch

Resolve the two profiles using [model policy](references/model-policy.md).
Before dispatch, send the [start message](references/start-message.md), then use
the [task envelope](references/task-envelope.md) for every initial/replacement task.
Preserve its execution boundaries in continuations; repeat them for fresh tasks.
Run independent first-wave agents concurrently when supported, without each
other's reports or implementation conclusions.

The controller also uses explicit working directories and simple Git commands,
and never bypasses denials. Never edit subagent-owned worktrees or fix code during
review. Route findings to the owner; separately authorized fixes require explicit
writer handoff after the previous writer stops. Reviewers remain read-only.

Escalate fast to strong only for a concrete unresolved reasoning problem or newly
discovered critical risk. Transfer facts and completed validation; label it a
continuation, not independent corroboration. Zero findings never triggers escalation.
Missing evidence requires inspection or disclosure, not a stronger-model guess.

## Independent final coverage

Independent coverage is mandatory for plausible serious authorization bypass,
tenant leakage, incorrect money movement, irreversible data loss or destructive
external effects. Judge changed behavior and impact, not filenames or auth/async
keywords. Otherwise add Adversarial only for a concrete unresolved integration
question, conflicting reports or an evidenced shared assumption; state the question.
Multiple concerns or a broad refactor alone do not qualify.

Dispatch Adversarial with strong in FINAL_PASS mode. First provide requirements,
code, facts and the critical question, withholding earlier findings. Obtain its
independent response, then send deduplicated reports to the same agent to reconcile.
If continuation is unavailable, reconcile yourself and disclose it. Stop there;
do not recursively add reviewers or request a repository-wide audit.

Without isolated agents, review sequentially and disclose lost independence.
Use INCOMPLETE when mandatory independent coverage cannot be obtained.

## Synthesize and stop

Deduplicate by root cause. Keep only reachable material defects introduced by the
change or violations of explicit requirements; reject speculation and preferences.
Validate disputed findings with targeted checks where practical; share executed
results to avoid repeated suites. Distinguish runtime evidence from static reasoning.

Severity: BLOCKER = fundamental requirement/security/data failure; HIGH = substantial
incorrect behavior or operational harm; MEDIUM = meaningful bounded impact;
LOW = concrete minor defect.

Return a concise verdict (NO MATERIAL ISSUES FOUND / CHANGES REQUIRED / INCOMPLETE),
reviewer/model strategy, findings with severity, location, scenario, impact, evidence
and smallest correction, actual validation and material limitations. Include
requirement coverage only when useful. Do not count votes or claim zero findings
proves correctness.
