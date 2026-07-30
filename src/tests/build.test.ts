import { describe, test } from "bun:test";
import { join } from "node:path";
import {
	cleanup,
	copy,
	ensureDir,
	expectAbsent,
	expectExists,
	expectFailure,
	expectSuccess,
	makeTempDir,
	REPO_ROOT,
	run,
	write,
} from "./helpers";

describe("skill build", () => {
	test("copies skills, strips private artifacts, and replaces stale deployments", () => {
		const temporaryRoot = makeTempDir("build-test");
		const project = join(temporaryRoot, "project");
		const output = join(temporaryRoot, "generated-skills");
		const target = join(temporaryRoot, "installed-skills");
		const fixtureName = "build-test-fixture";
		const fixture = join(project, "skills", fixtureName);

		try {
			copy(
				join(REPO_ROOT, "src", "build.sh"),
				join(project, "src", "build.sh"),
			);
			copy(join(REPO_ROOT, "skills"), join(project, "skills"));

			const ignoredDirectories = [
				"node_modules/package",
				".pnpm-store",
				"build",
				"out",
				".next",
				".nuxt",
				".idea",
				"logs",
				"coverage",
				".cache",
				"__pycache__",
				".turbo",
				".code-flow",
			];
			for (const directory of ignoredDirectories) {
				ensureDir(join(fixture, directory));
			}

			write(join(fixture, "SKILL.md"), "fixture\n");
			write(join(fixture, ".gitignore"), "keep\n");
			write(join(fixture, ".env.example"), "keep\n");
			for (const file of [
				".env",
				".env.local",
				"swap.swp",
				"swap.swo",
				"backup~",
				".DS_Store",
				"Thumbs.db",
				"build.log",
				"state.tsbuildinfo",
				"__pycache__/module.pyc",
			]) {
				write(join(fixture, file), "ignored\n");
			}
			write(join(output, "stale-skill", "SKILL.md"), "stale\n");

			const firstBuild = run(["sh", join(project, "src", "build.sh")], {
				env: {
					AGENTS_SKILLS_BUILD_OUTPUT: output,
					AGENTS_SKILLS_BUILD_TARGET: target,
				},
			});
			expectSuccess(firstBuild);

			expectExists(join(output, "commit-changes", "SKILL.md"));
			expectExists(join(output, "code-flow", "SKILL.md"));
			expectAbsent(join(output, "stale-skill"));
			expectAbsent(join(output, "skill-master", "dev"));
			expectAbsent(join(output, "code-flow", "tests"));
			expectAbsent(join(output, "skill-master", "package.json"));
			expectAbsent(join(output, "code-flow", "package.json"));
			expectExists(join(output, fixtureName, "SKILL.md"));
			expectExists(join(output, fixtureName, ".gitignore"));
			expectExists(join(output, fixtureName, ".env.example"));

			for (const ignoredPath of [
				"node_modules",
				".pnpm-store",
				"build",
				"out",
				".next",
				".nuxt",
				".idea",
				"logs",
				"coverage",
				".cache",
				"__pycache__",
				".turbo",
				".code-flow",
				".env",
				".env.local",
				"swap.swp",
				"swap.swo",
				"backup~",
				".DS_Store",
				"Thumbs.db",
				"build.log",
				"state.tsbuildinfo",
			]) {
				expectAbsent(join(output, fixtureName, ignoredPath));
			}

			write(join(target, "code-toolbox", "SKILL.md"), "legacy\n");
			write(
				join(target, "code-flow", "templates", "obsolete-template.md"),
				"stale\n",
			);
			write(join(target, "external-skill", "SKILL.md"), "external\n");
			write(join(target, ".external-config"), "hidden\n");

			const secondBuild = run(["sh", join(project, "src", "build.sh")], {
				env: {
					AGENTS_SKILLS_BUILD_OUTPUT: output,
					AGENTS_SKILLS_BUILD_TARGET: target,
				},
			});
			expectSuccess(secondBuild);

			expectExists(join(target, "code-flow", "SKILL.md"));
			expectAbsent(join(target, "code-toolbox"));
			expectAbsent(
				join(target, "code-flow", "templates", "obsolete-template.md"),
			);
			expectAbsent(join(target, "external-skill"));
			expectAbsent(join(target, ".external-config"));
			expectAbsent(join(target, "skill-master", "dev"));
			expectAbsent(join(target, "code-flow", "tests"));
			expectAbsent(join(target, "skill-master", "package.json"));
			expectAbsent(join(target, "code-flow", "package.json"));
			expectAbsent(join(target, fixtureName, "__pycache__"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("rejects using the output directory as deployment target", () => {
		const temporaryRoot = makeTempDir("build-target-test");
		const project = join(temporaryRoot, "project");
		const output = join(temporaryRoot, "skills");

		try {
			copy(
				join(REPO_ROOT, "src", "build.sh"),
				join(project, "src", "build.sh"),
			);
			copy(join(REPO_ROOT, "skills"), join(project, "skills"));
			const result = run(["sh", join(project, "src", "build.sh")], {
				env: {
					AGENTS_SKILLS_BUILD_OUTPUT: output,
					AGENTS_SKILLS_BUILD_TARGET: output,
				},
			});
			expectFailure(result);
		} finally {
			cleanup(temporaryRoot);
		}
	});
});
