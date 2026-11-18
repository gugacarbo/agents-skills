# Dispatch envelope

Send one selected role prompt plus this self-contained envelope. Reference large
code/rules by accessible paths; include only facts relevant to the assigned question.

```text
TARGET / BASE / HEAD / UNCOMMITTED SCOPE:
WORKSPACE: <absolute path>
ROLE / MODE: <General BRIEF|STANDARD, Design, Risk, or Adversarial FINAL_PASS>
PROFILE / REQUESTED MODEL / EFFORT:
QUESTION / SCOPE: <invariant, reason, paths; inspect surrounding code as needed>
CONTEXT: <requirements or none explicit, entry points/contracts, rule/reference paths>
VALIDATION DONE: <actual commands/results and limitations>
ROLE PROMPT: <selected prompt>

BOUNDARIES:
- Read-only: no file or Git mutations. Use only exposed, authorized tools; no
  controller-only planning/lifecycle tools (e.g. update_plan, wrap_up).
  Return progress and final results as ordinary messages.
- Set the assigned working directory per command using supported tool controls;
  verify effective directory/repository. Directory changes do not persist.
- One simple Git command per invocation; no chains, wrappers or git -C overrides.
- Do not bypass denials, evade guards or seek broader privileges; report blockers.
- Do not repeat expensive validation without a concrete reason or claim unrun checks.

RETURN:
Material findings: severity, file:line, reachable scenario, problem/impact,
evidence and smallest correction. Exclude unrelated pre-existing defects and style.
If none, say so in one sentence. Include actual validation; limitations only when
material to the conclusion. For FINAL_PASS first return independent assumptions;
prior reports arrive only afterward for reconciliation.
```
