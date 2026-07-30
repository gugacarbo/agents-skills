import { describe, expect, test } from "bun:test";
import { REPO_ROOT, run } from "./helpers";

function isIgnored(path: string): boolean {
	return (
		run(["git", "-C", REPO_ROOT, "check-ignore", "--no-index", "-q", path])
			.exitCode === 0
	);
}

describe("gitignore rules", () => {
	for (const path of [
		".scripts",
		"AGENTS.md",
		".scripts/AGENTS.md",
		".scripts/README.md",
		"skills/commit-changes/SKILL.md",
		"src/install.sh",
		"src/update.sh",
		"src/tests/install.test.ts",
		"src/tests/update.test.ts",
		"skills/skill-master/AGENTS.md",
	]) {
		test(`tracks ${path}`, () => {
			expect(isIgnored(path)).toBe(false);
		});
	}

	test("ignores generated distribution files", () => {
		expect(isIgnored("dist/skills/commit-changes/SKILL.md")).toBe(true);
	});
});
