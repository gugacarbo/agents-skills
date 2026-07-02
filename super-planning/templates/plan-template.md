# [Feature Name] Implementation Plan

> **For agentic workers:** Use subagent-driven development to implement this plan task-by-task.
> The executable source of truth is `docs/tasks/NNNN-<feature-name>/tasks.json`.

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
| `[path]`       | `[Task-X-NNNN]` | [What it contains / interface contract] |

## Task Registry

- **Registry:** `docs/tasks/NNNN-<feature-name>/tasks.json`
- **Progress ledger:** `docs/tasks/NNNN-<feature-name>/progress-ledger.md`
- **Task directories:** `docs/tasks/NNNN-<feature-name>/<task-id>/`
- **Task-local logs:** `docs/tasks/NNNN-<feature-name>/<task-id>/progress.log`
- **Task-local logger:** `docs/tasks/NNNN-<feature-name>/<task-id>/log-task.sh`

---
