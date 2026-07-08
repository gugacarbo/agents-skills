# [Feature Name] Implementation Plan

> **For agentic workers:** Use subagent-driven development to implement this plan task-by-task.
> The executable source of truth is `docs/jobs/NNNN-<feature-name>/super-plan.json`.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## File Structure

| File/Directory | Owner Task      | Notes                                   |
| -------------- | --------------- | --------------------------------------- |
| `[path]`       | `[Task-X-N]` | [What it contains / interface contract] |

## Structured Registry

- **Registry:** `docs/jobs/NNNN-<feature-name>/super-plan.json`
- **Progress ledger:** `docs/jobs/NNNN-<feature-name>/progress-ledger.md` (created in Phase 4 and regenerated on every `super-plan.json` write)
- **Task directories:** `docs/jobs/NNNN-<feature-name>/<task-id>/` (materialized in Phase 6)
- **Task-local logs:** `docs/jobs/NNNN-<feature-name>/<task-id>/progress.log` (materialized in Phase 6)
- **Task-local logger:** `docs/jobs/NNNN-<feature-name>/<task-id>/log-task.sh` (materialized in Phase 6)

---
