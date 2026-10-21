import { expect } from "bun:test";
import {
	cpSync,
	existsSync,
	mkdirSync,
	mkdtempSync,
	readFileSync,
	rmSync,
	writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const REPO_ROOT = resolve(
	dirname(fileURLToPath(import.meta.url)),
	"../..",
);

export type RunOptions = {
	cwd?: string;
	env?: Record<string, string | undefined>;
	stdin?: string;
	timeout?: number;
};

export type RunResult = {
	exitCode: number;
	stdout: string;
	stderr: string;
	output: string;
};

export function makeTempDir(prefix: string): string {
	return mkdtempSync(join(tmpdir(), `${prefix}-`));
}

export function cleanup(path: string): void {
	rmSync(path, { force: true, recursive: true });
}

export function ensureDir(path: string): void {
	mkdirSync(path, { recursive: true });
}

export function write(path: string, contents: string): void {
	ensureDir(dirname(path));
	writeFileSync(path, contents);
}

export function append(path: string, contents: string): void {
	writeFileSync(path, contents, { flag: "a" });
}

export function read(path: string): string {
	return readFileSync(path, "utf8");
}

export function copy(source: string, destination: string): void {
	ensureDir(dirname(destination));
	cpSync(source, destination, { recursive: true });
}

// Git hooks export the parent repository context (GIT_DIR, GIT_INDEX_FILE...).
// Fixture repositories must not inherit it, or `git -C <dir>` inside a hook
// silently targets the host repository instead of the fixture.
const GIT_CONTEXT_VARIABLES = [
	"GIT_DIR",
	"GIT_COMMON_DIR",
	"GIT_WORK_TREE",
	"GIT_INDEX_FILE",
	"GIT_INDEX_VERSION",
	"GIT_OBJECT_DIRECTORY",
	"GIT_ALTERNATE_OBJECT_DIRECTORIES",
	"GIT_NAMESPACE",
];

export function run(command: string[], options: RunOptions = {}): RunResult {
	const env: Record<string, string | undefined> = {
		...Bun.env,
		AGENTS_SKILLS_PROMPT_INPUT: "/dev/null",
		...options.env,
	};
	for (const variable of GIT_CONTEXT_VARIABLES) {
		delete env[variable];
	}
	const process = Bun.spawnSync({
		cmd: command,
		cwd: options.cwd,
		env,
		stdin: options.stdin === undefined ? "ignore" : new Blob([options.stdin]),
		stdout: "pipe",
		stderr: "pipe",
		timeout: options.timeout,
	});
	const stdout = process.stdout.toString();
	const stderr = process.stderr.toString();

	return {
		exitCode: process.exitCode,
		stdout,
		stderr,
		output: `${stdout}${stderr}`,
	};
}

export function expectSuccess(result: RunResult): void {
	if (result.exitCode !== 0) {
		throw new Error(
			`Command failed with exit ${result.exitCode}\n${result.output}`,
		);
	}
}

export function expectFailure(result: RunResult): void {
	expect(result.exitCode).not.toBe(0);
}

export function expectExists(path: string): void {
	expect(existsSync(path), `expected path to exist: ${path}`).toBe(true);
}

export function expectAbsent(path: string): void {
	expect(existsSync(path), `expected path to be absent: ${path}`).toBe(false);
}

export function expectFileContains(path: string, expected: string): void {
	expect(read(path)).toContain(expected);
}

function createSkill(root: string, name: string, extra = ""): void {
	write(
		join(root, "skills", name, "SKILL.md"),
		`---\nname: ${name}\n---\n${extra}`,
	);
}

export function createRuntimeRepo(
	prefix: string,
	skills: string[],
	sourceScripts = ["build.sh", "dev.sh", "install.sh", "update.sh"],
): string {
	const root = makeTempDir(prefix);
	ensureDir(join(root, "src"));

	for (const script of sourceScripts) {
		copy(join(REPO_ROOT, "src", script), join(root, "src", script));
	}

	copy(join(REPO_ROOT, "skills.sh"), join(root, "skills.sh"));
	copy(join(REPO_ROOT, "README.md"), join(root, "README.md"));

	for (const skill of skills) {
		createSkill(root, skill);
	}

	return root;
}

export function buildRuntimeRepo(root: string): RunResult {
	return run(["sh", join(root, "src", "build.sh")], {
		env: {
			AGENTS_SKILLS_BUILD_DEPLOY: "0",
			AGENTS_SKILLS_BUILD_OUTPUT: join(root, "dist", "skills"),
		},
	});
}

export function createArchive(root: string, sourceRoot: string): string {
	ensureDir(root);
	const archivePath = join(root, "agents-skills-main.tar.gz");
	const result = run([
		"tar",
		"-czf",
		archivePath,
		"-C",
		dirname(sourceRoot),
		basename(sourceRoot),
	]);
	expectSuccess(result);
	return archivePath;
}
