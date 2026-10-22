import { describe, expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const skillRoot = resolve(import.meta.dir, "..");
const read = (path: string) => readFileSync(resolve(skillRoot, path), "utf8");

describe("orchestrate-implementation core contract", () => {
	const skill = read("SKILL.md");

	test("keeps explicit activation and controller-only implementation", () => {
		expect(skill).toContain("Use only when the user explicitly invokes");
		expect(skill).toContain(
			"controller never writes or corrects implementation code",
		);
		expect(skill).toContain(
			"It never implements or fixes product code itself.",
		);
	});

	test("uses an informative preflight without a configuration gate", () => {
		expect(skill).toContain("## Preflight");
		expect(skill).toContain("This is informational, not an approval gate");
		expect(skill).not.toContain("Configuration Gate");
		expect(skill).not.toContain("wait for its explicit approval");
	});

	test("requires approved concrete models without automatic escalation", () => {
		expect(skill).toContain(
			"Never dispatch a subagent with an unapproved model",
		);
		expect(skill).toContain("concrete system/workspace default");
		expect(skill).toContain("`auto`, `inherit`");
		expect(skill).toContain("never require automatic");
	});

	test("defaults to isolated worktrees and safe parallelism", () => {
		expect(skill).toContain("Default to isolation");
		expect(skill).toContain("using-git-worktrees");
		expect(skill).toContain(
			"Parallelism is automatic only when all four conditions",
		);
		for (const concept of [
			"No dependency conflict",
			"No write-set conflict",
			"No interface conflict",
			"No shared mutable resource",
		]) {
			expect(skill).toContain(concept);
		}
		expect(skill).toContain(
			"If any condition is uncertain, execute sequentially",
		);
	});

	test("allows grouping and subdivision while preserving traceability", () => {
		expect(skill).toContain("group small, tightly related tasks");
		expect(skill).toContain("split a large task into smaller units");
		expect(skill).toContain("mapping back to its source");
	});

	test("defaults to few coarse units to limit dispatch overhead", () => {
		expect(skill).toContain("few, coarse units; group by default");
		expect(skill).toContain("fewest units that one implementer can complete");
		expect(skill).toContain("tightly related tasks by default");
	});

	test("reviews units by risk and leaves the rest to the final review", () => {
		expect(skill).toContain("task_review: auto # auto | on | off");
		expect(skill).toContain("review a unit on its own only when");
		expect(skill).toContain("still covered by the final review");
		expect(skill).not.toContain("Task/unit review: enabled.");
	});

	test("trusts implementer validation evidence instead of re-running", () => {
		expect(skill).toContain("verify the implementer's report");
		expect(skill).toContain("never by default");
		expect(skill).not.toContain("run or verify the unit's focused validations");
	});

	test("scopes re-reviews to findings and the fix range", () => {
		expect(skill).toContain("### Scoped re-review");
		expect(skill).toContain("`fix_base..fix_head`");
		expect(skill).toContain("full final validation must");
	});

	test("reviews execution units and caps correction loops", () => {
		expect(skill).toContain("orchestrate-review");
		expect(skill).toContain("material");
		expect(skill).toContain("non-blocking");
		expect(skill).toContain("Correction round 1");
		expect(skill).toContain("Correction round 2");
		expect(skill).toContain("original implementer");
		expect(skill).toContain("new implementer");
		expect(skill).toContain("default 2");
	});

	test("integrates parallel units deterministically and falls back to sequential", () => {
		expect(skill).toContain("predetermined unit order");
		expect(skill).toContain("cherry-picking");
		expect(skill).toContain("abort that unit's cherry-pick");
		expect(skill).toContain("re-run the affected unit sequentially");
	});

	test("uses minimal recovery and no automatic publication", () => {
		expect(skill).toContain("Persist minimal recovery state");
		expect(skill).toContain("Git is the source of truth");
		expect(skill).not.toContain("append-only run records");
		expect(skill).toContain("Do not merge, push, create a PR");
	});

	test("uses focused validation and global final validation", () => {
		expect(skill).toContain("focused validations");
		expect(skill).toContain("Run final validation");
		expect(skill).toContain("Biome or Knip");
	});

	test("final fixes use fresh fixers", () => {
		expect(skill).toContain("Final fix round 1");
		expect(skill).toContain("dispatch a new fixer");
		expect(skill).toContain("Final fix round 2");
		expect(skill).toContain("another new fixer");
	});
});

describe("orchestrate-implementation prompts", () => {
	test("implementer prompt is scoped and forbids nested agents", () => {
		const prompt = read("implementer-prompt.md");
		expect(prompt).toContain("<APPROVED_CONCRETE_MODEL>");
		expect(prompt).toContain("Do not work on other units");
		expect(prompt).toContain("Never spawn another agent or reviewer");
		expect(prompt).toContain("Create one or more natural commits");
		expect(prompt).toContain("Focused validation");
		expect(prompt).toContain("exact command, exit status");
	});

	test("generic reviewer is a minimal read-only fallback", () => {
		const prompt = read("generic-reviewer-prompt.md");
		expect(prompt).toContain("orchestrate-review");
		expect(prompt).toContain("read-only");
		expect(prompt).toContain("material");
		expect(prompt).toContain("non-blocking");
		expect(prompt).toContain("never spawn");
		expect(prompt).toContain("scoped re-review");
	});
});

describe("orchestrate-implementation cleanup", () => {
	test("removes the old orchestration framework", () => {
		for (const path of [
			"task-reviewer-prompt.md",
			"re-review-prompt.md",
			"references/controller-setup.md",
			"references/controller-task-loop.md",
			"references/controller-finish.md",
			"references/parallel-waves.md",
			"references/code-reviewer.md",
			"references/requesting-code-review.md",
			"references/finishing-a-development-branch.md",
			"references/executing-plans/SKILL.md",
			"references/receiving-code-review/SKILL.md",
			"scripts/plan-workspace",
			"scripts/task-brief",
			"scripts/review-package",
		]) {
			expect(existsSync(resolve(skillRoot, path))).toBe(false);
		}
	});

	test("keeps primary files under the hard ceiling", () => {
		for (const path of [
			"SKILL.md",
			"implementer-prompt.md",
			"generic-reviewer-prompt.md",
		]) {
			const lines = read(path).split("\n").length;
			expect(lines).toBeLessThanOrEqual(1000);
		}
	});

	test("contains behavior-focused eval metadata", async () => {
		const catalog = await Bun.file(
			resolve(skillRoot, "evals/evals.json"),
		).json();
		expect(catalog.skill_name).toBe("orchestrate-implementation");
		expect(catalog.evals.length).toBeGreaterThanOrEqual(8);
		const names = new Set(
			catalog.evals.map((evaluation: { name: string }) => evaluation.name),
		);
		for (const name of [
			"safe-parallel-units",
			"uncertain-parallelism-serializes",
			"unit-review-fix-rounds",
			"final-review-fresh-fixers",
			"approved-model-default",
			"default-isolation",
			"task-grouping-and-splitting",
			"integration-conflict-fallback",
			"risk-based-review-skips-low-risk",
			"validation-evidence-not-rerun",
		]) {
			expect(names.has(name)).toBe(true);
		}
	});
});
