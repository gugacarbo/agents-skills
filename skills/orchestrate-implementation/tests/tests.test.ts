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
			"[`parallel-waves.md`](references/parallel-waves.md)",
		);
		expect(skill).toContain("parallel wave, load");
		expect(skill).toContain("sequentially by default");
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
		expect(catalog.evals).toHaveLength(5);
	});
});

describe("orchestrate-implementation implementation configuration", () => {
	test("approves models before implementation and records dispatch boundaries", () => {
		const skill = read("SKILL.md");
		const setup = read("references/controller-setup.md");
		const taskLoop = read("references/controller-task-loop.md");

		expect(skill).toContain("controller-setup.md");
		expect(setup).toContain("## Configuration Gate");
		expect(setup).toContain("Wait for explicit approval");
		expect(setup).toContain("## Ledger Records");
		expect(setup).toContain("append-only run records");
		expect(setup).toContain("exact values used");
		expect(taskLoop).toContain("approved write set");
		expect(taskLoop).toContain("base commit");
	});

	test("requires user-approved concrete models and recovers from validation failures when possible", () => {
		const skill = read("SKILL.md");
		const taskLoop = read("references/controller-task-loop.md");
		const implementerPrompt = read("implementer-prompt.md");
		const taskReviewerPrompt = read("task-reviewer-prompt.md");
		const reReviewPrompt = read("re-review-prompt.md");
		const branchReviewerPrompt = read("references/code-reviewer.md");
		const parallelWaves = read("references/parallel-waves.md");
		const finishingGuide = read("references/finishing-a-development-branch.md");

		expect(skill).toContain("Never dispatch an agent with an omitted model");
		expect(skill).toContain(
			"Run every validation requested by the user, plan, or Spec.",
		);
		expect(taskLoop).toContain("record its command and full output");
		expect(taskLoop).toContain("diagnose and fix it where viable");
		expect(skill).not.toContain(
			"return the error and its command output to the user before any retry, fix, reassignment, or further dispatch.",
		);
		expect(implementerPrompt).toContain(
			"record\n    the exact command and complete output, then diagnose and address the failure\n    when a viable implementation or environment-repair path remains.",
		);
		expect(implementerPrompt).toContain(
			"Report BLOCKED only when no viable\n    implementation path remains",
		);
		expect(parallelWaves).toContain(
			"diagnose and\nfix it before deciding that the orchestration is blocked",
		);
		expect(finishingGuide).toContain(
			"Fix and re-run the\ncovering tests when a viable implementation or environment-repair path remains",
		);
		expect(taskLoop).toContain("Two Rounds Maximum");
		expect(taskLoop).toContain("**Round 1:**");
		expect(taskLoop).toContain("**Round 2:**");
		expect(taskLoop).toContain("fix round <R>/2");

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

describe("orchestrate-implementation run reporting", () => {
	test("reports blockers promptly and summarizes completed batches", () => {
		const taskLoop = read("references/controller-task-loop.md");

		expect(taskLoop).toContain("ordinary task results");
		expect(taskLoop).toContain("without a separate progress\nmessage");
		expect(taskLoop).toContain("report the specific issue immediately");
		expect(taskLoop).toContain("show one concise table");
		expect(taskLoop).toContain("one row per original task plus a summary row");
		expect(taskLoop).toContain("parallel wave complete while any result");
	});

	test("contains parseable reporting eval metadata", async () => {
		const catalog = await Bun.file(
			resolve(skillRoot, "evals/evals.json"),
		).json();

		expect(catalog.evals).toHaveLength(5);
		const reportingEval = catalog.evals.find(
			(evaluation: { name: string }) =>
				evaluation.name === "result-and-batch-reporting",
		);
		expect(reportingEval).toBeDefined();
		expect(reportingEval?.expectations).toContainEqual(
			"Ordinary task results are recorded in the ledger without individual progress messages; blockers and required user decisions are reported immediately.",
		);
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
