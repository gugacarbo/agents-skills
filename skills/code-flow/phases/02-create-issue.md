# Fase 2: Criar a issue

Use o design aprovado da Fase 1 para preparar o source-set e criar a issue de
entrega no GitHub ou, após escolha explícita de Epic, o Epic de tracking.

Rode a descoberta de padrão do repositório (regra 2 do `SKILL.md`). Se a
ferramentagem estiver incerta, use `/code-flow tool doctor`. Continue só com uma
issue de entrega; uma iniciativa precisa de decisão explícita de Epic e de uma
filha delimitada. Antes de escrever, encontre o padrão do repositório para o
artefato e leve fonte e adaptações para a proposta. Uma issue de entrega usa
`templates/02-user-story.md` só quando complementar o padrão local; a
implementação permanece no plano aprovado como uma unidade do executor.

Despache `agents/01-issue-writer.md` para investigar a área focada, ADRs/specs
aceitos, código/testes, convenções, ownership, dependências, riscos e decisões
de produto abertas. Ele prepara a proposta; não cria nem atualiza ADR/spec
formal antes da aprovação humana. Refine só fatos deixados abertos pelo design
aprovado; não reabra escolhas de produto aprovadas sem evidência nova.

O `issue-writer` classifica o impacto de spec:

| Resultado | Quando usar | Ação necessária |
| --- | --- | --- |
| `create` | Novo contrato, comportamento observável ou decisão durável | Embutir rascunho ADR/spec no padrão do repositório na nova issue e pedir aprovação humana antes de criar o documento formal. |
| `update` | Um ADR/spec aceito governa comportamento alterado | Embutir a atualização proposta no padrão do repositório na nova issue e pedir aprovação humana antes de mudar o documento formal. |
| `not required` | Refator interno, restauração documentada, testes, docs, config ou sem mudança observável | Colocar o racional no-spec exato na nova issue e pedir aprovação humana; não criar spec só pelo workflow. |

ADRs/specs aceitos definem a intenção. Se uma fonte conflitar com o design
aprovado ou o código, pare e resolva antes de planejar. O `issue-writer` cria a
issue de entrega em `stage:spec-approval` + `needs-human`, usando o padrão de
issue/ADR/spec do repositório e `templates/03-issue-template.md` como proposta
e pedido de aprovação append-only. Inclui o design aprovado, rascunho ADR/spec
ou racional no-spec; ainda não materialize o ADR/spec formal.

Só `/code-flow issue create` cria a issue de entrega. A aprovação humana
autoriza o `issue-writer` a materializar o ADR/spec aprovado exatamente como
aprovado (ou reter o racional no-spec), anexar o link imutável e mutar labels
Não despachar `plan-writer` antes dessa evidência existir. `issue-reviewer` é opcional e
nunca substitui o gate humano.

Após o usuário selecionar explicitamente um Epic, crie-o no GitHub a partir do
padrão local e `templates/01-epic.md`. É só tracking: sem stage de entrega nem
plano. Cada issue filha selecionada segue esta fase de forma independente. No
modo `direct`, registre a mesma proposta, aprovação e ADR/spec materializado no
registro de entrega em `docs/delivery/<slug>.md` (pergunte se deve mudar o
caminho), sem estado GitHub.
