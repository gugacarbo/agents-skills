import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const skillDirectory = path.dirname(
	path.dirname(fileURLToPath(import.meta.url)),
);
const script = path.join(skillDirectory, "scripts", "project-init.mjs");

function run(args, cwd) {
	return JSON.parse(
		execFileSync(process.execPath, [script, ...args], {
			cwd,
			encoding: "utf8",
		}),
	);
}

async function temporaryDirectory(t) {
	const directory = await mkdtemp(path.join(os.tmpdir(), "project-init-test-"));
	t.after(async () => {
		const { rm } = await import("node:fs/promises");
		await rm(directory, { recursive: true, force: true });
	});
	return directory;
}

test("lists manifest-backed templates", () => {
	const result = run(["list"], skillDirectory);
	assert.deepEqual(
		result.templates.map((template) => template.id),
		[
			"base-only",
			"bun",
			"typescript",
			"typescript/node",
			"typescript/tanstack-start",
			"typescript/vite",
		],
	);
});

test("plans then applies Node with only CSpell assets", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "api-core");
	const args = [
		"--template",
		"typescript/node",
		"--target",
		target,
		"--optional",
		"cspell",
	];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.stack, ["_base", "typescript", "typescript/node"]);
	assert.equal(plan.commands.install[0].includes("@biomejs/biome"), true);
	assert.equal(
		plan.files.some((file) => file.target === ".lintstagedrc.js"),
		false,
	);
	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	for (const file of [
		"AGENTS.md",
		"REQUIREMENTS.md",
		".editorconfig",
		".gitignore",
		"knip.json",
		"cspell.config.yaml",
		".husky/pre-commit",
		".husky/pre-push",
		"scripts/pre-commit",
		"scripts/pre-push",
		"scripts/lib/shared.sh",
	]) {
		assert.equal((await stat(path.join(target, file))).isFile(), true, file);
	}
	const agents = await readFile(path.join(target, "AGENTS.md"), "utf8");
	assert.match(agents, /## General/);
	assert.match(agents, /Node\.js LTS/);
	assert.doesNotMatch(agents, /request_user_input/);
	const knip = await readFile(path.join(target, "knip.json"), "utf8");
	assert.doesNotMatch(knip, /lite-llm|shadcn|tailwindcss/);
});

test("keeps Vite plan-only until the generator has created package.json", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "web-ui");
	const plan = run(
		[
			"plan",
			"--template",
			"typescript/vite",
			"--target",
			target,
			"--variant",
			"svelte-ts",
		],
		directory,
	);
	assert.equal(
		plan.lifecycle.frameworkCommand,
		"pnpm create vite . --template svelte-ts",
	);
	assert.equal(plan.commands.typecheck, "svelte-check");
	assert.equal(plan.lifecycle.frameworkReady, false);
	assert.equal(plan.targetExists, false);
});

test("plans TanStack Start before overlay without redundant framework packages", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "dashboard");
	const plan = run(
		["plan", "--template", "typescript/tanstack-start", "--target", target],
		directory,
	);
	assert.equal(
		plan.lifecycle.frameworkCommand,
		"pnpm dlx create-tanstack-app@latest dashboard --template file-router --package-manager pnpm",
	);
	assert.match(
		plan.notes.join("\n"),
		/full-stack React.*server-side rendering.*Vite/i,
	);
	assert.match(plan.notes.join("\n"), /src\/routeTree\.gen\.ts/);
	assert.doesNotMatch(
		plan.commands.install.join("\n"),
		/@tanstack\/react-(?:start|router)/,
	);
	assert.equal(plan.targetExists, false);
});

test("requires exact collision approval and preserves unrelated files", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "existing-app");
	await mkdir(target);
	await writeFile(path.join(target, "AGENTS.md"), "existing agents\n");
	await writeFile(path.join(target, "README.md"), "keep me\n");
	const args = ["--template", "base-only", "--target", target];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.collisions, ["AGENTS.md"]);
	assert.equal(
		plan.files.some((file) => file.target === "README.md"),
		false,
	);
	const refused = spawnSync(process.execPath, [script, "apply", ...args], {
		cwd: directory,
		encoding: "utf8",
	});
	assert.equal(refused.status, 2);
	assert.equal(
		await readFile(path.join(target, "AGENTS.md"), "utf8"),
		"existing agents\n",
	);
	const applied = run(["apply", ...args, "--approve", "AGENTS.md"], directory);
	assert.deepEqual(applied.overwritten, ["AGENTS.md"]);
	assert.equal(
		await readFile(path.join(target, "README.md"), "utf8"),
		"keep me\n",
	);
	assert.equal(
		(await stat(path.join(target, "REQUIREMENTS.md"))).isFile(),
		true,
	);
});

test("renders Bun-aware hooks without repository-specific commands", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "bun-worker");
	const args = ["--template", "bun", "--target", target, "--optional", "turbo"];
	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	assert.deepEqual(applied.selectedOptionalTools, ["turbo"]);
	const shared = await readFile(
		path.join(target, "scripts/lib/shared.sh"),
		"utf8",
	);
	const prePush = await readFile(path.join(target, "scripts/pre-push"), "utf8");
	assert.match(shared, /PACKAGE_MANAGER="bun"/);
	assert.doesNotMatch(`${shared}\n${prePush}`, /release:verify|pnpm/);
	assert.equal(applied.commands.optional[0], "bun add -d turbo");
	assert.match(applied.commands.install[0], /@biomejs\/biome/);
});
