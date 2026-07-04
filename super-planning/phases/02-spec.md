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

## Spec File Location

```
docs/specs/NNNN-<feature-name>-spec.md
```

- `NNNN` is a zero-padded sequential number. Check `docs/specs/` for the next number; create the directory if it doesn't exist.
- **The plan MUST use the same number:**
  ```
  docs/specs/0003-auth-middleware-spec.md   ← spec
  docs/plans/0003-auth-middleware.md        ← plan
  ```

## Default Spec Format

Key sections:

- **Objective** — what the user/system can do once implemented
- **Flow** — step-by-step observable behavior (happy path + key branches)
- **Contract** — inputs, outputs, formats, guarantees
- **Edge cases** — enumerated and decided using EARS (`WHEN <trigger> the system MUST <response>`); undecided cases go to Open questions
- **Open questions** — each item blocks an implementation point; do not improvise
- **Definition of Done** — runnable commands with binary pass/fail criteria
- **Human review** — what requires human eyes and is NOT in the agent loop

## Pre-Write Approval Gate

<HARD-GATE>
Do NOT write the spec file until the user has approved the summary. This applies regardless of perceived simplicity.
</HARD-GATE>

1. **Present a summary:** problem statement (1–2 sentences), goal (1 sentence), key requirements (3–7 bullets), non-goals, architecture approach (1–2 sentences), open questions (if any).
2. **Ask for approval** using [`prompts/pre-write-approval.md`](../prompts/pre-write-approval.md). This prompt must also ask whether to create the optional brainstorming decisions file at `docs/specs/{feature_number}_{feature_name}_decisions.md`.
3. **If approved with decisions file enabled:** write `docs/specs/{feature_number}_{feature_name}_decisions.md` from the Phase 1 outputs using [`templates/decisions-template.md`](../templates/decisions-template.md), then write the spec file.
4. **If approved without the decisions file:** write the spec file only.
5. **If changes requested:** incorporate feedback and present the summary again.

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

## Optional Spec Reviewer Pass

When the spec is complex, high-risk, or likely to be ambiguous, dispatch a lightweight reviewer using [`prompts/spec-document-reviewer-prompt.md`](../prompts/spec-document-reviewer-prompt.md).

Use that pass to catch real planning blockers, not stylistic nits. If it finds issues, fix them before the Post-Write Approval Gate.

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
