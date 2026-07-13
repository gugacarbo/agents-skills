# Phase 2: Writing the Spec

Before any planning or code, capture what you're building in a spec document. The spec is the contract between the user and the implementation — every task in the plan must trace back to it.

## Check Workspace Documentation Patterns

Before writing, scan the workspace for existing conventions:

1. **Existing specs:** `docs/specs/`, `specs/`, `docs/`, or any spec-like directory.
2. **Naming conventions:** sequential numbering (`0001-`), date-based (`YYYY-MM-DD-`), etc.
3. **File format:** markdown, plain text, or structured formats.
4. **Content structure:** headers, sections, required fields.
5. **Templates:** `docs/templates/spec.template.md` or similar.

Follow existing patterns. If none exist, use [`templates/spec-template.md`](../templates/spec-template.md).

## Resolve Testing Guidance and TDD

Before presenting the pre-write summary, inspect the target repository for testing guidance:

1. Search for an existing `testing-anti-patterns.md`. If found, use it and do not overwrite it.
2. If it is absent, identify the repository's documentation/context convention from `AGENTS.md`, existing docs directories, and nearby guidance files.
3. Copy [`../templates/testing-anti-patterns.md`](../templates/testing-anti-patterns.md) to that convention. Use `docs/context/testing-anti-patterns.md` when no convention exists.
4. Record the effective guidance path in the spec's **Test Strategy** section and carry it into task rules for tasks that add or modify tests.

Before writing the spec, ask the user whether this spec should use TDD for behavior changes. If TDD is selected, apply it to features, bugs, behavior-changing refactors, and integrations. Documentation, static configuration, and ambiguous tasks require confirmation before being treated as TDD work.

## Spec File Location

```
docs/specs/NNNN-<feature-name>-spec.md
```

- `NNNN` is a zero-padded sequential number. **Allocate it now:** check `docs/specs/` for the next number; create the directory if it doesn't exist.
- **Rename the decisions file** from `docs/spec-decisions/<feature_name>_decisions.md` to `docs/spec-decisions/NNNN_<feature_name>_decisions.md` using the allocated number.
- **The plan MUST use the same number:**
  ```
  docs/specs/0003-auth-middleware-spec.md   ← spec
  docs/plans/0003-auth-middleware.md        ← plan
  ```

> **Naming fallback:** If the repo does not follow the `docs/specs/NNNN-<name>` convention, check existing spec files and follow the established pattern. Document the convention found in the decisions file.

## Default Spec Format

Key sections:

- **Objective** — what the user/system can do once implemented
- **Flow** — step-by-step observable behavior (happy path + key branches)
- **Contract** — inputs, outputs, formats, guarantees
- **Edge cases** — enumerated and decided using EARS (`WHEN <trigger> the system MUST <response>`); undecided cases go to Open questions
- **Open questions** — each item blocks an implementation point; do not improvise
- **Definition of Done** — runnable commands with binary pass/fail criteria
- **Test Strategy** — selected TDD mode, guidance path, runner/commands, main scenarios, test levels, and RED/GREEN evidence expectations
- **Human review** — what requires human eyes and is NOT in the agent loop

## Pre-Write Approval Gate

<HARD-GATE>
Do NOT write the spec file until the user has approved the summary. This applies regardless of perceived simplicity.
</HARD-GATE>

1. **Present a summary:** problem statement (1–2 sentences), goal (1 sentence), key requirements (3–7 bullets), non-goals, architecture approach (1–2 sentences), testing decision, main test scenarios, and open questions (if any).
2. **Ask for approval** using [`prompts/pre-write-approval.md`](../prompts/pre-write-approval.md).
3. **If approved:** first rename the decisions file from `docs/spec-decisions/<feature_name>_decisions.md` to `docs/spec-decisions/NNNN_<feature_name>_decisions.md` using the allocated number, then write the spec file.
4. **If changes requested:** incorporate feedback and present the summary again.

## Post-Write Approval Gate

After writing the spec, ask the user to review it before proceeding to planning. Use [`prompts/post-write-approval.md`](../prompts/post-write-approval.md).

Do NOT proceed to Phase 3 until the spec is approved. If changes are requested, update the spec and ask again.

## Spec Self-Review

Immediately after writing the spec, do a quick self-review before sending it to the user:

1. **Placeholder scan** — remove `TODO`, `TBD`, and incomplete sections.
2. **Internal consistency** — check that the architecture, requirements, and edge cases do not contradict each other.
3. **Scope check** — make sure the spec is still focused enough for one implementation plan.
4. **Ambiguity check** — if a requirement could be interpreted in multiple ways, choose one and make it explicit.

Fix issues inline before asking the user to review the file.

> **Record:** Append a `# Self-Review` section to the spec file with the reviewer's verdict (`approved`/`needs_revision`) and date.

## Optional Spec Document Review Subagent

After the self-review, ask the user:

> "Would you like me to dispatch a review subagent to audit this spec for inconsistencies, logical bugs, missing decisions, and planning blockers before we proceed?"

If the user agrees, dispatch a general-purpose subagent using [`agents/spec-document-reviewer.md`](../agents/spec-document-reviewer.md). Provide the spec file path and let the subagent produce a thorough Spec Document Review Report.

If the review finds critical issues, fix them before the Post-Write Approval Gate.

> **Note:** The spec document review subagent is optional, but if used, its findings MUST be addressed before proceeding. The decisions file is NOT optional — always save it.

**Full implementation audit:** For auditing whether the implementation matches the spec after all tasks are complete, use [`agents/spec-compliance-auditor.md`](../agents/spec-compliance-auditor.md) during Phase 7 (Integrate).

## Spec Status Lifecycle

| Status        | When                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| `draft`       | Initial state when the spec file is created.                              |
| `accepted`    | User has reviewed and approved the spec (after Post-Write Approval Gate). |
| `implemented` | All tasks complete, final review clean, and Definition of Done passes.    |
| `deprecated`  | Spec is no longer relevant.                                               |

Transition rules:

- Only move to `accepted` after the Post-Write Approval Gate passes.
- Only move to `implemented` after Phase 7 closes and the DoD commands run green.
- Update `implemented-by` with real paths when transitioning to `implemented`.
- Never skip states.
