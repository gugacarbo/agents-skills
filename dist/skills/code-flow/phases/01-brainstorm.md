# Phase 1: Prepare the source set

Run the execution preflight in `SKILL.md` first. Continue only after the work is confirmed as one delivery issue; an initiative needs an explicit Epic decision and a narrowed child issue before source-set preparation. Write each delivery issue as one user story with `templates/user-story.md`; reserve plan task IDs for implementation-only work.

Before issue creation, dispatch `agents/issue-writer.md`. It investigates the narrow repository area, accepted ADRs/specs, current code/tests, conventions, ownership, dependencies, risks, and unresolved product decisions.

The orchestrator uses its evidence to refine purpose, constraints, observable outcome, non-goals, and edge cases. Ask the user only for unresolved product decisions; the issue-writer must not improvise them. Use the visual companion only when it makes the next decision easier.

The issue-writer records its complete eight-field evidence envelope: as an issue comment immediately after issue creation, or in direct mode as a delivery-record section. It does not plan or implement. Carry the approved facts into Phase 2.
