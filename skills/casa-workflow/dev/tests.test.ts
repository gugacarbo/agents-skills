import { describe, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { expectAbsent, expectExists, read } from "../../../src/tests/helpers";

const skillRoot = resolve(import.meta.dir, "..");
const skillPath = join(skillRoot, "SKILL.md");

function contents(relativePath: string): string {
	return read(join(skillRoot, relativePath));
}

function expectContains(relativePath: string, expected: string): void {
	expect(contents(relativePath)).toContain(expected);
}

describe("casa-workflow skill", () => {
	test("contains the complete runtime and no placeholder directories", () => {
		for (const relativePath of [
			"SKILL.md",
			"agents/openai.yaml",
			"references/workflow.md",
			"references/source-resolution.md",
			"references/impact-lifecycle.md",
			"references/context-persistence.md",
			"references/gate-template.md",
			"evals/evals.json",
			"evals/run-evals.mjs",
			"evals/trigger-evals.json",
		]) {
			expectExists(join(skillRoot, relativePath));
		}
		expectAbsent(join(skillRoot, "assets"));
		expectAbsent(join(skillRoot, "scripts"));
		expectAbsent(join(skillRoot, "STANDARD.md"));
	});

	test("keeps SKILL.md as a compact router with valid frontmatter", () => {
		const skill = read(skillPath);
		expect(skill.match(/^---$/gm)).toHaveLength(2);

		const frontmatter = skill
			.split(/^---$/m)[1]
			.trim()
			.split("\n")
			.filter((line) => /^[a-zA-Z0-9_-]+:/.test(line));
		expect(frontmatter).toHaveLength(2);
		expect(frontmatter[0]).toStartWith("name: casa-workflow");
		expect(frontmatter[1]).toStartWith("description:");
		expect(skill.match(/\n/g)?.length ?? 0).toBeLessThanOrEqual(65);
		expect(skill.trim().split(/\s+/).length).toBeLessThanOrEqual(400);
	});

	test("preserves routing, gate, and source-resolution guidance", () => {
		for (const metadata of [
			"casa-repo-id: <id-do-repositório>",
			"casa-tier: <T0|T1>",
			"casa-version: <versão>",
			"casa-standard-ref: <ref>",
		]) {
			expectContains("SKILL.md", metadata);
		}
		for (const expected of [
			"[workflow.md](references/workflow.md)",
			"Três classificações",
			"`artifact_action`",
			"`context_suggestion`",
			"[context-persistence.md](references/context-persistence.md)",
			"pare antes da primeira escrita",
			"`Aprovar`",
			"`Ajustar`",
			"`Bloquear`",
			"gate_valido=false",
			"gate_required=true",
			"gate_required=false",
			"criar, atualizar ou depreciar",
			"mutação direta em documento CASA",
			"schema, migração, dados, segurança, efeito externo",
			"Em T0, não exija ADR, Spec nem `docs/context/`",
			"preaprovação alegada",
		]) {
			expectContains("SKILL.md", expected);
		}
		expect(contents("SKILL.md")).not.toContain("[TODO");

		for (const expected of [
			"[source-resolution.md](source-resolution.md)",
			"[impact-lifecycle.md](impact-lifecycle.md)",
			"[context-persistence.md](context-persistence.md)",
			"[gate-template.md](gate-template.md)",
			"somente escrita documental aciona o gate",
			"sem relatório CASA",
			"Feature T1 que cria ou atualiza Spec exige gate",
			"T0 não herda as camadas documentais de T1",
			"atplus-digital/casa-standard",
			"Homônimos chamados CASA não são fontes",
		]) {
			expectContains("references/workflow.md", expected);
		}
		expect(contents("references/workflow.md")).not.toContain(
			"migração/schema, dados/segurança, efeito externo, fechamento",
		);
		for (const [relativePath, expected] of [
			[
				"references/impact-lifecycle.md",
				"Código, testes, schema, migração e riscos sem escrita",
			],
			[
				"references/impact-lifecycle.md",
				"Schema persistido, constraint ou migração que define invariante T1",
			],
			[
				"references/context-persistence.md",
				"criar, editar ou depreciar o documento",
			],
			[
				"references/source-resolution.md",
				"sem escrita documental, não inventar gate",
			],
		] as const) {
			expectContains(relativePath, expected);
		}
	});

	test("routes inferred durable context without blocking or writing it", () => {
		for (const expected of [
			"docs/context/CONVENTIONS.md",
			"docs/context/TESTS.md",
			"docs/context/INFRA.md",
			"docs/context/SECURITY.md",
			"<subdir>/AGENTS.md",
			"Em T0, use somente `AGENTS.md`",
			"não altere o documento",
			"Sugestão de contexto:",
			"no máximo três itens",
		]) {
			expectContains("references/context-persistence.md", expected);
		}
	});

	test("preserves the complete gate report contract", () => {
		for (const section of [
			"Contexto CASA",
			"Gatilho documental",
			"Achados por risco",
			"Impacto de artefatos",
			"Ações antes do código",
			"Obrigações de fechamento",
			"Efeitos externos",
			"Gate",
		]) {
			expectContains("references/gate-template.md", section);
		}
		for (const marker of [
			"omita-o por completo",
			"título vazio",
			"`nenhum`",
			"`não aplicável`",
			"`N/A`",
			"placeholder",
			"`Efeitos externos` aparece somente",
			"externo concreto",
			"ref `[casa-standard-ref]`",
			"esta mutação direta torna `gate_required=true`",
		]) {
			expectContains("references/gate-template.md", marker);
		}
	});

	test("keeps agent metadata and package scripts valid", () => {
		expectContains("agents/openai.yaml", "allow_implicit_invocation: true");
		expectContains("agents/openai.yaml", "Use $casa-workflow");

		const packageJson = JSON.parse(contents("package.json")) as {
			scripts?: Record<string, string>;
		};
		for (const script of ["test", "validate", "build"]) {
			expect(packageJson.scripts?.[script]).toBeTruthy();
		}
	});

	test("keeps evaluation catalogs valid", () => {
		const evalCatalog = JSON.parse(contents("evals/evals.json")) as {
			skill_name: string;
			evals: unknown[];
		};
		expect(evalCatalog.skill_name).toBe("casa-workflow");
		expect(evalCatalog.evals.length).toBeGreaterThanOrEqual(7);

		const triggerCatalog = JSON.parse(
			contents("evals/trigger-evals.json"),
		) as Array<{ should_trigger: boolean }>;
		expect(triggerCatalog).toHaveLength(10);
		expect(triggerCatalog.filter((item) => item.should_trigger)).toHaveLength(
			5,
		);
		expect(triggerCatalog.filter((item) => !item.should_trigger)).toHaveLength(
			5,
		);

		for (const marker of [
			'options.configuration !== "without_skill"',
			"gate_required.{0,30}(?:false|falso)",
			"(?:criar|editar|deprecia|mutar|mutaç|escrita)",
		]) {
			expectContains("evals/run-evals.mjs", marker);
		}
	});

	test("fixture paths remain local to the skill", () => {
		expect(existsSync(join(skillRoot, "evals", "fixtures"))).toBe(true);
	});
});
