import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import {
	cp,
	mkdir,
	mkdtemp,
	readFile,
	stat,
	symlink,
	writeFile,
} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const skillDirectory = path.dirname(
	path.dirname(fileURLToPath(import.meta.url)),
);
const script = path.join(skillDirectory, "scripts", "project-init.mjs");

function run(args, cwd, selectedScript = script) {
	return JSON.parse(
		execFileSync(process.execPath, [selectedScript, ...args], {
			cwd,
			encoding: "utf8",
		}),
	);
}

function runResult(args, cwd, selectedScript = script) {
	const result = spawnSync(process.execPath, [selectedScript, ...args], {
		cwd,
		encoding: "utf8",
	});
	return {
		status: result.status,
		stdout: result.stdout,
		stderr: result.stderr,
		json: JSON.parse(result.stdout),
	};
}

async function temporaryDirectory(t) {
	const directory = await mkdtemp(path.join(os.tmpdir(), "project-init-test-"));
	t.after(async () => {
		const { rm } = await import("node:fs/promises");
		await rm(directory, { recursive: true, force: true });
	});
	return directory;
}

async function writeJson(filePath, value) {
	await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

test("lists templates with inherited complete optional tools", () => {
	const result = run(["list"], skillDirectory);
	assert.deepEqual(
		result.templates.map((template) => template.id),
		[
			"base",
			"bun",
			"typescript",
			"typescript/node",
			"typescript/tanstack-start",
			"typescript/vite",
		],
	);
	const base = result.templates.find((template) => template.id === "base");
	assert.deepEqual(
		base.optionalTools.map((tool) => tool.id),
		["ci-github-actions"],
	);
	const node = result.templates.find(
		(template) => template.id === "typescript/node",
	);
	assert.deepEqual(
		node.optionalTools.map((tool) => tool.id),
		[
			"ci-github-actions",
			"cspell",
			"env",
			"secrets",
			"format",
			"lint-staged",
			"docker",
		],
	);
	const bun = result.templates.find((template) => template.id === "bun");
	assert.deepEqual(
		bun.optionalTools.map((tool) => tool.id),
		[
			"ci-github-actions",
			"cspell",
			"env",
			"secrets",
			"format",
			"docker",
			"lint-staged",
		],
	);
});

test("plans and applies a complete Node overlay with CSpell", async (t) => {
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
	assert.deepEqual(plan.stack, ["base", "typescript", "typescript/node"]);
	assert.equal(plan.lifecycle.frameworkCommand, null);
	assert.equal(plan.commands.setup.includes("pnpm exec husky init"), false);
	assert.match(
		plan.commands.install.join("\n"),
		/^pnpm --allow-build=esbuild add -D /m,
	);
	assert.match(plan.commands.install.join("\n"), /@biomejs\/biome/);
	assert.match(plan.commands.optional.join("\n"), /cspell/);
	assert.deepEqual(plan.collisions, []);

	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	for (const file of [
		"AGENTS.md",
		"REQUIREMENTS.md",
		".editorconfig",
		".gitignore",
		"biome.json",
		"knip.json",
		"tsconfig.json",
		"src/index.ts",
		"package.json",
		"cspell.config.yaml",
		".husky/pre-commit",
		".husky/pre-push",
		"scripts/pre-commit",
		"scripts/pre-push",
		"scripts/lib/shared.sh",
	]) {
		assert.equal((await stat(path.join(target, file))).isFile(), true, file);
	}
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.equal(packageJson.scripts.prepare, "husky");
	assert.equal(packageJson.scripts.typecheck, "tsc --noEmit");
	assert.equal(packageJson.scripts.spellcheck, "cspell .");
	assert.equal(packageJson.scripts.dev, "tsx watch src/index.ts");
	assert.equal(
		await stat(path.join(target, "scripts/pre-commit")).then(
			(item) => item.mode & 0o111,
		),
		0o111,
	);
});

test("plans nested Vite targets from their absolute parent", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "apps", "customer portal");
	const plan = run(
		[
			"plan",
			"--template",
			"typescript/vite",
			"--target",
			target,
			"--name",
			"customer-portal",
			"--variant",
			"svelte-ts",
		],
		directory,
	);
	assert.equal(
		plan.lifecycle.frameworkCommand,
		"pnpm create vite 'customer portal' --template svelte-ts",
	);
	assert.equal(plan.lifecycle.frameworkCwd, path.dirname(target));
	assert.equal(plan.commands.typecheck, "pnpm run typecheck");
	assert.equal(
		plan.packageChanges.find(
			(change) => change.pointer === "/scripts/typecheck",
		)?.after,
		"svelte-check --tsconfig ./tsconfig.app.json && tsc -p tsconfig.node.json",
	);
	assert.match(plan.commands.install.join("\n"), /svelte-check/);
	assert.equal(plan.lifecycle.frameworkReady, false);
	assert.deepEqual(plan.lifecycle.missingPackages, ["vite", "svelte"]);
	assert.equal(
		await stat(target)
			.then(() => true)
			.catch(() => false),
		false,
	);
});

test("composes framework-specific Vite typecheck scripts", async (t) => {
	const directory = await temporaryDirectory(t);
	const variants = {
		"vanilla-ts": "tsc --noEmit",
		"react-ts": "tsc -b",
		"vue-ts": "vue-tsc -b",
		"svelte-ts":
			"svelte-check --tsconfig ./tsconfig.app.json && tsc -p tsconfig.node.json",
	};
	for (const [variant, expected] of Object.entries(variants)) {
		const plan = run(
			[
				"plan",
				"--template",
				"typescript/vite",
				"--target",
				path.join(directory, variant),
				"--variant",
				variant,
			],
			directory,
		);
		assert.equal(
			plan.packageChanges.find(
				(change) => change.pointer === "/scripts/typecheck",
			)?.after,
			expected,
			variant,
		);
		assert.equal(plan.commands.typecheck, "pnpm run typecheck", variant);
		assert.equal(
			plan.files.some((file) => file.target === "vitest.config.ts"),
			true,
			variant,
		);
	}
});

test("removes Vite React's replaced linter dependency with scoped approval", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "react-app");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "react-app",
		private: true,
		type: "module",
		scripts: {
			dev: "vite",
			build: "tsc -b && vite build",
			lint: "oxlint",
		},
		dependencies: { react: "latest" },
		devDependencies: { oxlint: "latest", vite: "latest" },
	});
	const args = [
		"--template",
		"typescript/vite",
		"--target",
		target,
		"--variant",
		"react-ts",
	];
	const plan = run(["plan", ...args], directory);
	assert.equal(
		plan.packageChanges.some(
			(change) =>
				change.pointer === "/devDependencies/oxlint" &&
				change.status === "remove",
		),
		true,
	);
	assert.deepEqual(plan.collisions, [
		"package.json#/scripts/lint",
		"package.json#/devDependencies/oxlint",
	]);
	const applied = run(
		[
			"apply",
			...args,
			"--approve",
			"package.json#/devDependencies/oxlint,package.json#/scripts/lint",
		],
		directory,
	);
	assert.equal(applied.applied, true);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.equal(packageJson.devDependencies.oxlint, undefined);
	assert.equal(packageJson.devDependencies.vite, "latest");
});

test("requires framework-specific Vite readiness markers", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "web-ui");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "web-ui",
		private: true,
		type: "module",
		dependencies: { vite: "latest" },
	});
	const args = [
		"plan",
		"--template",
		"typescript/vite",
		"--target",
		target,
		"--variant",
		"react-ts",
	];
	const incomplete = run(args, directory);
	assert.equal(incomplete.lifecycle.frameworkReady, false);
	assert.deepEqual(incomplete.lifecycle.missingPackages, ["react"]);

	await writeJson(path.join(target, "package.json"), {
		name: "web-ui",
		private: true,
		type: "module",
		dependencies: { vite: "latest", react: "latest" },
	});
	const ready = run(args, directory);
	assert.equal(ready.lifecycle.frameworkReady, true);
	assert.deepEqual(ready.lifecycle.missingPackages, []);
});

test("plans TanStack Start with its current generator contract", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "products", "dashboard");
	const plan = run(
		["plan", "--template", "typescript/tanstack-start", "--target", target],
		directory,
	);
	assert.equal(
		plan.lifecycle.frameworkCommand,
		"pnpm dlx @tanstack/cli@latest create dashboard --package-manager pnpm --toolchain biome --no-examples --no-intent --yes",
	);
	assert.equal(plan.lifecycle.frameworkCwd, path.dirname(target));
	assert.match(plan.notes.join("\n"), /full-stack React.*Vite/i);
	assert.match(plan.notes.join("\n"), /src\/routeTree\.gen\.ts/);
	assert.equal(plan.lifecycle.frameworkReady, false);
	assert.equal(
		plan.files.some((file) => file.target === "biome.json"),
		false,
	);
	assert.equal(
		plan.files.some((file) => file.target === "vitest.config.ts"),
		true,
	);
	assert.equal(
		plan.packageChanges.find((change) => change.pointer === "/scripts/test")
			?.after,
		"vitest run --config vitest.config.ts --passWithNoTests",
	);
	assert.match(
		plan.commands.install.join("\n"),
		/pnpm --allow-build=esbuild --allow-build=lightningcss add -D/,
	);
	assert.deepEqual(plan.commands.setup, [
		"pnpm exec biome migrate --write",
		"pnpm run prepare",
	]);
});

test("removes obsolete TanStack pnpm policy with scoped approval", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "dashboard");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "dashboard",
		private: true,
		type: "module",
		scripts: {
			dev: "vite dev",
			build: "vite build",
			lint: "biome lint",
			format: "biome format",
		},
		dependencies: { "@tanstack/react-start": "latest" },
		devDependencies: { "@biomejs/biome": "2.4.5" },
		pnpm: { onlyBuiltDependencies: ["esbuild", "lightningcss"] },
		custom: { preserved: true },
	});
	const args = ["--template", "typescript/tanstack-start", "--target", target];
	const plan = run(["plan", ...args], directory);
	assert.equal(plan.lifecycle.frameworkReady, true);
	assert.equal(
		plan.packageChanges.some(
			(change) =>
				change.pointer === "/pnpm/onlyBuiltDependencies" &&
				change.status === "remove",
		),
		true,
	);
	assert.equal(
		plan.collisions.includes("package.json#/pnpm/onlyBuiltDependencies"),
		true,
	);
	const applied = run(
		[
			"apply",
			...args,
			"--approve",
			"package.json#/scripts/format,package.json#/pnpm/onlyBuiltDependencies",
		],
		directory,
	);
	assert.equal(applied.applied, true);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.equal(packageJson.pnpm, undefined);
	assert.deepEqual(packageJson.custom, { preserved: true });
});

test("merges package.json semantically with field-level approval", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "library");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "library",
		private: true,
		type: "module",
		scripts: {
			dev: "custom-dev",
			lint: "eslint .",
		},
		custom: { preserved: true },
	});
	const args = ["--template", "typescript", "--target", target];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.collisions, [
		"package.json#/scripts/dev",
		"package.json#/scripts/lint",
	]);
	assert.equal(
		plan.packageChanges.some(
			(change) =>
				change.pointer === "/scripts/typecheck" && change.status === "add",
		),
		true,
	);
	const refused = runResult(["apply", ...args], directory);
	assert.equal(refused.status, 2);
	assert.deepEqual(refused.json.unapproved, plan.collisions);

	const applied = run(
		[
			"apply",
			...args,
			"--approve",
			"package.json#/scripts/dev,package.json#/scripts/lint",
		],
		directory,
	);
	assert.deepEqual(applied.merged, ["package.json"]);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.deepEqual(packageJson.custom, { preserved: true });
	assert.equal(packageJson.scripts.dev, "tsc --watch");
	assert.equal(packageJson.scripts.lint, "biome lint .");
	assert.equal(packageJson.scripts.prepare, "husky");
});

test("requires exact file approval and preserves unrelated files", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "existing-app");
	await mkdir(target);
	await writeFile(path.join(target, "AGENTS.md"), "existing agents\n");
	await writeFile(path.join(target, "README.md"), "keep me\n");
	const args = ["--template", "base", "--target", target];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.collisions, ["AGENTS.md"]);
	assert.equal(
		plan.files.some((file) => file.target === "README.md"),
		false,
	);
	const refused = runResult(["apply", ...args], directory);
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
});

test("rejects the removed base-only template id", async (t) => {
	const directory = await temporaryDirectory(t);
	const result = runResult(
		[
			"plan",
			"--template",
			"base-only",
			"--target",
			path.join(directory, "app"),
		],
		directory,
	);
	assert.equal(result.status, 1);
	assert.equal(result.json.ok, false);
	assert.match(result.json.error, /Unknown template: base-only/);
});

test("rejects unknown CLI flags with structured JSON", async (t) => {
	const directory = await temporaryDirectory(t);
	const result = runResult(
		[
			"plan",
			"--template",
			"base",
			"--target",
			path.join(directory, "app"),
			"--opitonal",
			"cspell",
		],
		directory,
	);
	assert.equal(result.status, 1);
	assert.equal(result.json.ok, false);
	assert.match(result.json.error, /Unknown option/);
});

test("rejects symlink destinations before planning writes", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "app");
	const external = path.join(directory, "external-agents.md");
	await mkdir(target);
	await writeFile(external, "outside\n");
	await symlink(external, path.join(target, "AGENTS.md"));
	const result = runResult(
		["plan", "--template", "base", "--target", target],
		directory,
	);
	assert.equal(result.status, 1);
	assert.match(result.json.error, /Symlinks are not allowed/);
	assert.equal(await readFile(external, "utf8"), "outside\n");
});

test("rejects manifest targets that escape the destination", async (t) => {
	const directory = await temporaryDirectory(t);
	const copiedSkill = path.join(directory, "project-init");
	await cp(skillDirectory, copiedSkill, { recursive: true });
	const manifestPath = path.join(
		copiedSkill,
		"templates",
		"base",
		"template.json",
	);
	const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
	manifest.files.push({
		source: "files/.editorconfig",
		target: "../escaped",
	});
	await writeJson(manifestPath, manifest);
	const result = runResult(
		["plan", "--template", "base", "--target", path.join(directory, "target")],
		directory,
		path.join(copiedSkill, "scripts", "project-init.mjs"),
	);
	assert.equal(result.status, 1);
	assert.match(result.json.error, /Invalid output target/);
	assert.equal(
		await stat(path.join(directory, "escaped"))
			.then(() => true)
			.catch(() => false),
		false,
	);
});

test("plans and applies a Node overlay with docker, env, secrets, and ci-github-actions", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "service");
	const args = [
		"--template",
		"typescript/node",
		"--target",
		target,
		"--optional",
		"docker,env,secrets,ci-github-actions",
	];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.collisions, []);
	for (const optional of ["docker", "env", "secrets", "ci-github-actions"]) {
		assert.equal(plan.selectedOptionalTools.includes(optional), true, optional);
	}
	assert.equal(
		plan.files.some((file) => file.target === "Dockerfile"),
		true,
		"Dockerfile planned",
	);
	assert.equal(
		plan.files.some((file) => file.target === ".dockerignore"),
		true,
		".dockerignore planned",
	);
	assert.equal(
		plan.files.some((file) => file.target === ".env.example"),
		true,
		".env.example planned",
	);
	assert.equal(
		plan.files.some((file) => file.target === "scripts/gitleaks-check"),
		true,
		"gitleaks-check planned",
	);
	assert.equal(
		plan.files.some((file) => file.target === ".github/workflows/CI.yaml"),
		true,
		"CI workflow planned",
	);
	assert.match(plan.commands.optional.join("\n"), /@t3-oss\/env-core/);
	assert.match(plan.commands.optional.join("\n"), /zod/);
	assert.match(
		plan.notes.join("\n"),
		/@t3-oss\/env-core/,
		"env planNote present",
	);

	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	for (const file of [
		"Dockerfile",
		".dockerignore",
		".env.example",
		"scripts/gitleaks-check",
		".github/workflows/CI.yaml",
	]) {
		assert.equal((await stat(path.join(target, file))).isFile(), true, file);
	}
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.equal(
		packageJson.scripts["secrets:check"],
		"sh scripts/gitleaks-check",
	);
	const gitleaksCheck = await readFile(
		path.join(target, "scripts/gitleaks-check"),
		"utf8",
	);
	assert.match(gitleaksCheck, /gitleaks protect/);
	assert.match(gitleaksCheck, /AVISO/);
	const preCommit = await readFile(
		path.join(target, "scripts/pre-commit"),
		"utf8",
	);
	assert.match(preCommit, /scripts\/gitleaks-check/);
	assert.match(preCommit, /run_pm run secrets:check/);
	const dockerfile = await readFile(path.join(target, "Dockerfile"), "utf8");
	assert.match(dockerfile, /node:22-alpine/);
	assert.match(dockerfile, /USER node/);
});

test("plans a Bun service with the Bun-specific Dockerfile", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "bun-service");
	const plan = run(
		["plan", "--template", "bun", "--target", target, "--optional", "docker"],
		directory,
	);
	assert.equal(plan.lifecycle.frameworkReady, false);
	assert.equal(
		plan.files.some((file) => file.target === "Dockerfile"),
		true,
	);
});

test("plans the static-serving Vite Dockerfile", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "web");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "web",
		private: true,
		type: "module",
		dependencies: { vite: "latest", react: "latest" },
	});
	const plan = run(
		[
			"plan",
			"--template",
			"typescript/vite",
			"--target",
			target,
			"--variant",
			"react-ts",
			"--optional",
			"docker",
		],
		directory,
	);
	assert.equal(
		plan.files.some((file) => file.target === "Dockerfile"),
		true,
	);
	const dockerfileOutput = plan.files.find((f) => f.target === "Dockerfile");
	assert.equal(dockerfileOutput.origin, "typescript/vite");
});

test("the Vite vitest config ships v8 coverage thresholds", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "web-ui");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "web-ui",
		private: true,
		type: "module",
		dependencies: { vite: "latest", react: "latest" },
	});
	const plan = run(
		[
			"plan",
			"--template",
			"typescript/vite",
			"--target",
			target,
			"--variant",
			"react-ts",
		],
		directory,
	);
	assert.equal(plan.lifecycle.frameworkReady, true);
	const vitest = await readFile(
		path.join(
			skillDirectory,
			"templates",
			"typescript",
			"vite",
			"files",
			"vitest.config.ts",
		),
		"utf8",
	);
	assert.match(vitest, /provider: "v8"/);
	assert.match(vitest, /lines: 90/);
	assert.match(vitest, /pool: "threads"/);
	assert.match(vitest, /environment: "node"/);
});

test("the format tool overlays Markdown/shell formatting onto the base format script", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "fmt-app");
	const args = [
		"--template",
		"typescript/node",
		"--target",
		target,
		"--optional",
		"format",
	];
	const plan = run(["plan", ...args], directory);
	assert.deepEqual(plan.collisions, []);
	assert.match(
		plan.packageChanges.find((change) => change.pointer === "/scripts/format")
			.after,
		/biome format --write/,
	);
	assert.match(plan.commands.optional.join("\n"), /prettier-plugin-sh/);
	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	assert.equal(applied.created.includes("package.json"), true);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.equal(typeof packageJson.scripts["format:md"], "string");
	assert.equal(typeof packageJson.scripts["format:sh"], "string");
	assert.match(packageJson.scripts.format, /format:md/);
	assert.match(packageJson.scripts.format, /format:sh/);
});

test("the format tool requires approval when an existing format script conflicts", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "fmt-existing");
	await mkdir(target);
	await writeJson(path.join(target, "package.json"), {
		name: "fmt-existing",
		private: true,
		type: "module",
		scripts: { format: "custom-formatter" },
	});
	const args = [
		"--template",
		"typescript/node",
		"--target",
		target,
		"--optional",
		"format",
	];
	const plan = run(["plan", ...args], directory);
	assert.equal(plan.collisions.includes("package.json#/scripts/format"), true);
	const applied = run(
		[
			"apply",
			...args,
			"--approve",
			plan.collisions
				.filter((collision) => collision.startsWith("package.json#/scripts/"))
				.join(","),
		],
		directory,
	);
	assert.equal(applied.applied, true);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.doesNotMatch(
		packageJson.scripts.format,
		/custom-formatter/,
		"existing format script was replaced",
	);
});

test("the lint-staged tool adds test-staged and keeps a single pre-commit hook", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "ls-app");
	const args = [
		"--template",
		"typescript/node",
		"--target",
		target,
		"--optional",
		"lint-staged",
	];
	const plan = run(["plan", ...args], directory);
	assert.match(plan.commands.optional.join("\n"), /test-staged/);
	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	const lintStagedRc = await readFile(
		path.join(target, ".lintstagedrc.js"),
		"utf8",
	);
	assert.match(lintStagedRc, /test-staged/);
	const preCommit = await readFile(
		path.join(target, "scripts/pre-commit"),
		"utf8",
	);
	assert.match(preCommit, /\.lintstagedrc\.js/);
	assert.match(preCommit, /run_pm run lint-staged/);
});

test("applies Bun tooling only after Bun readiness and renders Bun commands", async (t) => {
	const directory = await temporaryDirectory(t);
	const target = path.join(directory, "workers", "bun-worker");
	const prePlan = run(
		["plan", "--template", "bun", "--target", target],
		directory,
	);
	assert.equal(prePlan.lifecycle.frameworkReady, false);
	assert.equal(prePlan.lifecycle.frameworkCommand, "bun init --yes bun-worker");
	assert.equal(prePlan.lifecycle.frameworkCwd, path.dirname(target));

	await mkdir(target, { recursive: true });
	await writeJson(path.join(target, "package.json"), {
		name: "bun-worker",
		private: true,
		type: "module",
		devDependencies: { "@types/bun": "latest" },
	});
	await writeJson(path.join(target, "tsconfig.json"), {
		compilerOptions: { types: ["bun"] },
	});
	const args = [
		"--template",
		"bun",
		"--target",
		target,
		"--optional",
		"lint-staged",
	];
	const plan = run(["plan", ...args], directory);
	assert.equal(plan.lifecycle.frameworkReady, true);
	assert.match(plan.commands.optional.join("\n"), /lint-staged/);
	const applied = run(["apply", ...args], directory);
	assert.equal(applied.applied, true);
	const lintStaged = await readFile(
		path.join(target, ".lintstagedrc.js"),
		"utf8",
	);
	const preCommit = await readFile(
		path.join(target, "scripts/pre-commit"),
		"utf8",
	);
	const packageJson = JSON.parse(
		await readFile(path.join(target, "package.json"), "utf8"),
	);
	assert.match(lintStaged, /bunx biome/);
	assert.doesNotMatch(lintStaged, /pnpm/);
	assert.match(preCommit, /run_pm run lint-staged/);
	assert.equal(packageJson.scripts.test, "bun test --pass-with-no-tests");
	assert.equal(packageJson.scripts.typecheck, "tsc --noEmit --types bun");
});
