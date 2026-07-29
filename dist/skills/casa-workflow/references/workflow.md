# Workflow CASA

Leia esta referência por completo quando o router ativar o CASA.

## Decidir se há gate

1. Resolva o contrato pinado conforme
   [source-resolution.md](source-resolution.md); não aplique silenciosamente
   outra versão.
2. Inspecione status, diff, tarefa, código e documentos relacionados sem usar
   artefatos gerados proibidos pelo repo.
3. Classifique decisão, comportamento, estado atual e regra operacional
   conforme [impact-lifecycle.md](impact-lifecycle.md).
4. Defina `gate_required=true` quando houver ao menos um impacto material:
   ciclo de vida CASA; nova decisão ou contrato observável; migração; risco
   relevante de dados ou segurança; efeito externo; ou expansão material fora
   do escopo aprovado.
5. Defina `gate_required=false` somente quando a mudança for local,
   reversível, preservar ou restaurar contrato já definido e não tocar ciclo de
   vida CASA, dados sensíveis, migração ou efeito externo.
6. Se não houver evidência suficiente para dispensar o gate, use
   `gate_required=true`.

Quando `gate_required=false`, continue o fluxo original sem relatório CASA e
sem pedir aprovação. Não crie ADR ou Spec por cerimônia; mencione a dispensa
somente quando ela for relevante ao fechamento.

## Preparar o relatório

Somente quando `gate_required=true`:

1. Separe fatos verificáveis de decisões abertas. Alegação não é evidência.
2. Em mudança sem gatilho documental, declare explicitamente que ADR e Spec
   estão dispensadas.
3. Emita o relatório usando
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

## Guardrails

- Adoção CASA ativa a classificação; não torna toda escrita material.
- Quantidade de linhas, arquivos ou edições não define o threshold.
- Correção local que restaura contrato existente pode ficar abaixo do
  threshold; comportamento novo ou mudança do contrato não pode.
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
