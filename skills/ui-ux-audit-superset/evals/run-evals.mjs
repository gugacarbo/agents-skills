#!/usr/bin/env bun

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const evalDir = path.dirname(fileURLToPath(import.meta.url));
const skillRoot = path.resolve(evalDir, "..");
const catalogPath = path.join(evalDir, "evals.json");

const usage = `Usage:
  bun evals/run-evals.mjs --host claude --configuration with_skill|without_skill --output PATH [options]

Options:
  --skill PATH       Skill source (default: parent of evals/)
  --evals IDS        Comma-separated eval IDs (default: all)
  --runs NUMBER      Fresh repetitions (default: 1)
  --run NUMBER       Starting run number (default: 1)
  --model MODEL      Claude model (default: configured default)
  --reasoning LEVEL  Claude effort level (default: medium)
  --timeout SECONDS  Per-run timeout (default: 600)
  --aggregate-only   Rebuild benchmark.json from existing summaries
  --regrade-only     Regrade existing runs and rebuild benchmark.json
  --help             Show this help`;

function parseArgs(argv) {
	const options = {
		host: "claude",
		runs: 1,
		run: 1,
		timeout: 600,
		reasoning: "medium",
		skill: skillRoot,
	};
	for (let index = 0; index < argv.length; index += 1) {
		const argument = argv[index];
		if (argument === "--help") return { help: true };
		if (argument === "--aggregate-only") {
			options.aggregateOnly = true;
			continue;
		}
		if (argument === "--regrade-only") {
			options.regradeOnly = true;
			continue;
		}
		if (!argument.startsWith("--"))
			throw new Error(`Unexpected argument: ${argument}`);
		const value = argv[index + 1];
		if (!value || value.startsWith("--"))
			throw new Error(`Missing value for ${argument}`);
		options[argument.slice(2)] = value;
		index += 1;
	}
	if (options.help) return options;
	if (!options.output) throw new Error("Missing --output");
	if (options.host !== "claude")
		throw new Error("Only --host claude is supported");
	if (
		!options.aggregateOnly &&
		!options.regradeOnly &&
		!new Set(["with_skill", "without_skill"]).has(options.configuration)
	)
		throw new Error("--configuration must be with_skill or without_skill");
	options.output = path.resolve(options.output);
	options.skill = path.resolve(options.skill);
	options.runs = Number(options.runs);
	options.run = Number(options.run);
	options.timeout = Number(options.timeout);
	options.evalIds = options.evals
		? new Set(String(options.evals).split(",").map(Number))
		: null;
	if (!Number.isInteger(options.runs) || options.runs < 1)
		throw new Error("--runs must be a positive integer");
	return options;
}

async function exists(target) {
	return fs.access(target).then(
		() => true,
		() => false,
	);
}

async function hashFile(target) {
	return createHash("sha256")
		.update(await fs.readFile(target))
		.digest("hex");
}

async function snapshot(root, relative = "") {
	const files = [];
	for (const entry of (
		await fs.readdir(path.join(root, relative), { withFileTypes: true })
	).sort((a, b) => a.name.localeCompare(b.name))) {
		if ([".git", ".claude", ".agents"].includes(entry.name)) continue;
		const child = path.join(relative, entry.name);
		if (entry.isDirectory()) files.push(...(await snapshot(root, child)));
		else if (entry.isFile())
			files.push({
				path: child.replaceAll(path.sep, "/"),
				sha256: await hashFile(path.join(root, child)),
			});
	}
	return files;
}

async function runCommand(
	command,
	args,
	{ cwd, env, stdout, stderr, timeoutMs },
) {
	const out = await fs.open(stdout, "w");
	const err = await fs.open(stderr, "w");
	const startedAt = new Date();
	const started = performance.now();
	let timedOut = false;
	try {
		const exitCode = await new Promise((resolve, reject) => {
			const child = spawn(command, args, {
				cwd,
				env,
				stdio: ["ignore", out.fd, err.fd],
			});
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
			timedOut,
			startedAt: startedAt.toISOString(),
			endedAt: new Date().toISOString(),
			durationSeconds: (performance.now() - started) / 1000,
		};
	} finally {
		await out.close();
		await err.close();
	}
}

async function installRuntimeSkill(source, home) {
	const target = path.join(home, ".claude", "skills", "ui-ux-audit-superset");
	await fs.mkdir(target, { recursive: true });
	for (const entry of await fs.readdir(source, { withFileTypes: true })) {
		if (
			new Set(["tests", "evals", "package.json", ".gitignore"]).has(entry.name)
		)
			continue;
		await fs.cp(path.join(source, entry.name), path.join(target, entry.name), {
			recursive: true,
		});
	}
}

function contains(text, expression) {
	return new RegExp(expression, "isu").test(text);
}

function finalTextFromResult(raw) {
	try {
		return JSON.parse(raw).result ?? raw;
	} catch {
		return raw;
	}
}

/**
 * Grade a final response against the catalog's deterministic assertions.
 * These checks intentionally support manual review; they are not a substitute
 * for reading each output, diff, and transcript.
 */
function grade(evalCase, text, changed) {
	const normalized = `${text}\n${changed.join("\n")}`;
	const noChanges = changed.length === 0;
	const checks = [];
	const add = (index, passed, evidence) =>
		checks.push({
			text: evalCase.expectations[index],
			passed: Boolean(passed),
			evidence,
		});
	if (evalCase.id === 1) {
		add(
			0,
			contains(normalized, "audit mode|mode:|full product audit") &&
				contains(normalized, "WCAG 2\\.2") &&
				contains(normalized, "viewport|desktop|mobile"),
			"Checked scope and baseline.",
		);
		add(
			1,
			contains(normalized, "title") &&
				contains(normalized, "error|required|validation"),
			"Checked form-error discussion.",
		);
		add(
			2,
			contains(normalized, "delete service|delete permanently|danger zone") &&
				contains(normalized, "focus|cancel|dialog"),
			"Checked destructive-dialog discussion.",
		);
		add(
			3,
			contains(normalized, "keyboard") && contains(normalized, "focus"),
			"Checked keyboard/focus discussion.",
		);
		add(
			4,
			contains(normalized, "mobile|320|375|390|reflow|viewport"),
			"Checked responsive evidence or gap.",
		);
		add(
			5,
			contains(normalized, "assumption") &&
				contains(normalized, "not tested|not verified|verification gap") &&
				contains(normalized, "screen.?reader"),
			"Checked uncertainty handling.",
		);
		add(
			6,
			!contains(normalized, "WCAG compliant|legally compliant") && noChanges,
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 2) {
		add(
			0,
			contains(normalized, "WCAG 2\\.2") &&
				!contains(normalized, "WCAG compliant|conformant"),
			"Checked baseline and no conformance claim.",
		);
		add(
			1,
			contains(normalized, "title") &&
				contains(normalized, "aria-describedby|error|required|invalid") &&
				contains(normalized, "focus"),
			"Checked form-error behavior.",
		);
		add(
			2,
			contains(normalized, "status") &&
				contains(normalized, "role=.?status|live region|aria-live"),
			"Checked dynamic status evidence.",
		);
		add(
			3,
			contains(normalized, "target size|24.?24|row action|acknowledge"),
			"Checked target-size reasoning.",
		);
		add(
			4,
			contains(normalized, "dialog") &&
				contains(normalized, "escape|focus") &&
				contains(normalized, "restore|return"),
			"Checked dialog keyboard/focus.",
		);
		add(
			5,
			contains(normalized, "2\\.[0-9]+\\.[0-9]+|4\\.1\\.3|3\\.3\\.1") &&
				contains(normalized, "screen reader") &&
				contains(normalized, "not verified|not tested"),
			"Checked cautious criterion mapping and AT gap.",
		);
		add(
			6,
			!contains(normalized, "legally compliant|WCAG compliant") && noChanges,
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 3) {
		add(
			0,
			changed.length > 0 &&
				changed.every((file) => file === "index.html" || file.endsWith(".md")),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			contains(normalized, "aria-describedby|error") &&
				contains(normalized, "focus|preserv"),
			"Checked form-recovery remediation.",
		);
		add(
			2,
			contains(normalized, "dialog") &&
				contains(normalized, "escape|\\bEsc\\b|\\bEsc key\\b") &&
				contains(normalized, "focus"),
			"Checked dialog remediation.",
		);
		add(
			3,
			contains(normalized, "native") || contains(normalized, "semantics"),
			"Checked preservation of semantics.",
		);
		add(
			4,
			contains(normalized, "retest|tested|verify") &&
				contains(normalized, "keyboard|dialog") &&
				contains(normalized, "mobile|viewport|narrow"),
			"Checked retest report.",
		);
		add(
			5,
			contains(normalized, "fixed|partially fixed|unable to verify|not fixed"),
			"Checked status reporting.",
		);
	} else if (evalCase.id === 4) {
		add(
			0,
			contains(normalized, "scop|fast|review") &&
				!contains(normalized, "redesign the entire"),
			"Checked scoped response.",
		);
		add(
			1,
			contains(normalized, "button") && contains(normalized, "focus"),
			"Checked credit for native/focus strengths.",
		);
		add(
			2,
			!contains(normalized, "add (an? )?(onkey|key.*handler).*button"),
			"Checked no redundant native-button handler demand.",
		);
		add(
			3,
			contains(normalized, "reflow|form|dialog|target size|state|responsive"),
			"Checked relevant remaining risk.",
		);
		add(4, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 5) {
		add(
			0,
			contains(normalized, "DESIGN_SYSTEM\\.md") &&
				!contains(normalized, "figma (?:dev mode|spec)|storybook inspection"),
			"Checked canonical source without invented design sources.",
		);
		add(
			1,
			contains(normalized, "promo|accelerated rollout") &&
				contains(normalized, "drift|deviat|inconsisten") &&
				contains(normalized, "#7c3aed|purple|46px|10px|shadow"),
			"Checked accidental drift evidence.",
		);
		add(
			2,
			contains(normalized, "primary|secondary") &&
				(contains(normalized, "focus|border|40px|token") ||
					contains(normalized, "input")),
			"Checked successful canonical patterns.",
		);
		add(
			3,
			contains(normalized, "32px|32 px") &&
				contains(normalized, "approved exception|exception"),
			"Checked approved dense action exception.",
		);
		add(
			4,
			contains(normalized, "disabled|pending|loading|state"),
			"Checked required variants/states discussion.",
		);
		add(
			5,
			noChanges && !contains(normalized, "every hard.?coded|all hard.?coded"),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 6) {
		add(
			0,
			contains(normalized, "responsive|reflow") &&
				!contains(normalized, "full.?product audit"),
			"Checked scoped response.",
		);
		add(
			1,
			(contains(normalized, "375|390|320|mobile") &&
				contains(normalized, "intermediate|breakpoint|between|700")) ||
				contains(
					normalized,
					"viewport (?:testing|verification) (?:was )?(?:unavailable|not)",
				),
			"Checked mobile/intermediate coverage or gap.",
		);
		add(
			2,
			contains(
				normalized,
				"zoom|200%|400%|text (?:size|scaling)|not verified|could not",
			),
			"Checked zoom/reflow or recorded gap.",
		);
		add(
			3,
			contains(normalized, "table") &&
				contains(normalized, "horizontal scroll|column|card|overflow") &&
				contains(normalized, "header|action|understand"),
			"Checked table strategy.",
		);
		add(
			4,
			contains(normalized, "long|unbounded|truncat|wrap") &&
				!contains(normalized, "tables must|all tables should"),
			"Checked content robustness without universal rule.",
		);
		add(5, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 7) {
		add(
			0,
			contains(normalized, "rubric|dimension|criteria|weight"),
			"Checked scoring rubric definition.",
		);
		add(
			1,
			contains(normalized, "heuristic") &&
				(contains(normalized, "overall") || contains(normalized, "category")) &&
				contains(
					normalized,
					"not (?:authoritative|definitive)|do not establish|subjective|judgment",
				),
			"Checked heuristic score labeling.",
		);
		add(
			2,
			contains(normalized, "standards|WCAG|design system") &&
				contains(normalized, "heuristic|aesthetic|opportunit"),
			"Checked finding-type separation.",
		);
		add(
			3,
			contains(normalized, "DESIGN_SYSTEM|promo|token|button|input"),
			"Checked concrete evidence use.",
		);
		add(
			4,
			!contains(
				normalized,
				"WCAG compliant|legally compliant|fully conformant",
			),
			"Checked conformance overclaim.",
		);
		add(5, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 8) {
		add(
			0,
			contains(normalized, "quick audit|quick review|quick ui"),
			"Checked quick label.",
		);
		add(
			1,
			contains(normalized, "desktop") &&
				contains(normalized, "mobile") &&
				(contains(normalized, "keyboard") || contains(normalized, "focus")),
			"Checked requested minimum coverage.",
		);
		add(
			2,
			contains(normalized, "top|highest.?impact|priorit") &&
				!contains(normalized, "full product inventory|every applicable row"),
			"Checked top-impact focus.",
		);
		add(
			3,
			!contains(
				normalized,
				"whole product (?:is|proves)|entire product (?:is|proves)|fully accessible|full conformance",
			),
			"Checked no generalization.",
		);
		add(4, noChanges, `changed=${JSON.stringify(changed)}`);
	}
	const passed = checks.filter((check) => check.passed).length;
	return {
		expectations: checks,
		summary: {
			passed,
			failed: checks.length - passed,
			total: checks.length,
			pass_rate: checks.length ? passed / checks.length : 0,
		},
	};
}

async function collectSummaries(root) {
	const summaries = [];
	async function walk(directory) {
		for (const entry of await fs
			.readdir(directory, { withFileTypes: true })
			.catch(() => [])) {
			const target = path.join(directory, entry.name);
			if (entry.isDirectory()) await walk(target);
			else if (entry.name === "summary.json") {
				const summary = JSON.parse(await fs.readFile(target, "utf8"));
				summaries.push({ ...summary, __path: target });
			}
		}
	}
	await walk(root);
	return summaries;
}

function statistics(values) {
	if (!values.length) return { mean: 0, stddev: 0, min: 0, max: 0 };
	const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
	return {
		mean,
		stddev: Math.sqrt(
			values.reduce((sum, value) => sum + (value - mean) ** 2, 0) /
				values.length,
		),
		min: Math.min(...values),
		max: Math.max(...values),
	};
}

async function updateBenchmark(output, options) {
	const collected = await collectSummaries(output);
	const summaries = [...collected].sort(
		(a, b) =>
			a.configuration.localeCompare(b.configuration) ||
			a.evalId - b.evalId ||
			a.run - b.run,
	);
	for (const summary of summaries) delete summary.__path;
	const runs = summaries.map((summary) => ({
		eval_id: summary.evalId,
		eval_name: summary.evalName,
		configuration: summary.configuration,
		run_number: summary.run,
		result: {
			pass_rate: summary.grading.summary.pass_rate,
			passed: summary.grading.summary.passed,
			failed: summary.grading.summary.failed,
			total: summary.grading.summary.total,
			time_seconds: summary.timing.durationSeconds,
			tokens: summary.tokens,
			errors: summary.timing.exitCode === 0 ? 0 : 1,
		},
		expectations: summary.grading.expectations,
		notes: summary.notes,
	}));
	const configurations = [...new Set(runs.map((run) => run.configuration))];
	const models = [
		...new Set(
			summaries
				.map((summary) => summary.model)
				.filter((model) => Boolean(model)),
		),
	];
	const runSummary = {};
	for (const configuration of configurations) {
		const selected = runs.filter((run) => run.configuration === configuration);
		runSummary[configuration] = {
			pass_rate: statistics(selected.map((run) => run.result.pass_rate)),
			time_seconds: statistics(selected.map((run) => run.result.time_seconds)),
			tokens: statistics(selected.map((run) => run.result.tokens)),
		};
	}
	const withSkill = runSummary.with_skill;
	const withoutSkill = runSummary.without_skill;
	runSummary.delta = {
		pass_rate:
			(withSkill?.pass_rate.mean ?? 0) - (withoutSkill?.pass_rate.mean ?? 0),
		time_seconds:
			(withSkill?.time_seconds.mean ?? 0) -
			(withoutSkill?.time_seconds.mean ?? 0),
		tokens: (withSkill?.tokens.mean ?? 0) - (withoutSkill?.tokens.mean ?? 0),
	};
	await fs.writeFile(
		path.join(output, "benchmark.json"),
		JSON.stringify(
			{
				metadata: {
					skill_name: "ui-ux-audit-superset",
					skill_path: options.skill,
					timestamp: new Date().toISOString(),
					evals_run: [...new Set(runs.map((run) => run.eval_id))].sort(
						(a, b) => a - b,
					),
					runs_per_configuration: options.runs,
					models,
				},
				runs,
				run_summary: runSummary,
				notes: [
					"Deterministic rubric grading. Inspect each transcript and diff before treating a qualitative evaluation as verified.",
				],
			},
			null,
			2,
		),
	);
}

async function regradeExisting(output, catalog, options) {
	const cases = new Map(catalog.evals.map((item) => [item.id, item]));
	for (const summary of await collectSummaries(output)) {
		const evalCase = cases.get(summary.evalId);
		if (!evalCase || !summary.__path) continue;
		const runDir = path.dirname(summary.__path);
		const finalText = await fs
			.readFile(path.join(runDir, "outputs", "final.md"), "utf8")
			.catch(() => "");
		const changed = JSON.parse(
			await fs
				.readFile(path.join(runDir, "outputs", "changed-files.json"), "utf8")
				.catch(() => "[]"),
		);
		const grading = grade(evalCase, finalText, changed);
		summary.grading = grading;
		delete summary.__path;
		await fs.writeFile(
			path.join(runDir, "grading.json"),
			JSON.stringify(grading, null, 2),
		);
		await fs.writeFile(
			path.join(runDir, "summary.json"),
			JSON.stringify(summary, null, 2),
		);
	}
	await updateBenchmark(output, options);
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.help) return process.stdout.write(`${usage}\n`);
	if (!(await exists(path.join(options.skill, "SKILL.md"))))
		throw new Error(`Skill not found: ${options.skill}`);
	await fs.mkdir(options.output, { recursive: true });
	const catalog = JSON.parse(await fs.readFile(catalogPath, "utf8"));
	if (options.aggregateOnly || options.regradeOnly) {
		if (options.regradeOnly)
			await regradeExisting(options.output, catalog, options);
		else await updateBenchmark(options.output, options);
		return;
	}
	const cases = catalog.evals.filter(
		(item) => !options.evalIds || options.evalIds.has(item.id),
	);
	for (let repetition = 0; repetition < options.runs; repetition += 1) {
		for (const evalCase of cases) {
			const runNumber = options.run + repetition;
			const runDir = path.join(
				options.output,
				options.host,
				options.configuration,
				`run-${runNumber}`,
				`eval-${evalCase.id}-${evalCase.name}`,
			);
			const workspace = path.join(runDir, "repo");
			const home = path.join(runDir, "home");
			await fs.rm(runDir, { recursive: true, force: true });
			await fs.mkdir(runDir, { recursive: true });
			const fixture = path.join(evalDir, evalCase.files[0]);
			await fs.cp(fixture, workspace, { recursive: true });
			await runCommand("git", ["init", "-q"], {
				cwd: workspace,
				env: process.env,
				stdout: path.join(runDir, "git-init.out"),
				stderr: path.join(runDir, "git-init.err"),
				timeoutMs: 30_000,
			});
			await runCommand("git", ["add", "."], {
				cwd: workspace,
				env: process.env,
				stdout: path.join(runDir, "git-add.out"),
				stderr: path.join(runDir, "git-add.err"),
				timeoutMs: 30_000,
			});
			await runCommand(
				"git",
				[
					"-c",
					"user.name=Eval",
					"-c",
					"user.email=eval@example.test",
					"commit",
					"-qm",
					"fixture",
				],
				{
					cwd: workspace,
					env: process.env,
					stdout: path.join(runDir, "git-commit.out"),
					stderr: path.join(runDir, "git-commit.err"),
					timeoutMs: 30_000,
				},
			);
			if (options.configuration === "with_skill")
				await installRuntimeSkill(options.skill, home);
			else await fs.mkdir(path.join(home, ".claude"), { recursive: true });
			const before = await snapshot(workspace);
			const prompt =
				options.configuration === "with_skill"
					? `/ui-ux-audit-superset\n\n${evalCase.prompt}`
					: evalCase.prompt;
			const stdout = path.join(runDir, "result.json");
			const stderr = path.join(runDir, "stderr.log");
			const environment = {
				...process.env,
				HOME: home,
				CLAUDE_CONFIG_DIR: path.join(home, ".claude"),
				CLAUDE_CODE_SKIP_BEDROCK_AUTH: "1",
				CLAUDE_CODE_SKIP_VERTEX_AUTH: "1",
				CLAUDECODE: "",
			};
			environment.PATH = `${home}/.local/bin:${environment.PATH ?? ""}`;
			const args = [
				"-p",
				"--permission-mode",
				"acceptEdits",
				"--output-format",
				"json",
				"--effort",
				options.reasoning,
			];
			if (evalCase.id !== 3)
				args.push("--disallowedTools", "Write,Edit,NotebookEdit");
			if (options.model) args.push("--model", options.model);
			args.push("--", prompt);
			const timing = await runCommand("claude", args, {
				cwd: workspace,
				env: environment,
				stdout,
				stderr,
				timeoutMs: options.timeout * 1000,
			});
			const raw = await fs.readFile(stdout, "utf8").catch(() => "");
			const finalText = finalTextFromResult(raw);
			const result = JSON.parse(raw || "{}");
			const after = await snapshot(workspace);
			const beforeMap = new Map(before.map((item) => [item.path, item.sha256]));
			const afterMap = new Map(after.map((item) => [item.path, item.sha256]));
			const changed = [...new Set([...beforeMap.keys(), ...afterMap.keys()])]
				.filter((file) => beforeMap.get(file) !== afterMap.get(file))
				.sort();
			const grading = grade(evalCase, finalText, changed);
			const outputs = path.join(runDir, "outputs");
			await fs.mkdir(outputs, { recursive: true });
			await fs.writeFile(path.join(outputs, "final.md"), finalText);
			await fs.writeFile(
				path.join(outputs, "changed-files.json"),
				JSON.stringify(changed, null, 2),
			);
			await fs.writeFile(
				path.join(runDir, "grading.json"),
				JSON.stringify(grading, null, 2),
			);
			await fs.writeFile(
				path.join(runDir, "timing.json"),
				JSON.stringify(timing, null, 2),
			);
			const summary = {
				evalId: evalCase.id,
				evalName: evalCase.name,
				host: options.host,
				configuration: options.configuration,
				run: runNumber,
				model:
					Object.keys(result.modelUsage ?? {})[0] ??
					options.model ??
					"configured-default",
				reasoning: options.reasoning,
				tokens:
					(result.usage?.input_tokens ?? 0) +
					(result.usage?.output_tokens ?? 0),
				timing,
				changedFiles: changed,
				grading,
				notes: timing.timedOut ? ["executor timed out"] : [],
			};
			await fs.writeFile(
				path.join(runDir, "summary.json"),
				JSON.stringify(summary, null, 2),
			);
			process.stdout.write(
				`${options.host}/${options.configuration}/run-${runNumber}/eval-${evalCase.id}: ${grading.summary.passed}/${grading.summary.total}\n`,
			);
		}
	}
	await updateBenchmark(options.output, options);
}

main().catch((error) => {
	process.stderr.write(`${error.stack ?? error.message}\n`);
	process.exitCode = 1;
});
