# Verification status

`tests/tests.test.ts` checks structure and a few core invariants: links
resolve, prompt placeholders and model/effort fields exist, every implementer
status is handled, configuration keys, recovery-state values, finding
categories, and file sizes. It does not prove agent behavior.

Behavior is described by `evals/evals.json`. These evals have not been run
against agents yet. Run them with the `skill-master` eval workflow (with-skill
vs. baseline runs, graded against each eval's `expectations`) before claiming a
behavior change is verified. `skill-master/scripts/run_eval.py` only measures
description triggering, not this behavior.
