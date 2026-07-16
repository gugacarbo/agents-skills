# Required Spec Approval Prompt

Use this prompt only after Phase 2 returns `create` or `update`. Do not use it when spec impact is `not required`.

```
Question: "This change requires a repository ADR/spec because it changes [contract | observable behavior | durable decision].

Target: [path]
Summary: [goal, contract/decision, edge cases, DoD, test strategy]

Should I write or update this document before the plan?"

Options:
  - "Approved — write/update the ADR or spec"
  - "Needs changes — [feedback]"
```

After the document is written, obtain explicit human approval before dispatching the plan author. Do not create a decision file for `not required` work.
