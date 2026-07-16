## Revisão independente do plano

Agent: `plan-reviewer`
Phase/scope: `plan cycle <k>/3`
Summary: `<review result>`
Sources/evidence: `<plan comment URL, immutable source links, and base SHA>`
Decisions: `<literal verdict and required decisions>`
Changes/validation: `<review checks and validation, or none>`
Blockers: `<blocker or none>`
Next action: `<approve plan | revise plan | human decision, owner>`

**Plan cycle:** `<plan comment URL>`
**Plan base SHA:** `<full SHA>`
**Reviewer independence:** `I did not author this plan and have no implementation assignment for this cycle.`
**Veredito:** `APROVO | APROVO COM RESSALVAS | PEÇO AJUSTES | NÃO APROVO`

## Findings

- `Critical | Important | Minor | Cannot verify` — `<plan section or source>` — `<impact and required action>`

## Evidence checked

- Accepted ADR/spec or approved no-spec rationale: …
- Immutable source links and base SHA: …
- Task IDs, ownership, dependencies, and assembly order: …
- Acceptance criteria, EARS cases, verification/TDD, and binary DoD: …

---

*Process: code-toolbox — append-only eight-field plan review, independent from plan authorship and not a task/code review.*
