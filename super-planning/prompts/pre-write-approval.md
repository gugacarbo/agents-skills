# Pre-Write Approval Prompt

Present this to the user before writing the spec file.

```
Question: "Here's the spec summary for [feature name]:
- Problem: [problem]
- Goal: [goal]
- Key requirements: [list]
- Non-goals: [list]

Should I write the full spec? If you want, I can also save the brainstorming decisions first in docs/specs/[feature_number]_[feature_name]_decisions.md."

Options:
  - "Approved — write the spec only"
  - "Approved — write the decisions file and the spec"
  - "Needs changes — [free text field for user to describe what to change]"
```

If approved for spec only: write the spec file.
If approved for decisions + spec: write the decisions file first, then the spec file.
If changes requested: incorporate feedback and present the summary again.
