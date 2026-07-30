import { describe, expect, test } from "bun:test";
import { join } from "node:path";
import {
	cleanup,
	copy,
	createArchive,
	ensureDir,
	expectFailure,
	expectFileContains,
	expectSuccess,
	makeTempDir,
	REPO_ROOT,
	run,
	write,
} from "./helpers";

const updater = join(REPO_ROOT, "src", "update.sh");
const fixtureSkill = "update-test-fixture-skill";

function makeArchive(temporaryRoot: string, version: string): string {
	const archiveRoot = join(temporaryRoot, "archive-src", "agents-skills-main");
	write(
		join(archiveRoot, "dist", "skills", fixtureSkill, "SKILL.md"),
		`---\nname: ${fixtureSkill}\n---\nversion: ${version}\n`,
	);
	write(
		join(archiveRoot, "skills.sh"),
		`#!/usr/bin/env sh\nprintf '%s\\n' remote-${version}\n`,
	);
	write(join(archiveRoot, "README.md"), `remote readme ${version}\n`);
	write(
		join(archiveRoot, "src", "install.sh"),
		`#!/usr/bin/env sh\nprintf '%s\\n' install-${version}\n`,
	);
	return createArchive(join(temporaryRoot, "archive"), archiveRoot);
}

function seedTarget(
	temporaryRoot: string,
	archivePath: string,
	target: string,
): void {
	const extracted = join(temporaryRoot, "seed");
	ensureDir(extracted);
	expectSuccess(run(["tar", "-xzf", archivePath, "-C", extracted]));
	ensureDir(target);
	copy(join(extracted, "agents-skills-main"), target);
}

function runUpdater(archivePath: string, args: string[], promptInput?: string) {
	return run([updater, ...args], {
		env: {
			AGENTS_SKILLS_ARCHIVE_URL: `file://${archivePath}`,
			AGENTS_SKILLS_PROMPT_INPUT: promptInput,
		},
	});
}

describe("skill updater", () => {
	test("reports an already current installation", () => {
		const temporaryRoot = makeTempDir("update-current-test");
		try {
			const archivePath = makeArchive(temporaryRoot, "remote");
			const target = join(temporaryRoot, "skills");
			seedTarget(temporaryRoot, archivePath, target);
			const result = runUpdater(archivePath, ["--path", target]);
			expectSuccess(result);
			expect(result.output).toContain("já está atualizada");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("prompts before overwriting changed files", () => {
		const temporaryRoot = makeTempDir("update-prompt-test");
		try {
			const archivePath = makeArchive(temporaryRoot, "remote");
			const target = join(temporaryRoot, "skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"local version\n",
			);
			write(promptInput, "y\n");
			const result = runUpdater(archivePath, ["--path", target], promptInput);
			expectSuccess(result);
			expectFileContains(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"version: remote",
			);
			expect(result.output).toContain("Atualização concluída");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("cancels without confirmation", () => {
		const temporaryRoot = makeTempDir("update-cancel-test");
		try {
			const archivePath = makeArchive(temporaryRoot, "remote");
			const target = join(temporaryRoot, "skills");
			const promptInput = join(temporaryRoot, "tty-input");
			const skillPath = join(
				target,
				"dist",
				"skills",
				fixtureSkill,
				"SKILL.md",
			);
			write(skillPath, "local version\n");
			write(promptInput, "n\n");
			const result = runUpdater(archivePath, ["--path", target], promptInput);
			expectFailure(result);
			expectFileContains(skillPath, "local version");
			expect(result.output).toContain("Atualização cancelada");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--yes overwrites without prompting", () => {
		const temporaryRoot = makeTempDir("update-yes-test");
		try {
			const archivePath = makeArchive(temporaryRoot, "remote");
			const target = join(temporaryRoot, "skills");
			const skillPath = join(
				target,
				"dist",
				"skills",
				fixtureSkill,
				"SKILL.md",
			);
			write(skillPath, "local version\n");
			const result = runUpdater(archivePath, ["--path", target, "--yes"]);
			expectSuccess(result);
			expectFileContains(skillPath, "version: remote");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("fails when the target does not exist", () => {
		const temporaryRoot = makeTempDir("update-missing-test");
		try {
			const archivePath = makeArchive(temporaryRoot, "remote");
			const target = join(temporaryRoot, "missing-skills");
			const result = runUpdater(archivePath, ["--path", target, "--yes"]);
			expectFailure(result);
			expect(result.output).toContain("Destino de update não existe");
		} finally {
			cleanup(temporaryRoot);
		}
	});
});
