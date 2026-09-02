# Baseline before parallel-wave guidance

Snapshot SHA-256 for the original `SKILL.md`:
`1be8e177978b4dcba930c655e5d7effc2f10ef1787e848da47365d8b8d8d7122`.

The old skill had one unconditional execution choice:
`Never dispatch multiple implementation subagents in parallel (conflicts).`

Observed contract failures and controls:

- A plan with two independent tasks and disjoint writes was serialized. The
  skill had no route that could dispatch both implementers concurrently.
- A plan with overlapping writes was serialized correctly. This remains a
  regression control for the new conditional behavior.
- The old preflight inspected shared files and interfaces but did not calculate
  complete write sets, operational state, task waves, or isolated task
  worktrees, so removing the prohibition alone would have made concurrency
  unsafe.

Because this environment did not authorize evaluator subagents, this is a
deterministic instruction-contract baseline rather than a behavioral agent
run. Paired behavioral runs remain required before claiming the revision is
verified.
