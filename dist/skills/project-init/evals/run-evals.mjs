#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const evalsDirectory = path.dirname(fileURLToPath(import.meta.url));

const usage = `Usage:
  node evals/run-evals.mjs --skill PATH --output PATH [options]

Options:
  --configuration NAME  Result directory label (default: with_skill)
  --evals IDS           Comma-separated eval IDs (default: all)
  --model MODEL         Codex executor model (default: gpt-5.4-mini)
  --reasoning EFFORT    Model reasoning effort (default: medium)
  --run NUMBER          Run number (default: 1)
  --help                Show this help`;

function parseArgs(argv) {
	const options = {
		configuration: "with_skill",
		model: "gpt-5.4-mini",
		reasoning: "medium",
		run: 1,
	};
	for (let index = 0; index < argv.length; index += 1) {
		const argument = argv[index];
		if (argument === "--help") return { help: true };
		if (!argument.startsWith("--")) continue;
		const key = argument.slice(2);
		const value = argv[index + 1];
		if (!value || value.startsWith("--"))
			throw new Error(`Missing value for --${key}`);
		options[key] = value;
		index += 1;
	}
	for (const required of ["skill", "output"]) {
		if (!options[required]) throw new Error(`Missing required --${required}`);
	}
	options.skill = path.resolve(options.skill);
	options.output = path.resolve(options.output);
	options.run = Number(options.run);
	options.evalIds = options.evals
		? new Set(
				String(options.evals)
					.split(",")
					.map((value) => Number(value.trim())),
			)
		: null;
	return options;
}

async function exists(filePath) {
	try {
		await fs.access(filePath);
		return true;
	} catch {
		return false;
	}
}

async function hashFile(filePath) {
	const content = await fs.readFile(filePath);
	return createHash("sha256").update(content).digest("hex");
}

async function collectFiles(root, relative = "") {
	const directory = path.join(root, relative);
	if (!(await exists(directory))) return [];
	const entries = await fs.readdir(directory, { withFileTypes: true });
	const files = [];
	for (const entry of entries.sort((left, right) =>
		left.name.localeCompare(right.name),
	)) {
		if ([".agents", ".git"].includes(entry.name)) continue;
		const child = path.join(relative, entry.name);
		if (entry.isDirectory()) files.push(...(await collectFiles(root, child)));
		else if (entry.isFile()) {
			files.push({
				path: child.replaceAll(path.sep, "/"),
				sha256: await hashFile(path.join(root, child)),
			});
		}
	}
	return files;
}

async function runCommand(command, args, options) {
	const startedAt = new Date();
	const started = performance.now();
	const stdoutHandle = await fs.open(options.stdout, "w");
	const stderrHandle = await fs.open(options.stderr, "w");
	let timedOut = false;
	try {
		const exitCode = await new Promise((resolve, reject) => {
			const child = spawn(command, args, {
				cwd: options.cwd,
				env: options.env ?? process.env,
				stdio: ["ignore", stdoutHandle.fd, stderrHandle.fd],
			});
			const timer = setTimeout(() => {
				timedOut = true;
				child.kill("SIGTERM");
			}, options.timeoutMs ?? 600_000);
			child.once("error", reject);
			child.once("exit", (code) => {
				clearTimeout(timer);
				resolve(code ?? 1);
			});
		});
		return {
			exitCode,
			timedOut,
			startedAt: startedAt.toISOString(),
			endedAt: new Date().toISOString(),
			durationSeconds: (performance.now() - started) / 1000,
		};
	} finally {
		await stdoutHandle.close();
		await stderrHandle.close();
	}
}

function parseEvents(transcript) {
	const events = [];
	for (const line of transcript.split("\n")) {
		if (!line.trim().startsWith("{")) continue;
		try {
			events.push(JSON.parse(line));
		} catch {
			// Preserve malformed lines in the raw transcript; they are not structured events.
		}
	}
	return events;
}

function commandExecutions(events) {
	const commands = [];
	for (const event of events) {
		if (event.type !== "item.completed") continue;
		const item = event?.item;
		if (
			!item ||
			!["command_execution", "tool_call", "mcp_tool_call"].includes(item.type)
		)
			continue;
		const command =
			item.command ?? item.arguments?.command ?? item.arguments?.cmd;
		if (typeof command === "string") commands.push(command);
		else if (Array.isArray(command)) commands.push(command.join(" "));
	}
	return commands;
}

function projectInitPlan(events) {
	for (const event of [...events].reverse()) {
		if (event.type !== "item.completed") continue;
		const item = event?.item;
		if (
			item?.type !== "command_execution" ||
			!String(item.command).includes("scripts/project-init.mjs plan")
		)
			continue;
		try {
			return JSON.parse(item.aggregated_output);
		} catch {
			return null;
		}
	}
	return null;
}

function packageManagerWasExecuted(commands) {
	return commands.some((command) =>
		/(^|(?:&&|\|\||;|\n)\s*)(?:pnpm|npm|bun)(?:\s|$)/m.test(command),
	);
}

function hasProjectInitCommand(commands, phase) {
	return commands.some(
		(command) =>
			command.includes("scripts/project-init.mjs") &&
			command.includes(` ${phase}`),
	);
}

function commandIndex(commands, phase) {
	return commands.findIndex(
		(command) =>
			command.includes("scripts/project-init.mjs") &&
			command.includes(` ${phase}`),
	);
}

function fileMap(files) {
	return new Map(files.map((item) => [item.path, item.sha256]));
}

function result(text, passed, evidence) {
	return { text, passed: Boolean(passed), evidence };
}

async function grade(evalCase, context) {
	const {
		commands,
		transcriptText,
		finalText,
		files,
		beforeHashes,
		workspace,
		events,
	} = context;
	const combined = `${transcriptText}\n${finalText}`;
	const plannerResult = projectInitPlan(events);
	const targetName = [2, 4].includes(evalCase.id)
		? evalCase.id === 2
			? "web-ui"
			: "dashboard"
		: evalCase.id === 5
			? "bun-worker"
			: evalCase.id === 1
				? "api-core"
				: "existing-app";
	const target = path.join(workspace, targetName);
	const targetFiles = fileMap(
		files.filter((item) => item.path.startsWith(`${targetName}/`)),
	);
	const relativeTargetFiles = new Set(
		[...targetFiles.keys()].map((file) => file.slice(targetName.length + 1)),
	);
	const planIndex = commandIndex(commands, "plan");
	const applyIndex = commandIndex(commands, "apply");
	const noPackageExecution = !packageManagerWasExecuted(commands);
	const expectations = [];

	if (evalCase.id === 1) {
		const required = [
			"AGENTS.md",
			"REQUIREMENTS.md",
			".editorconfig",
			".gitignore",
			"knip.json",
			"cspell.config.yaml",
			".husky/pre-commit",
			".husky/pre-push",
			"scripts/pre-commit",
			"scripts/lib/shared.sh",
		];
		const agents = await fs
			.readFile(path.join(target, "AGENTS.md"), "utf8")
			.catch(() => "");
		expectations.push(
			result(
				evalCase.expectations[0],
				planIndex >= 0 && applyIndex > planIndex,
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				required.every((file) => relativeTargetFiles.has(file)),
				`files=${JSON.stringify([...relativeTargetFiles])}`,
			),
			result(
				evalCase.expectations[2],
				!relativeTargetFiles.has(".lintstagedrc.js"),
				`files=${JSON.stringify([...relativeTargetFiles])}`,
			),
			result(
				evalCase.expectations[3],
				/Node/i.test(agents) &&
					/General/i.test(agents) &&
					!agents.includes("request_user_input"),
				`AGENTS.md chars=${agents.length}`,
			),
			result(
				evalCase.expectations[4],
				combined.includes("@biomejs/biome") &&
					/cspell/i.test(finalText) &&
					noPackageExecution,
				`package_manager_executed=${!noPackageExecution}`,
			),
		);
	}

	if (evalCase.id === 2) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasProjectInitCommand(commands, "plan") &&
					combined.includes("svelte-ts"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				combined.includes("pnpm create vite . --template svelte-ts") &&
					/overlay/i.test(combined),
				"framework command and overlay order inspected in transcript",
			),
			result(
				evalCase.expectations[2],
				combined.includes("svelte-check") &&
					combined.includes("@biomejs/biome"),
				"typecheck and Biome command inspected in transcript",
			),
			result(
				evalCase.expectations[3],
				!(await exists(target)) && noPackageExecution,
				`target_exists=${await exists(target)} package_manager_executed=${!noPackageExecution}`,
			),
		);
	}

	if (evalCase.id === 3) {
		const agentsPath = path.join(target, "AGENTS.md");
		const readmePath = path.join(target, "README.md");
		const agentsHash = await hashFile(agentsPath).catch(() => "missing");
		const readmeHash = await hashFile(readmePath).catch(() => "missing");
		expectations.push(
			result(
				evalCase.expectations[0],
				hasProjectInitCommand(commands, "plan"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				JSON.stringify(plannerResult?.collisions) ===
					JSON.stringify(["AGENTS.md"]),
				`collisions=${JSON.stringify(plannerResult?.collisions ?? null)}`,
			),
			result(
				evalCase.expectations[2],
				!hasProjectInitCommand(commands, "apply") ||
					!commands.some(
						(command) =>
							command.includes("--approve") || command.includes("--force"),
					),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[3],
				agentsHash === beforeHashes.AGENTS &&
					readmeHash === beforeHashes.README,
				`agents=${agentsHash} readme=${readmeHash}`,
			),
			result(
				evalCase.expectations[4],
				/(?:approv|aprova|confirm)[^\n]*AGENTS\.md|AGENTS\.md[^\n]*(?:approv|aprova|confirm)/i.test(
					finalText,
				) && !/Aguardando aprova(?:ç|c)[aã]o:\s*nenhum/i.test(finalText),
				`final=${finalText}`,
			),
		);
	}

	if (evalCase.id === 4) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasProjectInitCommand(commands, "plan") &&
					combined.includes("typescript/tanstack-start"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				combined.includes(
					"pnpm dlx create-tanstack-app@latest dashboard --template file-router --package-manager pnpm",
				) && /overlay/i.test(combined),
				"TanStack CLI and overlay order inspected in transcript",
			),
			result(
				evalCase.expectations[2],
				/full-stack|full stack/i.test(combined) &&
					/SSR|server-side rendering/i.test(combined) &&
					/Vite/i.test(combined) &&
					/routeTree\.gen\.ts/i.test(combined),
				"TanStack conventions inspected in transcript",
			),
			result(
				evalCase.expectations[3],
				combined.includes("@biomejs/biome") &&
					!/pnpm add[^\n]*(?:@tanstack\/react-start|@tanstack\/react-router)/i.test(
						finalText,
					),
				"post-generator dependencies inspected",
			),
			result(
				evalCase.expectations[4],
				!(await exists(target)) && noPackageExecution,
				`target_exists=${await exists(target)} package_manager_executed=${!noPackageExecution}`,
			),
		);
	}

	if (evalCase.id === 5) {
		const required = [
			"AGENTS.md",
			"REQUIREMENTS.md",
			".editorconfig",
			".gitignore",
			"knip.json",
			".husky/pre-commit",
			".husky/pre-push",
			"scripts/pre-commit",
			"scripts/lib/shared.sh",
		];
		const scripts = await Promise.all(
			["scripts/pre-commit", "scripts/lib/shared.sh", ".husky/pre-push"].map(
				(file) => fs.readFile(path.join(target, file), "utf8").catch(() => ""),
			),
		);
		const scriptText = scripts.join("\n");
		expectations.push(
			result(
				evalCase.expectations[0],
				planIndex >= 0 && applyIndex > planIndex,
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				required.every((file) => relativeTargetFiles.has(file)),
				`files=${JSON.stringify([...relativeTargetFiles])}`,
			),
			result(
				evalCase.expectations[2],
				!relativeTargetFiles.has("cspell.config.yaml") &&
					!relativeTargetFiles.has(".lintstagedrc.js"),
				`files=${JSON.stringify([...relativeTargetFiles])}`,
			),
			result(
				evalCase.expectations[3],
				/bun/i.test(scriptText) && !scriptText.includes("release:verify"),
				`script_chars=${scriptText.length}`,
			),
			result(
				evalCase.expectations[4],
				/bun add[^\n]*turbo/i.test(finalText) &&
					finalText.includes("@biomejs/biome") &&
					noPackageExecution,
				`package_manager_executed=${!noPackageExecution}`,
			),
		);
	}

	if (evalCase.id === 6) {
		const agentsPath = path.join(target, "AGENTS.md");
		const readmePath = path.join(target, "README.md");
		const agentsHash = await hashFile(agentsPath).catch(() => "missing");
		const readmeHash = await hashFile(readmePath).catch(() => "missing");
		expectations.push(
			result(
				evalCase.expectations[0],
				planIndex >= 0 &&
					applyIndex > planIndex &&
					commands[applyIndex].includes("--approve") &&
					commands[applyIndex].includes("AGENTS.md"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				agentsHash !== beforeHashes.AGENTS && agentsHash !== "missing",
				`before=${beforeHashes.AGENTS} after=${agentsHash}`,
			),
			result(
				evalCase.expectations[2],
				readmeHash === beforeHashes.README,
				`before=${beforeHashes.README} after=${readmeHash}`,
			),
			result(
				evalCase.expectations[3],
				[".editorconfig", ".gitignore", "REQUIREMENTS.md"].every((file) =>
					relativeTargetFiles.has(file),
				),
				`files=${JSON.stringify([...relativeTargetFiles])}`,
			),
			result(
				evalCase.expectations[4],
				/overwrit|substitu|sobrescrit/i.test(finalText) &&
					/created|criad/i.test(finalText) &&
					/preserv/i.test(finalText),
				`final=${finalText}`,
			),
		);
	}

	const passed = expectations.filter(
		(expectation) => expectation.passed,
	).length;
	return {
		expectations,
		summary: {
			passed,
			failed: expectations.length - passed,
			total: expectations.length,
			pass_rate: expectations.length ? passed / expectations.length : 0,
		},
	};
}

async function prepareWorkspace(workspace, selectedSkill, evalCase) {
	await fs.mkdir(workspace, { recursive: true });
	await runCommand("git", ["init", "-q"], {
		cwd: workspace,
		stdout: path.join(workspace, ".git-init.stdout"),
		stderr: path.join(workspace, ".git-init.stderr"),
		timeoutMs: 30_000,
	});
	const installedSkill = path.join(
		workspace,
		".agents",
		"skills",
		"project-init",
	);
	await fs.mkdir(path.dirname(installedSkill), { recursive: true });
	await fs.cp(selectedSkill, installedSkill, { recursive: true, force: true });
	if ([3, 6].includes(evalCase.id)) {
		await fs.cp(
			path.join(evalsDirectory, "fixtures", "existing-app"),
			path.join(workspace, "existing-app"),
			{
				recursive: true,
				force: true,
			},
		);
	}
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.help) {
		console.log(usage);
		return;
	}
	const evalData = JSON.parse(
		await fs.readFile(path.join(evalsDirectory, "evals.json"), "utf8"),
	);
	const selectedEvals = evalData.evals.filter(
		(evalCase) => !options.evalIds || options.evalIds.has(evalCase.id),
	);
	if (!selectedEvals.length) throw new Error("No evals selected");

	for (const evalCase of selectedEvals) {
		const runDirectory = path.join(
			options.output,
			`eval-${evalCase.id}`,
			options.configuration,
			`run-${options.run}`,
		);
		if (await exists(runDirectory))
			throw new Error(`Run directory already exists: ${runDirectory}`);
		const workspace = path.join(runDirectory, "workspace");
		const outputs = path.join(runDirectory, "outputs");
		await fs.mkdir(outputs, { recursive: true });
		await prepareWorkspace(workspace, options.skill, evalCase);
		await fs.writeFile(
			path.join(runDirectory, "eval_metadata.json"),
			`${JSON.stringify({ eval_id: evalCase.id, configuration: options.configuration }, null, 2)}\n`,
		);

		const beforeHashes = {};
		if ([3, 6].includes(evalCase.id)) {
			beforeHashes.AGENTS = await hashFile(
				path.join(workspace, "existing-app", "AGENTS.md"),
			);
			beforeHashes.README = await hashFile(
				path.join(workspace, "existing-app", "README.md"),
			);
		}

		const finalPath = path.join(outputs, "final.txt");
		const transcriptPath = path.join(outputs, "transcript.jsonl");
		const stderrPath = path.join(outputs, "stderr.log");
		const prompt = [
			"You are executing a behavioral evaluation in an isolated git workspace.",
			"You must use the repository-local project-init skill at .agents/skills/project-init/SKILL.md.",
			"Do not modify anything under .agents/skills.",
			"Treat the following text as the user's task and complete it autonomously:",
			"",
			evalCase.prompt,
		].join("\n");
		console.log(`[${options.configuration}] eval ${evalCase.id} starting`);
		const isolatedHome = path.join(workspace, ".eval-home");
		await fs.mkdir(isolatedHome, { recursive: true });
		const codexHome =
			process.env.CODEX_HOME ?? path.join(process.env.HOME, ".codex");
		const execution = await runCommand(
			"codex",
			[
				"exec",
				"--ephemeral",
				"--skip-git-repo-check",
				"--ignore-user-config",
				"--model",
				options.model,
				"--config",
				`model_reasoning_effort=${JSON.stringify(options.reasoning)}`,
				"--config",
				'skills.config=[{path="/home/gustavo/.agents/skills/project-init/SKILL.md",enabled=false}]',
				"--dangerously-bypass-approvals-and-sandbox",
				"--json",
				"--output-last-message",
				finalPath,
				prompt,
			],
			{
				cwd: workspace,
				stdout: transcriptPath,
				stderr: stderrPath,
				env: { ...process.env, HOME: isolatedHome, CODEX_HOME: codexHome },
			},
		);
		const transcriptText = await fs
			.readFile(transcriptPath, "utf8")
			.catch(() => "");
		const finalText = await fs.readFile(finalPath, "utf8").catch(() => "");
		const events = parseEvents(transcriptText);
		const commands = commandExecutions(events);
		const files = await collectFiles(workspace);
		await fs.writeFile(
			path.join(outputs, "files.json"),
			`${JSON.stringify(files, null, 2)}\n`,
		);
		await fs.writeFile(
			path.join(outputs, "commands.json"),
			`${JSON.stringify(commands, null, 2)}\n`,
		);

		const usageEvent = [...events]
			.reverse()
			.find((event) => event.type === "turn.completed");
		const usage = usageEvent?.usage ?? {};
		const toolCalls = {};
		for (const event of events) {
			if (!event?.item?.type || !event.type?.startsWith("item.")) continue;
			toolCalls[event.item.type] = (toolCalls[event.item.type] ?? 0) + 1;
		}
		const metrics = {
			tool_calls: toolCalls,
			total_tool_calls: Object.values(toolCalls).reduce(
				(sum, count) => sum + count,
				0,
			),
			total_steps: events.filter((event) => event.type === "item.completed")
				.length,
			files_created: files.map((item) => item.path),
			errors_encountered: execution.exitCode === 0 ? 0 : 1,
			output_chars: finalText.length,
			transcript_chars: transcriptText.length,
		};
		await fs.writeFile(
			path.join(outputs, "metrics.json"),
			`${JSON.stringify(metrics, null, 2)}\n`,
		);
		const totalTokens =
			(usage.input_tokens ?? 0) +
			(usage.output_tokens ?? 0) +
			(usage.reasoning_output_tokens ?? 0);
		const timing = {
			total_tokens: totalTokens,
			total_duration_seconds: execution.durationSeconds,
			executor_start: execution.startedAt,
			executor_end: execution.endedAt,
			executor_duration_seconds: execution.durationSeconds,
		};
		await fs.writeFile(
			path.join(runDirectory, "timing.json"),
			`${JSON.stringify(timing, null, 2)}\n`,
		);
		const grading = await grade(evalCase, {
			commands,
			events,
			transcriptText,
			finalText,
			files,
			beforeHashes,
			workspace,
		});
		grading.execution_metrics = metrics;
		grading.timing = timing;
		grading.user_notes_summary = {
			uncertainties: execution.timedOut ? ["Executor timed out"] : [],
			needs_review:
				execution.exitCode === 0
					? []
					: [`Codex exited with ${execution.exitCode}`],
			workarounds: [],
		};
		await fs.writeFile(
			path.join(runDirectory, "grading.json"),
			`${JSON.stringify(grading, null, 2)}\n`,
		);
		console.log(
			`[${options.configuration}] eval ${evalCase.id} ${grading.summary.passed}/${grading.summary.total} in ${execution.durationSeconds.toFixed(1)}s`,
		);
	}
}

await main();
