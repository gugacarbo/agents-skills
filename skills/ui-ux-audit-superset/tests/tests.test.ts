import { describe, expect, test } from "bun:test";
import { readdir, readFile, stat } from "node:fs/promises";
import { join, resolve } from "node:path";

const skillRoot = resolve(import.meta.dir, "..");

async function read(relativePath: string): Promise<string> {
	return readFile(join(skillRoot, relativePath), "utf8");
}

async function exists(relativePath: string): Promise<boolean> {
	return stat(join(skillRoot, relativePath)).then(
		() => true,
		() => false,
	);
}

function parseFrontmatter(skill: string) {
	const match = skill.match(/^---\n([\s\S]*?)\n---\n/u);
	expect(match).toBeTruthy();
	const frontmatterSource = match?.[1] ?? "";
	const entries = frontmatterSource
		.split("\n")
		.filter((line) => /^[a-zA-Z0-9_-]+:/.test(line));
	return Object.fromEntries(
		entries.map((line) => {
			const separator = line.indexOf(":");
			return [
				line.slice(0, separator).trim(),
				line.slice(separator + 1).trim(),
			];
		}),
	);
}

describe("ui-ux-audit-superset", () => {
	test("has valid, unambiguous metadata and a complete runtime bundle", async () => {
		const skill = await read("SKILL.md");
		const frontmatter = parseFrontmatter(skill);

		expect(frontmatter.name).toBe("ui-ux-audit-superset");
		expect(frontmatter.description).toBe(">-");
		expect(frontmatter.description).toBe(">-");
		expect(skill).toContain("audit-only by default");
		expect(frontmatter.description.length).toBeLessThanOrEqual(1024);

		for (const runtimeFile of [
			"README.md",
			"SOURCES.md",
			"references/accessibility-wcag22.md",
			"references/code-review-rules.md",
			"references/content-i18n.md",
			"references/coverage-matrix.md",
			"references/design-system.md",
			"references/forms-inputs.md",
			"references/interaction-states.md",
			"references/performance-web-quality.md",
			"references/report-template.md",
			"references/responsive-layout.md",
			"references/severity-confidence.md",
			"references/trust-safety-ui.md",
			"references/usability-ia.md",
			"references/visual-design.md",
		]) {
			expect(await exists(runtimeFile)).toBe(true);
		}
		for (const developmentFile of ["tests/tests.test.ts", "package.json"]) {
			expect(await exists(developmentFile)).toBe(true);
		}
	});

	test("keeps all bundled names and prose consistent with the skill directory", async () => {
		const markdownFiles = [
			"SKILL.md",
			"README.md",
			"SOURCES.md",
			...(await readdir(join(skillRoot, "references"))).map(
				(name) => `references/${name}`,
			),
		];
		for (const file of markdownFiles) {
			const text = await read(file);
			expect(text).not.toContain("name: ui-ux-audit\n");
			expect(text).not.toContain("ui-ux-audit/\n");
			expect(text).not.toContain("Use ui-ux-audit ");
		}
	});

	test("routes every reference and makes full-audit coverage explicit", async () => {
		const skill = await read("SKILL.md");
		const referenceFiles = (await readdir(join(skillRoot, "references")))
			.filter((name) => name.endsWith(".md"))
			.map((name) => `references/${name}`);
		for (const reference of referenceFiles) {
			expect(skill).toContain(`\`${reference}\``);
		}

		expect(skill).toContain("## Runtime evidence procedure");
		expect(skill).toContain(
			"Do not copy secrets, personal data, or customer data",
		);
		expect(skill).toContain("`references/coverage-matrix.md`");
		expect(skill).toContain("Not verified");
		expect(skill).toContain(
			"A source-only or capture-only review must be labeled",
		);
	});

	test("embeds the audit safety contract and report contract", async () => {
		const skill = await read("SKILL.md");
		for (const required of [
			"define the dimensions, weights, evidence limits, and scoring scale first",
			"label every numeric score and the overall score as **heuristic**",
			"Audit before remediation",
			"A source-only review is not a complete UI/UX audit",
			"Do not claim legal compliance",
			"Do not invent requirements",
			"Be explicit about verification gaps",
			"ID;",
			"severity;",
			"confidence;",
			"evidence;",
			"verification method",
		]) {
			expect(skill).toContain(required);
		}
		expect(skill).toContain("WCAG 2.2 Level AA");
		expect(skill).not.toContain("WCAG 2.1 A");
	});

	test("keeps reference guidance grounded and free of placeholder markers", async () => {
		for (const name of await readdir(join(skillRoot, "references"))) {
			const text = await read(`references/${name}`);
			expect(text).not.toContain("[TODO");
		}
		const report = await read("references/report-template.md");
		expect(report).toContain("## 13. Verification gaps");
		expect(report).not.toContain("WCAG compliant");
		const severity = await read("references/severity-confidence.md");
		for (const level of [
			"Blocker",
			"Critical",
			"Major",
			"Minor",
			"Opportunity",
		]) {
			expect(severity).toContain(`### ${level}`);
		}
	});

	test("keeps the eval catalog local and structurally valid", async () => {
		const catalogPath = "evals/evals.json";
		expect(await exists(catalogPath)).toBe(true);
		const catalog = JSON.parse(await read(catalogPath)) as {
			skill_name: string;
			evals: Array<{
				id: number;
				name: string;
				prompt: string;
				expected_output: string;
				files?: string[];
				expectations: string[];
			}>;
		};
		expect(catalog.skill_name).toBe("ui-ux-audit-superset");
		expect(catalog.evals).toHaveLength(8);
		expect(catalog.evals.map((item) => item.id)).toEqual([
			1, 2, 3, 4, 5, 6, 7, 8,
		]);

		const expectedNames = new Set([
			"full-runtime-audit",
			"accessibility-deep-dive",
			"scoped-remediation-review",
			"pr-ui-counterexample",
			"design-system-drift",
			"responsive-reflow-audit",
			"heuristic-scoring-contract",
			"quick-audit-boundaries",
		]);
		expect(new Set(catalog.evals.map((item) => item.name))).toEqual(
			expectedNames,
		);
		for (const evalCase of catalog.evals) {
			expect(evalCase.name).toBeTruthy();
			expect(evalCase.prompt).toBeTruthy();
			expect(evalCase.expected_output).toBeTruthy();
			expect(evalCase.expectations.length).toBeGreaterThanOrEqual(4);
			for (const file of evalCase.files ?? []) {
				const fixture = file.replace(/^fixtures\//u, "evals/fixtures/");
				expect(await exists(fixture)).toBe(true);
			}
		}

		const triggerCatalog = JSON.parse(
			await read("evals/trigger-evals.json"),
		) as Array<{ query: string; should_trigger: boolean }>;
		expect(triggerCatalog).toHaveLength(14);
		expect(triggerCatalog.filter((item) => item.should_trigger)).toHaveLength(
			10,
		);
		expect(triggerCatalog.filter((item) => !item.should_trigger)).toHaveLength(
			4,
		);

		const runner = await read("evals/run-evals.mjs");
		expect(runner).toContain("--host claude");
		expect(runner).toContain("configuration");
		expect(runner).toContain("const models = [");
		expect(runner).toContain("aggregate-only");
		expect(runner).toContain("regrade-only");
		expect(runner).toContain("snapshot");
		expect(runner).toContain("ui-ux-audit-superset");
	});

	test("all fixtures referenced by the runner are complete", async () => {
		expect(await exists("evals/fixtures/app/index.html")).toBe(true);
		expect(await exists("evals/fixtures/design-app/index.html")).toBe(true);
		expect(await exists("evals/fixtures/design-app/DESIGN_SYSTEM.md")).toBe(
			true,
		);

		const app = await readdir(join(skillRoot, "evals", "fixtures", "app"));
		const designApp = await readdir(
			join(skillRoot, "evals", "fixtures", "design-app"),
		);
		expect(app).toEqual(["index.html"]);
		expect(designApp).toEqual(["index.html", "DESIGN_SYSTEM.md"]);
	});
});
