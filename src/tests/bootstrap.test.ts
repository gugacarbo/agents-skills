import { describe, expect, test } from "bun:test";
import { join } from "node:path";
import {
	cleanup,
	copy,
	createArchive,
	ensureDir,
	expectAbsent,
	expectExists,
	expectFailure,
	expectFileContains,
	expectSuccess,
	makeTempDir,
	REPO_ROOT,
	read,
	run,
	write,
} from "./helpers";

const orchestrator = join(REPO_ROOT, "skills.sh");
const fixtureSkill = "sample-skill";

function createBootstrapArchive(options: {
	includeInstall?: boolean;
	includeUpdate?: boolean;
	skills?: string[];
	version?: string;
}): { archivePath: string; temporaryRoot: string } {
	const temporaryRoot = makeTempDir("bootstrap-test");
	const archiveRoot = join(temporaryRoot, "archive-src", "agents-skills-main");
	ensureDir(archiveRoot);
	copy(orchestrator, join(archiveRoot, "skills.sh"));

	if (options.includeInstall || options.includeUpdate) {
		ensureDir(join(archiveRoot, "src"));
	}
	if (options.includeInstall) {
		copy(
			join(REPO_ROOT, "src", "install.sh"),
			join(archiveRoot, "src", "install.sh"),
		);
	}
	if (options.includeUpdate) {
		copy(
			join(REPO_ROOT, "src", "update.sh"),
			join(archiveRoot, "src", "update.sh"),
		);
	}

	for (const skill of options.skills ?? []) {
		write(
			join(archiveRoot, "dist", "skills", skill, "SKILL.md"),
			`---\nname: ${skill}\n---\n${options.version ? `version: ${options.version}\n` : ""}`,
		);
	}

	return {
		archivePath: createArchive(join(temporaryRoot, "archive"), archiveRoot),
		temporaryRoot,
	};
}

function runStreamed(
	archivePath: string,
	args: string[],
	cwd: string,
	extraEnv: Record<string, string> = {},
) {
	return run(["sh", "-s", "--", ...args], {
		cwd,
		env: {
			AGENTS_SKILLS_ARCHIVE_URL: `file://${archivePath}`,
			...extraEnv,
		},
		stdin: read(orchestrator),
		timeout: 10_000,
	});
}

describe("streamed bootstrap", () => {
	test("uses the archive and runs install", () => {
		const fixture = createBootstrapArchive({
			includeInstall: true,
			skills: [fixtureSkill],
		});
		try {
			const target = join(fixture.temporaryRoot, "custom-skills");
			const result = runStreamed(
				fixture.archivePath,
				["install", "--path", target],
				fixture.temporaryRoot,
				{ AGENTS_SKILLS_ARCHIVE_URL_FORCE: "1" },
			);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
		} finally {
			cleanup(fixture.temporaryRoot);
		}
	});

	test("forwards selected skills", () => {
		const fixture = createBootstrapArchive({
			includeInstall: true,
			skills: [fixtureSkill, "other-skill"],
		});
		try {
			const target = join(fixture.temporaryRoot, "custom-skills");
			const result = runStreamed(
				fixture.archivePath,
				["install", fixtureSkill, "--path", target],
				fixture.temporaryRoot,
			);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expectAbsent(join(target, "other-skill"));
		} finally {
			cleanup(fixture.temporaryRoot);
		}
	});

	test("uses the archive and runs update", () => {
		const fixture = createBootstrapArchive({
			includeUpdate: true,
			skills: [fixtureSkill],
			version: "remote",
		});
		try {
			const target = join(fixture.temporaryRoot, "custom-skills");
			write(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"version: local\n",
			);
			const result = runStreamed(
				fixture.archivePath,
				["update", "--path", target, "--yes"],
				fixture.temporaryRoot,
				{ AGENTS_SKILLS_ARCHIVE_URL_FORCE: "1" },
			);
			expectSuccess(result);
			expectFileContains(
				join(target, "dist", "skills", fixtureSkill, "SKILL.md"),
				"version: remote",
			);
		} finally {
			cleanup(fixture.temporaryRoot);
		}
	});

	test("does not loop when the downloaded archive lacks the command", () => {
		const fixture = createBootstrapArchive({});
		try {
			const result = runStreamed(
				fixture.archivePath,
				["install", "--path", join(fixture.temporaryRoot, "custom-skills")],
				fixture.temporaryRoot,
				{ AGENTS_SKILLS_ARCHIVE_URL_FORCE: "1" },
			);
			expectFailure(result);
			expect(result.output.match(/Baixando pacote de bootstrap/g)?.length).toBe(
				1,
			);
			expect(result.output).toContain("Comando install não encontrado");
		} finally {
			cleanup(fixture.temporaryRoot);
		}
	});
});
