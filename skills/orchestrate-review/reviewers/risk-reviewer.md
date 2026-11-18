# Risk

Use strong. Investigate assigned paths, combining related risks:

- Security: trace hostile input or attacker action through server-side authorization,
  ownership/tenant checks and sensitive sinks. UI restrictions are not enforcement.
  Require a plausible attack path and impact.
- Reliability: examine duplicate/concurrent/out-of-order execution, failure between
  steps, and lost acknowledgment after side effects. Check transaction/external
  divergence, idempotency, retries and reconciliation.
- Performance: require a plausible workload, scaling mechanism, material resource
  impact and validation method; inspect unbounded/repeated work, payloads and retention.

Check local correctness; avoid generic checklists and speculative optimizations.
Request a split only for substantial independent investigations that cannot fit
this scope. Use the envelope's output contract.
