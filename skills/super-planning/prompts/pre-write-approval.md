# Pre-Write TDD and Spec Approval Prompt

Present the TDD decision first, then present the spec summary. Do not write the spec file until both decisions are complete.

```
Question: "Should this spec use TDD for behavior-changing work?

Options:
  - "Yes — require RED/GREEN evidence for behavior changes"
  - "No — use conventional test coverage"
  - "Custom scope — I will define the exceptions"
```

Record the answer in the decisions handoff and the spec's `Test Strategy` section. If the answer is ambiguous, ask for clarification before writing the summary.

Then present:

```
Question: "Here's the spec summary for [feature name]:
- Problem: [problem]
- Goal: [goal]
- Key requirements: [list]
- Non-goals: [list]
- Testing mode: [TDD or conventional coverage]
- Main test scenarios: [list]
- Testing guidance: [effective testing-anti-patterns.md path]

Should I write the full spec? I'll save the brainstorming decisions first in docs/spec-decisions/[feature_number]_[feature_name]_decisions.md."

Options:
  - "Approved — write the decisions file and the spec"
  - "Needs changes — [free text field for user to describe what to change]"
```

If approved: save the decisions file first using the template, then write the spec file.
If changes requested: incorporate feedback and present the summary again.
