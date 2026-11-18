# Routing evaluation cases

The behavioral scenarios now live in [the eval catalog](../evals/evals.json).
Run them against the original snapshot and candidate with the same harness.

The former Python router and boolean fixtures were removed: they implemented a
second routing policy instead of evaluating the skill that an agent actually reads.
The baseline passed all 16 former fixtures, but that did not measure agent behavior.

Do not treat scenario simulations as evidence of defect detection or latency gains.
For those claims, use real diffs with known defects and repeated paired executions,
as described in [evaluation guidance](../evals/README.md).
