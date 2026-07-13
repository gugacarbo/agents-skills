---
name: skill-master
description: Use when creating, editing, evaluating, or preparing reusable agent skills for deployment, including skill discovery, test scenarios, benchmark results, or triggering accuracy.
---

# Skill Master

Create skills through a short authoring loop and a reproducible evaluation loop.
The main document is a router. Read only the reference that matches the current
decision instead of loading every authoring rule into context.

## Operating modes

### Verified workflow

Use this mode for a skill that will be deployed, packaged, or called complete.
It follows RED → GREEN → REFACTOR:

1. Run a baseline before writing or editing the skill.
2. Write the smallest guidance that addresses the observed failure.
3. Run the same scenarios with the skill and inspect the results.
4. Close new loopholes, rerun, and only then package or optimize discovery.

The baseline is `without_skill` for a new skill. For an existing skill, snapshot
the old version and use that snapshot as the comparison configuration.

### Fast draft mode

Use this only when the user explicitly wants an exploratory draft or declines
evaluation. Produce a clearly marked draft, but do not call it verified, do not
claim that it improves behavior, and do not package it as ready for deployment.
Offer the verified workflow as the next step.

## Start by classifying the work

Capture the intended capability, trigger conditions, output contract, inputs,
dependencies, and success criteria. Classify the skill before choosing its
tests:

| Type | Main question | Useful test |
| --- | --- | --- |
| Discipline | Will the agent follow a rule under pressure? | Pressure scenario and rationalization capture |
| Technique | Can the agent apply a method to a new case? | Application and edge-case scenarios |
| Pattern | Can the agent recognize when a mental model applies? | Recognition, application, and counter-example |
| Reference | Can the agent retrieve and apply the right fact? | Retrieval and correctness assertions |

For authoring structure, descriptions, naming, examples, and token budgets,
read [`references/authoring.md`](references/authoring.md). For baseline design,
eval execution, assertions, and iteration, read
[`references/testing.md`](references/testing.md). For rules that must survive
pressure, read [`references/discipline-skills.md`](references/discipline-skills.md).

## Verified workflow

### 1. Establish RED before editing

Write two or three realistic prompts that expose the intended behavior. Run
them without the new guidance, or against the old snapshot when improving an
existing skill. Record the actual choices, omissions, workarounds, and
rationalizations. A test that passes without the skill does not demonstrate
that the skill adds value.

Do not write the final instruction first and then invent a test that confirms
it. If the baseline does not exhibit the target failure, revise the scenario
or stop authoring that rule.

### 2. Write GREEN guidance

Use the baseline evidence to write a focused `SKILL.md` with valid `name` and
`description` frontmatter. The description should contain concrete trigger
conditions and symptoms, not a summary of the workflow; the body contains the
workflow. Keep the main file short and move heavy references or reusable tools
to bundled files.

Choose the instruction form from the failure:

- rule violated under pressure → prohibition, rationalization table, and red flags;
- output has the wrong shape → positive recipe or output contract;
- required element is omitted → a required field or template slot;
- behavior depends on state → a condition keyed to an observable predicate.

### 3. Create and approve evals

Save prompts to `<skill>/evals/evals.json`. Include the expected result and
assertions when they are objectively verifiable. For a discipline skill,
record the observed baseline in the eval metadata:

```json
{
  "id": 1,
  "prompt": "The realistic task prompt",
  "expected_output": "What success looks like",
  "files": [],
  "expectations": [],
  "skill_type": "discipline",
  "baseline_failure": "violates_rule_under_pressure",
  "pressures": ["deadline", "authority"],
  "rationalizations": ["The change is trivial"]
}
```

Run `eval-viewer/generate_prompt_review.py` and wait for the user to approve
the prompt set before running the full evals. Keep the prompt set realistic;
bad prompts produce misleading benchmarks.

### 4. Run paired evaluations

Launch the with-skill and baseline configurations for every eval together so
their timing and context are comparable. Save each result in a sibling
workspace organized by iteration and eval name. Capture timing data when each
run completes.

Grade every assertion using the existing grader format (`text`, `passed`, and
`evidence`). Prefer scripts for deterministic checks. Aggregate with
`scripts/aggregate_benchmark`, ask the analyzer to inspect non-discriminating
assertions and variance, then open `eval-viewer/generate_review.py` so the user
can inspect outputs and benchmark data.

### 5. Iterate from evidence

Read the user's `feedback.json`, transcripts, formal grades, and benchmark.
Generalize from repeated failures instead of overfitting to one prompt. Remove
instructions that cause wasted work, explain important reasons, and bundle a
repeated helper into `scripts/` when multiple runs reinvent it.

Repeat the paired evaluation in a new iteration until the user is satisfied,
feedback is empty, or further changes stop improving the result.

### 6. Optimize and package last

After the skill behavior is stable, optionally optimize the description using
the trigger-eval loop in `scripts/run_loop.py`. Use realistic should-trigger
and near-miss should-not-trigger queries, compare held-out performance, and
show the before/after description.

Run `scripts/quick_validate.py` and package with
`scripts/package_skill.py` only after the verified workflow is complete.

## Environment adaptations

If subagents or a browser are unavailable, run scenarios sequentially and use
the static viewers. A reduced environment changes the rigor of the evidence;
it does not turn a fast draft into a verified result. Skip quantitative
benchmarking only when no meaningful baseline comparison is possible, and say
so in the handoff.

## Safety and scope

Skills must be reusable guidance, not a narrative of one incident. Do not
create instructions for malware, unauthorized access, deception, or data
exfiltration. Preserve user changes outside the integration and never silently
overwrite an existing skill version used as a baseline.

## Reference map

- [`references/authoring.md`](references/authoring.md): skill anatomy, progressive disclosure, SDO, examples, and file layout.
- [`references/testing.md`](references/testing.md): TDD mapping, eval design, baseline comparison, grading, and iteration.
- [`references/discipline-skills.md`](references/discipline-skills.md): pressure tests, rationalizations, red flags, and loophole closure.
- [`references/schemas.md`](references/schemas.md): JSON formats for evals, runs, grading, timing, and benchmarks.
- `agents/`: grader, analyzer, and blind comparator prompts.
- `eval-viewer/`: prompt approval and qualitative/quantitative review UIs.
- `scripts/`: evaluation, aggregation, description optimization, validation, and packaging tools.
