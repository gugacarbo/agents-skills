#!/usr/bin/env bun
import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const evalsDirectory = path.dirname(fileURLToPath(import.meta.url));

const usage = `Usage:
  bun tests/evals/run-evals.mjs --skill PATH --output PATH [options]

Options:
  --configuration NAME  Result directory label (default: with_skill)
  --evals IDS           Comma-separated eval IDs (default: all)
  --model MODEL          Agent executor model (default: gpt-5.4-mini)
  --reasoning EFFORT    Model reasoning effort (default: medium)
  --agent CLI            Agent CLI to invoke (default: codex)
  --run NUMBER           Run number (default: 1)
  --help                 Show this help`;

function parseArgs(argv) {
	const options = {
		configuration: "with_skill",
		model: "gpt-5.4-mini",
		reasoning: "medium",
		agent: "codex",
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
			// Preserve malformed lines in the raw transcript.
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

function result(text, passed, evidence) {
	return { text, passed: Boolean(passed), evidence };
}

async function grade(evalCase, context) {
	const { commands, transcriptText, finalText } = context;
	const combined = `${transcriptText}\n${finalText}`;
	const expectations = [];

	const hasCommand = (pattern) =>
		commands.some((command) => new RegExp(pattern, "i").test(command));
	const hasText = (pattern) => new RegExp(pattern, "i").test(combined);

	if (evalCase.id === 1) {
		expectations.push(
			result(
				evalCase.expectations[0],
				!hasCommand("transition-issue.sh.*--activate") &&
					!hasText("/code-flow"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[1],
				!hasCommand("gh issue edit.*--add-label.*code-flow") &&
					!hasCommand("gh issue edit.*--add-label.*stage:"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[2],
				hasText("read-only|explícit|explicit|não ativa|not activate"),
				`transcript excerpt inspected`,
			),
			result(
				evalCase.expectations[3],
				!hasCommand("gh issue edit.*--add-label"),
				`commands=${JSON.stringify(commands)}`,
			),
		);
	}

	if (evalCase.id === 2) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasText("stage:in-progress"),
				`transcript mentions overlay`,
			),
			result(
				evalCase.expectations[1],
				!hasCommand("transition-issue.sh.*--start-work"),
				`commands=${JSON.stringify(commands)}`,
			),
			result(
				evalCase.expectations[2],
				hasText("abc-123"),
				`transcript references existing run_id`,
			),
			result(
				evalCase.expectations[3],
				hasText("activity reset|reset|wait|aguardar|outro|another"),
				`transcript recommends reset or waiting`,
			),
		);
	}

	if (evalCase.id === 3) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasText("dispatcher"),
				`transcript identifies dispatcher`,
			),
			result(
				evalCase.expectations[1],
				hasText("Complexity:?\\s*S|complexidade:?\\s*S") &&
					hasText("rubric|rubrica|revers"),
				`transcript records S rubric`,
			),
			result(
				evalCase.expectations[2],
				hasText("stage:ready-for-execution"),
				`transcript selects direct execution`,
			),
			result(
				evalCase.expectations[3],
				!hasText("awaiting-triage-approval|stage:needs-architect"),
				`transcript avoids unnecessary gates`,
			),
		);
	}

	if (evalCase.id === 4) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasCommand("validate-evidence.sh") || hasText("run.?id"),
				`transcript validates evidence/run IDs`,
			),
			result(
				evalCase.expectations[1],
				hasText("disp-1") && hasText("exec-1"),
				`transcript references producer runs`,
			),
			result(
				evalCase.expectations[2],
				!hasText("recus|refus|autor.*viol|author.*viol"),
				`same GitHub author is allowed`,
			),
			result(
				evalCase.expectations[3],
				hasText("review|revis"),
				`code-reviewer proceeds`,
			),
		);
	}

	if (evalCase.id === 5) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasText("AGENTS.md"),
				`transcript discovers AGENTS.md`,
			),
			result(
				evalCase.expectations[1],
				hasText("project_guidance"),
				`transcript records project_guidance`,
			),
			result(
				evalCase.expectations[2],
				hasText("conventional commit|squash"),
				`transcript respects project conventions`,
			),
			result(
				evalCase.expectations[3],
				!hasText("override|ignor.*convention|contradiz"),
				`transcript does not override conventions`,
			),
		);
	}

	if (evalCase.id === 6) {
		expectations.push(
			result(
				evalCase.expectations[0],
				hasText("contrato público|public contract|spec"),
				"material impact detected",
			),
			result(
				evalCase.expectations[1],
				hasText("pare|stop|não.*implement|do not.*implement"),
				"implementation stops",
			),
			result(
				evalCase.expectations[2],
				hasText("stage:needs-architect"),
				"architect destination selected",
			),
		);
	}

	const passed = expectations.every((item) => item.passed);
	return { passed, expectations };
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.help) {
		process.stdout.write(`${usage}\n`);
		return;
	}

	const evalsPath = path.join(evalsDirectory, "evals.json");
	const evalsFile = JSON.parse(await fs.readFile(evalsPath, "utf8"));
	const cases = evalsFile.evals.filter(
		(item) => !options.evalIds || options.evalIds.has(item.id),
	);

	const runDir = path.join(
		options.output,
		options.configuration,
		`run-${options.run}`,
	);
	await fs.mkdir(runDir, { recursive: true });

	const results = [];
	for (const evalCase of cases) {
		const caseDir = path.join(runDir, `eval-${evalCase.id}`);
		await fs.mkdir(caseDir, { recursive: true });

		const promptPath = path.join(caseDir, "prompt.md");
		await fs.writeFile(promptPath, evalCase.prompt);

		const transcriptPath = path.join(caseDir, "transcript.jsonl");
		const stderrPath = path.join(caseDir, "stderr.log");
		const finalPath = path.join(caseDir, "final.md");

		const prompt =
			options.configuration === "with_skill"
				? `Read and apply the skill at ${path.join(options.skill, "SKILL.md")}.\n\n${evalCase.prompt}`
				: evalCase.prompt;
		const agentArgs = [
			"exec",
			"--json",
			"--sandbox",
			"read-only",
			"--skip-git-repo-check",
			"-m",
			options.model,
			"--output-last-message",
			finalPath,
			prompt,
		];

		const runResult = await runCommand(options.agent, agentArgs, {
			cwd: caseDir,
			stdout: transcriptPath,
			stderr: stderrPath,
			env: { ...process.env, CODE_FLOW_EVAL_PROMPT: prompt },
			timeoutMs: 600_000,
		});

		const transcriptText = await fs
			.readFile(transcriptPath, "utf8")
			.catch(() => "");
		const finalText = await fs.readFile(finalPath, "utf8").catch(() => "");
		const events = parseEvents(transcriptText);
		const commands = commandExecutions(events);

		const gradeResult = await grade(evalCase, {
			commands,
			transcriptText,
			finalText,
			events,
		});

		const summary = {
			id: evalCase.id,
			skill_type: evalCase.skill_type,
			configuration: options.configuration,
			run: options.run,
			passed: gradeResult.passed,
			exitCode: runResult.exitCode,
			timedOut: runResult.timedOut,
			durationSeconds: runResult.durationSeconds,
			expectations: gradeResult.expectations,
		};
		results.push(summary);
		await fs.writeFile(
			path.join(caseDir, "result.json"),
			`${JSON.stringify(summary, null, 2)}\n`,
		);
	}

	const summaryPath = path.join(runDir, "summary.json");
	await fs.writeFile(
		summaryPath,
		`${JSON.stringify({ configuration: options.configuration, results }, null, 2)}\n`,
	);

	const passed = results.filter((item) => item.passed).length;
	process.stdout.write(
		`configuration=${options.configuration} run=${options.run} passed=${passed}/${results.length}\n`,
	);
	if (passed < results.length) process.exitCode = 1;
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
