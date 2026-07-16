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

## Plan review execution — cycle `1/3`

Agent: `plan-reviewer`  
Phase/scope: `Phase 3 / independent review / repository delivery record / plan cycle 1 of 3`  
Summary: `PEÇO AJUSTES`. The six-agent topology, independence constraints,
direct-mode boundary, and stage sequence are sound, but the plan cannot yet
guarantee immutable evidence or the full per-execution evidence contract.  
Sources/evidence: accepted spec
`docs/specs/0001-code-toolbox-six-agent-issue-evidence.md` at checkpoint
`1439bdb094603c0a3c6d55019f32d1c62b45915d`; plan snapshot in this delivery
record at the same checkpoint; current source inspection of
`skills/code-toolbox/` templates, phases, references, tests, and agents.  
Decisions: preserve the accepted six-role contract and existing labels/stages;
do not dispatch implementation until the plan adds the required immutable
evidence checkpoint, explicit outcome coverage, and source-set comment
templates.  
Changes/validation: none; review only. Confirmed the cited checkpoint exists
with `git show --no-patch 1439bdb094603c0a3c6d55019f32d1c62b45915d`.  
Blockers: the following findings require a corrected append-only plan cycle
and another fresh independent review before implementation.  
Next action: `plan-writer` publishes plan cycle `2/3` addressing P1-1 through
P1-3 and P2 below; then dispatch a fresh `plan-reviewer`.

### Findings

- **P1-1 — immutable checkpoint before executor evidence is not an executable
  task.** The plan previously described a pending immutable source revision,
  but its dependency order starts `CT-6A-001` immediately after plan approval.
  Add a pre-execution checkpoint that commits the accepted spec, plan, and
  approving review; record their full SHA/immutable URLs in this delivery
  record; and require append-only evidence/commit checkpoints for each task
  and review before the next gate.
- **P1-2 — “successful invocation” conflicts with required blocker evidence.**
  Replace it everywhere in the plan with a rule covering every completed
  outcome, including no-change, `BLOCKED`, `PEÇO AJUSTES`, `NÃO APROVO`, error,
  and absent/invalid verdict. Require the full eight-field envelope before the
  orchestrator advances or blocks state, and add corresponding structural/eval
  checks.
- **P1-3 — source-set issue comments have no explicit template mapping.** The
  plan says to update generic “issue creation/review” templates, while the
  existing `issue-review-comment.md` is task/range review. Name the template
  (new or redefined) for the initial `issue-writer` comment and the
  `issue-reviewer` source-set review; map both to the eight fields in order and
  test that neither moves `stage:spec-approval` to `stage:needs-plan`.
- **P2 — removed-role scan is too narrow.** Make CT-6A-003 scan the complete
  publishable source package, including scripts, dev tooling, metadata, tests,
  and evals—not only Markdown/templates—so no removed role remains exposed or
  executable.

Resume: `Phase 3 / plan cycle 2 of 3 / address P1-1, P1-2, P1-3, and P2`.

## Plan snapshot — cycle `2/3`

### Execution evidence

Agent: `plan-writer`  
Phase/scope: `Phase 3 / repository delivery record / corrective plan cycle 2 of 3`  
Summary: replaced cycle 1 as the proposed implementation plan after the independent `PEÇO AJUSTES` review, adding immutable checkpoint gates, all-outcome evidence, dedicated source-set templates, and a full-package removed-role scan.  
Sources/evidence: accepted specification at [docs/specs/0001-code-toolbox-six-agent-issue-evidence.md](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/specs/0001-code-toolbox-six-agent-issue-evidence.md); cycle-1 plan and its review at [docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md); immutable base SHA `1439bdb094603c0a3c6d55019f32d1c62b45915d`.  
Decisions: execution is forbidden until this cycle has a literal independent `APROVO`/`APROVO COM RESSALVAS` and the approved spec, cycle-2 plan, and approving review are committed as a new immutable checkpoint; every completed agent outcome publishes the eight-field envelope before the orchestrator applies a transition or stop gate; source-set evidence receives dedicated templates.  
Changes/validation: appended this corrective plan only; verified both source documents exist at checkpoint `1439bdb094603c0a3c6d55019f32d1c62b45915d`; implementation validation remains pending.  
Blockers: implementation remains blocked pending a fresh independent review of cycle 2 and the subsequent immutable pre-execution checkpoint.  
Next action: dispatch a fresh `plan-reviewer`; if and only if its literal verdict approves, create and record the pre-execution checkpoint before dispatching an `executor`.

- **Plan revision:** working-tree cycle 2 anchored to immutable base `1439bdb094603c0a3c6d55019f32d1c62b45915d`; its immutable commit URL/SHA is a mandatory precondition recorded by CT-6A-000 after independent approval.
- **Spec impact/update:** no new ADR/spec is required. This plan implements the accepted contract at immutable revision [`1439bdb`](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/specs/0001-code-toolbox-six-agent-issue-evidence.md). A discovered contract conflict stops execution, updates the repository source with human approval, and starts a new plan cycle.
- **Evidence rule:** every completed invocation or conclusion of every agent, in either mode, writes the full envelope in this exact order before the orchestrator transitions, blocks, or otherwise stops the flow: `Agent`, `Phase/scope`, `Summary`, `Sources/evidence`, `Decisions`, `Changes/validation`, `Blockers`, `Next action`. This includes a no-change outcome, `BLOCKED`, `PEÇO AJUSTES`, `NÃO APROVO`, an error, and missing/invalid/absent literal verdict. Issue mode uses a new append-only issue comment; repository direct mode appends a new section to this record. An error or absent verdict does not waive evidence; it records the available command/output/cause and the required human or retry action before the gate is applied.

#### CT-6A-000 — Create and record the immutable pre-execution checkpoint

- **Owner:** central orchestrator after a fresh independent plan-review approval; **depends on:** a literal `APROVO` or `APROVO COM RESSALVAS` for cycle 2; **parallel safety:** mandatory serial gate, with no executor, worktree, or implementation task allowed before it completes.
- **Files/evidence:** commit the accepted specification, this delivery record including the cycle-2 approval, and any generated documentation indexes required by the documentation checker. Append full commit SHA and immutable URLs for the spec, plan, and review to this record before dispatch.
- **Implementation:** validate the recorded base/review and create one checkpoint commit. The orchestrator records the checkpoint URL/SHA in a new append-only envelope/section and exposes it to every executor and delivery-reviewer. It does not alter the source contract, labels, or GitHub state in direct mode.
- **Acceptance criteria:** cycle 2 has an approving literal verdict from a fresh `plan-reviewer`; the checkpoint is reachable by full SHA; spec, plan, and approval all resolve at that revision; no task evidence predates it.
- **Verification:** `git show --no-patch <checkpoint-SHA>`; `git ls-tree -r --name-only <checkpoint-SHA>` for the spec and record; open immutable URLs; append the successful checkpoint evidence before CT-6A-001.
- **Risks/rollback:** committing a stale or unapproved review would make evidence misleading. Stop, append the exact mismatch with `Resume: Phase 3 / plan review`, and create a new checkpoint only after a fresh valid review; never amend or rewrite an evidence checkpoint.

#### CT-6A-001 — Consolidate the exposed agent topology with durable outcome evidence

- **Owner:** `executor`; **depends on:** CT-6A-000; **parallel safety:** serial with CT-6A-002 because they alter the same role names and dispatch contract.
- **Files:** under `skills/code-toolbox/agents/`, add only `issue-writer.md`, `issue-reviewer.md`, `plan-writer.md`, `plan-reviewer.md`, `executor.md`, and `delivery-reviewer.md`; remove `investigator.md`, `spec-author.md`, `plan-author.md`, `general-executor.md`, `deep-executor.md`, `code-reviewer.md`, and `spec-compliance-auditor.md`.
- **Implementation:** assign investigation, conditional ADR/spec preparation, user-decision consolidation, issue creation, and initial issue evidence to `issue-writer`; assign independent source-set review without human self-approval to `issue-reviewer`; assign one adaptive task implementer to `executor`; assign task/range review and a separate fresh final-audit instance to `delivery-reviewer`. Each prompt explicitly emits the evidence envelope for all completed outcomes, not only success, and posts/appends it before a state decision.
- **Acceptance criteria:** exactly six exposed prompts remain; planner/reviewer and final-audit independence is explicit; issue-writer comments only after issue creation; no-change, blocking, requested-change, rejection, error, and invalid-verdict outcomes all have mandatory evidence and next action.
- **Task checkpoint/evidence:** after implementation, the executor appends its eight-field task envelope containing the CT-6A-000 base, changed files, commands/results, and new full commit SHA. Commit CT-6A-001 before requesting an independent delivery review; append that review envelope and its immutable commit/range before CT-6A-002 can start.
- **Verification:** enumerate source agent filenames; inspect every prompt for all eight fields, direct-mode behavior, and independence rules; verify immutable executor and delivery-review evidence entries point to the checkpoint and task commit.
- **Risks/rollback:** a consolidation could erase a required independence rule or leave a legacy role reachable. Restore only the affected task commit, append its rejection/blocker evidence, then correct with a new task attempt and review; never continue on an unreviewed range.

#### CT-6A-002 — Rewrite routes, phases, references, and dedicated evidence templates

- **Owner:** `executor`; **depends on:** reviewed CT-6A-001 evidence; **parallel safety:** serial with all other tasks due to shared router/templates.
- **Files:** `skills/code-toolbox/SKILL.md`, `README.md`, `phases/00-issue-context.md`, `phases/01-brainstorm.md`, `phases/02-spec.md`, `phases/03-plan.md`, `phases/04-dispatch.md`, `phases/05-review.md`, `phases/06-integrate.md`, `phases/08-reference.md`, `references/github-flow.md`, `references/evidence-contract.md`, all live templates, plus new `templates/issue-source-set-comment.md` and `templates/issue-source-set-review-comment.md`.
- **Implementation:** route Phase 1 and the conditional spec decision to `issue-writer`; require independent `issue-reviewer` evidence while the issue remains `stage:spec-approval`; route planning to `plan-writer`, execution to `executor`, and range/final audits to fresh `delivery-reviewer` instances. Preserve all existing stages and `needs-human` semantics. Create the two named source-set templates for, respectively, the issue-writer initial comment and issue-reviewer source-set review; both contain the eight fields in the required order. Keep `issue-review-comment.md` exclusively for `delivery-reviewer` task/range review and do not repurpose it for source-set evidence. Update every live issue/repository template so each completed outcome records the envelope before the orchestrator transition/stop.
- **Acceptance criteria:** neither source-set template can move `stage:spec-approval` to `stage:needs-plan`; only recorded human source-set approval can do that; direct mode creates no issue, label, or GitHub comment; all six roles map to exactly one durable evidence path; no newly invented label/stage exists.
- **Task checkpoint/evidence:** append executor evidence with base checkpoint, changed files, validation, and full task commit SHA; commit CT-6A-002; append an independent delivery-reviewer task/range verdict linked to that commit before CT-6A-003 begins. A `PEÇO AJUSTES`, `NÃO APROVO`, error, or missing verdict first appends its envelope and then stops/returns according to the existing gate.
- **Verification:** trace each phase to an allowed role; inspect source-set templates for the ordered eight fields; assert task/range template separation; validate stage transition wording and direct negative rules; verify review evidence links both checkpoint and task commit.
- **Risks/rollback:** route/template edits can contradict gates or accidentally reuse task review for source-set review. Stop and append the exact conflict with `Resume: Phase 4 / CT-6A-002`; revert only the task commit, correct the source-set mapping, recommit, and obtain a fresh review.

#### CT-6A-003 — Validate the complete publishable source package and regenerate output

- **Owner:** `executor`; **depends on:** reviewed CT-6A-002 evidence; **parallel safety:** final serial task because it asserts the finished source layout and regenerates `dist/`.
- **Files:** `skills/code-toolbox/README.md`, `skills/code-toolbox/dev/tests.sh`, `skills/code-toolbox/dev/README.md` when needed, `skills/code-toolbox/evals/evals.json`, every publishable source file under `skills/code-toolbox/` including `SKILL.md`, all `agents/`, `phases/`, `references/`, `templates/`, `scripts/`, `scripts/visual-companion/`, `dev/`, `evals/`, and `package.json`; generated `dist/skills/code-toolbox/**` only through `pnpm build`; generated documentation index only through `python3 scripts/docs-check --emit-index` if required.
- **Implementation:** update README, structural tests, evals, package metadata, developer tooling, and every source consumer for exactly six roles. Add tests/evals for all eight specification edge cases and every evidence outcome listed above. Scan the entire publishable source package—including scripts, developer tooling, package metadata, tests, and evals—for removed role names. The scan may retain names only inside an explicit negative-regression assertion; no role may be exposed as a prompt, dispatch target, executable route, metadata value, or positive workflow behavior. Regenerate `dist/` through the build, never manually.
- **Acceptance criteria:** structural tests prove exactly six prompt files; dedicated source-set templates exist and are distinct from task/range review; evaluations cover pending decisions, required/no-spec, human gate, no-change evidence, direct mode, fresh audit, and blocker/invalid verdict; complete-package scan yields no exposed/executable removed role; generated package matches source policy.
- **Task checkpoint/evidence:** append executor evidence with CT-6A-000 base and full CT-6A-003 commit SHA, then commit the final validation/build output. A fresh `delivery-reviewer` reviews this final range and appends an immutable verdict. Only after all three task checkpoints and reviews can a distinct fresh `delivery-reviewer` append the final DoD audit.
- **Verification:** run `git diff --check`; full-package role scan with reviewed negative-test allowlist; `bash skills/code-toolbox/dev/tests.sh`; `pnpm test`; `pnpm build`; rerun focused tests after build; `python3 scripts/docs-check`; `python3 scripts/docs-check --emit-index` only when drift requires it; inspect `git status --short`, `git diff --name-status`, and source/dist role inventories.
- **Risks/rollback:** source, generated output, and tests may drift or broad tests may fail for unrelated causes. Append the actual output and `Resume` instruction before a gate decision, distinguish unrelated failures, regenerate output from corrected source, and review the corrective commit as a new task attempt.

### Dependency and evidence order

`fresh cycle-2 approval → CT-6A-000 immutable checkpoint → CT-6A-001 executor evidence + independent review checkpoint → CT-6A-002 executor evidence + independent review checkpoint → CT-6A-003 executor evidence + independent review checkpoint → fresh final delivery-reviewer audit`. The tasks are intentionally serial. Any rejection, error, absent verdict, file overlap, or blocker appends its envelope first and stops at its recorded `Resume` point; it cannot advance a later task or audit.

### Definition of Done

- [ ] A fresh independent reviewer literally approves cycle 2 and CT-6A-000 records an immutable checkpoint containing the accepted spec, plan, and approval before an executor starts.
- [ ] Source and generated package expose only the six allowed prompts; all removed-role references are absent except deliberate negative assertions in the complete-package scan.
- [ ] Dedicated issue-writer and issue-reviewer source-set templates each contain the ordered eight-field envelope and cannot replace human source-set approval.
- [ ] Every completed agent outcome, including no-change, `BLOCKED`, `PEÇO AJUSTES`, `NÃO APROVO`, error, and invalid/absent verdict, records the envelope before the orchestrator transitions or blocks.
- [ ] Each task has an immutable executor commit/evidence checkpoint and independent review checkpoint before the next task; a fresh final delivery-reviewer audit records DoD, validation, and optional integration status.
- [ ] `stage:spec-approval` remains human-gated, direct remains GitHub-free, and integration remains optional after PR approval.

## Independent plan review — cycle `2/3`

- **Review revision:** pending fresh `plan-reviewer` execution against cycle 2.
- **Reviewer independence:** reviewer must not be the cycle-2 `plan-writer`, an executor, or a delivery reviewer for this delivery.
- **Verdict:** pending literal verdict.
- **Resume:** `Phase 3 / await independent plan review for cycle 2`.

## Plan review execution — cycle `2/3`

Agent: `plan-reviewer`  
Phase/scope: `Phase 3 / independent review / repository delivery record / plan cycle 2 of 3`  
Summary: `PEÇO AJUSTES`. O ciclo 2 resolveu a intenção dos quatro achados do
ciclo 1 — checkpoint base `1439bdb`, evidência para todos os resultados,
templates explícitos de source set, varredura integral e independência —, mas
ainda não torna imutáveis, em uma ordem executável, as evidências de cada
tarefa e revisão; também contradiz a DoD aceita ao permitir nomes removidos em
testes negativos.  
Sources/evidence: spec aceita em
`docs/specs/0001-code-toolbox-six-agent-issue-evidence.md` no checkpoint
`1439bdb094603c0a3c6d55019f32d1c62b45915d`; ciclo 2 em
`docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md`; inspeção de
`git show --no-patch 1439bdb094603c0a3c6d55019f32d1c62b45915d`, do conteúdo
integral de CT-6A-000 a CT-6A-003 e do inventário atual de `skills/code-toolbox/`.  
Decisions: manter o contrato de seis papéis, os dois templates novos, o gate
humano de `stage:spec-approval` e a execução serial; exigir commits separados
para cada envelope de executor e reviewer, e eliminar a exceção para nomes de
papéis removidos em testes.  
Changes/validation: nenhuma mudança de implementação; revisão independente
somente. Confirmei que a spec e o delivery record existem no checkpoint
`1439bdb094603c0a3c6d55019f32d1c62b45915d`.  
Blockers: P1-1 e P1-2 abaixo impedem iniciar CT-6A-000/execução até um ciclo 3
append-only ser revisado por um novo `plan-reviewer`.  
Next action: `plan-writer` publica ciclo `3/3` com a sequência imutável
explícita e sem allowlist de nomes removidos; então um novo `plan-reviewer`
emite veredito literal.

### Findings

- **P1-1 — checkpoints de evidência não têm ordem commitável.** CT-6A-001,
  CT-6A-002 e CT-6A-003 mandam anexar a evidência contendo o SHA do novo
  commit, mas não definem o commit posterior que torna esse envelope, e depois
  o envelope do `delivery-reviewer`, imutáveis antes da próxima tarefa. Isso
  falha a DoD de checkpoint de executor e review por tarefa. Para cada tarefa,
  o plano deve exigir: `commit de código → anexar envelope do executor → commit
  da evidência → revisão independente sobre essas revisões imutáveis → anexar
  envelope do reviewer → commit da revisão → próxima tarefa`. Aplicar a mesma
  regra ao checkpoint pré-execução e à auditoria final.
- **P1-2 — allowlist de papéis removidos conflita com a spec aceita.**
  CT-6A-003 e sua DoD permitem nomes removidos em asserções negativas, mas a
  spec aceita exige que nenhuma rota, referência, template ou teste nomeie os
  papéis removidos. Remover essa exceção. Testes devem afirmar somente o
  conjunto permitido de seis prompts e a ausência de arquivos/rotas legadas,
  sem citar os nomes dos papéis removidos.

Resume: `Phase 3 / plan cycle 3 of 3 / address P1-1 and P1-2`.

## Plan snapshot — cycle `3/3`

### Execution evidence

Agent: `plan-writer`  
Phase/scope: `Phase 3 / repository delivery record / corrective plan cycle 3 of 3`  
Summary: replaced cycle 2 after independent `PEÇO AJUSTES`, defining a commitable immutable-evidence sequence for the plan, initial checkpoint, every task/review, and final audit; removed the proposed exception for legacy-role names in tests.  
Sources/evidence: accepted specification at [docs/specs/0001-code-toolbox-six-agent-issue-evidence.md](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/specs/0001-code-toolbox-six-agent-issue-evidence.md); prior cycles and reviews at [docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/delivery/0001-code-toolbox-six-agent-issue-evidence.md); immutable base SHA `1439bdb094603c0a3c6d55019f32d1c62b45915d`.  
Decisions: execution remains forbidden until a fresh reviewer approves this cycle and the immutable initial-checkpoint sequence completes; every executor/reviewer/auditor envelope is committed before a subsequent gate; tests assert the allowed six-role surface positively and structural absence of extra prompts/routes without mentioning removed roles.  
Changes/validation: appended this cycle only; no skill implementation or commit was made by this planning step.  
Blockers: implementation is blocked pending a fresh literal approving verdict for cycle 3 and its committed initial checkpoint.  
Next action: commit this plan snapshot, dispatch a fresh `plan-reviewer` against that immutable revision, then follow CT-6A-000 only if its literal verdict approves.

- **Plan revision:** working-tree cycle 3 based on `1439bdb094603c0a3c6d55019f32d1c62b45915d`. Before review, commit this plan snapshot and append its full SHA/immutable URL; the reviewer must read that committed revision, not an uncommitted worktree.
- **Spec impact/update:** no new ADR/spec is needed. The accepted source remains the immutable revision [`1439bdb`](https://github.com/gugacarbo/agents-skills/blob/1439bdb094603c0a3c6d55019f32d1c62b45915d/docs/specs/0001-code-toolbox-six-agent-issue-evidence.md). A source conflict stops the chain, records the envelope, obtains human approval, and begins a new plan cycle.
- **Universal envelope rule:** every completed invocation or conclusion writes the ordered envelope (`Agent`, `Phase/scope`, `Summary`, `Sources/evidence`, `Decisions`, `Changes/validation`, `Blockers`, `Next action`) before the orchestrator transitions, blocks, or stops. That includes no-change, `BLOCKED`, `PEÇO AJUSTES`, `NÃO APROVO`, error, and absent/invalid verdict. In direct mode, each appended envelope is immediately committed before another agent may consume it. In issue mode, the append-only comment URL is immutable evidence; when code changes, its task/range commit SHA is also required before the next gate.

### Immutable evidence protocol

Each item below is a serial, commitable gate. A later item must receive full
SHAs/immutable URLs for all earlier items; it must not read only the working
tree. A rejection, error, no-change, blocker, or absent verdict still follows
the same envelope-and-commit step, then stops at its recorded `Resume` action.

1. **Plan/review bootstrap:** append cycle 3, commit the plan snapshot, and record its full SHA. A fresh `plan-reviewer` reads that committed plan, appends its literal-verdict envelope, and commits the review evidence. Only a committed `APROVO` or `APROVO COM RESSALVAS` can begin CT-6A-000.
2. **Initial checkpoint:** the orchestrator reads the immutable spec, plan, and approving-review commits; appends the CT-6A-000 checkpoint envelope with their full SHAs/URLs; then commits that envelope. Only this committed checkpoint can be the base of CT-6A-001.
3. **Each implementation task:** commit the task's code/documentation and validations; append the executor envelope referencing that code commit and the initial checkpoint; commit the executor evidence; a fresh `delivery-reviewer` reads the immutable code and executor-evidence commits; appends its verdict envelope; commits the review evidence. Only that review-evidence commit may unlock the next task.
4. **Final audit:** a fresh `delivery-reviewer`, distinct from all task/range reviewers, reads every immutable task code/evidence/review commit; appends its final audit/DoD envelope and closure matrix; commits the audit evidence. Only this committed audit can support optional, explicitly user-confirmed integration/merge.

#### CT-6A-000 — Commit and verify the initial immutable checkpoint

- **Owner:** central orchestrator; **depends on:** the committed plan snapshot and a fresh committed approving plan-review envelope; **parallel safety:** mandatory serial gate; no executor, worktree, or implementation starts earlier.
- **Commitable order:** (a) commit cycle-3 plan snapshot; (b) fresh reviewer reads that SHA, appends verdict, and commits review evidence; (c) orchestrator reads the immutable spec/plan/review revisions, appends the checkpoint envelope with their full SHAs/URLs, and commits that envelope; (d) record the resulting checkpoint SHA as the only allowed task base.
- **Files/evidence:** accepted spec, this record, and generated documentation indexes when required. The checkpoint envelope identifies the exact spec, plan, review, and checkpoint commits.
- **Acceptance/verification:** `git show --no-patch` and `git ls-tree -r --name-only` resolve every cited revision; the source documents are present at their cited SHAs; no task evidence predates the committed checkpoint.
- **Rollback:** if a cited revision is missing, stale, unapproved, or uncommitted, append the failure envelope, commit it, and stop at `Resume: Phase 3 / plan review`; never amend/rewrite a prior evidence commit.

#### CT-6A-001 — Consolidate the six allowed agent prompts

- **Owner:** `executor`; **depends on:** committed CT-6A-000 checkpoint; **parallel safety:** serial with CT-6A-002 because they share prompt names and dispatch contract.
- **Files/implementation:** retain exactly the six accepted prompt files and their responsibility mapping; remove all superseded prompt files. Consolidate issue preparation/source-set work, planning, implementation, and task/final delivery review according to the accepted spec. Every prompt mandates the universal envelope before any gate decision, including failure/no-change outcomes.
- **Commitable task order:** commit the prompt/documentation changes and focused validation; append executor envelope citing that code commit plus CT-6A-000; commit the executor evidence; dispatch fresh `delivery-reviewer` on those immutable revisions; append its verdict envelope; commit the review evidence. CT-6A-002 cannot start until this review-evidence commit has a literal acceptable verdict.
- **Acceptance/verification:** exactly the six accepted prompt filenames exist; every prompt has the ordered envelope, direct-mode behavior, and required independence; `git show` resolves code, executor-evidence, and reviewer-evidence commits in order.
- **Rollback:** append/commit the outcome evidence first, then stop at `Resume: Phase 4 / CT-6A-001`; correct in a new code commit and repeat the full task sequence with a fresh review.

#### CT-6A-002 — Rewrite routing, evidence contract, and source-set templates

- **Owner:** `executor`; **depends on:** committed acceptable CT-6A-001 review evidence; **parallel safety:** serial with the other tasks.
- **Files/implementation:** update router, README, phases, references, and live templates; add `templates/issue-source-set-comment.md` and `templates/issue-source-set-review-comment.md`. The two source-set templates contain the eight fields in the required order and are distinct from task/range review. Preserve the existing labels/stages, human source-set approval, direct-mode GitHub prohibition, and optional post-PR integration.
- **Commitable task order:** commit route/template/reference changes and validation; append executor envelope citing that code commit and CT-6A-000; commit executor evidence; fresh `delivery-reviewer` reads code plus evidence commits, appends verdict envelope, and commits the review. CT-6A-003 begins only after this committed review evidence approves.
- **Acceptance/verification:** neither source-set template can move `stage:spec-approval`; only human source-set approval transitions it; every route maps only to one of the six accepted agents; direct mode writes no GitHub state; immutable evidence chain resolves in its required order.
- **Rollback:** append and commit the exact issue/review result, stop at `Resume: Phase 4 / CT-6A-002`, correct in a new commit, then obtain a fresh immutable review.

#### CT-6A-003 — Validate the allowed surface and regenerate generated output

- **Owner:** `executor`; **depends on:** committed acceptable CT-6A-002 review evidence; **parallel safety:** final serial task because it validates the final layout and builds `dist/`.
- **Files/implementation:** update package documentation, developer tests, evals, package metadata, scripts, and all publishable source under `skills/code-toolbox/`; regenerate `dist/` only through `pnpm build`; regenerate documentation indexes only with `python3 scripts/docs-check --emit-index` when required.
- **Legacy-surface test strategy:** assert the exact allowed set of six prompt filenames and six route identifiers; assert no additional file under `agents/` and no route target outside that positive set; assert legacy route/file structures are absent by structural directory/inventory checks. Tests and evals must not contain or compare against removed-role names. The complete-package scan covers `SKILL.md`, `agents/`, `phases/`, `references/`, `templates/`, `scripts/`, `scripts/visual-companion/`, `dev/`, `evals/`, and `package.json` and validates only that the allowed surface is present with no extras.
- **Commitable task order:** commit test/eval/source changes and regenerated output; append executor envelope with code commit, command output, and CT-6A-000; commit executor evidence; fresh `delivery-reviewer` reads immutable artifacts, appends verdict envelope, and commits the review evidence. A final, distinct fresh `delivery-reviewer` then performs CT-6A-FINAL under the same append-then-commit protocol.
- **Verification:** `git diff --check`; structural allowed-surface inventory; `bash skills/code-toolbox/dev/tests.sh`; `pnpm test`; `pnpm build`; focused tests after build; `python3 scripts/docs-check`; docs index emission only if needed; `git status --short`; `git diff --name-status`; `git show` for each code/evidence/review commit in the chain.
- **Rollback:** append and commit the actual failed validation envelope, stop at its `Resume`, correct in a new commit, then repeat executor and independent-review evidence commits.

#### CT-6A-FINAL — Commit the final delivery audit and closure

- **Owner:** a fresh `delivery-reviewer` instance that did not review a task/range and did not author implementation; **depends on:** all three committed acceptable task-review evidence revisions; **parallel safety:** final serial gate.
- **Commitable order:** read immutable code, executor-evidence, and reviewer-evidence commits for every task; append the final audit envelope and closure matrix with all full SHAs/validation results; commit that audit/DoD evidence; only then offer optional integration/merge to the user.
- **Acceptance/verification:** matrix has every task and every immutable link; DoD commands/results are present; the audit instance declares freshness; no integration occurs without explicit user confirmation.
- **Rollback:** append/commit audit failure evidence with `Resume: Phase 6 / final audit`; stop and repair through a new task commit/review chain.

### Definition of Done

- [ ] Cycle-3 plan, fresh approving plan review, and CT-6A-000 checkpoint each exist as distinct committed immutable evidence before any executor starts.
- [ ] For CT-6A-001, CT-6A-002, and CT-6A-003, the order is code/documentation commit → executor envelope → evidence commit → fresh reviewer reads immutable artifacts → reviewer envelope → review-evidence commit → next task.
- [ ] The final fresh delivery audit follows the same append-envelope then commit pattern and links every task code/evidence/review SHA before optional user-confirmed integration.
- [ ] Source and generated package expose only the six accepted prompts/routes; tests/evals validate the positive allowed surface and absence of extra/legacy structures without naming removed roles.
- [ ] Dedicated issue-writer and issue-reviewer source-set templates contain the ordered eight-field envelope and cannot replace human approval at `stage:spec-approval`.
- [ ] Every completed outcome, including no-change, `BLOCKED`, `PEÇO AJUSTES`, `NÃO APROVO`, error, and invalid/absent verdict, commits its envelope before the orchestrator applies a transition, block, or stop.
- [ ] Direct remains GitHub-free; existing labels/stages remain unchanged; integration remains optional after PR approval.

## Independent plan review — cycle `3/3`

- **Review revision:** pending a fresh `plan-reviewer` reading the committed cycle-3 plan snapshot.
- **Reviewer independence:** reviewer must not be the cycle-3 `plan-writer`, an executor, or a delivery reviewer for this delivery.
- **Verdict:** pending literal verdict.
- **Resume:** `Phase 3 / commit cycle 3, then await independent plan review`.

## Direct execution override and working-tree evidence

Agent: orchestrator / user decision  
Phase/scope: `Phase 4–6 / direct execution override`  
Summary: the user explicitly authorized direct execution without the additional checkpoint commits required by cycle 3.  
Sources/evidence: user instruction in the active thread; implementation and validation remain in the current working tree.  
Decisions: honor the direct repository-mode override; do not create GitHub issues, labels, stages, or comments.  
Changes/validation: retain the accepted spec, cycle-3 plan, and all source changes as working-tree evidence.  
Blockers: immutable task/review SHAs are intentionally unavailable under this override.  
Next action: user may create a save commit if immutable delivery evidence is required.

Agent: executor  
Phase/scope: `CT-6A-001..003 / direct implementation`  
Summary: consolidated the exposed topology to exactly six agents and updated routing, phases, evidence templates, tests, evals, and documentation.  
Sources/evidence: current source tree under `skills/code-toolbox/`; accepted spec `docs/specs/0001-code-toolbox-six-agent-issue-evidence.md`.  
Decisions: use `issue-writer`, `issue-reviewer`, `plan-writer`, `plan-reviewer`, `executor`, and `delivery-reviewer`; preserve the existing stage sequence and direct-mode boundary.  
Changes/validation: added source-set templates, enforced the eight-field envelope, updated the positive allowlist and evals; `bash skills/code-toolbox/dev/tests.sh`, `pnpm test`, `pnpm build`, `python3 scripts/docs-check`, and `git diff --check` pass.  
Blockers: no implementation blocker; immutable commit chain waived by the user override above.  
Next action: record independent delivery review and final audit; offer optional integration only after PR approval.

Agent: delivery-reviewer  
Phase/scope: `CT-6A-001..003 / independent code and evidence review`  
Summary: `APROVO`; no P0–P3 findings.  
Sources/evidence: source tree, generated package, all seven issue templates plus delivery record, focused tests, `pnpm test`, `pnpm build`, and `docs-check`.  
Decisions: six-agent allowlist, human source-set gate, direct GitHub prohibition, and fresh final reviewer are coherent.  
Changes/validation: review completed without edits.  
Blockers: none for functional behavior; immutable commit evidence remains waived by the user override.  
Next action: final fresh audit.

Agent: delivery-reviewer  
Phase/scope: `CT-6A-FINAL / fresh final audit`  
Summary: functional `APROVO`; closure traceability remains intentionally waived.  
Sources/evidence: accepted spec, source/dist inventories, six prompts, ordered envelopes, focused/global validation, and current delivery record.  
Decisions: treat the working tree as the direct-mode delivery surface because the user explicitly requested execution without another checkpoint commit.  
Changes/validation: source/dist contain the same six-agent topology; all required validations pass.  
Blockers: no immutable CT-6A-000/task/review SHAs and the earlier cycle-3 review remains a pending plan-review artifact.  
Next action: user can create a save commit and request immutable closure if desired.

## Direct-mode closure status

- Functional implementation: `complete`.
- Tests/build/docs validation: `complete`.
- GitHub issue/label state: `not applicable` (direct mode).
- Immutable commit-chain DoD: `waived by explicit user instruction`; not represented as completed evidence.
