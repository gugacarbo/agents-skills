import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const skillRoot = resolve(import.meta.dir, "..");
const read = (path: string) => readFileSync(resolve(skillRoot, path), "utf8");

describe("orchestrate-implementation parallel waves", () => {
	const skill = read("SKILL.md");
	const parallelWaves = read("references/parallel-waves.md");
	const implementerPrompt = read("implementer-prompt.md");

	test("routes safe parallel execution to the detailed reference", () => {
		expect(skill).toContain(
			"[parallel-waves.md](references/parallel-waves.md)",
		);
		expect(skill).toContain("Parallel wave:");
		expect(skill).toContain("Sequential task:");
		expect(skill).not.toContain(
			"Never dispatch multiple implementation subagents in parallel",
		);
	});

	test("requires more than different named source files", () => {
		for (const requirement of [
			"complete write set",
			"generated files",
			"shared resource",
			"own linked worktree and branch",
		]) {
			expect(parallelWaves).toContain(requirement);
		}
	});

	test("integrates task branches deterministically and falls back on conflict", () => {
		expect(parallelWaves).toContain("in plan order");
		expect(parallelWaves).toContain("Cherry-pick");
		expect(parallelWaves).toContain("with `-x`");
		expect(parallelWaves).toContain("source-to-integration commit mapping");
		expect(parallelWaves).toContain("abort that cherry-pick");
		expect(parallelWaves).toContain("re-run the affected task sequentially");
	});

	test("gives each parallel implementer an enforceable isolation contract", () => {
		for (const placeholder of ["[WORKTREE]", "[TASK_BRANCH]", "[WRITE_SET]"]) {
			expect(implementerPrompt).toContain(placeholder);
		}
		expect(implementerPrompt).toContain("do not write outside that set");
		expect(implementerPrompt).toContain("return NEEDS_CONTEXT");
		expect(implementerPrompt).toContain("the only write allowed");
		expect(implementerPrompt).toContain(
			"outside a parallel task's approved source write set",
		);
	});

	test("contains parseable behavioral eval metadata", async () => {
		const catalog = await Bun.file(
			resolve(skillRoot, "evals/evals.json"),
		).json();
		expect(catalog.skill_name).toBe("orchestrate-implementation");
		expect(catalog.evals).toHaveLength(4);
	});
});

describe("orchestrate-implementation implementation configuration", () => {
	test("requires model confirmation before implementation and persists dispatch variables", () => {
		const skill = read("SKILL.md");

		expect(skill).toContain("## Implementation Configuration Gate");
		expect(skill).toContain("wait\nfor explicit approval");
		expect(skill).toContain("## Implementation configuration");
		for (const variable of [
			"PLAN_FILE",
			"WORKSPACE",
			"MERGE_BASE",
			"MODEL",
			"BRIEF_FILE",
			"REPORT_FILE",
			"WORKTREE",
			"TASK_BRANCH",
			"WRITE_SET",
			"GLOBAL_CONSTRAINTS",
			"BASE_SHA",
			"HEAD_SHA",
			"WAVE_BASE",
			"INTEGRATION_BASE",
			"FIX_BASE_SHA",
			"DIFF_FILE",
			"FINDINGS",
		]) {
			expect(skill).toContain(variable);
		}
	});

	test("requires user-approved concrete models and returns test failures to the user", () => {
		const skill = read("SKILL.md");
		const implementerPrompt = read("implementer-prompt.md");
		const taskReviewerPrompt = read("task-reviewer-prompt.md");
		const reReviewPrompt = read("re-review-prompt.md");
		const branchReviewerPrompt = read("references/code-reviewer.md");

		expect(skill).toContain(
			"Never dispatch a subagent with an omitted model or `model: inherit`.",
		);
		expect(skill).toContain(
			"Never dispatch, replace, or otherwise use a model that the user has not explicitly approved.",
		);
		expect(skill).toContain(
			"Run every test or validation command explicitly requested by the user, plan, or spec.",
		);
		expect(skill).toContain(
			"return the error and its command output to the user before any retry, fix, reassignment, or further dispatch.",
		);
		expect(skill).not.toContain("the four named below");

		for (const prompt of [
			implementerPrompt,
			taskReviewerPrompt,
			reReviewPrompt,
			branchReviewerPrompt,
		]) {
			expect(prompt).toContain("model: [MODEL");
			expect(prompt).toContain("explicitly approved by the");
			expect(prompt).toContain("`model: inherit`");
		}
	});
});

describe("orchestrate-implementation activation", () => {
	test("requires an explicit user invocation", () => {
		const skill = read("SKILL.md");

		expect(skill).toContain(
			"Use only when the user explicitly invokes `$orchestrate-implementation`",
		);
		expect(skill).toContain(
			"Do not activate automatically for ordinary implementation requests or plans.",
		);
	});
});
