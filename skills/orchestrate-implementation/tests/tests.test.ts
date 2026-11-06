import { describe, expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

const skillRoot = resolve(import.meta.dir, "..");
const read = (path: string) => readFileSync(resolve(skillRoot, path), "utf8");

const primaryFiles = [
	"SKILL.md",
	"parallel-waves.md",
	"implementer-prompt.md",
	"generic-reviewer-prompt.md",
];

const skill = read("SKILL.md");

/** Splits markdown into fenced-code text and prose text. */
const splitFences = (markdown: string) => {
	const parts = markdown.split("```");
	return {
		code: parts.filter((_, index) => index % 2 === 1).join("\n"),
		prose: parts.filter((_, index) => index % 2 === 0).join("\n"),
	};
};

const placeholders = (text: string) =>
	new Set(text.match(/<[A-Z][A-Z0-9_]+>/g) ?? []);

/** Returns the body of a `## <heading>` section, up to the next `## `. */
const section = (markdown: string, heading: string) => {
	const start = markdown.indexOf(`\n## ${heading}`);
	expect(start).toBeGreaterThan(-1);
	const end = markdown.indexOf("\n## ", start + 1);
	return markdown.slice(start, end === -1 ? undefined : end);
};

describe("structure: cross-file consistency", () => {
	test("every relative markdown link resolves", () => {
		for (const path of primaryFiles) {
			const links = [...read(path).matchAll(/\]\(([^)#]+)\)/g)].map(
				(match) => match[1],
			);
			for (const link of links) {
				if (/^[a-z]+:/.test(link)) continue;
				expect(existsSync(resolve(skillRoot, dirname(path), link))).toBe(true);
			}
		}
	});

	test("placeholders named in prose exist in the prompt templates", () => {
		for (const path of [
			"implementer-prompt.md",
			"generic-reviewer-prompt.md",
		]) {
			const { code, prose } = splitFences(read(path));
			const defined = placeholders(code);
			expect(defined.size).toBeGreaterThan(0);
			for (const name of placeholders(prose)) {
				expect(defined.has(name)).toBe(true);
			}
		}
	});

	test("prompt templates carry a model and effort field", () => {
		for (const path of [
			"implementer-prompt.md",
			"generic-reviewer-prompt.md",
		]) {
			const { code } = splitFences(read(path));
			expect(code).toMatch(/model: <[A-Z_]+_MODEL>/);
			expect(code).toMatch(/effort: <[A-Z_]+_EFFORT>/);
		}
	});

	test("every implementer status is handled by the controller", () => {
		const statusLine = read("implementer-prompt.md").match(
			/Status: ([A-Z_| ]+)/,
		);
		expect(statusLine).not.toBeNull();
		const statuses = (statusLine?.[1] ?? "").split("|").map((s) => s.trim());
		expect(statuses.length).toBe(4);
		const dispatch = section(skill, "4. Dispatch implementers");
		for (const status of statuses) {
			expect(dispatch).toContain(`**${status}**`);
		}
	});

	test("the configuration block only has run-shape keys", () => {
		const config = skill.match(/```yaml\n([\s\S]*?)```/);
		expect(config).not.toBeNull();
		const keys = (config?.[1] ?? "")
			.split("\n")
			.filter(Boolean)
			.map((line) => line.split(":")[0].trim());
		expect(keys).toEqual(["parallel", "worktree", "max_fix_rounds"]);
		for (const path of primaryFiles) {
			expect(read(path)).not.toMatch(/task_review|final_review/);
		}
	});

	test("recovery-state review values match the documented set", () => {
		const state = section(skill, "6. Persist minimal recovery state");
		const declared = state.match(/`review` is one of `([^`]+)`/);
		expect(declared).not.toBeNull();
		const allowed = new Set(
			(declared?.[1] ?? "").split("|").map((value) => value.trim()),
		);
		const used = [...state.matchAll(/^\s+review: (\S+)$/gm)].map((m) => m[1]);
		expect(used.length).toBeGreaterThan(0);
		for (const value of used) expect(allowed.has(value)).toBe(true);
		expect(allowed.has("deferred-to-final")).toBe(true);
	});

	test("deferred-finding categories agree between controller and reviewer", () => {
		const categories = (text: string) => {
			const match = text.match(
				/category:?\s\(?`?(correctness \| tests \| maintainability \| style \| pre-existing)/,
			);
			return match?.[1];
		};
		const controller = categories(skill);
		expect(controller).toBeDefined();
		expect(categories(read("generic-reviewer-prompt.md"))).toBe(controller);
	});

	test("the three model roles appear in the roles table and the preflight", () => {
		const models = section(skill, "Models");
		const preflight = section(skill, "Preflight");
		for (const role of ["implement", "task review", "final review"]) {
			expect(models).toContain(`| ${role}`);
			expect(preflight).toContain(`${role}: <model / effort>`);
		}
	});

	test("every deferred-finding reason is assigned by the finding gate", () => {
		const state = section(skill, "6. Persist minimal recovery state");
		const declared = state.match(/reason\s\(`([^`]+)`\)/);
		expect(declared).not.toBeNull();
		const gate = skill.slice(skill.indexOf("### Finding gate"));
		for (const reason of (declared?.[1] ?? "").split("|")) {
			expect(gate).toContain(reason.trim());
		}
	});

	test("resume and wave exits are routed", () => {
		expect(section(skill, "1. Resolve the workspace")).toContain(
			"git worktree list",
		);
		expect(read("parallel-waves.md")).toContain("## Write-set expansion");
	});

	test("parallel mechanics live only in parallel-waves.md", () => {
		expect(skill).toContain("[`parallel-waves.md`](parallel-waves.md)");
		expect(skill).not.toContain("cherry-pick");
		expect(read("parallel-waves.md")).toContain("cherry-pick");
	});
});

describe("contract: core invariants", () => {
	test("activates only on explicit invocation", () => {
		expect(skill).toContain("Use only when the user explicitly invokes");
	});

	test("controller never writes product code", () => {
		expect(skill).toContain(
			"controller never writes or corrects implementation code",
		);
	});

	test("never dispatches with an unapproved model", () => {
		expect(skill).toContain(
			"Never dispatch a subagent with an unapproved model",
		);
		expect(skill).toContain("`auto`, `inherit`");
		expect(skill).toContain("Do not save proposals between runs");
	});

	test("never publishes without an explicit request", () => {
		expect(skill).toContain(
			"Nothing leaves the session without an explicit request",
		);
		expect(skill).toContain("Do not merge, push, create a PR");
	});
});

describe("maintenance", () => {
	test("primary files stay focused", () => {
		for (const path of primaryFiles) {
			const lines = read(path).split("\n").length;
			expect(lines).toBeLessThanOrEqual(path === "SKILL.md" ? 450 : 200);
		}
	});

	test("removed orchestration framework stays removed", () => {
		for (const path of [
			"task-reviewer-prompt.md",
			"re-review-prompt.md",
			"references/controller-setup.md",
			"references/controller-task-loop.md",
			"references/controller-finish.md",
			"references/code-reviewer.md",
			"scripts/plan-workspace",
			"scripts/task-brief",
			"scripts/review-package",
		]) {
			expect(existsSync(resolve(skillRoot, path))).toBe(false);
		}
	});

	test("eval catalog covers the behavior contract", async () => {
		const catalog = await Bun.file(
			resolve(skillRoot, "evals/evals.json"),
		).json();
		expect(catalog.skill_name).toBe("orchestrate-implementation");
		const ids = catalog.evals.map(
			(evaluation: { id: number }) => evaluation.id,
		);
		expect(new Set(ids).size).toBe(ids.length);
		const names = new Set(
			catalog.evals.map((evaluation: { name: string }) => evaluation.name),
		);
		for (const name of [
			"safe-parallel-units",
			"uncertain-parallelism-serializes",
			"unit-review-fix-rounds",
			"final-review-fix-routing",
			"approved-model-default",
			"missing-model-proposal",
			"default-isolation",
			"reuse-linked-worktree",
			"task-grouping-by-graph",
			"small-units-not-parallel",
			"integration-conflict-disables-parallel",
			"no-automatic-publication",
			"risk-based-review-skips-low-risk",
			"validation-evidence-not-rerun",
			"unsupported-finding-downgraded",
			"refactor-is-non-blocking",
			"no-final-review-reviews-every-unit",
			"blocked-unit-becomes-blocker",
			"deferred-findings-consolidated",
		]) {
			expect(names.has(name)).toBe(true);
		}
	});
});
