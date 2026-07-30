import { describe, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { join } from "node:path";
import {
	append,
	cleanup,
	copy,
	createRuntimeRepo,
	expectAbsent,
	expectExists,
	expectSuccess,
	makeTempDir,
	read,
	run,
	write,
} from "./helpers";

async function waitForContent(path: string, expected: string): Promise<void> {
	for (let attempt = 0; attempt < 50; attempt += 1) {
		if (existsSync(path) && read(path).includes(expected)) {
			return;
		}
		await Bun.sleep(100);
	}
	throw new Error(`timed out waiting for ${path} to contain: ${expected}`);
}

describe("development watcher", () => {
	test("builds once without publishing globally", () => {
		const root = createRuntimeRepo("dev-once-test", ["commit-changes"]);
		const buildOutput = join(root, "build-output");
		try {
			const result = run(["sh", join(root, "src", "dev.sh")], {
				env: {
					HOME: join(root, "home"),
					AGENTS_SKILLS_BUILD_OUTPUT: buildOutput,
					AGENTS_SKILLS_WATCH_ONCE: "1",
				},
			});
			expectSuccess(result);
			expectExists(join(buildOutput, "commit-changes", "SKILL.md"));
			expectAbsent(join(root, "home", ".agents", "skills"));
		} finally {
			cleanup(root);
		}
	});

	test("rebuilds after a source change", async () => {
		const temporaryRoot = makeTempDir("dev-watch-test");
		const project = join(temporaryRoot, "project");
		const buildOutput = join(temporaryRoot, "build-output");
		const testBin = join(temporaryRoot, "bin");
		const testSleep = join(testBin, "sleep");
		const stdoutPath = join(temporaryRoot, "stdout.log");
		const stderrPath = join(temporaryRoot, "stderr.log");
		copy(
			join(import.meta.dir, "..", "build.sh"),
			join(project, "src", "build.sh"),
		);
		copy(join(import.meta.dir, "..", "dev.sh"), join(project, "src", "dev.sh"));
		write(testSleep, "#!/usr/bin/env sh\nexec /bin/sleep 0.01\n");
		expectSuccess(run(["chmod", "+x", testSleep]));
		write(
			join(project, "skills", "example-skill", "SKILL.md"),
			"---\nname: example-skill\nversion: initial\n---\n",
		);

		const process = Bun.spawn({
			cmd: ["sh", join(project, "src", "dev.sh")],
			env: {
				...Bun.env,
				AGENTS_SKILLS_BUILD_OUTPUT: buildOutput,
				PATH: `${testBin}:${Bun.env.PATH}`,
			},
			stdout: Bun.file(stdoutPath),
			stderr: Bun.file(stderrPath),
		});

		try {
			const builtSkill = join(buildOutput, "example-skill", "SKILL.md");
			await waitForContent(builtSkill, "version: initial");
			append(
				join(project, "skills", "example-skill", "SKILL.md"),
				"version: updated\n",
			);
			await waitForContent(builtSkill, "version: updated");
			process.kill("SIGTERM");
			const exitCode = await process.exited;
			expect(exitCode, `${read(stdoutPath)}${read(stderrPath)}`).toBe(0);
		} finally {
			if (process.exitCode === null) {
				process.kill("SIGKILL");
				await process.exited;
			}
			cleanup(temporaryRoot);
		}
	}, 10_000);
});
