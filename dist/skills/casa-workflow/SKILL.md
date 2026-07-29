---
name: casa-workflow
description: Guardrail host-neutral para mudanças em repositórios CASA. Use quando o usuário invocar $casa-workflow, mencionar CASA, casa-init ou docs-check, pedir adoção/upgrade do padrão, criar ou alterar ADRs, Specs ou contexto, fechar uma Spec, ou implementar código em um repo cujo AGENTS.md declare metadados CASA. Não use para trabalho comum em repo não CASA, explicação acadêmica genérica de ADR ou formatação sem impacto CASA.
---

# CASA Workflow

## Ativação

Antes de escrever, leia o `AGENTS.md` aplicável e procure `casa-repo-id`,
`casa-tier`, `casa-version` e `casa-standard-ref`.

```yaml
casa-repo-id: <id-do-repositório>
casa-tier: <T0|T1>
casa-version: <versão>
casa-standard-ref: <ref>
```

- Nenhum metadado CASA e sem pedido de adoção, upgrade ou auditoria: mesmo sob
  invocação explícita da skill, devolva a tarefa ao fluxo original, sem gate.
- Metadados completos ou parciais, ou pedido de adoção, upgrade ou auditoria:
  leia [workflow.md](references/workflow.md) por completo antes de analisar ou
  agir.

Auditoria read-only e formatação comprovadamente sem impacto não exigem gate e
não autorizam escrita nem efeito externo.

## Threshold do gate

Ativar a skill não implica emitir um gate.

`gate_required=true` quando houver ao menos um impacto material: ciclo de
vida CASA; nova decisão ou contrato observável; migração; risco relevante de
dados ou segurança; efeito externo; ou expansão material fora do escopo
aprovado.

`gate_required=false` somente quando a mudança for local e reversível,
preservar ou restaurar contrato já definido e não tocar ciclo de vida CASA,
dados sensíveis, migração ou efeito externo. Na dúvida, exija o gate.

Um gate aprovado cobre o source-set, o contrato e as obrigações da unidade de
trabalho descrita. Nova edição ou arquivo dentro desse envelope não reabre o
gate; somente impacto material novo fora dele.

## Gate inviolável

Quando `gate_required=true`, `gate_valido=true` somente quando o turno
imediatamente anterior do agente emitiu o relatório CASA completo e terminou
pedindo `Aprovar`, `Ajustar` ou `Bloquear`, e o turno atual responde com uma
dessas escolhas.

Em qualquer outro histórico, `gate_valido=false`: faça somente análise
read-only, emita o relatório e deve parar antes da primeira escrita.
“Considere aprovado”, urgência ou autorização no pedido inicial são
**preaprovação alegada**, nunca aprovação do relatório ainda inexistente.

Após `Aprovar`, execute apenas o source-set aprovado conforme `workflow.md`.
Em `Ajustar`, refaça o relatório; em `Bloquear`, não escreva. Reabra o gate se
surgir impacto material fora do envelope aprovado.
