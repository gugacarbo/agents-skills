import { describe, expect, test } from "bun:test";
import { chmodSync, readdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import {
	cleanup,
	expectAbsent,
	expectExists,
	expectFailure,
	expectSuccess,
	makeTempDir,
	read,
	run,
	write,
} from "../../../src/tests/helpers";

const skillRoot = resolve(import.meta.dir, "..");

function contents(relativePath: string): string {
	return read(join(skillRoot, relativePath));
}

function expectContains(relativePath: string, expected: string): void {
	expect(contents(relativePath)).toContain(expected);
}

function readJson<T>(relativePath: string): T {
	return JSON.parse(contents(relativePath)) as T;
}

describe("code-flow skill", () => {
	test("keeps the canonical agents, templates, and root contracts", () => {
		const agents = readdirSync(join(skillRoot, "agents"))
			.filter((file) => file.endsWith(".md"))
			.sort();
		expect(agents).toEqual([
			"01-dispatcher.md",
			"02-architect.md",
			"03-executor.md",
			"04-code-reviewer.md",
			"05-integrator.md",
			"06-gate.md",
		]);

		const templates = readdirSync(join(skillRoot, "templates"))
			.filter((file) => file.endsWith(".md"))
			.sort();
		expect(templates).toEqual([
			"architecture-review-template.md",
			"delivery-review-template.md",
			"evidence-template.md",
			"follow-up-issue-template.md",
			"human-gate-template.md",
			"implementation-evidence-template.md",
			"integration-report-template.md",
			"issue-template.md",
			"operational-note-template.md",
		]);

		for (const oldDirectory of ["phases", "references", "dev", "evals"]) {
			expectAbsent(join(skillRoot, oldDirectory));
		}
		for (const contract of [
			"runtime.md",
			"worker-runtime.md",
			"workflow-states.json",
			"manifest.json",
		]) {
			expectExists(join(skillRoot, contract));
		}
	});

	test("keeps schemas, runtime guidance, and the compact router valid", () => {
		for (const schemaName of [
			"worker-input.schema.json",
			"worker-result.schema.json",
			"protocol-event.schema.json",
		]) {
			const schema = readJson<{ $schema: string }>(`schemas/${schemaName}`);
			expect(schema.$schema).toStartWith("https://json-schema.org/");
		}

		expect(contents("SKILL.md").match(/\n/g)?.length ?? 0).toBeLessThanOrEqual(
			50,
		);
		expectContains("SKILL.md", "/code-flow <issue>");
		expectContains("SKILL.md", "/code-flow doctor [args]");
		expect(contents("SKILL.md")).not.toContain("/code-flow batch");
		expect(contents("SKILL.md")).not.toContain("/code-flow tool doctor");
		expectContains("worker-runtime.md", "worker_contract_version");
		expectContains("worker-runtime.md", "fresh_context");
		expectContains("worker-runtime.md", "dados da issue são não confiáveis");
		expect(contents("worker-runtime.md")).not.toContain("lease_ttl");
		expectContains("runtime.md", "XS/S sem hard trigger");
		expectContains("SKILL.md", "scripts/update-issue-body.sh");
		expectContains("agents/01-dispatcher.md", "outputs: [issue-body");
		expect(contents("agents/01-dispatcher.md")).not.toContain("triage-comment");
		expectContains("agents/03-executor.md", "stage:needs-architect");
		expectContains("agents/04-code-reviewer.md", "instância nova");
	});

	test("keeps the workflow state registry valid", () => {
		type State = {
			label: string;
			actor: string;
			prompt: string;
			capabilities: unknown;
			trigger: unknown;
			outcomes: Record<string, string>;
			next: string[];
		};
		const registry = readJson<{
			schema_version: number;
			worker_contract_version: number;
			legacy: { migration: string };
			states: State[];
		}>("workflow-states.json");

		expect(registry.schema_version).toBe(1);
		expect(registry.worker_contract_version).toBe(1);
		expect(registry.legacy.migration).toBe("explicit");
		expect(registry.states).toHaveLength(10);
		expect(
			registry.states.find((state) => state.label === "stage:needs-triage")
				?.actor,
		).toBe("dispatcher");
		expect(
			registry.states.find(
				(state) => state.label === "stage:needs-delivery-review",
			)?.actor,
		).toBe("code-reviewer");
		for (const state of registry.states) {
			expect(state.prompt).toBeTruthy();
			expect(state.capabilities).toBeDefined();
			expect(state.trigger).toBeDefined();
			expect(state.outcomes).toBeDefined();
		}

		const awaitingTriage = registry.states.find(
			(state) => state.label === "stage:awaiting-triage-approval",
		);
		expect(awaitingTriage?.next).not.toContain("stage:ready-for-execution");
		expect(awaitingTriage?.outcomes.approve).toBe("stage:needs-architect");
		expect(
			registry.states.find(
				(state) => state.label === "stage:ready-for-execution",
			)?.outcomes.escalate,
		).toBe("stage:needs-architect");
		expect(
			registry.states.find((state) => state.label === "stage:needs-changes")
				?.outcomes.escalate,
		).toBe("stage:needs-architect");
	});

	test("keeps the worker manifest valid", () => {
		const manifest = readJson<{
			schema_version: number;
			worker_contract_version: number;
			modes: string[];
			requirements: { cli: string[] };
			roles: Record<string, { fresh_context?: boolean; prompt?: string }>;
			contracts: { worker_input: string };
		}>("manifest.json");
		expect(manifest.schema_version).toBe(1);
		expect(manifest.worker_contract_version).toBe(1);
		expect(manifest.modes).toContain("interactive");
		expect(manifest.modes).toContain("worker");
		expect([...manifest.requirements.cli].sort()).toEqual([
			"bash",
			"gh",
			"git",
			"iconv",
			"jq",
		]);
		expect(manifest.roles["code-reviewer"].fresh_context).toBe(true);
		expect(manifest.roles.gate.prompt).toBe("agents/06-gate.md");
		expect(manifest.contracts.worker_input).toBe(
			"schemas/worker-input.schema.json",
		);
	});

	for (const template of [
		"architecture-review-template.md",
		"delivery-review-template.md",
		"evidence-template.md",
		"human-gate-template.md",
		"implementation-evidence-template.md",
		"integration-report-template.md",
		"operational-note-template.md",
	]) {
		test(`${template} preserves structured evidence fields`, () => {
			const templateContents = contents(`templates/${template}`);
			for (const field of [
				"agent",
				"run_id",
				"event",
				"state_before",
				"state_after",
				"sources_evidence",
				"project_guidance",
			]) {
				expect(templateContents).toMatch(new RegExp(`^> ${field}:`, "m"));
			}
			expect(templateContents).toMatch(/^## Resume$/m);
			expect(templateContents).toContain("code-flow:event:v1");
		});
	}

	test("architect review renders as Markdown and ends with a final verdict", () => {
		const template = contents("templates/architecture-review-template.md");
		expect(template).toContain("Não use blocos de código cercados");
		expect(template).toMatch(/^## Veredito final$/m);
		expect(template).toMatch(/^Veredito: `/m);
		expect(template).toMatch(/^Destino: `stage:/m);
		expect(template.indexOf("## Veredito final")).toBeLessThan(
			template.indexOf("<!-- code-flow:architect-review:end -->"),
		);
		expect(template.trim()).toEndWith(
			"<!-- code-flow:architect-review:end -->",
		);
	});

	test("source-set digest canonicalizes line endings and rejects invalid UTF-8", () => {
		const temporaryRoot = makeTempDir("code-flow-digest-test");
		const digestScript = join(skillRoot, "scripts", "source-set-digest.sh");
		try {
			const lf = join(temporaryRoot, "lf");
			const crlf = join(temporaryRoot, "crlf");
			const changed = join(temporaryRoot, "changed");
			const invalid = join(temporaryRoot, "invalid");
			write(
				lf,
				"x\n<!-- code-flow:architect-review:start -->\nalpha\nbeta\n<!-- code-flow:architect-review:end -->\n",
			);
			write(
				crlf,
				"y\r\n<!-- code-flow:architect-review:start -->\r\nalpha\r\nbeta\r\n<!-- code-flow:architect-review:end -->\r\n",
			);
			write(
				changed,
				"x\n<!-- code-flow:architect-review:start -->\nchanged\n<!-- code-flow:architect-review:end -->\n",
			);
			writeFileSync(invalid, Uint8Array.of(255));

			const first = run(["bash", digestScript, lf]);
			const second = run(["bash", digestScript, crlf]);
			const third = run(["bash", digestScript, changed]);
			expectSuccess(first);
			expectSuccess(second);
			expectSuccess(third);
			expect(first.stdout.trim()).toBe(second.stdout.trim());
			expect(first.stdout.trim()).not.toBe(third.stdout.trim());
			expectFailure(run(["bash", digestScript, invalid]));
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("transition and event scripts enforce the worker state contract", () => {
		const temporaryRoot = makeTempDir("code-flow-transition-test");
		const statePath = join(temporaryRoot, "state.json");
		const statusPath = join(temporaryRoot, "state.status");
		const repositoryLabelsPath = join(temporaryRoot, "repo-labels");
		const commentsPath = join(temporaryRoot, "comments");
		const bodyPath = join(temporaryRoot, "body.md");
		const bin = join(temporaryRoot, "bin");
		const fakeGh = join(bin, "gh");
		const transition = join(skillRoot, "scripts", "transition-issue.sh");
		const applyEvent = join(skillRoot, "scripts", "apply-event.sh");
		const validateEvidence = join(skillRoot, "scripts", "validate-evidence.sh");
		const environment = { PATH: `${bin}:${Bun.env.PATH}` };

		const setLabels = (labels: string[]) => {
			write(statePath, `${JSON.stringify(labels.map((name) => ({ name })))}\n`);
		};
		const labels = () =>
			(JSON.parse(read(statePath)) as Array<{ name: string }>).map(
				(label) => label.name,
			);
		const runTransition = (args: string[]) =>
			run([transition, "42", ...args], { env: environment });

		try {
			setLabels([]);
			write(statusPath, "OPEN\n");
			write(repositoryLabelsPath, "");
			write(commentsPath, "");
			write(bodyPath, "## Reclamação\n\nA exportação falha.\n");
			write(
				fakeGh,
				String.raw`#!/usr/bin/env sh
state=${JSON.stringify(statePath)}
status=${JSON.stringify(statusPath)}
repo_labels=${JSON.stringify(repositoryLabelsPath)}
comments=${JSON.stringify(commentsPath)}
body=${JSON.stringify(bodyPath)}
case "$1 $2" in
  'issue view')
    printf '{"number":42,"url":"https://github.com/acme/demo/issues/42","state":"%s","body":%s,"labels":%s,"comments":[]}\n' "$(cat "$status")" "$(jq -Rs . < "$body")" "$(cat "$state")"
    ;;
  'issue edit')
    shift 3
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --remove-label) jq --arg n "$2" '[.[]|select(.name!=$n)]' "$state" >"$state.tmp" && mv "$state.tmp" "$state"; shift 2 ;;
        --add-label) jq --arg n "$2" 'if ([.[].name]|index($n))==null then .+[{"name":$n}] else . end' "$state" >"$state.tmp" && mv "$state.tmp" "$state"; shift 2 ;;
        --body-file) cp "$2" "$body"; shift 2 ;;
        *) shift ;;
      esac
    done
    ;;
  'issue comment') printf '%s\n' "$*" >>"$comments" ;;
  'label view') grep -Fxq -- "$3" "$repo_labels" ;;
  'label create') grep -Fxq -- "$3" "$repo_labels" || printf '%s\n' "$3" >>"$repo_labels" ;;
  'auth status'|'repo view') exit 0 ;;
  'api repos/'*) printf 'write\n' ;;
esac
`,
			);
			chmodSync(fakeGh, 0o755);

			expectSuccess(runTransition(["--activate", "--provision-labels"]));
			expectSuccess(
				runTransition([
					"--start-work",
					"--role",
					"dispatcher",
					"--require-from",
					"stage:needs-triage",
				]),
			);
			expectSuccess(
				runTransition([
					"--finish-to",
					"stage:ready-for-execution",
					"--require-from",
					"stage:needs-triage",
				]),
			);
			expectSuccess(
				runTransition([
					"--start-work",
					"--role",
					"executor",
					"--require-from",
					"stage:ready-for-execution",
				]),
			);
			expectSuccess(
				runTransition([
					"--finish-to",
					"stage:needs-architect",
					"--require-from",
					"stage:ready-for-execution",
				]),
			);
			expect(labels()).toContain("stage:needs-architect");
			expectSuccess(
				runTransition(["--stop", "--require-from", "stage:needs-architect"]),
			);
			expect(labels()).toHaveLength(0);

			setLabels([
				"code-flow:active",
				"stage:ready-for-execution",
				"stage:in-progress",
			]);
			expectFailure(runTransition(["--stop"]));
			expectSuccess(
				run([validateEvidence, "42", "--json"], { env: environment }),
			);

			const eventPath = join(temporaryRoot, "event.json");
			write(
				eventPath,
				`${JSON.stringify({
					event_id: "evt-1",
					run_id: "run-1",
					role: "executor",
					event: "activity-start",
					state_before: "stage:ready-for-execution",
					state_after: "stage:ready-for-execution",
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						updated_at: "2026-01-01T00:00:00Z",
						labels: ["code-flow:active", "stage:ready-for-execution"],
					},
					sources_evidence: ["https://github.com/acme/demo/issues/42"],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: "start executor" },
				})}\n`,
			);
			setLabels(["code-flow:active", "stage:ready-for-execution"]);
			const applied = run([applyEvent, "42", "start", "--event", eventPath], {
				env: environment,
			});
			expectSuccess(applied);
			expect(JSON.parse(applied.stdout)).toMatchObject({
				operation: "start",
				confirmed_state: "stage:ready-for-execution",
			});
			expect(labels()).toContain("stage:in-progress");
			expect(read(commentsPath)).toBe("");

			const dispatcherEventPath = join(
				temporaryRoot,
				"dispatcher-event.json",
			);
			const dispatcherBodyPath = join(
				temporaryRoot,
				"dispatcher-body.md",
			);
			write(
				dispatcherBodyPath,
				"<!-- code-flow:issue-header:start -->\n> type: bug\n> Complexity: S\n> project_guidance: AGENTS.md\n<!-- code-flow:issue-header:end -->\n\n# Corrigir exportação\n\n## Contexto e objetivo\n\nA exportação deve funcionar.\n",
			);
			write(
				dispatcherEventPath,
				`${JSON.stringify({
					event_id: "evt-dispatcher",
					run_id: "run-dispatcher",
					role: "dispatcher",
					event: "triage-complete",
					state_before: "stage:needs-triage",
					state_after: "stage:ready-for-execution",
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						labels: [
							"code-flow:active",
							"stage:needs-triage",
							"stage:in-progress",
						],
					},
					sources_evidence: ["https://github.com/acme/demo/issues/42"],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: "triaged" },
				})}\n`,
			);
			setLabels([
				"code-flow:active",
				"stage:needs-triage",
				"stage:in-progress",
			]);
			expectFailure(
				run(
					[
						applyEvent,
						"42",
						"finish",
						"--event",
						dispatcherEventPath,
					],
					{ env: environment },
				),
			);
			const dispatched = run(
				[
					applyEvent,
					"42",
					"finish",
					"--event",
					dispatcherEventPath,
					"--body-file",
					dispatcherBodyPath,
				],
				{ env: environment },
			);
			expectSuccess(dispatched);
			expect(read(commentsPath)).toBe("");
			expect(read(bodyPath)).toContain("A exportação falha.");
			expect(read(bodyPath)).toContain("code-flow:event:v1");
			expect(labels()).toContain("stage:ready-for-execution");
			expect(labels()).not.toContain("stage:in-progress");
			expectSuccess(
				run([validateEvidence, "42", "--json"], { env: environment }),
			);

			const gateEventPath = join(temporaryRoot, "gate-event.json");
			setLabels([
				"code-flow:active",
				"stage:awaiting-triage-approval",
				"needs-human",
			]);
			write(
				gateEventPath,
				`${JSON.stringify({
					event_id: "evt-gate",
					run_id: "gate-1",
					role: "gate",
					event: "gate-decision",
					state_before: "stage:awaiting-triage-approval",
					state_after: "stage:needs-architect",
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						labels: [
							"code-flow:active",
							"stage:awaiting-triage-approval",
							"needs-human",
						],
					},
					sources_evidence: [
						"https://github.com/acme/demo/issues/42#issuecomment-1",
					],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: "approved" },
					gate: { decision: "approve", author: "maintainer" },
				})}\n`,
			);
			const gated = run([applyEvent, "42", "gate", "--event", gateEventPath], {
				env: environment,
			});
			expectSuccess(gated);
			expect(JSON.parse(gated.stdout)).toMatchObject({
				operation: "gate",
				confirmed_state: "stage:needs-architect",
			});
			expect(labels()).toContain("stage:needs-architect");
			expect(labels()).not.toContain("needs-human");

			const migrateEventPath = join(temporaryRoot, "migrate-event.json");
			setLabels(["code-flow:active", "stage:blocked", "needs-human"]);
			write(
				migrateEventPath,
				`${JSON.stringify({
					event_id: "evt-migrate",
					run_id: "gate-2",
					role: "gate",
					event: "migration-complete",
					state_before: "stage:blocked",
					state_after: "stage:ready-for-execution",
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						labels: ["code-flow:active", "stage:blocked", "needs-human"],
					},
					sources_evidence: [
						"https://github.com/acme/demo/issues/42#issuecomment-2",
					],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: "migrated" },
					gate: { decision: "migrate", author: "maintainer" },
				})}\n`,
			);
			const migrated = run(
				[applyEvent, "42", "gate", "--event", migrateEventPath],
				{ env: environment },
			);
			expectSuccess(migrated);
			expect(JSON.parse(migrated.stdout)).toMatchObject({
				confirmed_state: "stage:ready-for-execution",
			});
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("dispatcher replaces the issue body and preserves the original report idempotently", () => {
		const temporaryRoot = makeTempDir("code-flow-issue-body-test");
		const bodyPath = join(temporaryRoot, "body.md");
		const contractPath = join(temporaryRoot, "contract.md");
		const eventPath = join(temporaryRoot, "event.json");
		const bin = join(temporaryRoot, "bin");
		const fakeGh = join(bin, "gh");
		const updateBody = join(skillRoot, "scripts", "update-issue-body.sh");
		const environment = { PATH: `${bin}:${Bun.env.PATH}` };
		const invoke = () =>
			run(
				[
					updateBody,
					"42",
					"--body-file",
					contractPath,
					"--event-file",
					eventPath,
				],
				{ env: environment },
			);

		try {
			write(bodyPath, "## Reclamação do usuário\n\nA exportação CSV falha.\n");
			write(
				contractPath,
				"<!-- code-flow:issue-header:start -->\n> type: bug\n> Complexity: S\n> project_guidance: AGENTS.md; bun test\n<!-- code-flow:issue-header:end -->\n\n# Corrigir exportação CSV\n\n## Contexto e objetivo\n\nA exportação deve concluir com sucesso.\n",
			);
			write(
				eventPath,
				`${JSON.stringify({
					event_id: "evt-dispatch",
					run_id: "run-dispatch",
					role: "dispatcher",
					event: "triage-complete",
					state_before: "stage:needs-triage",
					state_after: "stage:ready-for-execution",
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						labels: ["code-flow:active", "stage:needs-triage"],
					},
					sources_evidence: ["https://github.com/acme/demo/issues/42"],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: "triaged" },
				})}\n`,
			);
			write(
				fakeGh,
				String.raw`#!/usr/bin/env sh
body=${JSON.stringify(bodyPath)}
case "$1 $2" in
  'issue view') jq -n --rawfile body "$body" '{number:42,url:"https://github.com/acme/demo/issues/42",body:$body}' ;;
  'issue edit')
    shift 3
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --body-file) cp "$2" "$body"; shift 2 ;;
        *) shift ;;
      esac
    done
    ;;
esac
`,
			);
			chmodSync(fakeGh, 0o755);

			expectSuccess(invoke());
			const firstBody = read(bodyPath);
			expect(firstBody).toStartWith(
				"<!-- code-flow:triage:start -->\n<!-- code-flow:event:v1",
			);
			expect(firstBody).toContain("> type: bug\n> Complexity: S");
			expect(firstBody).toContain("## Contexto e objetivo");
			expect(firstBody).toContain(
				"## Relato original\n\n<!-- code-flow:original-report:start -->\n## Reclamação do usuário\n\nA exportação CSV falha.\n<!-- code-flow:original-report:end -->",
			);

			expectSuccess(invoke());
			expect(read(bodyPath)).toBe(firstBody);
			expect(
				read(bodyPath).match(/code-flow:original-report:start/g),
			).toHaveLength(1);

			write(
				bodyPath,
				"<!-- code-flow:issue-header:start -->\n> type: feature\n> Complexity: S\n> project_guidance: AGENTS.md\n<!-- code-flow:issue-header:end -->\n\n## Pedido legado\n\nNão perder este contexto.\n",
			);
			expectSuccess(invoke());
			expect(
				read(bodyPath).match(/code-flow:issue-header:start/g),
			).toHaveLength(1);
			expect(read(bodyPath)).toContain(
				"## Relato original\n\n<!-- code-flow:original-report:start -->\n## Pedido legado\n\nNão perder este contexto.",
			);

			write(bodyPath, "  \n\n");
			expectSuccess(invoke());
			expect(read(bodyPath)).toContain("# Corrigir exportação CSV");
			expect(read(bodyPath)).not.toContain("## Relato original");
		} finally {
			cleanup(temporaryRoot);
		}
	});

	test("all runtime shell scripts have valid syntax and eval files exist", () => {
		for (const script of readdirSync(join(skillRoot, "scripts"))
			.filter((file) => file.endsWith(".sh"))
			.sort()) {
			expectSuccess(run(["bash", "-n", join(skillRoot, "scripts", script)]));
		}

		const evalCatalog = readJson<{ skill_name: string; evals: unknown[] }>(
			"tests/evals/evals.json",
		);
		expect(evalCatalog.skill_name).toBe("code-flow");
		expect(evalCatalog.evals.length).toBeGreaterThanOrEqual(5);
		expectExists(join(skillRoot, "tests", "evals", "run-evals.mjs"));
		expectContains("tests/evals/run-evals.mjs", "model_reasoning_effort");
		expectExists(
			join(
				skillRoot,
				"tests",
				"evals",
				"fixtures",
				"e5-agents-md",
				"AGENTS.md",
			),
		);
	});
});
