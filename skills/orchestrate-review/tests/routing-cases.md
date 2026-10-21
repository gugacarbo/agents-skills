# Routing validation cases

These cases are intended to validate reviewer selection, not finding correctness.

| #   | Scenario                                                                                | Expected routing                                                                                                               |
| --- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1   | README typo                                                                             | code-reviewer                                                                                                                  |
| 2   | One CSS spacing fix, no behavior/state changes                                          | code-reviewer                                                                                                                  |
| 3   | Mechanical rename of private helper with callers updated                                | code-reviewer                                                                                                                  |
| 4   | Routine bounded bug fix in one service, no specialist risk                              | final-adversarial-reviewer(STANDALONE)                                                                                         |
| 5   | CRUD page + endpoint with ordinary validation, no auth model change                     | final-adversarial-reviewer(STANDALONE)                                                                                         |
| 6   | Complex parser with branching and normalization                                         | functional-correctness-reviewer                                                                                                |
| 7   | Resource ownership/authorization logic change                                           | security-reviewer -> final-adversarial-reviewer(FINAL_PASS) because high-impact boundary                                       |
| 8   | Queue worker retry/idempotency bug fix                                                  | reliability-reviewer -> final pass only when external/irreversible side effects make it high-impact                            |
| 9   | Payment webhook with signature verification and idempotent persistence                  | security-reviewer + reliability-reviewer in parallel -> final-adversarial-reviewer(FINAL_PASS)                                 |
| 10  | Feature implemented from multi-step acceptance criteria spanning UI/API/db              | implementation-reviewer plus only triggered specialists; final pass if cross-layer/high-risk gate is met                       |
| 11  | New shared package and dependency direction                                             | architecture-reviewer; add maintainability-agent-dx-reviewer only if canonical-pattern ambiguity is introduced                 |
| 12  | Broad behavior-preserving refactor                                                      | architecture-reviewer + test-quality-reviewer + maintainability-agent-dx-reviewer in parallel -> final pass                    |
| 13  | Large listing query rewritten for performance without semantic changes                  | performance-reviewer                                                                                                           |
| 14  | Listing query rewrite also changes filters/pagination semantics                         | performance-reviewer + functional-correctness-reviewer in parallel -> final pass if interaction is material                    |
| 15  | Test harness/mocking layer change                                                       | test-quality-reviewer                                                                                                          |
| 16  | Large feature with explicit spec + authz + async external side effects + critical tests | implementation + security + reliability + test-quality (+ functional if domain logic is non-trivial) in parallel -> final pass |

## Invariants these cases enforce

1. Simple changes never fan out.
2. Ordinary PRs use exactly one general adversarial reviewer.
3. Specialists are triggered by actual risk surfaces, not file count.
4. `code-reviewer` is never combined with specialist reviewers.
5. First-wave specialists are parallelizable.
6. Final adversarial review is second-wave only when a gate condition applies.
7. A reviewer can legitimately return zero findings.
