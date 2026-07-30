import { describe, expect, test } from "bun:test";
import { join, resolve } from "node:path";
import { expectSuccess, read, run } from "../../../src/tests/helpers";

const skillRoot = resolve(import.meta.dir, "..");

function expectContains(relativePath: string, expected: string): void {
	expect(read(join(skillRoot, relativePath))).toContain(expected);
}

describe("skill-master integration", () => {
	test("routes verified and fast-draft workflows to their references", () => {
		for (const expected of [
			"Verified workflow",
			"Fast draft mode",
			"references/authoring.md",
			"references/testing.md",
			"references/discipline-skills.md",
		]) {
			expectContains("SKILL.md", expected);
		}
	});

	test("preserves authoring, testing, discipline, and schema guidance", () => {
		expectContains("references/authoring.md", "Skill Discovery Optimization");
		expectContains("references/testing.md", "Baseline first");
		expectContains("references/testing.md", "pressure scenarios");
		expectContains(
			"references/discipline-skills.md",
			"Match the instruction form to the failure",
		);
		expectContains("references/schemas.md", "baseline_failure");
		expectContains("references/schemas.md", "rationalizations");
	});

	test("prompt review accepts extended discipline metadata", () => {
		const python = `
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
`;
		const result = run(["python3", "-c", python], {
			env: { SKILL_CREATOR_ROOT: skillRoot },
		});
		expectSuccess(result);
	});
});
