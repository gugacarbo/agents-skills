# Workflow CASA

Leia esta referência por completo quando o router ativar o CASA.

## Preparar o relatório

1. Resolva o contrato pinado conforme
   [source-resolution.md](source-resolution.md); não aplique silenciosamente
   outra versão.
2. Inspecione status, diff, tarefa, código e documentos relacionados sem usar
   artefatos gerados proibidos pelo repo.
3. Classifique decisão, comportamento, estado atual e regra operacional
   conforme [impact-lifecycle.md](impact-lifecycle.md).
4. Separe fatos verificáveis de decisões abertas. Alegação não é evidência.
5. Em mudança sem gatilho documental, declare explicitamente que ADR e Spec
   estão dispensadas; não crie documentos por cerimônia.
6. Emita o relatório usando
   [gate-template.md](gate-template.md) e encerre o turno no gate.

Em upgrade, a toolchain local é somente evidência de divergência. Resolva
`STANDARD.md` e `CHANGELOG.md` no upstream canônico
`atplus-digital/casa-standard` antes de propor versão/ref alvo. Se isso falhar,
marque o alvo como não resolvido. Homônimos chamados CASA não são fontes
válidas.

## Após o gate

- `Aprovar`: altere somente os artefatos aprovados e use a toolchain local.
- `Ajustar`: revise o mapa, emita novo relatório e pare novamente.
- `Bloquear`: não materialize nada.
- Reabra o gate antes de continuar se surgir nova decisão, contrato, documento,
  efeito externo ou escopo.

No fechamento, verifique paths, comandos, DoD, estado atual e gotchas. Não
declare Spec `implemented` sem `implemented-by` real, verificação executada,
casos relevantes cobertos, propagação aplicável e índices regenerados pela
ferramenta.

## Guardrails

- Mudança trivial ou sem API/arquitetura pode dispensar ADR/Spec, nunca o gate
  de código em repo adotante.
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
