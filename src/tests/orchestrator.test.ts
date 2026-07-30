import { afterAll, beforeAll, describe, test } from "bun:test";
import { join } from "node:path";
import {
	buildRuntimeRepo,
	cleanup,
	createArchive,
	createRuntimeRepo,
	expectExists,
	expectFileContains,
	expectSuccess,
	makeTempDir,
	run,
	write,
} from "./helpers";

const fixtureSkill = "orchestrator-test-fixture-skill";
let runtimeRoot = "";
let orchestrator = "";

beforeAll(() => {
	runtimeRoot = createRuntimeRepo("orchestrator-test-runtime", [
		fixtureSkill,
		"commit-changes",
	]);
	orchestrator = join(runtimeRoot, "skills.sh");
	expectSuccess(buildRuntimeRepo(runtimeRoot));
});

afterAll(() => {
	cleanup(runtimeRoot);
});

describe("skills orchestrator", () => {
	test("delegates install to the inner script", () => {
		const temporaryRoot = makeTempDir("orchestrator-install-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const promptInput = join(temporaryRoot, "prompt-input");
			write(promptInput, "n\n");
			const result = run([orchestrator, "install", "--path", target], {
				cwd: temporaryRoot,
				env: { AGENTS_SKILLS_PROMPT_INPUT: promptInput },
			});
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("delegates build to the inner script", () => {
		const temporaryRoot = makeTempDir("orchestrator-build-test");
		try {
			const output = join(temporaryRoot, "generated-skills");
			const target = join(temporaryRoot, "installed-skills");
			const result = run([orchestrator, "build"], {
				env: {
					AGENTS_SKILLS_BUILD_OUTPUT: output,
					AGENTS_SKILLS_BUILD_TARGET: target,
				},
			});
			expectSuccess(result);
			expectExists(join(output, "commit-changes", "SKILL.md"));
			expectExists(join(target, "commit-changes", "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("delegates dev and builds once without publishing", () => {
		const temporaryRoot = makeTempDir("orchestrator-dev-test");
		try {
			const output = join(temporaryRoot, "build-output");
			const result = run([orchestrator, "dev"], {
				env: {
					AGENTS_SKILLS_BUILD_OUTPUT: output,
					AGENTS_SKILLS_WATCH_ONCE: "1",
				},
			});
			expectSuccess(result);
			expectExists(join(output, "commit-changes", "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("delegates update to the inner script", () => {
		const temporaryRoot = makeTempDir("orchestrator-update-test");
		try {
			const archiveRoot = join(
				temporaryRoot,
				"archive-src",
				"agents-skills-main",
			);
			const target = join(temporaryRoot, "custom-skills");
			write(
				join(archiveRoot, "dist", "skills", fixtureSkill, "SKILL.md"),
				`---\nname: ${fixtureSkill}\n---\nversion: remote\n`,
			);
			write(join(archiveRoot, "skills.sh"), "#!/usr/bin/env sh\n");
			write(join(archiveRoot, "src", "install.sh"), "#!/usr/bin/env sh\n");
			write(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"version: local\n",
			);
			const archivePath = createArchive(
				join(temporaryRoot, "archive"),
				archiveRoot,
			);
			const result = run([orchestrator, "update", "--path", target, "--yes"], {
				cwd: temporaryRoot,
				env: { AGENTS_SKILLS_ARCHIVE_URL: `file://${archivePath}` },
			});
			expectSuccess(result);
			expectFileContains(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"version: remote",
			);
		} finally {
			cleanup(temporaryRoot);
		}
	});
});
