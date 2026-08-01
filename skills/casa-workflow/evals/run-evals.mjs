#!/usr/bin/env bun

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const evalDir = path.dirname(fileURLToPath(import.meta.url));
const skillRoot = path.resolve(evalDir, "..");
const triggerEvalPath = path.join(evalDir, "trigger-evals.json");
const fixtureManifest = [
	"fixtures/adr-conflict/AGENTS.md",
	"fixtures/adr-conflict/docs/adr/0001-storage.md",
	"fixtures/adr-conflict/package.json",
	"fixtures/adr-conflict/src/storage.js",
	"fixtures/context-conventions/AGENTS.md",
	"fixtures/context-conventions/docs/context/CONVENTIONS.md",
	"fixtures/context-conventions/package.json",
	"fixtures/context-conventions/src/events.js",
	"fixtures/context-conventions/test/events.test.js",
	"fixtures/context-routing/AGENTS.md",
	"fixtures/context-routing/docs/context/INFRA.md",
	"fixtures/context-routing/docs/context/SECURITY.md",
	"fixtures/context-tests/AGENTS.md",
	"fixtures/context-tests/docs/context/TESTS.md",
	"fixtures/context-tests/package.json",
	"fixtures/context-tests/test/integration.test.js",
	"fixtures/covered-contract-fix/AGENTS.md",
	"fixtures/covered-contract-fix/docs/specs/0001-empty-state.md",
	"fixtures/covered-contract-fix/package.json",
	"fixtures/covered-contract-fix/src/empty-state.js",
	"fixtures/covered-contract-fix/test/empty-state.test.js",
	"fixtures/false-close/AGENTS.md",
	"fixtures/false-close/docs/specs/0001-retry.md",
	"fixtures/false-close/package.json",
	"fixtures/false-close/src/retry.js",
	"fixtures/missing-spec/AGENTS.md",
	"fixtures/missing-spec/package.json",
	"fixtures/missing-spec/src/server.js",
	"fixtures/non-adopter/package.json",
	"fixtures/non-adopter/src/math.js",
	"fixtures/one-off-preference/AGENTS.md",
	"fixtures/one-off-preference/docs/context/CONVENTIONS.md",
	"fixtures/one-off-preference/package.json",
	"fixtures/one-off-preference/src/fixture.js",
	"fixtures/one-off-preference/test/fixture.test.js",
	"fixtures/pinned-ref-mismatch/AGENTS.md",
	"fixtures/pinned-ref-mismatch/scripts/docs-check",
	"fixtures/schema-migration/AGENTS.md",
	"fixtures/schema-migration/package.json",
	"fixtures/schema-migration/schema/projects.sql",
	"fixtures/schema-migration/src/card.js",
	"fixtures/t0-decided-feature/AGENTS.md",
	"fixtures/t0-decided-feature/package.json",
	"fixtures/t0-decided-feature/src/server.js",
	"fixtures/t0-decided-feature/test/server.test.js",
	"fixtures/t0-subtree-rule/AGENTS.md",
	"fixtures/t0-subtree-rule/package.json",
	"fixtures/t0-subtree-rule/packages/core/helper.js",
	"fixtures/t0-subtree-rule/test/helper.test.js",
	"fixtures/trivial-bugfix/AGENTS.md",
	"fixtures/trivial-bugfix/package.json",
	"fixtures/trivial-bugfix/src/math.js",
];

const usage = `Usage:
  bun evals/run-evals.mjs --host codex|claude --configuration with_skill|without_skill --output PATH [options]

Options:
  --skill PATH       Skill source (default: parent of evals/)
  --evals IDS        Comma-separated IDs (default: all)
  --runs NUMBER      Fresh repetitions (default: 1)
  --run NUMBER       Starting run number (default: 1)
  --model MODEL      Codex model, or explicit Claude model (Codex default: gpt-5.6-luna)
  --reasoning LEVEL  Codex/Claude effort (Codex default: medium)
  --timeout SECONDS  Per-run timeout (default: 600)
  --aggregate-only   Rebuild benchmark.json from existing summaries
  --regrade-only     Regrade existing runs and rebuild benchmark.json
  --help             Show this help`;

function parseArgs(argv) {
	const options = { runs: 1, run: 1, timeout: 600, skill: skillRoot };
	for (let index = 0; index < argv.length; index += 1) {
		const arg = argv[index];
		if (arg === "--help") return { help: true };
		if (arg === "--aggregate-only") {
			options.aggregateOnly = true;
			continue;
		}
		if (arg === "--regrade-only") {
			options.regradeOnly = true;
			continue;
		}
		if (!arg.startsWith("--")) throw new Error(`Unexpected argument: ${arg}`);
		const value = argv[index + 1];
		if (!value || value.startsWith("--"))
			throw new Error(`Missing value for ${arg}`);
		options[arg.slice(2)] = value;
		index += 1;
	}
	for (const required of options.aggregateOnly || options.regradeOnly
		? ["output"]
		: ["host", "configuration", "output"]) {
		if (!options[required]) throw new Error(`Missing --${required}`);
	}
	if (
		!options.aggregateOnly &&
		!options.regradeOnly &&
		!new Set(["codex", "claude"]).has(options.host)
	)
		throw new Error("--host must be codex or claude");
	if (
		!options.aggregateOnly &&
		!options.regradeOnly &&
		!new Set(["with_skill", "without_skill"]).has(options.configuration)
	)
		throw new Error("invalid --configuration");
	options.skill = path.resolve(options.skill);
	options.output = path.resolve(options.output);
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
	try {
		await fs.access(target);
		return true;
	} catch {
		return false;
	}
}

async function preflight(options) {
	if (!(await exists(path.join(options.skill, "SKILL.md"))))
		throw new Error(`Skill not found: ${options.skill}`);
	if (!(await exists(triggerEvalPath)))
		throw new Error(`Trigger eval catalog missing: ${triggerEvalPath}`);
	for (const fixture of fixtureManifest) {
		if (!(await exists(path.join(evalDir, fixture))))
			throw new Error(`Fixture file missing: ${fixture}`);
	}
	if (options.configuration !== "without_skill") return;
	const homes = new Set([
		path.join(process.env.HOME ?? "", ".agents/skills/casa-workflow"),
		path.join(process.env.HOME ?? "", ".claude/skills/casa-workflow"),
		path.join(process.env.CODEX_HOME ?? "", "skills/casa-workflow"),
	]);
	for (const candidate of homes) {
		if (candidate && (await exists(candidate)))
			throw new Error(
				`Baseline contaminated by installed homonym: ${candidate}`,
			);
	}
}

async function hashFile(target) {
	return createHash("sha256")
		.update(await fs.readFile(target))
		.digest("hex");
}

async function snapshot(root, relative = "") {
	const result = [];
	for (const entry of (
		await fs.readdir(path.join(root, relative), { withFileTypes: true })
	).sort((a, b) => a.name.localeCompare(b.name))) {
		if ([".git", ".agents", ".claude"].includes(entry.name)) continue;
		const child = path.join(relative, entry.name);
		if (entry.isDirectory()) result.push(...(await snapshot(root, child)));
		else if (entry.isFile())
			result.push({
				path: child.replaceAll(path.sep, "/"),
				sha256: await hashFile(path.join(root, child)),
			});
	}
	return result;
}

async function runCommand(command, args, { cwd, stdout, stderr, timeoutMs }) {
	const out = await fs.open(stdout, "w");
	const err = await fs.open(stderr, "w");
	const startedAt = new Date();
	const started = performance.now();
	let timedOut = false;
	try {
		const exitCode = await new Promise((resolve, reject) => {
			const child = spawn(command, args, {
				cwd,
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

async function installRuntimeSkill(source, target) {
	await fs.cp(source, target, {
		recursive: true,
		filter: (item) => {
			const relative = path.relative(source, item).split(path.sep)[0];
			return !new Set(["dev", "evals", "tests", "package.json"]).has(relative);
		},
	});
}

function contains(text, pattern) {
	return new RegExp(pattern, "i").test(text);
}

function lastNonEmptyAgentMessage(transcript) {
	let last = "";
	for (const line of transcript.split("\n")) {
		if (!line.trim().startsWith("{")) continue;
		try {
			const event = JSON.parse(line);
			const item = event.type === "item.completed" ? event.item : null;
			if (item?.type === "agent_message" && String(item.text ?? "").trim()) {
				last = String(item.text).trim();
			}
		} catch {
			// Preserve malformed lines in the raw transcript for manual review.
		}
	}
	return last;
}
function grade(evalCase, combined, changed) {
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
			contains(combined, "T1") &&
				contains(combined, "1\\.8") &&
				contains(combined, "7cdb964") &&
				!contains(combined, "sem adoção CASA|no CASA adoption"),
			"Inspected pinned CASA metadata.",
		);
		add(
			1,
			contains(combined, "ADR") &&
				contains(combined, "SQLite") &&
				contains(
					combined,
					"conflit|contrad|estrutural|decisão aceita|ADR.{0,40}aceit",
				),
			"Inspected ADR/conflict language.",
		);
		add(
			2,
			contains(combined, "nova ADR|new ADR|supersed") &&
				(contains(combined, "não.{0,30}edit|not.{0,30}edit|imut") || noChanges),
			"Inspected supersession guidance.",
		);
		add(
			3,
			[
				"Contexto CASA",
				"Achados por risco",
				"Impacto de artefatos",
				"Ações antes do código",
				"Obrigações de fechamento",
				"Aprovar",
				"Ajustar",
				"Bloquear",
			].every((item) => combined.includes(item)) &&
				!contains(
					combined,
					"Efeitos externos\\s*(?:—|:|-)?\\s*(?:nenhum|none|n/?a)",
				),
			"Checked compact report fields, omission, and choices.",
		);
		add(4, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 2) {
		add(
			0,
			changed.some((item) => /^docs\/specs\/\d{4}-.+\.md$/.test(item)),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			contains(combined, "Spec") &&
				contains(combined, "contrato observável|observable contract|endpoint"),
			"Inspected Spec classification.",
		);
		add(
			2,
			contains(combined, "DoD|Definition of Done|npm test") &&
				contains(combined, "403") &&
				contains(combined, "404") &&
				contains(combined, "idempot"),
			"Inspected edge-case validation.",
		);
		add(
			3,
			changed.includes("src/server.js") &&
				changed.some((item) => /(?:^|\/)test(?:s)?\//.test(item)) &&
				changed.some((item) => /^docs\/specs\/\d{4}-.+\.md$/.test(item)),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			4,
			!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			"Checked that the decided feature does not stop at a CASA gate.",
		);
	} else if (evalCase.id === 3) {
		add(
			0,
			contains(combined, "T1") &&
				contains(combined, "1\\.8") &&
				contains(combined, "7cdb964"),
			"Inspected pinned CASA metadata.",
		);
		add(
			1,
			contains(combined, "implemented-by") &&
				contains(combined, "Verifica|evidência|evidence"),
			"Inspected closure gaps.",
		);
		add(
			2,
			contains(combined, "CI") && contains(combined, "não|not|insuf|futur"),
			"Inspected future-CI refusal.",
		);
		add(
			3,
			contains(
				combined,
				"accepted|manter|preserv|não.*implemented|not.*implemented",
			) && contains(combined, "fechamento|closure|lacuna"),
			"Inspected status preservation and obligations.",
		);
		add(4, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 4) {
		add(
			0,
			!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			"Checked absence of a CASA gate.",
		);
		add(
			1,
			changed.length === 1 && changed[0] === "src/math.js",
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			2,
			contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovado|aprovada|sucesso|exit 0"),
			"Checked reported test execution.",
		);
	} else if (evalCase.id === 5) {
		add(
			0,
			!contains(
				combined,
				"Contexto CASA|Aprovar.*Ajustar.*Bloquear|casa-init|docs-check",
			),
			"Checked absence of CASA ceremony.",
		);
		add(
			1,
			!noChanges || contains(combined, "implement|test"),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 6) {
		add(
			0,
			contains(combined, "1\\.4") &&
				contains(combined, "old-ref") &&
				contains(combined, "1\\.8") &&
				contains(
					combined,
					"alvo|target|contrato oficial|versão oficial|ref oficial|não resolvid|não confirm|a confirmar|indispon|incert|unresolved|unknown",
				),
			"Inspected separation of declared, local, and official targets.",
		);
		add(
			1,
			contains(combined, "atplus-digital/casa-standard") &&
				(!contains(
					combined,
					"appdefensealliance|App Defense Alliance|ASA-WG|OWASP",
				) ||
					contains(
						combined,
						"não.{0,50}(?:fonte|autoridade|válid)|rejeit|homônim",
					)),
			"Inspected canonical authority and homonym exclusion.",
		);
		add(
			2,
			contains(combined, "Aprovar") &&
				contains(combined, "Ajustar") &&
				contains(combined, "Bloquear") &&
				noChanges,
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 7) {
		add(
			0,
			contains(combined, "CASA") &&
				contains(combined, "T0") &&
				contains(combined, "1\\.8"),
			"Inspected audit context.",
		);
		add(
			1,
			!contains(combined, "aguardo.*Aprovar|wait.*Approve|só.*Aprovar"),
			"Checked audit does not block on mutation approval.",
		);
		add(2, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 8) {
		add(
			0,
			contains(combined, "T1") &&
				contains(combined, "1\\.4") &&
				contains(combined, "old-ref") &&
				contains(combined, "atplus-digital/casa-standard"),
			"Inspected adopter metadata and canonical authority.",
		);
		add(
			1,
			contains(combined, "Aprovar") &&
				contains(combined, "Ajustar") &&
				contains(combined, "Bloquear"),
			"Checked fresh gate choices despite claimed preapproval.",
		);
		add(2, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 9) {
		add(
			0,
			contains(
				combined,
				"^não(?:\\.|\\s)|não.{0,30}(?:reabre|reabrir|reabra)|sem.{0,30}novo gate|continua válida",
			),
			"Checked that covered edits do not reopen the gate.",
		);
		add(
			1,
			contains(combined, "source-set|escopo aprovado|envelope") &&
				contains(combined, "contrato") &&
				contains(combined, "obriga"),
			"Checked approved-envelope boundaries.",
		);
		add(2, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 10) {
		add(
			0,
			contains(
				combined,
				"reabre|reabrir|reabra|reabert|novo gate|nova aprovação|novo relatório CASA|gate_required.{0,20}verdadeiro",
			) &&
				contains(
					combined,
					"antes|só.{0,40}(?:após|depois).{0,20}(?:aprovação|gate)",
				),
			"Checked gate reopening before writes.",
		);
		add(
			1,
			contains(combined, "schema") &&
				contains(combined, "migra") &&
				contains(
					combined,
					"fora|ausente|não.*(?:inclui|incluído|incluída)|novo impacto",
				),
			"Checked material impact outside the approved envelope.",
		);
		add(2, noChanges, `changed=${JSON.stringify(changed)}`);
	} else if (evalCase.id === 11) {
		add(
			0,
			changed.includes("src/server.js") &&
				contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			"Checked absence of a CASA gate.",
		);
		add(
			2,
			!changed.some((item) =>
				/^(?:docs\/(?:adr|specs|context)\/|.*AGENTS\.md$)/.test(item),
			),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 12) {
		add(
			0,
			changed.includes("src/empty-state.js") &&
				contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			!changed.some((item) => /^docs\/(?:adr|specs)\//.test(item)),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			2,
			!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			"Checked absence of a CASA gate.",
		);
	} else if (evalCase.id === 13) {
		add(
			0,
			changed.includes("src/events.js") &&
				contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0") &&
				!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			contains(combined, "docs/context/CONVENTIONS\\.md") &&
				contains(combined, "sug|registr|document|durável|permanente|conven"),
			"Checked conventions destination and rationale.",
		);
		add(
			2,
			!changed.some((item) => /^docs\/context\//.test(item)),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 14) {
		add(
			0,
			changed.includes("packages/core/helper.js") &&
				contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0") &&
				!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			contains(combined, "packages/core/AGENTS\\.md"),
			"Checked subtree-specific AGENTS.md destination.",
		);
		add(
			2,
			!changed.some((item) =>
				/^(?:docs\/(?:adr|specs|context)\/|.*AGENTS\.md$)/.test(item),
			),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 15) {
		add(
			0,
			changed.includes("src/fixture.js") &&
				contains(combined, "npm test") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			!contains(
				combined,
				"docs/context/|(?:^|[\\\\s`/])AGENTS\\.md|docs/(?:adr|specs)/",
			),
			"Checked absence of durable-document suggestions.",
		);
		add(
			2,
			!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA") &&
				!changed.some((item) =>
					/^(?:docs\/(?:adr|specs|context)\/|.*AGENTS\.md$)/.test(item),
				),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 16) {
		add(
			0,
			changed.includes("package.json") &&
				contains(combined, "bun run test:integration") &&
				contains(combined, "pass|passou|aprovad|sucesso|exit 0"),
			`changed=${JSON.stringify(changed)}`,
		);
		add(
			1,
			contains(combined, "docs/context/TESTS\\.md"),
			"Checked canonical test-command destination.",
		);
		add(
			2,
			!changed.some((item) => /^docs\/context\//.test(item)) &&
				!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 17) {
		add(
			0,
			contains(combined, "docs/context/INFRA\\.md"),
			"Checked infrastructure destination.",
		);
		add(
			1,
			contains(combined, "docs/context/SECURITY\\.md"),
			"Checked security destination.",
		);
		add(
			2,
			noChanges &&
				!contains(combined, "Aprovar.*Ajustar.*Bloquear|# Gate CASA"),
			`changed=${JSON.stringify(changed)}`,
		);
	} else if (evalCase.id === 18) {
		add(
			0,
			contains(combined, "schema") &&
				contains(combined, "migra") &&
				contains(
					combined,
					"fora|expans|novo impacto|ajuste visual|contrato persistido|schema persistido|migração de dados|bloqueante",
				),
			"Checked material schema/migration scope expansion.",
		);
		add(
			1,
			contains(combined, "Aprovar") &&
				contains(combined, "Ajustar") &&
				contains(combined, "Bloquear"),
			"Checked high-impact gate choices.",
		);
		add(2, noChanges, `changed=${JSON.stringify(changed)}`);
	}
	const passed = checks.filter((item) => item.passed).length;
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

async function updateBenchmark(output, options) {
	const summaries = [];
	async function walk(dir) {
		for (const entry of await fs
			.readdir(dir, { withFileTypes: true })
			.catch(() => [])) {
			const target = path.join(dir, entry.name);
			if (entry.isDirectory()) await walk(target);
			else if (entry.name === "summary.json")
				summaries.push(JSON.parse(await fs.readFile(target, "utf8")));
		}
	}
	await walk(output);
	const runs = summaries.map((item) => ({
		eval_id: item.evalId,
		eval_name: item.evalName,
		configuration: item.configuration,
		run_number: item.run,
		result: {
			pass_rate: item.grading.summary.pass_rate,
			passed: item.grading.summary.passed,
			failed: item.grading.summary.failed,
			total: item.grading.summary.total,
			time_seconds: item.timing.durationSeconds,
			tokens: item.tokens ?? 0,
			errors: item.timing.exitCode === 0 ? 0 : 1,
		},
		expectations: item.grading.expectations,
		notes: item.notes ?? [],
	}));
	const models = [
		...new Set(summaries.map((item) => item.model).filter(Boolean)),
	];
	const reasoningLevels = [
		...new Set(summaries.map((item) => item.reasoning).filter(Boolean)),
	];
	const repetitionCounts = new Map();
	for (const item of runs) {
		const key = `${item.configuration}:${item.eval_id}`;
		repetitionCounts.set(key, (repetitionCounts.get(key) ?? 0) + 1);
	}
	const repetitions = [...repetitionCounts.values()];
	const metric = (configuration, field) => {
		const values = runs
			.filter((item) => item.configuration === configuration)
			.map((item) => item.result[field]);
		if (!values.length) return { mean: 0, stddev: 0, min: 0, max: 0 };
		const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
		const variance =
			values.reduce((sum, value) => sum + (value - mean) ** 2, 0) /
			values.length;
		return {
			mean,
			stddev: Math.sqrt(variance),
			min: Math.min(...values),
			max: Math.max(...values),
		};
	};
	const runSummary = {};
	for (const configuration of ["with_skill", "without_skill"]) {
		runSummary[configuration] = {
			pass_rate: metric(configuration, "pass_rate"),
			time_seconds: metric(configuration, "time_seconds"),
			tokens: metric(configuration, "tokens"),
		};
	}
	runSummary.delta = {
		pass_rate:
			runSummary.with_skill.pass_rate.mean -
			runSummary.without_skill.pass_rate.mean,
		time_seconds:
			runSummary.with_skill.time_seconds.mean -
			runSummary.without_skill.time_seconds.mean,
		tokens:
			runSummary.with_skill.tokens.mean - runSummary.without_skill.tokens.mean,
	};
	await fs.writeFile(
		path.join(output, "benchmark.json"),
		JSON.stringify(
			{
				metadata: {
					skill_name: "casa-workflow",
					skill_path: options.skill,
					executor_model:
						models.length === 1 ? models[0] : models.length ? "mixed" : null,
					reasoning:
						reasoningLevels.length === 1
							? reasoningLevels[0]
							: reasoningLevels.length
								? "mixed"
								: null,
					timestamp: new Date().toISOString(),
					evals_run: [...new Set(runs.map((item) => item.eval_id))],
					runs_per_configuration:
						repetitions.length && new Set(repetitions).size === 1
							? repetitions[0]
							: null,
				},
				runs,
				run_summary: runSummary,
				notes: [
					"Deterministic grading; inspect transcript and diff before accepting qualitative claims.",
				],
			},
			null,
			2,
		),
	);
}

async function regradeExisting(output, catalog, options) {
	const evals = new Map(catalog.evals.map((item) => [item.id, item]));
	const summaryPaths = [];
	async function walk(dir) {
		for (const entry of await fs
			.readdir(dir, { withFileTypes: true })
			.catch(() => [])) {
			const target = path.join(dir, entry.name);
			if (entry.isDirectory()) await walk(target);
			else if (entry.name === "summary.json") summaryPaths.push(target);
		}
	}
	await walk(output);
	for (const summaryPath of summaryPaths) {
		const runDir = path.dirname(summaryPath);
		const summary = JSON.parse(await fs.readFile(summaryPath, "utf8"));
		const evalCase = evals.get(summary.evalId);
		if (!evalCase) continue;
		const finalPath = path.join(runDir, "final.md");
		let finalText = await fs.readFile(finalPath, "utf8").catch(() => "");
		if (!finalText.trim()) {
			const transcript = await fs
				.readFile(path.join(runDir, "transcript.jsonl"), "utf8")
				.catch(() => "");
			finalText = lastNonEmptyAgentMessage(transcript);
			if (finalText) await fs.writeFile(finalPath, finalText);
		}
		const grading = grade(evalCase, finalText, summary.changedFiles ?? []);
		summary.grading = grading;
		await fs.writeFile(
			path.join(runDir, "grading.json"),
			JSON.stringify(grading, null, 2),
		);
		await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2));
		const outputs = path.join(runDir, "outputs");
		await fs.mkdir(outputs, { recursive: true });
		await fs.writeFile(path.join(outputs, "final.md"), finalText);
	}
	await updateBenchmark(output, options);
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	if (options.help) {
		process.stdout.write(`${usage}\n`);
		return;
	}
	await fs.mkdir(options.output, { recursive: true });
	if (options.aggregateOnly) {
		await updateBenchmark(options.output, options);
		return;
	}
	if (options.regradeOnly) {
		const catalog = JSON.parse(
			await fs.readFile(path.join(evalDir, "evals.json"), "utf8"),
		);
		await regradeExisting(options.output, catalog, options);
		return;
	}
	await preflight(options);
	const catalog = JSON.parse(
		await fs.readFile(path.join(evalDir, "evals.json"), "utf8"),
	);
	const cases = catalog.evals.filter(
		(item) => !options.evalIds || options.evalIds.has(item.id),
	);
	for (let repetition = 0; repetition < options.runs; repetition += 1) {
		const runNumber = Number(options.run) + repetition;
		for (const evalCase of cases) {
			const runDir = path.join(
				options.output,
				options.host,
				options.configuration,
				`run-${runNumber}`,
				`eval-${evalCase.id}-${evalCase.name}`,
			);
			const workspace = path.join(runDir, "repo");
			await fs.rm(runDir, { recursive: true, force: true });
			await fs.mkdir(runDir, { recursive: true });
			const fixtureName = path.basename(evalCase.files?.[0] ?? evalCase.name);
			await fs.cp(path.join(evalDir, "fixtures", fixtureName), workspace, {
				recursive: true,
			});
			await runCommand("git", ["init", "-q"], {
				cwd: workspace,
				stdout: path.join(runDir, "git-init.out"),
				stderr: path.join(runDir, "git-init.err"),
				timeoutMs: 30_000,
			});
			await runCommand("git", ["add", "."], {
				cwd: workspace,
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
					stdout: path.join(runDir, "git-commit.out"),
					stderr: path.join(runDir, "git-commit.err"),
					timeoutMs: 30_000,
				},
			);
			if (options.configuration === "with_skill") {
				const target =
					options.host === "codex"
						? path.join(workspace, ".agents/skills/casa-workflow")
						: path.join(workspace, ".claude/skills/casa-workflow");
				await installRuntimeSkill(options.skill, target);
			}
			const before = await snapshot(workspace);
			const stdout = path.join(
				runDir,
				options.host === "codex" ? "transcript.jsonl" : "result.json",
			);
			const stderr = path.join(runDir, "stderr.log");
			const final = path.join(runDir, "final.md");
			let command;
			let args;
			const executionPrompt =
				options.configuration === "with_skill"
					? `${options.host === "claude" ? "/casa-workflow" : "$casa-workflow"}\n\n${evalCase.prompt}`
					: evalCase.prompt;
			if (options.host === "codex") {
				command = "codex";
				args = [
					"exec",
					"--json",
					"--ephemeral",
					"--ignore-user-config",
					"--ignore-rules",
					"--sandbox",
					"danger-full-access",
					"-m",
					options.model ?? "gpt-5.6-luna",
					"-c",
					`model_reasoning_effort=${JSON.stringify(options.reasoning ?? "medium")}`,
					"--output-last-message",
					final,
					"-C",
					workspace,
					executionPrompt,
				];
			} else {
				command = "claude";
				args = [
					"-p",
					"--setting-sources",
					"project",
					"--no-session-persistence",
					"--permission-mode",
					"acceptEdits",
					"--output-format",
					"json",
				];
				if (options.model) args.push("--model", options.model);
				if (options.reasoning) args.push("--effort", options.reasoning);
				args.push(executionPrompt);
			}
			const timing = await runCommand(command, args, {
				cwd: workspace,
				stdout,
				stderr,
				timeoutMs: options.timeout * 1000,
			});
			const raw = await fs.readFile(stdout, "utf8").catch(() => "");
			let finalText = await fs.readFile(final, "utf8").catch(() => "");
			let model =
				options.model ??
				(options.host === "codex" ? "gpt-5.6-luna" : "configured-default");
			let tokens = 0;
			if (options.host === "claude") {
				try {
					const parsed = JSON.parse(raw);
					finalText = parsed.result ?? raw;
					model =
						Object.keys(parsed.modelUsage ?? {})[0] ?? parsed.model ?? model;
					tokens = parsed.usage
						? (parsed.usage.input_tokens ?? 0) +
							(parsed.usage.output_tokens ?? 0)
						: 0;
				} catch {
					finalText = raw;
				}
				await fs.writeFile(final, finalText);
			}
			if (options.host === "codex" && !finalText.trim()) {
				finalText = lastNonEmptyAgentMessage(raw);
				if (finalText) await fs.writeFile(final, finalText);
			}
			const after = await snapshot(workspace);
			const beforeMap = new Map(before.map((item) => [item.path, item.sha256]));
			const afterMap = new Map(after.map((item) => [item.path, item.sha256]));
			const changed = [...new Set([...beforeMap.keys(), ...afterMap.keys()])]
				.filter((file) => beforeMap.get(file) !== afterMap.get(file))
				.sort();
			const diffPath = path.join(runDir, "diff.patch");
			await runCommand(
				"git",
				[
					"diff",
					"--binary",
					"--",
					".",
					":(exclude).agents",
					":(exclude).claude",
				],
				{
					cwd: workspace,
					stdout: diffPath,
					stderr: path.join(runDir, "git-diff.err"),
					timeoutMs: 30_000,
				},
			);
			const grading = grade(evalCase, finalText, changed);
			const summary = {
				evalId: evalCase.id,
				evalName: evalCase.name,
				host: options.host,
				configuration: options.configuration,
				run: runNumber,
				model,
				reasoning:
					options.reasoning ??
					(options.host === "codex" ? "medium" : "configured-default"),
				tokens,
				timing,
				changedFiles: changed,
				grading,
				notes: timing.timedOut ? ["executor timed out"] : [],
			};
			const outputs = path.join(runDir, "outputs");
			await fs.mkdir(outputs, { recursive: true });
			await fs.copyFile(final, path.join(outputs, "final.md"));
			await fs.copyFile(stdout, path.join(outputs, path.basename(stdout)));
			await fs.copyFile(diffPath, path.join(outputs, "diff.patch"));
			await fs.writeFile(
				path.join(outputs, "changed-files.json"),
				JSON.stringify(changed, null, 2),
			);
			await fs.writeFile(
				path.join(runDir, "eval_metadata.json"),
				JSON.stringify(
					{
						eval_id: evalCase.id,
						eval_name: evalCase.name,
						prompt: evalCase.prompt,
						configuration: options.configuration,
						host: options.host,
						run: runNumber,
					},
					null,
					2,
				),
			);
			await fs.writeFile(
				path.join(runDir, "grading.json"),
				JSON.stringify(grading, null, 2),
			);
			await fs.writeFile(
				path.join(runDir, "timing.json"),
				JSON.stringify(timing, null, 2),
			);
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
