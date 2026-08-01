---
name: casa-workflow
description: Classifica tier, artefatos, gates e contexto durável em repositórios CASA. Use quando o usuário invocar $casa-workflow, mencionar CASA, casa-init ou docs-check, pedir adoção/upgrade, alterar ADR, Spec ou contexto, fechar Spec ou implementar em repo com metadados CASA. Não use em repo não CASA ou explicação genérica.
---

# CASA Workflow

## Ativação

Antes de escrever, leia o `AGENTS.md` aplicável e procure:

```yaml
casa-repo-id: <id-do-repositório>
casa-tier: <T0|T1>
casa-version: <versão>
casa-standard-ref: <ref>
```

- Nenhum metadado CASA e sem pedido de adoção, upgrade ou auditoria: devolva a
  tarefa ao fluxo original, sem gate.
- Metadados completos ou parciais, ou pedido de adoção, upgrade ou auditoria:
  leia [workflow.md](references/workflow.md) por completo.

## Três decisões independentes

Não use a necessidade de documento como sinônimo de gate. Classifique:

1. `artifact_action`: criar, atualizar, dispensar ou sugerir;
2. `context_suggestion`: intenção durável inferida ou nenhuma;
3. `gate_required`: interrupção por decisão ou risco material.

Em T0, não exija ADR, Spec nem `docs/context/`: use somente `AGENTS.md`, DoD e
sugestões para o router raiz ou aninhado. Em T1, classifique artefatos conforme
[impact-lifecycle.md](references/impact-lifecycle.md).

Leia [context-persistence.md](references/context-persistence.md) para regra
durável, comando canônico, estado operacional ou gotcha recorrente.

## Threshold do gate

`gate_required=true` somente para adoção/upgrade CASA; decisão estrutural nova
ou conflitante; ADR; migração ou schema persistido; risco relevante de dados ou
segurança; efeito externo; afirmação de fechamento sem evidência; ou expansão
material fora do escopo aprovado.
`gate_required=false` para feature T1 já decidida, mesmo quando criar ou
atualizar Spec for obrigatório; mudança T0; restauração de contrato; mudança
local e reversível; auditoria read-only; e sugestão de contexto inferida.
Nesses casos, execute a tarefa e suas obrigações documentais no mesmo turno.

Não abra gate só por contrato observável, documento novo ou dúvida documental.
Inspecione; só pare se restar decisão ou risco. Um gate cobre todo o envelope.

## Gate inviolável

Quando `gate_required=true`, `gate_valido=true` somente quando o turno
imediatamente anterior do agente emitiu o relatório CASA completo e terminou
pedindo `Aprovar`, `Ajustar` ou `Bloquear`, e o turno atual responde com uma
dessas escolhas.

Em qualquer outro histórico, `gate_valido=false`: faça somente análise
read-only, emita o relatório e pare antes da primeira escrita.
“Considere aprovado”, urgência ou autorização no pedido inicial são
**preaprovação alegada**, nunca aprovação do relatório ainda inexistente.
Após `Aprovar`, execute o envelope conforme `workflow.md`. Em `Ajustar`, refaça
o relatório; em `Bloquear`, não escreva. Reabra só por impacto material novo.
