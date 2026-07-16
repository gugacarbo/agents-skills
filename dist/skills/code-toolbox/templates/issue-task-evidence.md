## Task evidence

Agent: `executor`
Phase/scope: `<plan cycle and Task-ID>`
Summary: `<DONE | DONE_WITH_CONCERNS | BLOCKED | no-change result>`
Sources/evidence: `<plan URL, base SHA, branch, commits, and PR when available>`
Decisions: `<applied, pending, or none>`
Changes/validation: `<changed files, commands, and results>`
Blockers: `<blocker or none>`
Next action: `<delivery-reviewer review | resolve blocker, owner>`

**Plan cycle / task:** `<URL and Task-ID>`
**Status:** `DONE | DONE_WITH_CONCERNS | BLOCKED`
**Base SHA / branch:** `<SHA> / <branch>`
**Commits / PR:** `<links>`

## Changed files

- …

## Verification

```text
<command> — <result>
```

## TDD evidence

`not applicable | RED: … | GREEN: …`

## Concerns or blocker

…

---

*Process: code-toolbox — append-only eight-field executor evidence for independent review.*

`BLOCKED` is not review-ready. It must identify the exact required decision or correction and keeps the issue blocked until resolved.
