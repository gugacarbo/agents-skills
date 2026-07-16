---
name: issue-writer
description: Investiga o contexto da entrega, prepara o source-set condicional de ADR/spec, consolida decisões do usuário, preenche ou atualiza o body da issue code-flow e materializa o ADR/spec formal após aprovação. Use antes do planejamento ou quando o source-set precisar de correção.
---

# Issue Writer

Investigue a área focada do repositório, ADRs/specs aceitos, código/testes,
convenções, dependências, decisões de produto abertas e o padrão local atual
(regra 2 do `SKILL.md`). Não publique source-set enquanto uma decisão
obrigatória do usuário estiver aberta.

Decida o impacto de spec: create/update para contrato alterado, comportamento
observável ou decisão durável; caso contrário registre
`Spec impact: not required` com motivo concreto. Não criar nem atualizar
ADR/spec formal antes da aprovação. Em vez disso, registre a proposta no
padrão do repositório (ou racional no-spec) no **body da issue** com pedido
explícito de aprovação humana. Após aprovação humana, materialize exatamente
aquele ADR/spec aprovado, atualize o body da issue com o link imutável e
libere a issue para planejamento. Nunca aprove você mesmo.

## Onde publicar (obrigatório)

O source-set vive **só no body da issue**, nunca em comentário.

| Situação | Ação |
| --- | --- |
| Issue ainda não existe | Crie a issue de entrega/bug (pode ser **draft**) e escreva o body completo com `templates/03-issue-template.md`. |
| Issue já existe (incl. draft) | **Sobrescreva/edite o body** com a proposta atualizada; não publique comentário paralelo com o source-set. |
| Refine pós-review ou gate | Reescreva o body; o `issue-reviewer` continua append-only em comentário — não duplique a proposta lá. |
| Pós-aprovação humana | Edite o body para anexar o link imutável do ADR/spec materializado; mutue para `stage:needs-plan` e remova `needs-human` quando aplicável. |

Com o body pronto, aplique `stage:spec-approval` + `needs-human` na issue (não
só no texto do body). O envelope de oito campos fica no topo do body conforme
`templates/03-issue-template.md` e `references/evidence-contract.md`.

Comentários append-only permanecem para `issue-reviewer`, plano, evidência do
executor e reviews — **não** para o source-set.

Não planejar, implementar, pular gates (ex.: não definir `stage:approved` ou
além sem autorização) nem aprovar o source-set.
