# Skill testing reference

Skill testing is test-driven development applied to process documentation.
The document is the production code; the agent's behavior is the runtime.

## TDD mapping

| TDD | Skill work |
| --- | --- |
| RED | Agent violates or misses the target behavior without the skill |
| GREEN | Minimal skill makes the same scenario comply |
| REFACTOR | New rationalizations or edge cases are closed and retested |

## Baseline first

For a new skill, run the prompt with no skill. For an edit, copy the original
skill to a snapshot and run that version. Record exact choices, omissions,
workarounds, and rationalizations before writing the new guidance. Tests that
pass immediately do not prove the guidance changed behavior.

For discipline skills, combine pressures such as deadline, sunk cost,
authority, ambiguity, or exhaustion. The strongest useful baseline is the one
that makes the tempting shortcut plausible.

## Test by skill type

- Discipline: academic understanding, pressure compliance, and combinations of
  pressures. Success means following the rule when a shortcut is tempting.
- Technique: application to a normal case, variation, and missing information.
- Pattern: recognition, correct application, and a counter-example where it
  should not be used.
- Reference: retrieval, application, and gaps in common use cases.

Assertions should measure meaningful outcomes, not superficial presence. A
filename, a quoted rule, or a passing status alone is weak evidence. Graders
must inspect the transcript and output files and cite concrete evidence.

## Eval metadata

Use the optional fields in `references/schemas.md` to preserve the reason an
eval exists: `skill_type`, `baseline_failure`, `failure_form`, `pressures`, and
`rationalizations`. Existing evals remain valid without these fields.

## Execution loop

1. Draft two or three realistic prompts.
2. Obtain prompt approval with the prompt viewer.
3. Launch with-skill and baseline runs in the same turn.
4. Draft assertions while runs are in progress.
5. Capture timing as completion notifications arrive.
6. Grade with `text`, `passed`, and `evidence` fields.
7. Aggregate pass rate, time, tokens, and variance.
8. Read the analyzer and human review before editing.
9. Rerun in a new iteration and compare with the previous workspace.

Use the existing scripts and viewers; do not invent a parallel `/skill-test`
workflow. In headless environments, generate static HTML and collect the
downloaded feedback file.

## Micro-tests

For behavior-shaping wording, first run at least five fresh-context samples per
variant, including a no-guidance control. Read flagged matches manually because
quoted examples and template echoes can look like compliance. Treat variance
as a signal: inconsistent interpretations mean the wording needs a clearer
form, not merely more words. Micro-tests do not replace full pressure scenarios
for discipline skills.

## Completion criteria

A skill is verified only when the intended behavior is observed in the
with-skill runs, the baseline comparison is recorded, important assertions are
discriminating, and the user has had a chance to review outputs. If a user
chooses a fast draft, label the evidence gap and stop before packaging.
