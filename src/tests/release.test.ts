import { test } from "bun:test";
import { join } from "node:path";
import {
	cleanup,
	copy,
	createRuntimeRepo,
	expectAbsent,
	expectFileContains,
	expectSuccess,
	makeTempDir,
	REPO_ROOT,
	read,
	run,
	write,
} from "./helpers";

test("release package installs and updates skills without source tooling", () => {
	const root = createRuntimeRepo("release-package", ["sample"]);
	const temporary = makeTempDir("release-consumer");
	try {
		copy(
			join(REPO_ROOT, "scripts", "package-release.sh"),
			join(root, "scripts", "package-release.sh"),
		);
		write(join(root, "skills", "sample", "package.json"), "{}");
		write(join(root, "skills", "sample", "tests", "private.txt"), "private");
		const archive = join(temporary, "agents-skills.tar.gz");
		expectSuccess(
			run(["sh", join(root, "src", "build.sh")], {
				env: { AGENTS_SKILLS_BUILD_DEPLOY: "0" },
			}),
		);
		expectSuccess(
			run(["sh", join(root, "scripts", "package-release.sh"), archive]),
		);
		const target = join(temporary, "installed");
		const env = { AGENTS_SKILLS_ARCHIVE_URL: `file://${archive}` };
		expectSuccess(
			run(["sh", "-s", "--", "install", "--path", target, "--yes"], {
				cwd: temporary,
				env,
				stdin: read(join(root, "skills.sh")),
			}),
		);
		expectFileContains(join(target, "sample", "SKILL.md"), "name: sample");
		expectAbsent(join(target, "sample", "package.json"));
		expectAbsent(join(target, "sample", "tests"));
		write(join(target, "sample", "SKILL.md"), "old");
		write(join(target, "local.txt"), "keep");
		expectSuccess(
			run(["sh", "-s", "--", "update", "--path", target, "--yes"], {
				cwd: temporary,
				env,
				stdin: read(join(root, "skills.sh")),
			}),
		);
		expectFileContains(join(target, "sample", "SKILL.md"), "name: sample");
		expectFileContains(join(target, "local.txt"), "keep");
		expectAbsent(join(target, "dist"));
		expectAbsent(join(target, "src"));

		// A source checkout has no tracked dist: install must fetch the release.
		cleanup(join(root, "dist"));
		const checkoutTarget = join(temporary, "from-checkout");
		expectSuccess(
			run(
				[
					"sh",
					join(root, "skills.sh"),
					"install",
					"--path",
					checkoutTarget,
					"--yes",
				],
				{ env },
			),
		);
		expectFileContains(
			join(checkoutTarget, "sample", "SKILL.md"),
			"name: sample",
		);
	} finally {
		cleanup(root);
		cleanup(temporary);
	}
});
