---
process: code-toolbox
base-sha: 71ad9a3a7c3e18e0bd05e66ede25f1fc2eb40eb9
sources:
  - docs/specs/0001-code-toolbox-six-agent-issue-evidence.md (approved working-tree snapshot; immutable commit URL pending)
---

# Delivery — code-toolbox: seis agentes e evidência por comentário

This is one versioned delivery record, not a generated registry. Keep every
snapshot below append-only and commit each material update. Link every source,
review, evidence, and DoD result to a full SHA or immutable repository URL.

## Source-set approval

- **Accepted ADR/spec or approved no-spec rationale:** `docs/specs/0001-code-toolbox-six-agent-issue-evidence.md`; accepted specification for the six-agent topology and mandatory execution evidence.
- **Human approval evidence:** user approved the specification and explicitly authorized direct implementation in repository mode on 2026-07-15.
- **Source revision:** approved working-tree snapshot anchored to base `71ad9a3a7c3e18e0bd05e66ede25f1fc2eb40eb9`; append the immutable commit URL/SHA when the specification is first committed. It cannot truthfully link to an immutable revision yet because the specification is untracked at this base.

## Plan snapshot — cycle `1/3`

### Execution evidence

Agent: `plan-writer`  
Phase/scope: `Phase 3 / repository delivery record / plan cycle 1 of 3`  
Summary: planned the direct repository-mode implementation of the accepted six-agent topology and mandatory append-only evidence contract.  
Sources/evidence: approved spec at `docs/specs/0001-code-toolbox-six-agent-issue-evidence.md`; base SHA `71ad9a3a7c3e18e0bd05e66ede25f1fc2eb40eb9`; active source files under `skills/code-toolbox/`. Immutable source URL is pending because the approved spec has not yet been committed.  
Decisions: use `docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md` as the single versioned repository-mode evidence surface; preserve the existing labels/stages and direct-mode boundary; do not implement or commit in this plan step.  
Changes/validation: created this append-only delivery record and authored the plan only; implementation validation is listed below and remains pending.  
Blockers: none.  
Next action: dispatch a fresh `plan-reviewer` to review this cycle against the accepted spec before implementation.

- **Plan revision:** working-tree snapshot based on `71ad9a3a7c3e18e0bd05e66ede25f1fc2eb40eb9`; append the commit SHA/immutable URL that contains this snapshot before recording implementation evidence.
- **Spec impact/update:** no new ADR/spec is required. This delivery implements the already accepted behavior contract in `docs/specs/0001-code-toolbox-six-agent-issue-evidence.md`; do not change that spec unless implementation discovers a contract conflict. Any material spec update requires human approval and a new plan cycle.
- **Global acceptance:** source and generated package expose exactly `issue-writer`, `issue-reviewer`, `plan-writer`, `plan-reviewer`, `executor`, and `delivery-reviewer`; every successful agent invocation appends the eight evidence fields to an issue comment or this record; direct mode remains repository-only and never writes GitHub state.

#### CT-6A-001 — Consolidate the exposed agent topology

- **Owner:** `executor`; **depends on:** source-set approval and this approved plan; **parallel safety:** sequential with CT-6A-002 because both change agent names referenced by router, phases, tests, and templates.
- **Files:** `skills/code-toolbox/agents/` — add `issue-writer.md`, `issue-reviewer.md`, `plan-writer.md`, `plan-reviewer.md`, `executor.md`, and `delivery-reviewer.md`; remove `investigator.md`, `spec-author.md`, `plan-author.md`, `general-executor.md`, `deep-executor.md`, `code-reviewer.md`, and `spec-compliance-auditor.md`. Retain only files still deliberately referenced by the final package.
- **Implementation:** move investigation, conditional ADR/spec preparation, user-decision consolidation, issue creation, and initial evidence into `issue-writer`; make `issue-reviewer` independently inspect the issue/source set without granting human approval; make `executor` choose bounded or cross-cutting depth by task context; make `delivery-reviewer` review task/range and perform a fresh, distinct final audit. Require every new prompt to publish or append all eight contract fields, including no-change, blocker, and review outcomes.
- **Acceptance criteria:** exactly six exposed agent prompts exist; no prompt/reference names a removed role; planner/reviewer and final-audit freshness restrictions remain explicit; issue-writer waits for product decisions and only comments after the issue exists; direct mode appends equivalent evidence instead of GitHub mutations.
- **Verification:** `rg` inventory of `agents/` and role names; inspect each prompt for the eight fields and mode boundary; run focused skill tests after CT-6A-003; record files changed, commands, commit/range, and result as executor evidence.
- **Risks/rollback:** role consolidation could lose an independence rule or leave a deleted prompt referenced. Roll back the affected prompt set as one coherent patch, restore only the required prior file from Git history, then reapply the six-role mapping with reference/test updates; do not reintroduce a role merely to silence a stale reference.

#### CT-6A-002 — Rewrite workflow contract, evidence surfaces, and phase dispatch

- **Owner:** `executor`; **depends on:** CT-6A-001 role contract; **parallel safety:** sequential with CT-6A-001 and CT-6A-003 because the same strings and behavioral assertions span these files.
- **Files:** `skills/code-toolbox/SKILL.md`, `README.md`, `phases/00-issue-context.md`, `phases/01-brainstorm.md`, `phases/02-spec.md`, `phases/03-plan.md`, `phases/04-dispatch.md`, `phases/05-review.md`, `phases/06-integrate.md`, `phases/08-reference.md`, `references/github-flow.md`, `references/evidence-contract.md`, and all live files under `templates/` (especially issue creation/review, plan, task-evidence, integration, and repository-delivery templates).
- **Implementation:** assign Phase 1 and the conditional spec gate to `issue-writer`; require the independent `issue-reviewer` to comment while the issue remains `stage:spec-approval`; rename planner dispatch to `plan-writer`; dispatch the single `executor`; replace code-review and final-audit dispatch with `delivery-reviewer`, requiring a fresh second instance for the final audit. Preserve the existing stage sequence and `needs-human` behavior exactly. Define one reusable eight-field evidence envelope (`Agent`, `Phase/scope`, `Summary`, `Sources/evidence`, `Decisions`, `Changes/validation`, `Blockers`, `Next action`) and make every live issue template and every repository-record section require it. Make direct-mode wording unambiguous: it creates no issue, label, or GitHub comment and writes only this versioned record.
- **Acceptance criteria:** the router exposes only the six roles and assigns all former responsibilities; no label/stage is added; issue-reviewer approval cannot advance the human source-set gate; every successful role invocation, including no-op investigation/review and blocked result, has append-only evidence; final PR approval still offers user-confirmed optional integration only.
- **Verification:** trace every router phase to one allowed role; search all live source Markdown/templates for removed role names and legacy evidence exemptions; manually check the stage transition table, direct-mode negative rules, and template field ordering against the spec; use test/eval coverage from CT-6A-003.
- **Risks/rollback:** broad textual edits can produce contradictory mode or stage guidance. Roll back only the conflicting documentation/template hunk, compare it to the accepted spec and `github-flow.md`, then publish a new delivery-record plan/review cycle if the behavior contract changes materially.

#### CT-6A-003 — Align documentation, tests, evals, generated package, and validation

- **Owner:** `executor`; **depends on:** CT-6A-001 and CT-6A-002; **parallel safety:** must run last because it asserts the final source layout and regenerates `dist/`.
- **Files:** `skills/code-toolbox/README.md`, `skills/code-toolbox/dev/tests.sh`, `skills/code-toolbox/dev/README.md` if its instructions name old roles, `skills/code-toolbox/evals/evals.json`, `docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md`, and generated `dist/skills/code-toolbox/**` through `pnpm build` only. Regenerate `docs/index.json` and `docs/specs/README.md` only via `python3 scripts/docs-check --emit-index` if the documentation checker requires a generated update; do not hand-edit generated indexes.
- **Implementation:** replace role inventories and expected prompt files with the six-role contract; add structural/eval coverage for the eight spec edge cases: pending product decision, required spec, no-spec rationale, issue-reviewer not self-approving, evidence with no code changes, direct with no GitHub mutations, fresh delivery-reviewer for final audit, and blocker/invalid review stopping progression. Add negative checks that no removed agent role is exposed or referenced. Build to regenerate `dist/`, then compare generated content to source under the repo's existing build policy.
- **Acceptance criteria:** source tests prove exactly six prompts and their mapped responsibilities; evals exercise each spec case and direct-mode boundary; docs remain valid; `dist/` is a build artifact rather than a manually maintained source; all validations pass without relying on deleted files.
- **Verification:** run `git diff --check`; `bash skills/code-toolbox/dev/tests.sh`; `pnpm test`; `pnpm build`; rerun `bash skills/code-toolbox/dev/tests.sh` after build; `python3 scripts/docs-check`; and `python3 scripts/docs-check --emit-index` if index drift is reported. Inspect `git status --short` and `git diff --name-status` to confirm only intended source, docs, and regenerated `dist/` changes.
- **Risks/rollback:** generated `dist/` or docs indexes may drift from source, or broader tests may reveal unrelated repository failures. Preserve the focused-test result, separate unrelated failures from this delivery, regenerate rather than hand-patch output, and revert only the generated artifacts caused by an invalid source change before correcting source.

### Dependency and execution order

`CT-6A-001 → CT-6A-002 → CT-6A-003`. All tasks are deliberately sequential: role-file removal, route/template rewrites, and structural tests overlap in filenames and semantic contract. No parallel worktree is justified for this small, tightly coupled skill migration.

### Definition of Done

- [ ] The implementation satisfies every unchecked item in the accepted spec's Definition of Done without modifying the accepted contract silently.
- [ ] The source contains exactly the six allowed agent prompts and all live routing/references/templates use them.
- [ ] Every agent invocation has durable append-only eight-field evidence in issue mode or this record in direct mode.
- [ ] `stage:spec-approval` remains human-gated, direct remains GitHub-free, and final integration remains optional after PR approval.
- [ ] Task evidence, independent delivery review, final fresh audit, validation commands, and immutable commit/PR links are appended below before closure.

## Independent plan review

- **Review revision:** pending fresh `plan-reviewer` execution.
- **Reviewer independence:** pending; reviewer must not be this `plan-writer` instance or an eventual executor.
- **Verdict:** pending literal verdict.
- **Resume:** `Phase 3 / await independent plan review`.

## Task evidence and code reviews

| Task | Status | Commit/range | Evidence revision | Independent review revision |
| --- | --- | --- | --- | --- |
| CT-6A-001 | `PENDING` | — | — | — |
| CT-6A-002 | `PENDING` | — | — | — |
| CT-6A-003 | `PENDING` | — | — | — |

For every `BLOCKED`, rejected review, audit failure, or unresolved DoD item,
append the exact blocker and `Resume: <phase/task>` here. This record is the
only coordination surface in repository mode: never add GitHub labels/stages
or post GitHub comments.

## DoD and final audit

- **Audit revision and independence:** pending implementation, independent task/range review, and a fresh final `delivery-reviewer` instance.
- **DoD command/result:** pending.
- **Optional PR merge decision:** `not applicable until a PR exists; after approval, awaiting explicit user request`.
