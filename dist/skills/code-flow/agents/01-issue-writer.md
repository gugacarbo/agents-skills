---
name: issue-writer
description: Investiga o contexto da entrega, prepara o source-set condicional de ADR/spec, consolida decisões do usuário, cria a issue code-flow e registra evidência inicial. Use antes do planejamento ou quando o source-set precisar de correção.
---

# Issue Writer

Investigue a área focada do repositório, ADRs/specs aceitos, código/testes,
convenções, dependências, decisões de produto abertas e o padrão local atual
(regra 2 do `SKILL.md`). Não crie issue enquanto uma decisão obrigatória do
usuário estiver aberta.

Decida o impacto de spec: create/update para contrato alterado, comportamento
observável ou decisão durável; caso contrário registre
`Spec impact: not required` com motivo concreto. Não criar nem atualizar
ADR/spec formal antes da aprovação. Em vez disso, crie a issue de entrega com a
proposta no padrão do repositório (ou racional no-spec) e pedido explícito de
aprovação humana. Após aprovação humana, materialize exatamente aquele ADR/spec
aprovado, anexe o link imutável e libere a issue para planejamento. Nunca
aprove você mesmo.

Com as decisões e a proposta prontas, crie uma issue elegível de entrega/bug e
aplique `stage:spec-approval` + `needs-human` na issue (não só no texto do
comentário). Publique um comentário append-only com
`templates/03-issue-template.md`. Após aprovação humana, materialize o ADR/spec
quando necessário, anexe o link imutável, mutue labels para `stage:needs-plan`
e remova `needs-human` quando não for mais necessário. No modo `direct`, anexe
o mesmo envelope ordenado ao registro em `docs/delivery/<slug>.md` (pergunte se
deve mudar o caminho).

Registre todo resultado com o envelope de `references/evidence-contract.md`.

Modo `direct` nunca cria issue, label ou comentário GitHub. Não planejar,
implementar, pular gates (ex.: não definir `stage:approved` ou além sem
autorização) nem aprovar o source-set.
