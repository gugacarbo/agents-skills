#!/usr/bin/env bun

import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const evalDir = path.dirname(fileURLToPath(import.meta.url));
const defaultSkill = path.resolve(evalDir, "..");
const authSource = "/home/gustavo/.codex/auth.json";

function parseArgs(argv) {
	const options = {
		model: "gpt-5.4-mini",
		reasoning: "medium",
		timeout: 300,
		concurrency: 3,
		skill: defaultSkill,
	};
	for (let index = 0; index < argv.length; index += 1) {
		const arg = argv[index];
		if (arg === "--help") return { help: true };
		if (arg === "--regrade-only") {
			options.regradeOnly = true;
			continue;
		}
		const value = argv[index + 1];
		if (!arg.startsWith("--") || !value)
			throw new Error(`Invalid argument: ${arg}`);
		options[arg.slice(2)] = value;
		index += 1;
	}
	for (const required of ["configuration", "output"])
		if (!options[required]) throw new Error(`Missing --${required}`);
	if (!new Set(["baseline", "candidate"]).has(options.configuration))
		throw new Error("--configuration must be baseline or candidate");
	options.skill = path.resolve(options.skill);
	options.output = path.resolve(options.output);
	options.timeout = Number(options.timeout);
	options.concurrency = Number(options.concurrency);
	return options;
}

const usage = `Usage: bun evals/run-evals.mjs --configuration baseline|candidate --skill PATH --output PATH [options]

Options:
  --model MODEL          default: gpt-5.4-mini
  --reasoning LEVEL      default: medium
  --timeout SECONDS      default: 300
  --concurrency NUMBER   default: 3
  --regrade-only         recompute grades from existing outputs`;

async function exists(target) {
	return fs
		.access(target)
		.then(() => true)
		.catch(() => false);
}

async function runCommand(command, args, { cwd, env, timeoutMs = 30_000 }) {
	const started = performance.now();
	let stdout = "";
	let stderr = "";
	let timedOut = false;
	const exitCode = await new Promise((resolve, reject) => {
		const child = spawn(command, args, {
			cwd,
			env,
			stdio: ["ignore", "pipe", "pipe"],
		});
		child.stdout.on("data", (chunk) => (stdout += chunk));
		child.stderr.on("data", (chunk) => (stderr += chunk));
		const timer = setTimeout(() => {
			timedOut = true;
			child.kill("SIGTERM");
		}, timeoutMs);
		child.once("error", reject);
		child.once("exit", (code) => {
			clearTimeout(timer);
			resolve(code ?? 1);
		});
	});
	return {
		exitCode,
		stdout,
		stderr,
		timedOut,
		durationSeconds: (performance.now() - started) / 1000,
	};
}

async function git(cwd, args) {
	const result = await runCommand("git", args, { cwd });
	if (result.exitCode !== 0)
		throw new Error(`git ${args.join(" ")} failed: ${result.stderr}`);
	return result.stdout.trim();
}

async function writeFiles(root, files) {
	for (const [relative, content] of Object.entries(files)) {
		const target = path.join(root, relative);
		await fs.mkdir(path.dirname(target), { recursive: true });
		await fs.writeFile(target, content);
	}
}

async function setupFixture(id, workspace) {
	const initialById = {
		1: {
			"src/auth.ts": "export const refresh = () => 'old';\n",
			"tests/auth.test.ts": "// old auth test\n",
			"README.md": "# Example\n",
		},
		2: {
			"src/api/user.ts": "export const getUser = () => null;\n",
			"tests/api/user.test.ts": "// old API test\n",
			"README.md": "# Install\nRun bun install.\n",
		},
		3: {
			"src/api/user.ts": "export const getUser = () => null;\n",
			"package.json": '{"name":"fixture"}\n',
		},
		4: { "src/api/user.ts": "export const getUser = () => null;\n" },
		5: {
			"src/settings.ts":
				"const timeout = 10;\nconst retries = 2;\nexport { timeout, retries };\n",
		},
		6: { "src/app.js": "export const value = 0;\n" },
		7: { "src/report.ts": "export const report = () => 'old';\n" },
		8: {
			"package.json": '{\n  "scripts": {\n    "test": "bun test"\n  }\n}\n',
			"AGENTS.md": "# AGENTS.md\n\n## Commands\n\n- `bun test`: run tests.\n",
		},
	};
	await fs.mkdir(workspace, { recursive: true });
	await writeFiles(workspace, initialById[id]);
	await git(workspace, ["init", "-q"]);
	await git(workspace, ["add", "."]);
	await git(workspace, [
		"-c",
		"user.name=Fixture",
		"-c",
		"user.email=fixture@example.test",
		"commit",
		"-qm",
		"fixture",
	]);
	if (id !== 7) {
		await git(workspace, ["config", "user.name", "Eval"]);
		await git(workspace, ["config", "user.email", "eval@example.test"]);
	}

	if (id === 1)
		await writeFiles(workspace, {
			"src/auth.ts": "export const refresh = () => 'token';\n",
			"tests/auth.test.ts": "// refresh token test\n",
			"README.md": "# Example\n\nUnrelated local note.\n",
		});
	if (id === 2)
		await writeFiles(workspace, {
			"src/api/user.ts": "export const getUser = () => ({ id: 1 });\n",
			"tests/api/user.test.ts": "// user API regression test\n",
			"README.md": "# Install\nRun bun install --frozen-lockfile.\n",
		});
	if (id === 3) {
		await writeFiles(workspace, {
			"src/api/user.ts": "export const getUser = () => ({ id: 1 });\n",
			"package.json": '{"name":"fixture","private":true}\n',
		});
		await git(workspace, ["add", "package.json"]);
	}
	if (id === 5)
		await writeFiles(workspace, {
			"src/settings.ts":
				"const requestTimeout = 30;\nconst retryCount = 2;\nexport { requestTimeout, retryCount };\n",
		});
	if (id === 6) {
		await writeFiles(workspace, { "src/app.js": "export const value=1;\n" });
		const hook = path.join(workspace, ".git/hooks/pre-commit");
		await fs.writeFile(
			hook,
			"#!/bin/sh\nif ! grep -qx 'export const value = 1;' src/app.js; then\n  echo 'Formatting required: use export const value = 1;' >&2\n  exit 1\nfi\n",
		);
		await fs.chmod(hook, 0o755);
	}
	if (id === 7)
		await writeFiles(workspace, {
			"src/report.ts": "export const report = () => 'daily';\n",
		});
	if (id === 8)
		await writeFiles(workspace, {
			"package.json":
				'{\n  "scripts": {\n    "test": "bun test",\n    "reports:daily": "bun src/report.ts"\n  }\n}\n',
		});
	return git(workspace, ["rev-parse", "HEAD"]);
}

async function installSkill(source, target) {
	await fs.mkdir(target, { recursive: true });
	for (const file of ["SKILL.md", "README.md"])
		if (await exists(path.join(source, file)))
			await fs.copyFile(path.join(source, file), path.join(target, file));
}

function parseEvents(transcript) {
	return transcript.split("\n").flatMap((line) => {
		try {
			return line.trim() ? [JSON.parse(line)] : [];
		} catch {
			return [];
		}
	});
}

function commandTexts(events) {
	return events
		.filter(
			(event) =>
				event.type === "item.completed" &&
				event.item?.type === "command_execution",
		)
		.map((event) => String(event.item.command ?? ""));
}

async function commitsSince(workspace, baseSha) {
	const hashes = (
		await git(workspace, ["rev-list", "--reverse", `${baseSha}..HEAD`])
	)
		.split("\n")
		.filter(Boolean);
	const commits = [];
	for (const hash of hashes) {
		commits.push({
			hash,
			message: await git(workspace, ["show", "-s", "--format=%s", hash]),
			files: (
				await git(workspace, [
					"diff-tree",
					"--no-commit-id",
					"--name-only",
					"-r",
					hash,
				])
			)
				.split("\n")
				.filter(Boolean)
				.sort(),
		});
	}
	return commits;
}

const conventional =
	/^(feat|fix|refactor|docs|test|style|chore|perf|build)(\([^)]+\))?!?: /;
const sameFiles = (actual, expected) =>
	JSON.stringify([...actual].sort()) === JSON.stringify([...expected].sort());

async function gradeCase(evalCase, context) {
	const { workspace, baseSha, finalText, transcript, commands } = context;
	const commits = await commitsSince(workspace, baseSha);
	const status = await git(workspace, ["status", "--short"]);
	const staged = (await git(workspace, ["diff", "--cached", "--name-only"]))
		.split("\n")
		.filter(Boolean);
	const text = `${finalText}\n${transcript}`;
	const checks = [];
	const add = (index, passed, evidence) =>
		checks.push({
			text: evalCase.expectations[index],
			passed: Boolean(passed),
			evidence,
		});
	if (evalCase.id === 1) {
		add(0, /git status|git diff/.test(text), "transcript inspection");
		add(
			1,
			commits.length === 1 &&
				sameFiles(commits[0].files, ["src/auth.ts", "tests/auth.test.ts"]),
			JSON.stringify(commits),
		);
		add(2, status.includes("README.md"), status);
		add(
			3,
			commits.length === 1 && conventional.test(commits[0].message),
			commits[0]?.message ?? "no commit",
		);
		add(4, /README|untouched|não relacionad|deixad/.test(finalText), finalText);
	} else if (evalCase.id === 2) {
		add(0, !/spawn_agent|subagent|delegat/i.test(finalText), finalText);
		add(
			1,
			commits.some((item) =>
				sameFiles(item.files, ["src/api/user.ts", "tests/api/user.test.ts"]),
			),
			JSON.stringify(commits),
		);
		add(
			2,
			commits.some((item) => sameFiles(item.files, ["README.md"])),
			JSON.stringify(commits),
		);
		add(
			3,
			commits.length === 2 &&
				commits.every((item) => conventional.test(item.message)),
			JSON.stringify(commits),
		);
		add(4, commits.length === 2, JSON.stringify(commits));
	} else if (evalCase.id === 3) {
		add(0, /diff --cached|git status/.test(text), "transcript inspection");
		add(
			1,
			commits.length === 0 && staged.includes("package.json"),
			`commits=${commits.length}; staged=${staged}`,
		);
		add(2, staged.includes("package.json"), status);
		add(
			3,
			/stage|staged|escopo|scope|package\.json/i.test(finalText),
			finalText,
		);
	} else if (evalCase.id === 4) {
		add(
			0,
			/src\/api\/user\.ts/.test(text) && /git (status|diff)/.test(text),
			"transcript inspection",
		);
		add(1, commits.length === 0, JSON.stringify(commits));
		add(
			2,
			/no (?:local )?changes|sem altera|nenhuma altera|não há (?:altera|mudan)|inalterad/i.test(
				finalText,
			),
			finalText,
		);
	} else if (evalCase.id === 5) {
		add(0, commits.length === 0, JSON.stringify(commits));
		add(1, status.includes("src/settings.ts"), status);
		add(
			2,
			/mesmo arquivo|same file|hunk|mistur|separ/i.test(finalText),
			finalText,
		);
		add(3, /git add -p|combined|junto|um commit/i.test(finalText), finalText);
	} else if (evalCase.id === 6) {
		add(0, /Formatting required/.test(transcript), "hook output in transcript");
		add(
			1,
			(await fs.readFile(path.join(workspace, "src/app.js"), "utf8")) ===
				"export const value = 1;\n",
			"src/app.js content",
		);
		add(
			2,
			commits.length === 1 && sameFiles(commits[0].files, ["src/app.js"]),
			JSON.stringify(commits),
		);
		add(
			3,
			!commands.some((command) => /git commit[^\n]*--no-verify/.test(command)),
			commands.join("\n"),
		);
	} else if (evalCase.id === 7) {
		add(0, commits.length === 0, JSON.stringify(commits));
		const localName = await runCommand(
			"git",
			["config", "--local", "--get", "user.name"],
			{ cwd: workspace },
		);
		const localEmail = await runCommand(
			"git",
			["config", "--local", "--get", "user.email"],
			{ cwd: workspace },
		);
		add(
			1,
			localName.exitCode !== 0 && localEmail.exitCode !== 0,
			`user.name=${localName.stdout.trim() || "unset"}; user.email=${localEmail.stdout.trim() || "unset"}`,
		);
		add(
			2,
			/identity|identidade|user\.name|user\.email/i.test(finalText),
			finalText,
		);
		add(
			3,
			/git config(?! --global)|local|repositório/i.test(finalText),
			finalText,
		);
	} else if (evalCase.id === 8) {
		const agents = await fs.readFile(path.join(workspace, "AGENTS.md"), "utf8");
		add(0, /AGENTS\.md/.test(text), "transcript inspection");
		add(1, agents.includes("reports:daily"), agents);
		add(
			2,
			commits.length === 1 &&
				sameFiles(commits[0].files, ["AGENTS.md", "package.json"]),
			JSON.stringify(commits),
		);
		add(
			3,
			commits.length === 1 && conventional.test(commits[0].message),
			commits[0]?.message ?? "no commit",
		);
	}
	return {
		passed: checks.every((item) => item.passed),
		expectations: checks,
		commits,
		status,
	};
}

async function runCase(options, evalCase) {
	const runDir = path.join(
		options.output,
		options.configuration,
		`eval-${evalCase.id}-${evalCase.name}`,
	);
	await fs.rm(runDir, { recursive: true, force: true });
	const workspace = path.join(runDir, "repo");
	const baseSha = await setupFixture(evalCase.id, workspace);
	await installSkill(
		options.skill,
		path.join(workspace, ".agents/skills/commit-changes"),
	);
	await fs.appendFile(
		path.join(workspace, ".git/info/exclude"),
		"\n.agents/\n",
	);
	const isolatedHome = path.join(runDir, "home");
	const codexHome = path.join(runDir, "codex-home");
	await fs.mkdir(isolatedHome, { recursive: true });
	await fs.mkdir(codexHome, { recursive: true });
	await fs.symlink(authSource, path.join(codexHome, "auth.json"));
	const finalPath = path.join(runDir, "final.md");
	const prompt = [
		"You are in an isolated behavioral-evaluation repository.",
		"Read and apply .agents/skills/commit-changes/SKILL.md.",
		"Do not modify files under .agents. Complete the user's request autonomously.",
		"",
		evalCase.prompt,
	].join("\n");
	console.log(`[${options.configuration}] eval ${evalCase.id} starting`);
	const execution = await runCommand(
		"codex",
		[
			"exec",
			"--json",
			"--ephemeral",
			"--ignore-user-config",
			"--ignore-rules",
			"--dangerously-bypass-approvals-and-sandbox",
			"--model",
			options.model,
			"--config",
			`model_reasoning_effort=${JSON.stringify(options.reasoning)}`,
			"--output-last-message",
			finalPath,
			"-C",
			workspace,
			prompt,
		],
		{
			cwd: workspace,
			env: { ...process.env, HOME: isolatedHome, CODEX_HOME: codexHome },
			timeoutMs: options.timeout * 1000,
		},
	);
	await fs.writeFile(path.join(runDir, "transcript.jsonl"), execution.stdout);
	await fs.writeFile(path.join(runDir, "stderr.log"), execution.stderr);
	const finalText = await fs.readFile(finalPath, "utf8").catch(() => "");
	const events = parseEvents(execution.stdout);
	const commands = commandTexts(events);
	const grading = await gradeCase(evalCase, {
		workspace,
		baseSha,
		finalText,
		transcript: execution.stdout,
		commands,
	});
	const usage =
		[...events].reverse().find((event) => event.type === "turn.completed")
			?.usage ?? {};
	const result = {
		id: evalCase.id,
		name: evalCase.name,
		configuration: options.configuration,
		model: options.model,
		reasoning: options.reasoning,
		exitCode: execution.exitCode,
		timedOut: execution.timedOut,
		durationSeconds: execution.durationSeconds,
		totalTokens:
			(usage.input_tokens ?? 0) +
			(usage.output_tokens ?? 0) +
			(usage.reasoning_output_tokens ?? 0),
		...grading,
	};
	await fs.writeFile(
		path.join(runDir, "grading.json"),
		`${JSON.stringify({ expectations: grading.expectations }, null, 2)}\n`,
	);
	await fs.writeFile(
		path.join(runDir, "result.json"),
		`${JSON.stringify(result, null, 2)}\n`,
	);
	console.log(
		`[${options.configuration}] eval ${evalCase.id} ${result.passed ? "passed" : "failed"} (${execution.durationSeconds.toFixed(1)}s)`,
	);
	return result;
}

async function runPool(items, concurrency, worker) {
	const results = new Array(items.length);
	let next = 0;
	await Promise.all(
		Array.from({ length: Math.min(concurrency, items.length) }, async () => {
			while (next < items.length) {
				const index = next++;
				results[index] = await worker(items[index]);
			}
		}),
	);
	return results;
}

async function writeBenchmark(options, summary) {
	const summaries = { [options.configuration]: summary };
	for (const configuration of ["baseline", "candidate"]) {
		const target = path.join(options.output, `${configuration}-summary.json`);
		if (await exists(target))
			summaries[configuration] = JSON.parse(await fs.readFile(target, "utf8"));
	}
	await fs.writeFile(
		path.join(options.output, "benchmark.json"),
		`${JSON.stringify(
			{
				metadata: {
					model: options.model,
					reasoning: options.reasoning,
					generatedAt: new Date().toISOString(),
				},
				configurations: summaries,
			},
			null,
			2,
		)}\n`,
	);
}

function summarize(options, results) {
	return {
		configuration: options.configuration,
		model: options.model,
		reasoning: options.reasoning,
		passed: results.filter((item) => item.passed).length,
		total: results.length,
		passRate:
			results.filter((item) => item.passed).length /
			Math.max(results.length, 1),
		durationSeconds: results.reduce(
			(sum, item) => sum + item.durationSeconds,
			0,
		),
		totalTokens: results.reduce((sum, item) => sum + item.totalTokens, 0),
		results,
	};
}

async function regrade(options, catalog) {
	const results = [];
	for (const evalCase of catalog.evals) {
		const runDir = path.join(
			options.output,
			options.configuration,
			`eval-${evalCase.id}-${evalCase.name}`,
		);
		const resultPath = path.join(runDir, "result.json");
		if (!(await exists(resultPath)))
			throw new Error(`Missing result for eval ${evalCase.id}`);
		const previous = JSON.parse(await fs.readFile(resultPath, "utf8"));
		const workspace = path.join(runDir, "repo");
		const baseSha = (
			await git(workspace, ["rev-list", "--max-parents=0", "HEAD"])
		).split("\n")[0];
		const transcript = await fs.readFile(
			path.join(runDir, "transcript.jsonl"),
			"utf8",
		);
		const finalText = await fs
			.readFile(path.join(runDir, "final.md"), "utf8")
			.catch(() => "");
		const grading = await gradeCase(evalCase, {
			workspace,
			baseSha,
			finalText,
			transcript,
			commands: commandTexts(parseEvents(transcript)),
		});
		const result = { ...previous, ...grading };
		await fs.writeFile(resultPath, `${JSON.stringify(result, null, 2)}\n`);
		await fs.writeFile(
			path.join(runDir, "grading.json"),
			`${JSON.stringify({ expectations: grading.expectations }, null, 2)}\n`,
		);
		results.push(result);
	}
	return results;
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.help) return console.log(usage);
	if (!(await exists(path.join(options.skill, "SKILL.md"))))
		throw new Error("Skill source is missing SKILL.md");
	if (!(await exists(authSource)))
		throw new Error(`Codex auth not found at ${authSource}`);
	const catalog = JSON.parse(
		await fs.readFile(path.join(evalDir, "evals.json"), "utf8"),
	);
	await fs.mkdir(options.output, { recursive: true });
	const results = options.regradeOnly
		? await regrade(options, catalog)
		: await runPool(catalog.evals, options.concurrency, (item) =>
				runCase(options, item),
			);
	const summary = summarize(options, results);
	await fs.writeFile(
		path.join(options.output, `${options.configuration}-summary.json`),
		`${JSON.stringify(summary, null, 2)}\n`,
	);
	await writeBenchmark(options, summary);
	console.log(
		`${options.configuration}: ${summary.passed}/${summary.total} passed`,
	);
}

await main();
