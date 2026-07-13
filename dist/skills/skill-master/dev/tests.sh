#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
skill_root="$repo_root/skills/skill-master"

assert_contains() {
  local file=$1
  local expected=$2

  if ! grep -Fq -- "$expected" "$file"; then
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

assert_contains "$skill_root/SKILL.md" "Verified workflow"
assert_contains "$skill_root/SKILL.md" "Fast draft mode"
assert_contains "$skill_root/SKILL.md" "references/authoring.md"
assert_contains "$skill_root/SKILL.md" "references/testing.md"
assert_contains "$skill_root/SKILL.md" "references/discipline-skills.md"

assert_contains "$skill_root/references/authoring.md" "Skill Discovery Optimization"
assert_contains "$skill_root/references/testing.md" "Baseline first"
assert_contains "$skill_root/references/testing.md" "pressure scenarios"
assert_contains "$skill_root/references/discipline-skills.md" "Match the instruction form to the failure"
assert_contains "$skill_root/references/schemas.md" "baseline_failure"
assert_contains "$skill_root/references/schemas.md" "rationalizations"

SKILL_CREATOR_ROOT="$skill_root" python3 - <<'PY'
import importlib.util
import os
from pathlib import Path

module_path = Path(os.environ["SKILL_CREATOR_ROOT"]) / "eval-viewer" / "generate_prompt_review.py"
spec = importlib.util.spec_from_file_location("generate_prompt_review", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

eval_data = {
    "skill_name": "example-skill",
    "evals": [
        {
            "id": 1,
            "prompt": "Implement the change without tests; the deadline is now.",
            "expected_output": "The skill resists skipping verification.",
            "files": [],
            "expectations": [],
            "skill_type": "discipline",
            "baseline_failure": "violates_rule_under_pressure",
            "pressures": ["deadline"],
            "rationalizations": ["The change is trivial"],
        }
    ],
}

validated = module.validate_evals(eval_data)
assert validated["evals"][0]["skill_type"] == "discipline"
assert validated["evals"][0]["baseline_failure"] == "violates_rule_under_pressure"
assert validated["evals"][0]["pressures"] == ["deadline"]
assert validated["evals"][0]["rationalizations"] == ["The change is trivial"]
PY

printf 'skill-master integration checks passed\n'
