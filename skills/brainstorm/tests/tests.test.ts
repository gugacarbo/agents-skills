import { describe, test } from "bun:test";
import { existsSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import {
	cleanup,
	expectSuccess,
	makeTempDir,
	run,
} from "../../../src/tests/helpers";

const skillRoot = resolve(import.meta.dir, "..");

describe("brainstorm skill", () => {
	for (const relativePath of [
		"SKILL.md",
		"references/brainstorm.md",
		"references/visual-companion.md",
		"scripts/visual-companion",
		"scripts/visual-companion/server.cjs",
		"scripts/visual-companion/start-server.sh",
		"scripts/visual-companion/stop-server.sh",
		"scripts/visual-companion/helper.js",
		"scripts/visual-companion/frame-template.html",
	]) {
		test(`contains ${relativePath}`, () => {
			if (!existsSync(join(skillRoot, relativePath))) {
				throw new Error(`missing ${relativePath}`);
			}
		});
	}

	for (const scriptName of ["start-server.sh", "stop-server.sh"]) {
		test(`${scriptName} has valid shell syntax`, () => {
			const script = join(skillRoot, "scripts", "visual-companion", scriptName);
			const result = run(["sh", "-n", script]);
			expectSuccess(result);
		});
	}

	test("server.cjs builds for Bun", () => {
		const temporaryRoot = makeTempDir("brainstorm-server-test");
		try {
			const source = join(
				skillRoot,
				"scripts",
				"visual-companion",
				"server.cjs",
			);
			const output = join(temporaryRoot, basename(source));
			const result = run([
				"bun",
				"build",
				"--target=bun",
				source,
				"--outfile",
				output,
			]);
			expectSuccess(result);
		} finally {
			cleanup(temporaryRoot);
		}
	});
});
