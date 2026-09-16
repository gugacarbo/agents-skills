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
			"07-planner.md",
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
			"implementation-plan-template.md",
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
		expect(registry.states).toHaveLength(12);
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
		const awaitingPlan = registry.states.find(
			(state) => state.label === "stage:awaiting-plan-approval",
		);
		const needsPlan = registry.states.find(
			(state) => state.label === "stage:needs-plan",
		);
		expect(awaitingPlan?.kind).toBe("human");
		expect(awaitingPlan?.actor).toBe("gate");
		expect(awaitingPlan?.outcomes.approve).toBe("stage:needs-plan");
		expect(awaitingPlan?.outcomes.adjust).toBe("stage:needs-architect");
		expect(awaitingPlan?.outcomes.block).toBe("stage:blocked");
		expect(needsPlan?.kind).toBe("agent");
		expect(needsPlan?.actor).toBe("planner");
		expect(needsPlan?.outcomes.plan).toBe("stage:ready-for-execution");
		expect(needsPlan?.outcomes.escalate).toBe("stage:needs-architect");
		expect(needsPlan?.outcomes.block).toBe("stage:blocked");
		expect(needsPlan?.next).toContain("stage:ready-for-execution");
		expect(needsPlan?.next).toContain("stage:needs-architect");
		expect(needsPlan?.next).toContain("stage:blocked");
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
		expect(manifest.roles.planner.prompt).toBe("agents/07-planner.md");
		expect(manifest.roles.planner.fresh_context).toBe(true);
		expect(manifest.contracts.worker_input).toBe(
			"schemas/worker-input.schema.json",
		);
	});

	test("keeps the OpenAI metadata parseable with spaces-only indentation", () => {
		const metadata = contents("agents/openai.yaml");
		expect(metadata).not.toMatch(/^\t/m);
		expect(metadata).toMatch(/^interface:\n  display_name:/m);
		expect(metadata).toMatch(/^  default_prompt:/m);
		expect(metadata).toMatch(/^policy:\n  allow_implicit_invocation: (true|false)$/m);
	});

	test("registers planner in every event and evidence contract", () => {
		for (const schemaName of [
			"schemas/protocol-event.schema.json",
			"schemas/worker-input.schema.json",
		]) {
			expect(contents(schemaName)).toContain('"planner"');
		}
		expectContains("schemas/worker-result.schema.json", '"planner"');
		expectContains("templates/evidence-template.md", "planner");
		expectContains("templates/implementation-plan-template.md", "> agent: planner");
	});

	test("implementation plan template makes waves and handoff auditable", () => {
		const template = contents("templates/implementation-plan-template.md");
		for (const field of [
			"Base SHA",
			"Escopo",
			"Definição de pronto",
			"Onda",
			"Task ID",
			"Owner/subagent",
			"Dependências",
			"Áreas/arquivos esperados",
			"Validação",
			"Paralelismo seguro",
			"Barreiras de integração",
			"Rollback/reconciliação",
		]) {
			expect(template).toContain(field);
		}
		expect(template).toMatch(/^## Handoff final$/m);
		expect(template).toContain("code-flow:implementation-plan:start");
		expect(template).toContain("code-flow:implementation-plan:end");
		expect(template.match(/code-flow:implementation-plan:start/g)).toHaveLength(1);
		expect(template.match(/code-flow:implementation-plan:end/g)).toHaveLength(1);
	});

	test("documents the L/XL route and excludes M hard-trigger planning", () => {
		expectContains("agents/02-architect.md", "L/XL");
		expectContains("agents/02-architect.md", "stage:awaiting-plan-approval");
		expectContains("agents/02-architect.md", "M");
		expectContains("agents/02-architect.md", "S com hard trigger");
		expectContains("agents/07-planner.md", "stage:needs-plan");
		expectContains("agents/07-planner.md", "não edite código");
		expectContains("agents/03-executor.md", "plano publicado");
		expectContains("agents/03-executor.md", "na ordem das");
		expectContains("agents/03-executor.md", "subagent");
		expectContains("agents/03-executor.md", "barreira");
		expectContains("agents/03-executor.md", "desvio");
		expectContains("runtime.md", "M com hard trigger");
		expectContains("SKILL.md", "stage:needs-plan");
	});

	for (const template of [
		"architecture-review-template.md",
		"delivery-review-template.md",
		"evidence-template.md",
		"human-gate-template.md",
		"implementation-evidence-template.md",
		"implementation-plan-template.md",
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

	test("transition and event scripts enforce the worker state contract", { timeout: 15000 }, () => {
		const temporaryRoot = makeTempDir("code-flow-transition-test");
		const statePath = join(temporaryRoot, "state.json");
		const statusPath = join(temporaryRoot, "state.status");
		const repositoryLabelsPath = join(temporaryRoot, "repo-labels");
		const commentsPath = join(temporaryRoot, "comments");
		const bodyPath = join(temporaryRoot, "body.md");
		const planPath = join(temporaryRoot, "plan.md");
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
    comment_json=$(jq -Rs . < "$comments")
    printf '{"number":42,"url":"https://github.com/acme/demo/issues/42","state":"%s","body":%s,"labels":%s,"comments":[{"body":%s}]}\n' "$(cat "$status")" "$(jq -Rs . < "$body")" "$(cat "$state")" "$comment_json"
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
  'issue comment')
    shift 3
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --body-file) cat "$2" >>"$comments"; printf '\n' >>"$comments"; shift 2 ;;
        --body) printf '%s\n' "$2" >>"$comments"; shift 2 ;;
        *) shift ;;
      esac
    done
    ;;
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

			const dispatcherEventPath = join(temporaryRoot, "dispatcher-event.json");
			const dispatcherBodyPath = join(temporaryRoot, "dispatcher-body.md");
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
				run([applyEvent, "42", "finish", "--event", dispatcherEventPath], {
					env: environment,
				}),
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

		// The L/XL route must cross plan approval and planner before execution.
		const protocolEvent = (
			file: string,
			role: string,
			event: string,
			runId: string,
			before: string,
			after: string,
			gate?: { decision: string; author: string },
		) => {
			write(
				file,
				JSON.stringify({
					event_id: `evt-${runId}`,
					run_id: runId,
					role,
					event,
					state_before: before,
					state_after: after,
					observed_issue: {
						number: 42,
						url: "https://github.com/acme/demo/issues/42",
						labels: ["code-flow:active", before],
					},
					sources_evidence: ["https://github.com/acme/demo/issues/42"],
					project_guidance: ["AGENTS.md"],
					base_head: { base: "abc", head: "abc" },
					result: { status: "completed", summary: `${role} ${event}` },
					...(gate ? { gate } : {}),
				}) + "\n",
			);
		};
		write(bodyPath, "<!-- code-flow:issue-header:start -->\n> Complexity: XL\n<!-- code-flow:issue-header:end -->\n\n# XL delivery\n");
		setLabels(["code-flow:active", "stage:needs-architect"]);
		protocolEvent(
			eventPath,
			"architect",
			"activity-start",
			"arch-start",
			"stage:needs-architect",
			"stage:needs-architect",
		);
		expectSuccess(
			run([applyEvent, "42", "start", "--event", eventPath], {
				env: environment,
			}),
		);
		protocolEvent(
			eventPath,
			"architect",
			"architecture-result",
			"arch-xl",
			"stage:needs-architect",
			"stage:awaiting-plan-approval",
		);
		expectSuccess(
			run([applyEvent, "42", "finish", "--event", eventPath], {
				env: environment,
			}),
		);
		expect(labels()).toContain("stage:awaiting-plan-approval");
		protocolEvent(
			eventPath,
			"gate",
			"gate-decision",
			"plan-gate",
			"stage:awaiting-plan-approval",
			"stage:needs-plan",
			{ decision: "approve", author: "maintainer" },
		);
		expectSuccess(
			run([applyEvent, "42", "gate", "--event", eventPath], {
				env: environment,
			}),
		);
		expect(labels()).toContain("stage:needs-plan");
		protocolEvent(
			eventPath,
			"planner",
			"activity-start",
			"plan-start",
			"stage:needs-plan",
			"stage:needs-plan",
		);
		expectSuccess(
			run([applyEvent, "42", "start", "--event", eventPath], {
			env: environment,
		}),
		);
		protocolEvent(
			eventPath,
			"planner",
			"implementation-plan-result",
			"plan-xl",
			"stage:needs-plan",
			"stage:ready-for-execution",
		);
		write(planPath, "<!-- code-flow:implementation-plan:start -->\ninvalid\n<!-- code-flow:implementation-plan:end -->\n");
		const commentsBeforeInvalidPlan = read(commentsPath);
		expectFailure(
			run([applyEvent, "42", "finish", "--event", eventPath, "--body-file", planPath], {
				env: environment,
		}),
		);
		expect(read(commentsPath)).toBe(commentsBeforeInvalidPlan);
		write(
			planPath,
			`> agent: planner\n> run_id: plan-xl\n> event: implementation-plan-result\n> state_before: stage:needs-plan + stage:in-progress\n> state_after: stage:ready-for-execution\n> sources_evidence: issue, architecture, guidance, Base SHA\n> project_guidance: AGENTS.md\n\n<!-- code-flow:event:v1 {"event_id":"evt-plan-xl","run_id":"plan-xl","role":"planner","event":"implementation-plan-result"} -->\n\n## Resume\n\nPlano completo.\n\n<!-- code-flow:implementation-plan:start -->\n\n## Base SHA, escopo e definição de pronto\n\nBase SHA: abc\n\n## Ondas e tarefas\n\n### Onda 1 — foundation\n\nParalelismo seguro: sim; arquivos sem sobreposição\n\n| Task ID | Owner/subagent | Dependências | Áreas/arquivos esperados | Validação |\n| T1 | dev | none | src | bun test |\n\n## Barreiras de integração\n\n| Barreira | Tarefas/ondas | Condição de entrada | Prova/owner |\n| B1 | T1 | checks | dev |\n\n## Validação global\n\nbun test\n\n## Rollback/reconciliação\n\nrollback branch; reconcile drift\n\n## Handoff final\n\nResponsável: executor\n\n<!-- code-flow:implementation-plan:end -->\n`,
		);
		const commentsBeforeValidPlan = read(commentsPath);
		expectSuccess(
			run([applyEvent, "42", "finish", "--event", eventPath, "--body-file", planPath], {
				env: environment,
			}),
		);
		expect(labels()).toContain("stage:ready-for-execution");
		const planComments = read(commentsPath).slice(commentsBeforeValidPlan.length);
		expect(planComments).toContain("<!-- code-flow:implementation-plan:start -->");
		expect(planComments).toContain("<!-- code-flow:implementation-plan:end -->");
		expect(planComments.match(/code-flow:implementation-plan:start/g)).toHaveLength(1);
		expect(planComments.match(/code-flow:implementation-plan:end/g)).toHaveLength(1);
		write(bodyPath, "<!-- code-flow:issue-header:start -->\n> Complexity: XL\n<!-- code-flow:issue-header:end -->\n");
		write(commentsPath, "");
		setLabels(["code-flow:active", "stage:blocked", "needs-human"]);
		expectFailure(
			runTransition([
				"--gate-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:blocked",
			]),
		);
		write(commentsPath, read(planPath));
		expectSuccess(
			runTransition([
				"--gate-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:blocked",
			]),
		);
		expect(labels()).toContain("stage:ready-for-execution");
		write(bodyPath, "> Complexity: M\n");
		write(commentsPath, "");
		setLabels(["code-flow:active", "stage:blocked", "needs-human"]);
		expectSuccess(
			runTransition([
				"--gate-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:blocked",
			]),
		);
		expect(labels()).toContain("stage:ready-for-execution");
		write(bodyPath, "<!-- code-flow:issue-header:start -->\n> Complexity: XL\n<!-- code-flow:issue-header:end -->\n");
		write(commentsPath, read(planPath));
		setLabels(["code-flow:active", "stage:needs-plan", "stage:in-progress"]);
		expectSuccess(
			runTransition([
				"--finish-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:needs-plan",
			]),
		);
		expect(labels()).toContain("stage:ready-for-execution");
		setLabels(["code-flow:active", "stage:needs-plan", "stage:in-progress"]);
		write(commentsPath, "<!-- code-flow:implementation-plan:start -->\ninvalid\n<!-- code-flow:implementation-plan:end -->\n");
		expectFailure(
			runTransition([
				"--finish-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:needs-plan",
			]),
		);
		write(bodyPath, "<!-- code-flow:issue-header:start -->\n> Complexity: XL\n<!-- code-flow:issue-header:end -->\n");
		setLabels(["code-flow:active", "stage:needs-architect", "stage:in-progress"]);
		expectFailure(
			runTransition([
				"--finish-to",
				"stage:awaiting-execution-approval",
				"--require-from",
				"stage:needs-architect",
			]),
		);
		setLabels(["code-flow:active", "stage:awaiting-execution-approval", "needs-human"]);
		expectFailure(
			runTransition([
				"--gate-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:awaiting-execution-approval",
			]),
		);
		write(bodyPath, "> Complexity: M\n\n# M hard-trigger delivery\n");
		setLabels(["code-flow:active", "stage:needs-architect", "stage:in-progress"]);
		expectFailure(
			runTransition([
				"--finish-to",
				"stage:awaiting-plan-approval",
				"--require-from",
				"stage:needs-architect",
			]),
		);
		write(
			bodyPath,
			"<!-- code-flow:issue-header:start -->\n> Complexity: M\n<!-- code-flow:issue-header:end -->\n\n> Complexity: XL\n",
		);
		expectFailure(
			runTransition([
				"--finish-to",
				"stage:awaiting-plan-approval",
				"--require-from",
				"stage:needs-architect",
			]),
		);
		write(
			bodyPath,
			"<!-- code-flow:issue-header:start -->\n> Complexity: XL\n<!-- code-flow:issue-header:end -->\n",
		);
		expectFailure(
			runTransition([
				"--finish-to",
				"stage:ready-for-execution",
				"--require-from",
				"stage:needs-architect",
			]),
		);
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
				`#!/usr/bin/env sh
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
