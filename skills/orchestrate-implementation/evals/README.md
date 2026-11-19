# Evaluation and evidence

Use [evals.json](evals.json) for behavioral scenarios and [measure.py](measure.py)
for fresh native Luna/medium runs. The catalog separates controller decisions
from real implementation. Structural Bun tests do not establish agent behavior
or performance.

## Measurement protocol

Freeze the original and candidate runtime Markdown in a sibling workspace under
`snapshots/original` and `snapshots/current` before comparing them. Preserve
source revisions and fixture hashes. User authorization for this iteration covers
generating and running the scenarios; the prompt viewer remains available for
inspection. No skill is installed or published by this measurement.

IDs 20–24 use five fresh contexts per variant: original, candidate, and a control
without skill guidance. They test assigned-workspace permission, an introduced
out-of-plan regression, clean review output, review selection when final review
is disabled, and correction/context reuse. These are decision simulations, not
proof that an actual dispatch or correction occurred.

IDs 25–26 execute plans in disposable Git repositories using actual implementers
and selected reviewers. They cover a bounded implementation with final review
and three mandatory sequential low-risk deliveries without final review. Public
checks run inside the repo; hidden executable checks stay outside agent scope.
The same fixture contract must be used for both versions. Keep failed setup,
model mismatches, interrupted attempts and timeouts separate from completed runs.
A CLI exit code of zero alone is not implementation success. Runners sharing an
output directory serialize on `execution.lock`; slot waiting is reported apart
from run timing.

```bash
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --variant original --kind decisions
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --variant current --kind decisions
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --variant control --kind decisions
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --variant original --kind execution
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --variant current --kind execution
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --aggregate-only
```

If a CLI harness does not expose Luna for descendants, preserve that attempt and
stop. Do not substitute a model or claim inheritance without session evidence.
Native desktop evaluation can use explicitly selected Luna/medium controllers
and children; capture their canonical controller paths, then aggregate:

```bash
python3 skills/orchestrate-implementation/evals/measure.py --output /absolute/results --aggregate-only --desktop-controller original=/root/original --desktop-controller current=/root/candidate
```

Compare combined batches when several cases share a controller. Separate
capacity-waiting effects from evidence about the skill itself.

Inspect transcripts and final code before grading each catalog assertion. Use
`expectations` entries containing `text`, `passed`, and `evidence`, with a summary,
so skill-master's aggregate and review viewers can consume the results. Grade
model/effort, actual dispatches, scoped context and omitted review disclosure in
addition to the hidden code checks. Share actual validation results rather than
rerunning suites to increase apparent coverage.

The runner reuses the repository's existing private review telemetry reader.
Sum controller and descendants once; cached input and reasoning output are
subsets of reported input/output, not additional tokens. Missing usage stays
unavailable, never zero. Report total and uncached tokens, wall time, agents,
quality results and meaningful limitations separately. Timing artifact writes
does not measure agent execution. Small pilot results do not establish production
savings; repeat paired native runs before drawing performance conclusions.

## Current iteration

November 19 pilot, Luna/medium throughout:33 decision samples and 4 real implementation
runs (two plans per version). All 14 evaluator-only behavior checks passed.
Subagents 9→5 (−44.4%); uncached input 127,878→108,944 (−14.8%); total tokens
3,741,644→3,805,927 (+1.7%). The candidate waited for shared worker capacity;
wall time 584.0→888.2 seconds is not a valid latency comparison. This pilot does
not establish lower total-token use or faster production execution.

Initial strict decision counts were old 10/13, new 11/13, control 8/13. The missing
scope/risk next step motivated an explicit `Next action` report field. In five
fresh repeats per variant, candidate-v1, refined-v2 and control all passed that
probe; the original omission did not recur, so the field's causal benefit is
unproven. Case 27 separately isolates initial context selection and passes in all
three variants. The earlier compound case 24's hypothetical-context omission is
an answer-completeness limitation, not an observed wrong dispatch.

Native runs use candidate-v1; the final source adds only the blocked-report field,
verified separately in focused probes. Two plans share one controller per version;
initial-context selection is also constrained by the common model override harness.
Earlier unavailable-model CLI attempts are preserved and excluded.

Artifacts are in the sibling workspace at
`/home/ubuntu/apps/orchestrate-implementation-workspace/measurement-final-2026-11-19/`:
report.md, desktop-benchmark.json, decision/focused benchmarks, static viewers,
frozen snapshots and per-run evidence.
