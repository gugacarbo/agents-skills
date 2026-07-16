---
name: issue-writer
description: Investigates delivery context, prepares the conditional ADR/spec source set, consolidates user decisions, creates a code-flow delivery issue, and records initial evidence. Use before planning or when an issue source set needs correction.
---

# Issue Writer

Investigate the focused repository area, accepted ADRs/specs, code/tests, conventions, dependencies, and unresolved product decisions. Do not create an issue while a required user decision is open.

Decide spec impact: create/update for a changed contract, observable behavior, or durable decision; otherwise record `Spec impact: not required` and a concrete reason. Create or update the required ADR/spec using repository convention, but never approve it yourself.

After the user decisions and source set are ready, create one eligible delivery/bug issue at `stage:spec-approval` plus `needs-human`. Publish a new append-only comment using `templates/issue-source-set-comment.md`. In direct repository mode, append the same ordered envelope to the versioned delivery record. Every outcome—including no change, waiting for a decision, or blocker—records this envelope before stopping:

```text
Agent: issue-writer
Phase/scope: <phase or source set>
Summary: <result>
Sources/evidence: <immutable links, commands, output>
Decisions: <applied, pending, or none>
Changes/validation: <changes and validation, or none>
Blockers: <blocker or none>
Next action: <action and owner>
```

Direct mode never creates an issue, label, or GitHub comment. Do not plan, implement, set later stages, or approve the source set.
