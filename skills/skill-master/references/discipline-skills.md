# Discipline skill reference

Use this reference when the agent knows a rule but is likely to skip it under
pressure. It is not the default form for ordinary output-shaping problems.

## Match the instruction form to the failure

| Baseline failure             | Use                                           | Avoid as the primary fix                 |
| ---------------------------- | --------------------------------------------- | ---------------------------------------- |
| Rule violated under pressure | Prohibition, rationalization table, red flags | Soft “prefer” language                   |
| Output has the wrong shape   | Positive recipe or contract                   | A long list of “do not” rules            |
| Required element is omitted  | Required field or template slot               | A reminder buried in prose               |
| Behavior depends on state    | Conditional tied to an observable predicate   | Unconditional rule with vague exceptions |

Prohibitions are for a demonstrated discipline failure. They can backfire when
the real problem is output shape, because the agent negotiates with “do not X”.
A positive contract leaves less room for interpretation. Express exceptions as
their own observable condition instead of adding a nuance clause to a rule.

## Close the loopholes from evidence

After the baseline, preserve the agent's actual rationalizations. Add explicit
counters for the shortcuts that occurred, for example:

| Rationalization            | Counter                                                |
| -------------------------- | ------------------------------------------------------ |
| “The change is trivial.”   | The baseline is required regardless of size.           |
| “I will test after.”       | A test that passes immediately does not establish RED. |
| “This follows the spirit.” | The letter of the rule is the observable contract.     |

Do not invent a large prohibition list for hypothetical failures. Add the
smallest counter that blocks a rationalization seen in a run, then retest.

## Red flags

Put a short self-check near the relevant rule. Examples include:

- implementation or final guidance written before the baseline;
- “I already tested it manually” used as a substitute for the specified test;
- keeping untested work as a reference while claiming the test-first cycle;
- changing the scenario after seeing the baseline instead of documenting it;
- packaging or claiming readiness while the evidence is only a fast draft.

When a red flag appears, stop and return to RED. Do not preserve a pre-test
implementation as if it were a harmless draft of the solution.

## Pressure scenario design

Combine at least three realistic pressures for a discipline skill when possible:
time pressure, sunk cost, authority, ambiguity, or exhaustion. Ask the agent
to complete a plausible task while making the shortcut attractive. Record the
exact language used to justify a violation; that language becomes a regression
case.

The success criterion is behavior, not an explanation of the rule. An agent
that recites “always test first” and then edits the file has failed.

## Refactor loop

1. Run the baseline and capture the failure.
2. Add only the rule, contract, or conditional that addresses it.
3. Run the same pressure scenario with the skill.
4. Capture new loopholes and add focused counters.
5. Rerun until behavior is stable across fresh contexts.

For a user-requested quick draft, record the missing baseline and mark the
skill unverified. Flexibility changes the workflow's evidence level; it does
not erase the distinction between a draft and a tested skill.
