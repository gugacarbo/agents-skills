# Post-Write Approval Prompt

Use the question/ask tool after writing the spec file to confirm user approval before proceeding to planning.

```
Question: "Spec written to docs/specs/NNNN-<feature-name>-spec.md. Please review it."

Options:
  - "Approved — create the implementation plan"
  - "Needs changes — [free text field for user to describe what to change]"
```

Do NOT proceed to Phase 1 (planning) until the spec is approved. If changes are requested, update the spec and ask again. Loop until approved.
