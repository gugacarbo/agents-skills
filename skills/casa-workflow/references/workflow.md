# Workflow CASA

Leia esta referência por completo quando o router ativar o CASA.

## Classificar a unidade de trabalho

1. Resolva o contrato pinado conforme
   [source-resolution.md](source-resolution.md); não aplique silenciosamente
   outra versão.
2. Inspecione status, diff, tarefa, código e documentos relacionados sem usar
   artefatos gerados proibidos pelo repo.
3. Leia o tier antes de classificar documentos:
   - T0: não exigir ADR, Spec nem `docs/context/`; manter `AGENTS.md` e DoD.
   - T1: classificar decisão e comportamento conforme
     [impact-lifecycle.md](impact-lifecycle.md).
4. Calcule `artifact_action` e `context_suggestion`; derive `gate_required`
   exclusivamente da existência de mutação direta em documento CASA.
5. Leia [context-persistence.md](context-persistence.md) se houver intenção ou
   descoberta durável.
6. Use `gate_required=true` somente se o source-set criar, atualizar ou
   depreciar diretamente documento CASA, inclusive transição de status ou
   substituição. São documentos CASA os routers `AGENTS.md`, a ponte `CLAUDE.md`,
   ADRs, Specs, capítulos de contexto, backlog, templates e índices CASA.
7. Use `gate_required=false` quando não houver essa escrita documental, mesmo
   para decisão estrutural, migração/schema, dados/segurança, efeito externo,
   mudança T0, auditoria read-only ou sugestão inferida.

Risco técnico não substitui o predicado documental. Segurança, dados, operação
destrutiva, efeito remoto e expansão de escopo podem exigir autorização própria
pelas regras gerais do agente, mas não o relatório CASA sem escrita documental.
Não use essa regra para pular o mapa de impacto T1: classifique primeiro ADR,
Spec e contexto obrigatórios; somente então derive o gate da mutação resultante.

Se `gate_required=false`, continue sem relatório CASA. Se uma obrigação T1
exigir criar ou atualizar Spec, ADR ou outro documento CASA,
`gate_required=true`: emita o relatório e pare antes de qualquer escrita do
envelope. Após aprovação, use `docs-reserve` quando existir; sem ele, derive o
próximo `NNNN` de quatro dígitos dos arquivos locais e preserve o formato
`docs/specs/NNNN-titulo-kebab.md`. Não crie documento por cerimônia.

## Preparar o relatório

Somente quando `gate_required=true`:

1. Separe fatos verificáveis de decisões abertas. Alegação não é evidência.
2. Declare qual criação, atualização ou depreciação documental acionou o gate.
3. Emita o relatório usando
   [gate-template.md](gate-template.md) e encerre o turno no gate.

Em upgrade, a toolchain local é somente evidência de divergência. Resolva
`STANDARD.md` e `CHANGELOG.md` no upstream canônico
`atplus-digital/casa-standard` antes de propor versão/ref alvo. Se isso falhar,
marque o alvo como não resolvido. Homônimos chamados CASA não são fontes
válidas. Nomeie literalmente o upstream no relatório e só proponha um ref exato
confirmado; `main` é fonte de descoberta, não ref pinado.

## Após o gate

- `Aprovar`: altere somente os artefatos aprovados e use a toolchain local.
- `Ajustar`: revise o mapa, emita novo relatório e pare novamente.
- `Bloquear`: não materialize nada.
- A aprovação cobre o source-set, o contrato e as obrigações da unidade de
  trabalho descrita; novas edições e arquivos dentro desse envelope não exigem
  outro gate.
- Reabra antes da próxima escrita somente se surgir mutação direta de documento
  CASA fora do envelope documental aprovado.

No fechamento, verifique paths, comandos, DoD, estado atual e gotchas. Não
declare Spec `implemented` sem `implemented-by` real, verificação executada,
casos relevantes cobertos, propagação aplicável e índices regenerados pela
ferramenta.

Se uma intenção durável foi inferida e não era edição documental explícita,
termine a tarefa e só então apresente a sugestão compacta definida em
`context-persistence.md`. A sugestão não reabre gate e não autoriza escrita.

## Guardrails

- Adoção CASA ativa a classificação; somente escrita documental aciona o gate.
- Quantidade de linhas e risco técnico não definem o threshold.
- Documento CASA novo, editado, depreciado ou substituído exige gate.
- Feature T1 que cria ou atualiza Spec exige gate antes da primeira escrita.
- Correção que restaura contrato existente não altera a Spec.
- T0 não herda as camadas documentais de T1.
- Não edite o corpo de ADR aceita; crie nova ADR e marque a anterior como
  `superseded`.
- Não implemente contrato observável sem a Spec exigida pelo contrato pinado.
- Não execute `casa-init`, upgrade, issue, PR, label ou outro efeito remoto sem
  autorização específica; gate CASA existe apenas se também houver mutação
  documental e não concede autorização remota.
- Não copie o Standard, edite índice gerado manualmente ou use `dist/` quando o
  repo o proibir.
- Ao detectar escrita prematura, pare, reporte o desvio e retorne ao gate.

Metadados de desenvolvimento: [interface do agente](../agents/openai.yaml),
[runner de evals](../evals/run-evals.mjs) e
[catálogo de ativação](../evals/trigger-evals.json).
