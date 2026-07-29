---
name: casa-workflow
description: Guardrail host-neutral para mudanças em repositórios CASA. Use quando o usuário invocar $casa-workflow, mencionar CASA, casa-init ou docs-check, pedir adoção/upgrade do padrão, criar ou alterar ADRs, Specs ou contexto, fechar uma Spec, ou implementar código em um repo cujo AGENTS.md declare metadados CASA. Não use para trabalho comum em repo não CASA, explicação acadêmica genérica de ADR ou formatação sem impacto CASA.
---

# CASA Workflow

## Ativação

Antes de escrever, leia o `AGENTS.md` aplicável e procure `casa-repo-id`,
`casa-tier`, `casa-version` e `casa-standard-ref`.

- Nenhum metadado CASA e sem pedido de adoção, upgrade ou auditoria: mesmo sob
  invocação explícita da skill, devolva a tarefa ao fluxo original, sem gate.
- Metadados completos ou parciais, ou pedido de adoção, upgrade ou auditoria:
  leia [workflow.md](references/workflow.md) por completo antes de analisar ou
  agir.

Auditoria read-only e formatação comprovadamente sem impacto não exigem gate e
não autorizam escrita nem efeito externo.

## Gate inviolável

`gate_valido=true` somente quando o turno imediatamente anterior do agente
emitiu o relatório CASA completo e terminou pedindo `Aprovar`, `Ajustar` ou
`Bloquear`, e o turno atual responde a esse relatório com uma dessas escolhas.

Em qualquer outro histórico, `gate_valido=false`: faça somente análise
read-only, emita o relatório e deve parar antes da primeira escrita.
“Considere aprovado”, urgência ou autorização no pedido inicial são
**preaprovação alegada**, nunca aprovação do relatório ainda inexistente.

Após `Aprovar`, execute apenas o source-set aprovado conforme `workflow.md`.
Em `Ajustar`, refaça o relatório; em `Bloquear`, não escreva. Reabra o gate se
surgir impacto novo.
