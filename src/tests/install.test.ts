import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { lstatSync, readlinkSync } from "node:fs";
import { join } from "node:path";
import {
	buildRuntimeRepo,
	cleanup,
	copy,
	createRuntimeRepo,
	ensureDir,
	expectAbsent,
	expectExists,
	expectFailure,
	expectFileContains,
	expectSuccess,
	makeTempDir,
	type RunOptions,
	type RunResult,
	read,
	run,
	write,
} from "./helpers";

const fixtureSkill = "install-test-fixture-skill";
let runtimeRoot = "";
let installer = "";

function runInstaller(args: string[], options: RunOptions = {}): RunResult {
	return run([installer, ...args], options);
}

function initializeGitSource(sourceDir: string): void {
	ensureDir(sourceDir);
	copy(join(runtimeRoot, "src"), join(sourceDir, "src"));
	copy(join(runtimeRoot, "skills.sh"), join(sourceDir, "skills.sh"));
	copy(join(runtimeRoot, "dist"), join(sourceDir, "dist"));
	expectSuccess(run(["git", "-C", sourceDir, "init", "-b", "main"]));
	expectSuccess(run(["git", "-C", sourceDir, "add", "."]));
	expectSuccess(
		run([
			"git",
			"-C",
			sourceDir,
			"-c",
			"user.email=test@example.com",
			"-c",
			"user.name=test",
			"commit",
			"-m",
			"fixture",
		]),
	);
}

beforeAll(() => {
	runtimeRoot = createRuntimeRepo("install-test-runtime", [
		fixtureSkill,
		"commit-changes",
		"find-docs",
	]);
	installer = join(runtimeRoot, "src", "install.sh");
	expectSuccess(buildRuntimeRepo(runtimeRoot));
	expectExists(join(runtimeRoot, "dist", "skills", fixtureSkill, "SKILL.md"));
});

afterAll(() => {
	cleanup(runtimeRoot);
});

describe("skill installer", () => {
	test("installs to an explicit path", () => {
		const temporaryRoot = makeTempDir("install-path-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller(["-p", target], { cwd: temporaryRoot });
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("uses symlinks for the Claude installation by default", () => {
		const temporaryRoot = makeTempDir("install-claude-test");
		try {
			const primary = join(temporaryRoot, "custom-skills");
			const claudeTarget = join(temporaryRoot, "home", ".claude", "skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(promptInput, "y\n\n");
			const result = runInstaller(["--path", primary], {
				env: {
					HOME: join(temporaryRoot, "home"),
					AGENTS_SKILLS_PROMPT_INPUT: promptInput,
				},
			});
			expectSuccess(result);
			expectExists(join(primary, fixtureSkill, "SKILL.md"));
			expectExists(join(claudeTarget, fixtureSkill, "SKILL.md"));
			expect(lstatSync(join(claudeTarget, fixtureSkill)).isSymbolicLink()).toBe(
				true,
			);
			expect(readlinkSync(join(claudeTarget, fixtureSkill))).toBe(
				join(primary, fixtureSkill),
			);
			expect(result.output).toContain(
				`Também deseja instalar as skills em ${claudeTarget}`,
			);
			expect(result.output).toContain("Usar symlinks");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("copies the Claude installation when symlinks are declined", () => {
		const temporaryRoot = makeTempDir("install-claude-copy-test");
		try {
			const primary = join(temporaryRoot, "custom-skills");
			const claudeTarget = join(temporaryRoot, "home", ".claude", "skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(promptInput, "y\nn\n");
			const result = runInstaller(["--path", primary], {
				env: {
					HOME: join(temporaryRoot, "home"),
					AGENTS_SKILLS_PROMPT_INPUT: promptInput,
				},
			});
			expectSuccess(result);
			expectExists(join(claudeTarget, fixtureSkill, "SKILL.md"));
			expect(lstatSync(join(claudeTarget, fixtureSkill)).isSymbolicLink()).toBe(
				false,
			);
			expect(result.output).toContain("Instalação concluída com 3 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("preserves the primary destination when Claude installation is declined", () => {
		const temporaryRoot = makeTempDir("install-decline-claude-test");
		try {
			const primary = join(temporaryRoot, "custom-skills");
			const claudeTarget = join(temporaryRoot, "home", ".claude", "skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(promptInput, "n\n");
			const result = runInstaller(["--path", primary], {
				env: {
					HOME: join(temporaryRoot, "home"),
					AGENTS_SKILLS_PROMPT_INPUT: promptInput,
				},
			});
			expectSuccess(result);
			expectExists(join(primary, fixtureSkill, "SKILL.md"));
			expectAbsent(claudeTarget);
			expect(result.output).toContain(
				`Instalação em ${claudeTarget} não solicitada`,
			);
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("does not offer Claude when it is the primary destination", () => {
		const temporaryRoot = makeTempDir("install-primary-claude-test");
		try {
			const claudeTarget = join(temporaryRoot, "home", ".claude", "skills");
			const result = runInstaller(["--path", claudeTarget], {
				env: { HOME: join(temporaryRoot, "home") },
			});
			expectSuccess(result);
			expectExists(join(claudeTarget, fixtureSkill, "SKILL.md"));
			expect(result.output).not.toContain("Também deseja instalar as skills");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("installs one selected skill", () => {
		const temporaryRoot = makeTempDir("install-selected-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller([fixtureSkill, "--path", target]);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expectAbsent(join(target, "commit-changes"));
			expect(result.output).toContain("Instalação concluída com 1 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("installs multiple selected skills", () => {
		const temporaryRoot = makeTempDir("install-multiple-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller([
				fixtureSkill,
				"commit-changes",
				"--path",
				target,
			]);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expectExists(join(target, "commit-changes", "SKILL.md"));
			expectAbsent(join(target, "find-docs"));
			expect(result.output).toContain("Instalação concluída com 2 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("rejects an unknown skill before copying", () => {
		const temporaryRoot = makeTempDir("install-unknown-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller([
				fixtureSkill,
				"missing-skill",
				"--path",
				target,
			]);
			expectFailure(result);
			expectAbsent(target);
			expect(result.output).toContain("Skill não encontrada: missing-skill");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("installs a duplicate selection only once", () => {
		const temporaryRoot = makeTempDir("install-duplicate-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller([
				fixtureSkill,
				fixtureSkill,
				"--path",
				target,
			]);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expect(result.output).toContain("Instalação concluída com 1 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("installs in place when cwd is named skills", () => {
		const temporaryRoot = makeTempDir("install-cwd-test");
		try {
			const target = join(temporaryRoot, "skills");
			ensureDir(target);
			const result = runInstaller([], { cwd: target });
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--fresh removes installed skills and preserves non-skill files", () => {
		const temporaryRoot = makeTempDir("install-fresh-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			write(
				join(target, "old-skill", "SKILL.md"),
				"---\nname: old-skill\n---\n",
			);
			write(
				join(target, ".hidden-old-skill", "SKILL.md"),
				"---\nname: hidden-old-skill\n---\n",
			);
			write(join(target, "README.md"), "keep me\n");
			const result = runInstaller(["--fresh", "--path", target]);
			expectSuccess(result);
			expectAbsent(join(target, "old-skill"));
			expectAbsent(join(target, ".hidden-old-skill"));
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expect(read(join(target, "README.md"))).toBe("keep me\n");
			expect(result.output).toContain("--fresh removeu 2 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--fresh with a selection preserves other skills", () => {
		const temporaryRoot = makeTempDir("install-fresh-selection-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			write(
				join(target, fixtureSkill, "SKILL.md"),
				`---\nname: ${fixtureSkill}\n---\nstale\n`,
			);
			write(
				join(target, "other-skill", "SKILL.md"),
				"---\nname: other-skill\n---\n",
			);
			const result = runInstaller(["--fresh", fixtureSkill, "--path", target]);
			expectSuccess(result);
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expectExists(join(target, "other-skill", "SKILL.md"));
			expect(read(join(target, fixtureSkill, "SKILL.md"))).not.toContain(
				"stale",
			);
			expect(result.output).toContain("--fresh removeu 1 skill(s)");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("rejects --fresh with --init", () => {
		const temporaryRoot = makeTempDir("install-fresh-init-test");
		try {
			const result = runInstaller([
				"--fresh",
				"--init",
				"--path",
				join(temporaryRoot, "target"),
			]);
			expectFailure(result);
			expect(result.output).toContain("--fresh não pode ser usado com --init");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("rejects a skill selection with --init", () => {
		const temporaryRoot = makeTempDir("install-selection-init-test");
		try {
			const result = runInstaller([
				fixtureSkill,
				"--init",
				"--path",
				join(temporaryRoot, "target"),
			]);
			expectFailure(result);
			expect(result.output).toContain(
				"A seleção de skills não pode ser usada com --init",
			);
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("defaults to the global target outside a skills directory", () => {
		const temporaryRoot = makeTempDir("install-global-default-test");
		try {
			const home = join(temporaryRoot, "home");
			const project = join(temporaryRoot, "project");
			const work = join(project, "work");
			const promptInput = join(temporaryRoot, "tty-input");
			ensureDir(work);
			write(promptInput, "y\n");
			expectSuccess(run(["git", "-C", project, "init"]));
			const result = runInstaller([], {
				cwd: work,
				env: { HOME: home, AGENTS_SKILLS_PROMPT_INPUT: promptInput },
			});
			expectSuccess(result);
			expectExists(join(home, ".agents", "skills", fixtureSkill, "SKILL.md"));
			expectAbsent(join(project, ".agents", "skills", fixtureSkill));
			expect(result.output).toContain("destino padrão global");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("does not install when the global default is declined", () => {
		const temporaryRoot = makeTempDir("install-global-decline-test");
		try {
			const home = join(temporaryRoot, "home");
			const work = join(temporaryRoot, "work");
			const promptInput = join(temporaryRoot, "tty-input");
			ensureDir(work);
			write(promptInput, "n\n");
			const result = runInstaller([], {
				cwd: work,
				env: { HOME: home, AGENTS_SKILLS_PROMPT_INPUT: promptInput },
			});
			expectFailure(result);
			expectAbsent(join(work, fixtureSkill, "SKILL.md"));
			expectAbsent(join(home, ".agents", "skills", fixtureSkill));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--global prompts even when --yes is present", () => {
		const temporaryRoot = makeTempDir("install-global-yes-test");
		try {
			const home = join(temporaryRoot, "home");
			const work = join(temporaryRoot, "work");
			ensureDir(work);
			const result = runInstaller(["--global", "--yes"], {
				cwd: work,
				env: { HOME: home },
				stdin: "y\n",
			});
			expectSuccess(result);
			expectExists(join(home, ".agents", "skills", fixtureSkill, "SKILL.md"));
			expect(result.output).toContain("global");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--init clones a repository into the target", () => {
		const temporaryRoot = makeTempDir("install-init-test");
		try {
			const sourceDir = join(temporaryRoot, "source");
			const cloneDestination = join(temporaryRoot, "cloned-skills");
			initializeGitSource(sourceDir);
			const result = runInstaller(["--init", "--path", cloneDestination], {
				cwd: temporaryRoot,
				env: {
					AGENTS_SKILLS_REPO_URL: `file://${sourceDir}`,
					AGENTS_SKILLS_REF: "main",
				},
			});
			expectSuccess(result);
			expectExists(
				join(cloneDestination, "dist", "skills", fixtureSkill, "SKILL.md"),
			);
			expectExists(join(cloneDestination, ".git"));
			expectSuccess(
				run([
					"git",
					"-C",
					cloneDestination,
					"rev-parse",
					"--is-inside-work-tree",
				]),
			);
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--init merges into a non-empty destination after confirmation", () => {
		const temporaryRoot = makeTempDir("install-init-merge-test");
		try {
			const sourceDir = join(temporaryRoot, "source");
			const cloneDestination = join(temporaryRoot, "cloned-skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(join(cloneDestination, "existing.txt"), "occupied\n");
			write(promptInput, "y\n");
			initializeGitSource(sourceDir);
			const result = runInstaller(["--init", "--path", cloneDestination], {
				cwd: temporaryRoot,
				env: {
					AGENTS_SKILLS_REPO_URL: `file://${sourceDir}`,
					AGENTS_SKILLS_REF: "main",
					AGENTS_SKILLS_PROMPT_INPUT: promptInput,
				},
			});
			expectSuccess(result);
			expectExists(join(cloneDestination, "existing.txt"));
			expectExists(
				join(cloneDestination, "dist", "skills", fixtureSkill, "SKILL.md"),
			);
			expectExists(join(cloneDestination, ".git"));
			expect(result.output).toContain(
				"mantendo os arquivos existentes na worktree",
			);
			expect(read(join(cloneDestination, "existing.txt"))).toBe("occupied\n");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--instructions copies the repository README", () => {
		const temporaryRoot = makeTempDir("install-instructions-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			const result = runInstaller(["--instructions", "-p", target], {
				cwd: temporaryRoot,
			});
			expectSuccess(result);
			expectExists(join(target, "README.md"));
			expectExists(join(target, fixtureSkill, "SKILL.md"));
			expectFileContains(join(target, "README.md"), "agents-skills");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--instructions preserves an existing README", () => {
		const temporaryRoot = makeTempDir("install-existing-readme-test");
		try {
			const target = join(temporaryRoot, "custom-skills");
			write(join(target, "README.md"), "custom readme\n");
			const result = runInstaller(["--instructions", "-p", target], {
				cwd: temporaryRoot,
			});
			expectSuccess(result);
			expect(read(join(target, "README.md"))).toBe("custom readme\n");
			expect(result.output).toContain("README.md já existe");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("--init cancels a non-empty destination without confirmation", () => {
		const temporaryRoot = makeTempDir("install-init-cancel-test");
		try {
			const sourceDir = join(temporaryRoot, "source");
			const cloneDestination = join(temporaryRoot, "cloned-skills");
			const promptInput = join(temporaryRoot, "tty-input");
			write(join(cloneDestination, "existing.txt"), "occupied\n");
			write(promptInput, "n\n");
			initializeGitSource(sourceDir);
			const result = runInstaller(["--init", "--path", cloneDestination], {
				cwd: temporaryRoot,
				env: {
					AGENTS_SKILLS_REPO_URL: `file://${sourceDir}`,
					AGENTS_SKILLS_REF: "main",
					AGENTS_SKILLS_PROMPT_INPUT: promptInput,
				},
			});
			expectFailure(result);
			expectExists(join(cloneDestination, "existing.txt"));
			expectAbsent(join(cloneDestination, ".git"));
			expectAbsent(
				join(cloneDestination, "dist", "skills", fixtureSkill, "SKILL.md"),
			);
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("reads confirmation separately when stdin is a pipe", () => {
		const temporaryRoot = makeTempDir("install-piped-stdin-test");
		try {
			const home = join(temporaryRoot, "home");
			const promptInput = join(temporaryRoot, "tty-input");
			write(promptInput, "y\n");
			const result = runInstaller(["--global"], {
				cwd: temporaryRoot,
				env: { HOME: home, AGENTS_SKILLS_PROMPT_INPUT: promptInput },
				stdin: "",
			});
			expectSuccess(result);
			expectExists(join(home, ".agents", "skills", fixtureSkill, "SKILL.md"));
		} finally {
			cleanup(temporaryRoot);
		}
	});
});
