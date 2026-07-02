# Progress Ledger

Track task status in a durable file that survives context compaction. Update this file after every task state change.

## Format

```
| Task | Status       | Commits          | Report File | Review                                     |
| ---- | ------------ | ---------------- | ----------- | ------------------------------------------ |
| T01  | ✅ complete  | abc1234..def5678 | T01/report.md | clean                                      |
| T02  | 🔎 ready for review | ghi9012.. | T02/report.md | awaiting review                            |
| T03  | ⏳ pending   | —                | —           | —                                          |
```

## Status Values

- ⏳ pending — task not yet dispatched
- 🔄 in progress — implementer subagent is working
- 🔎 ready for review — implementer finished and independent review is next
- 🔄 in review — reviewer subagent is checking
- 🔁 needs-fix — reviewer found Critical/Important issues
- ✅ complete — spec compliance and code quality approved
- ❌ blocked — implementer escalated; cannot proceed without user input or plan change

## Notes

- After context compaction, trust this ledger and `git log` over your own recollection.
- Never re-dispatch a task the ledger marks as ✅ complete (see SKILL.md Red Flags).
- Record the commit range for each task so reviewers can generate diffs quickly.
- Store per-task report, review package, progress log, and logger under `docs/tasks/<plan>/<task-id>/`.
