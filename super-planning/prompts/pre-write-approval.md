# Pre-Write Approval Prompt

Present this to the user before writing the spec file.

```
Question: "Here's the spec summary for [feature name]:
- Problem: [problem]
- Goal: [goal]
- Key requirements: [list]
- Non-goals: [list]

Should I write the full spec?"

Options:
  - "Approved — write the spec"
  - "Needs changes — [free text field for user to describe what to change]"
```

If approved: write the spec file.
If changes requested: incorporate feedback and present the summary again.
