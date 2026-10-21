#!/usr/bin/env python3
"""Reference tests for the routing policy documented in ../SKILL.md.

This is not runtime code for the skill. It encodes the routing invariants so edits
to the skill package can be sanity-checked against representative PR shapes.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

MAP = [
    ("explicit_requirements", "implementation-reviewer"),
    ("functional_complexity", "functional-correctness-reviewer"),
    ("architecture_change", "architecture-reviewer"),
    ("security_boundary", "security-reviewer"),
    ("reliability_concurrency", "reliability-reviewer"),
    ("critical_test_risk", "test-quality-reviewer"),
    ("performance_scale", "performance-reviewer"),
    ("maintainability_pattern_change", "maintainability-agent-dx-reviewer"),
]


def route(case):
    selected = [reviewer for signal, reviewer in MAP if case.get(signal)]

    if case.get("trivial") and not selected:
        return ["code-reviewer"]

    if not selected:
        return ["final-adversarial-reviewer:STANDALONE"]

    final_gate = any([
        case.get("high_impact_boundary", False),
        case.get("cross_layer_integration", False),
        case.get("reviewer_disagreement", False),
        case.get("shared_assumption", False),
        case.get("broad_refactor", False),
        case.get("domains_interact", False) and len(selected) >= 2,
    ])

    if final_gate:
        selected.append("final-adversarial-reviewer:FINAL_PASS")

    return selected


def main():
    cases = json.loads((ROOT / "route_fixtures.json").read_text())
    failures = []
    for case in cases:
        actual = route(case)
        expected = case["expected"]
        if actual != expected:
            failures.append((case["name"], expected, actual))

    # Structural invariants.
    for case in cases:
        actual = route(case)
        if "code-reviewer" in actual and len(actual) != 1:
            failures.append((case["name"], "code-reviewer must be exclusive", actual))
        if "final-adversarial-reviewer:STANDALONE" in actual and len(actual) != 1:
            failures.append((case["name"], "standalone adversarial must be exclusive", actual))
        if "final-adversarial-reviewer:FINAL_PASS" in actual and actual[0].startswith("final-adversarial"):
            failures.append((case["name"], "final pass must follow first-wave reviewers", actual))

    if failures:
        for name, expected, actual in failures:
            print(f"FAIL: {name}\n  expected: {expected}\n  actual:   {actual}")
        raise SystemExit(1)

    print(f"PASS: {len(cases)} routing fixtures")
    print("PASS: exclusivity and final-pass ordering invariants")


if __name__ == "__main__":
    main()
