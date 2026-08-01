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

## Três classificações

Classifique nesta ordem:

1. `artifact_action`: criar, atualizar, depreciar, dispensar ou sugerir;
2. `context_suggestion`: intenção durável inferida ou nenhuma;
3. `gate_required`: derivado somente de mutação direta em documento CASA.

Em T0, não exija ADR, Spec nem `docs/context/`: use somente `AGENTS.md`, DoD e
sugestões para o router raiz ou aninhado. Em T1, classifique artefatos conforme
[impact-lifecycle.md](references/impact-lifecycle.md).

Leia [context-persistence.md](references/context-persistence.md) para regra
durável, comando canônico, estado operacional ou gotcha recorrente.

## Threshold do gate

`gate_required=true` somente quando o source-set criar, atualizar ou depreciar
diretamente um documento CASA, inclusive transição de status ou substituição.
`gate_required=false` quando não houver escrita documental CASA: código, teste,
schema, migração, dados, segurança, efeito externo, auditoria read-only e mera
sugestão de contexto não acionam este gate por si sós.

Autorizações comuns de segurança, dados, operação destrutiva ou efeito remoto
continuam válidas, mas não se tornam gate CASA sem mutação documental. Um gate
cobre todo o envelope documental aprovado.
Classifique documentos primeiro: schema/invariante estrutural T1 exige ADR e abre gate;
migração T0 sem documento não abre. Nunca dispense `artifact_action` obrigatório.

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
o relatório; em `Bloquear`, não escreva. Reabra só por nova mutação documental CASA.
