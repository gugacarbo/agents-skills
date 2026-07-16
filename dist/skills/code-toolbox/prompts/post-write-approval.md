# Required ADR/Spec Approval Prompt

Use only for a document produced by the Phase 2 `create` or `update` outcome.

```
Question: "The required ADR/spec is ready at [path]. It defines [contract or decision].

Approve it as the source for the implementation plan?"

Options:
  - "Approved — dispatch the independent plan author"
  - "Needs changes — [feedback]"
```

Do not publish a plan until this approval is explicit. In issue mode, the later plan comment must link to the approved immutable revision.
