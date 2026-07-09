# Pre-Write Approval Prompt

Present this to the user before writing the spec file.

```
Question: "Here's the spec summary for [feature name]:
- Problem: [problem]
- Goal: [goal]
- Key requirements: [list]
- Non-goals: [list]

Should I write the full spec? I'll save the brainstorming decisions first in docs/spec-decisions/[feature_number]_[feature_name]_decisions.md."

Options:
  - "Approved — write the decisions file and the spec"
  - "Needs changes — [free text field for user to describe what to change]"
```

If approved: save the decisions file first using the template, then write the spec file.
If changes requested: incorporate feedback and present the summary again.
