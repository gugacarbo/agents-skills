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
4. Calcule separadamente `artifact_action`, `context_suggestion` e
   `gate_required`; uma classificação não determina as outras.
5. Leia [context-persistence.md](context-persistence.md) se houver intenção ou
   descoberta durável.
6. Use `gate_required=true` somente para adoção/upgrade, decisão estrutural ou
   ADR, migração/schema, dados/segurança, efeito externo, fechamento sem
   evidência ou expansão material fora do envelope.
7. Use `gate_required=false` para feature decidida, inclusive com Spec
   obrigatória; T0; restauração de contrato; mudança local/reversível;
   read-only; e sugestão inferida.

Autenticação, autorização, erros ou dados já definidos no contrato da feature
pertencem à Spec e não acionam gate sozinhos. Risco de segurança/dados exige
gate quando surgir decisão, exposição ou tratamento sensível além do contrato
decidido.

Se `gate_required=false`, continue sem relatório CASA. Em T1, crie ou atualize a
Spec exigida antes do código e conclua documento, implementação e verificação
na mesma unidade autorizada. Use `docs-reserve` quando existir; sem ele, derive
o próximo `NNNN` de quatro dígitos dos arquivos locais e preserve o formato
`docs/specs/NNNN-titulo-kebab.md`. Não crie documento por cerimônia.

## Preparar o relatório

Somente quando `gate_required=true`:

1. Separe fatos verificáveis de decisões abertas. Alegação não é evidência.
2. Emita o relatório usando
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
- Reabra antes da próxima escrita somente se surgir impacto material fora do
  envelope: nova decisão, contrato, documento obrigatório, migração, risco
  relevante, efeito externo ou expansão material de escopo.

No fechamento, verifique paths, comandos, DoD, estado atual e gotchas. Não
declare Spec `implemented` sem `implemented-by` real, verificação executada,
casos relevantes cobertos, propagação aplicável e índices regenerados pela
ferramenta.

Se uma intenção durável foi inferida e não era edição documental explícita,
termine a tarefa e só então apresente a sugestão compacta definida em
`context-persistence.md`. A sugestão não reabre gate e não autoriza escrita.

## Guardrails

- Adoção CASA ativa a classificação; não torna toda escrita material.
- Quantidade de linhas, arquivos ou edições não define o threshold.
- Contrato observável ou documento novo, isoladamente, não exige gate.
- Feature T1 decidida cria/atualiza sua Spec sem interrupção adicional.
- Correção que restaura contrato existente não altera a Spec.
- T0 não herda as camadas documentais de T1.
- Não edite o corpo de ADR aceita; crie nova ADR e marque a anterior como
  `superseded`.
- Não implemente contrato observável sem a Spec exigida pelo contrato pinado.
- Não execute `casa-init`, upgrade, issue, PR, label ou outro efeito remoto sem
  autorização específica; o gate CASA não concede essa autorização.
- Não copie o Standard, edite índice gerado manualmente ou use `dist/` quando o
  repo o proibir.
- Ao detectar escrita prematura, pare, reporte o desvio e retorne ao gate.

Metadados de desenvolvimento: [interface do agente](../agents/openai.yaml),
[runner de evals](../evals/run-evals.mjs) e
[catálogo de ativação](../evals/trigger-evals.json).
