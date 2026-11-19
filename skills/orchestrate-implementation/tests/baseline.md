# Verification status

Bun tests check structure, links and prompt contracts. Python runner tests check
telemetry aggregation, missing counters, model mismatches and incomplete attempts.
Neither suite alone proves agent behavior.

The original runtime was frozen from revision 94156409 before editing. November 19
Luna/medium evidence now includes 33 decision samples and 4 real implementations
(two disposable plans per version); all 14 private behavior checks passed.
Subagent dispatches fell 9→5; uncached input fell 14.8%, while total tokens rose 1.7%.
Shared-capacity waiting makes the wall-time comparison inconclusive. No production
speed or total-token-saving guarantee follows from this pilot.

Initial simulations retained two candidate omissions. The needed scope/risk next
step gained a structural report field and passed five focused repeats; candidate-v1
and controls also passed those repeats, so there is no demonstrated causal gain.
A separate initial-dispatch probe addresses the compound context question's limits.
Native runs used candidate-v1; the final refinement only adds blocked-report output.

See the eval README for method and exact artifact locations. Earlier CLI model/setup
failures remain separate; do not include them in completed-run comparisons.
