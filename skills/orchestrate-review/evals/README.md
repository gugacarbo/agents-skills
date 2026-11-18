# Evaluation and evidence

Read this when changing routing or calibrating model profiles. The candidate is
not performance-verified until paired behavioral runs and real review cases exist.

Use the [eval catalog](evals.json) for routing simulations. It covers
mechanical changes, overlapping lenses, critical payments, clean fast reviews,
unsupported model controls, and a concrete integration disagreement. These cases
exercise decisions, not defect-detection ability. Do not replace them with a Python
function that merely reimplements the desired routing policy.

## Historical baseline (before the two-profile policy)

Before this revision, the original 16 Python routing fixtures passed. A fresh
agent reading the original skill reported:

- Mechanical authenticated UI rename: one code reviewer; no model policy.
- Shared-module move with duplicate canonical helper: architecture plus
  maintainability plus final reviewer, even without an open integration question.
- Payment signature/idempotency change: security plus reliability plus final;
  no model policy; final receives earlier reports before independent examination.

This baseline supports simplifying overlapping coverage and specifying model and
information-flow controls. It does not quantify time, token savings or detection.

## Four-role consolidation

The current catalog retains the six approved scenario prompts and updates expected
roles to General, Design, Risk and Adversarial. Compare against a snapshot from
before consolidation. The earlier 19/19 result applies to the previous policy,
not this revision. Model/effort checks and independent final sequencing remain.

New grouping: General BRIEF for mechanical changes, one Design for overlapping
structural lenses, Risk for sensitive/scale investigations, and Adversarial only
for justified final coverage. Substantial independent Risk investigations may be
split with explicit reasons; never infer an agent per lens.

## Paired measurement

1. Snapshot the original skill and preserve the same input revisions and model
   mappings. Obtain approval of evaluation prompts through the skill-master viewer
   before full agent evals. Keep results in a private evaluation workspace.
2. Run original and candidate on each approved scenario under comparable settings.
   Record actual calls, lenses, model/effort selection, initial context, escalation,
   report delivery timing and observed limitations. Inspect transcripts, not only
   the stated plan. Routing simulations cannot verify actual dispatch behavior.
3. Add real diff fixtures with known defects and clean controls before making
   quality or speed claims. Include authorization bypass, duplicate side effects,
   pagination semantics, and ordinary regression fixes.
4. Measure known defects detected, false positives, unique material root causes
   contributed by the final pass, total tokens and wall time. Use actual telemetry;
   mark unavailable values as unavailable, not zero. Repeat paired runs to assess
   variance. A smaller prompt is not a demonstrated latency improvement.
5. Review discriminating assertions and failures before changing model mappings.
   Save per-assertion evidence and separate structural checks, routing simulation,
   actual dispatch behavior, and real defect detection in the result summary.

Do not claim the two-profile policy is calibrated or ready from structural checks
alone. A critical defect missed by fast is evidence to revise routing or mapping;
a clean review is not an automatic reason to rerun it with strong.

## Text compaction

The compact revision folds eight optional lenses into the four role prompts and
removes the separate trigger catalog. Runtime Markdown drops from 17 files / 4,787
whitespace-delimited words to 8 files / 1,575 words (67% less text). This measures
available instruction text, not actual review tokens or latency; references were
already loaded on demand. The six approved routing simulations are reused for
regression comparison. Execution boundaries remain in every dispatch envelope;
these simulations do not establish real harness compliance or defect detection.

Both compact and baseline runs passed the same 25 catalog assertions using
Luna at medium effort. Outputs and per-assertion evidence are in
`/tmp/orchestrate-review-compact-{baseline,candidate}-results.json`. Each version
used one agent for six simulations, so this is a shared-context routing check,
not six isolated runs or a measured quality improvement.

## Measured full reviews

`measure.py` runs both snapshots concurrently on executable disposable Git fixtures
with fresh native reviewer agents. All agents are fixed to `gpt-6-luna` / `medium`
to isolate skill changes, overriding production profile defaults. It records CLI
wall time, descendant session token counters, model/effort, tool calls and agent
lifecycles; aggregation includes controller and reviewers without adding cached
input or reasoning output a second time. Missing telemetry stays null.

```bash
python3 skills/orchestrate-review/evals/measure.py --output /absolute/results --original-ref <original-commit> --repeat 1
python3 skills/orchestrate-review/evals/measure.py --output /absolute/results --original-ref <original-commit> --repeat 2
python3 skills/orchestrate-review/evals/measure.py --output /absolute/results --aggregate-only
```

Snapshots freeze at first use. Original/current variants share identical fixture
diffs; each repetition gets fresh sessions. Fixtures cover clean rename plus
normalization, payment idempotency and pagination regressions. Public tests are
green; private reproductions and grading are kept outside the review workspaces.
Failed setup, quota and timeout runs must be preserved separately and excluded
from completed-review comparisons. Stop the runner on failure before retrying.

The CLI uses this host's unrestricted permission profile because the nested
read-only sandbox cannot initialize here; agent tasks explicitly remain read-only.
Use only disposable fixture repos and trusted snapshot skills. Results are pilot
measurements on small synthetic diffs, not production latency/cost guarantees.

Measured pilot (2026-11-18): 16 complete reviews, eight per version, four synthetic
diffs, two fresh repetitions, Luna/medium throughout. Original → compact:
4,442,568 → 2,881,837 total tokens (−35.1%); 455,076 → 289,151 uncached input
(−36.5%); 86.3 → 82.9 seconds mean wall time (−4.0%); 25 → 10 reviewers.
Both detected all six expected defect occurrences and passed both clean controls.
The rename case increased total tokens by 33.5%; savings are workload-dependent.
Artifacts: `/home/ubuntu/apps/orchestrate-review-workspace/measurement-2026-11-18/`
contains `report.md`, `benchmark.json`, `agents.csv`, quality grades and raw events.
Setup/quota failures are preserved separately and excluded. No pricing or
production performance claim follows from this small pilot.

## Consolidated controller iteration

The next candidate merges the three mandatory references into SKILL.md, adds a
BRIEF branch with a shared small patch/reference packet, and names a single owner
for shared validation. There are five runtime Markdown files. The previous compact
working copy (eight files) is the paired baseline; do not confuse it with Git HEAD
or reuse historical timings as a contemporaneous comparison.

The four approved expanded fixtures are in `fixtures/expanded/`: two comparable
export-cache changes and two comparable durable-delivery changes. Neutral case IDs
do not reveal defective versus clean outcomes to reviewers. Each pair includes
one introduced defect and one clean control. Public suites pass on both revisions;
private reproductions stay outside review repositories. A contract-consistency check
also exercises module ordering, ensuring the export controls satisfy the approved
requirements before native runs.

The final frozen candidate is evaluated in the sibling workspace
`measurement-v3-2026-11-18`, with two fresh repetitions over eight real diffs per
version. `measurement-v2-2026-11-18` is a diagnostic first candidate; its BRIEF
rediscovery/test overhead motivated sharing the inspected patch and explicitly
assigning BRIEF shared tests to the controller when useful. Do not mix its results
into the final comparison.

`agents.json` also records literal commands extracted without evaluating tool code.
`suite_invoking_agents` and `suite_invocations` flag unittest calls for inspection;
interpreter failures, shared suites and distinct targeted tests must be distinguished
from actual duplicated completed validation.
