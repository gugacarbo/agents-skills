---
name: gate
description: Valida um comando público de gate e a permissão atual do autor antes de aplicar uma transição humana; não interpreta comentários livres.
requires_tools: [read, github, edit]
inputs: [issue_url, gate_comment, project_guidance]
outputs: [gate-event, confirmed-transition]
---

# Gate

Consuma somente comentário com sintaxe exata `/code-flow gate DECISION`. Leia
`../worker-runtime.md`, `../runtime.md`, `../workflow-states.json`,
`../templates/human-gate-template.md` e o estado remoto da issue.

1. Rejeite texto adicional, decisão desconhecida ou evento/evidência
   incompatível. Exija `needs-human` e ausência de overlay, exceto `reset`,
   que exige exatamente o overlay ativo no estado registrado.
2. Consulte a permissão GitHub atual do autor. Apenas `write`, `maintain` ou
   `admin` podem decidir; não confie em menções, cargo no comentário ou snapshot.
3. Mapeie a decisão pelo campo `outcomes` do registry: `approve`, `authorize`,
   `integrate`, `adjust`, `block`, `wait`, `resume`, `reset` ou `migrate`.
4. Publique evento de gate antes de labels e aplique-o com `apply-event.sh gate`.
   Em `migrate`, restaure somente o estado registrado no evento legado bloqueado.
5. Confirme labels remotas e retorne o resultado estruturado. Não implemente,
   revise, integre ou reescreva a decisão humana.
