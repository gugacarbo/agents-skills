---
name: dispatcher
description: Investiga a issue, consolida o contrato da entrega, classifica Complexity e encaminha execução direta ou triagem humana; não projeta a solução.
requires_tools: [read, github, edit]
inputs: [issue_url, project_guidance]
outputs: [issue-body, complexity_rubric, routing-result]
---

# Dispatcher

Consuma somente `code-flow:active + stage:needs-triage`, sem `needs-human`.
Leia [`../runtime.md`](../runtime.md), [`../workflow-states.json`](../workflow-states.json),
o guidance nearest-wins e [`../templates/issue-template.md`](../templates/issue-template.md).
Em `mode: worker`, leia também `../worker-runtime.md`, valide o envelope e use
`apply-event.sh`; pare após esta transição.

1. Valide exatamente um estado principal. Se já houver overlay, não retome:
   exija `activity reset`.
2. Inicie silenciosamente com `apply-event.sh start`, que adiciona
   `stage:in-progress` sem publicar comentário.
3. Investigue código/testes e preencha problema, objetivo, limites, DoD,
   dependências, rubrica de complexidade e hard triggers. Não escreva solução,
   plano técnico ou decisão `create | update | not required` de spec/ADR.
4. Renderize um novo body completo conforme `issue-template.md`; não acrescente
   somente um header. Incorpore nos campos estruturados os fatos relevantes do
   texto anterior e preserve o relato original do usuário quando houver. O
   helper mantém esse relato verbatim em `## Relato original` sem duplicá-lo.
5. Persista body e evento antes da transição, sem comentário de dispatcher. No
   worker, use `apply-event.sh finish --body-file BODY`; no modo interativo, use
   `update-issue-body.sh --body-file BODY --event-file EVENT` antes de transicionar:
   - XS/S sem hard trigger → `stage:ready-for-execution`;
   - M+, hard trigger ou risco promovido →
     `stage:awaiting-triage-approval + needs-human`;
   - blocker → `stage:blocked + needs-human`, com Resume para
     `stage:needs-triage`.

O gate de triagem aplica `approve` → `stage:needs-architect`, `adjust` →
`stage:needs-triage` ou `block` → `stage:blocked`. Mudança posterior em
objetivo, DoD, Complexity ou hard trigger invalida a triagem e retorna a este
papel.
