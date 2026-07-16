---
name: code-flow
description: "Coordinate non-trivial repository changes through ADR/spec-aware planning, six independent subagent roles, GitHub issue stages, review gates, and PR evidence. Use for delivery issues or batches; start from a named phase when requested."
metadata:
  user-invocable: true
---

# code-flow

Coordene o fluxo; despache os papéis nomeados em vez de escrever planos,
reviews ou implementação você mesmo.

## Comandos

| Invocação                                                               | Comportamento                                                                                                                                                                      |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/code-flow`                                                            | Sem issue: explique que a entrega exige issue GitHub e ofereça `issue create` ou `issue <#N>` / `batch`.                                                                           |
| `/code-flow issue create`                                               | Roda Fases 0–2 e cria ou preenche uma issue de entrega (incl. draft existente) cuja proposta ADR/spec no **body** entra em `stage:spec-approval` para review antes do gate humano. |
| `/code-flow create-issue`                                               | Alias de `/code-flow issue create` (canônico: `issue create`).                                                                                                                     |
| `/code-flow issue <#N\|URL> [phase]`                                    | Valida uma issue elegível existente e retoma seu stage ou fase nomeada.                                                                                                            |
| `/code-flow batch <#N\|URL>... --from <phase>`                          | Roda trilhas isoladas para issues elegíveis de entrega/bug existentes.                                                                                                             |
| `/code-flow brainstorm`                                                 | Fase 1 sem issue ainda; segue para `issue create` após o design aprovado.                                                                                                          |
| `/code-flow <plan\|dispatch\|review\|integrate>`                        | Exige issue (`issue <#N> [phase]`); recuse e peça `issue create` se não houver.                                                                                                    |
| `/code-flow tool <doctor\|bootstrap\|review-package\|transition-issue>` | Roda um helper e para.                                                                                                                                                             |

`issue create` é a única rota canônica de criação de issue (`create-issue` é
alias). Fases nomeadas nunca bypassam gates; `batch` nunca cria issues.
Entrega e evidência vivem em issues GitHub (labels + comentários append-only).
Não há modo sem issue.

## Regras antes de escrever

1. Classifique o trabalho. Uma issue de entrega tem um resultado fechável. Uma iniciativa tem múltiplos resultados independentemente entregáveis, owners, dependências ou decisões de release.
2. Antes de qualquer template `code-flow`, encontre o padrão atual do repositório: guidance, forms, schemas, documentos canônicos e artefatos aceitos recentes. Use um padrão local compatível como base; adicione só os campos que o gate atual precisa. Registre fonte, ausência ou adaptação na evidência.
3. ADRs/specs aceitos definem a intenção. Código e testes revelam comportamento atual e drift; não substituem a intenção aceita em silêncio.

Para uma iniciativa, explique os sinais e ofereça [`templates/01-epic.md`](templates/01-epic.md).
Crie um Epic só depois que o usuário o selecionar explicitamente. É só tracking:
sem stages de entrega, planos ou execução. Cada filha é uma issue de entrega/bug,
escrita com [`templates/02-user-story.md`](templates/02-user-story.md), e segue
este fluxo de forma independente. Subissues do GitHub ligam Epic às issues de
entrega; a implementação fica no plano aprovado de cada filha e numa passagem
única do executor — sem decomposição em task IDs.

## Fluxo de entrega

1. **Fases 0–1:** estabelecer contexto do repositório, escopo, padrões locais, riscos e decisões abertas do usuário.
2. **Fase 2:** preparar o source-set, decidir `create`, `update` ou `not required` para ADR/spec, e criar ou atualizar o **body** da issue de entrega com a proposta ou racional no-spec em `stage:spec-approval`, sem `needs-human`; o `issue-reviewer` atribui `stage:needs-issue-fix` em `PEÇO AJUSTES` ou adiciona `needs-human` quando o gate humano estiver pronto. Ainda não materializar o documento formal.
3. **Aprovação humana da fonte:** materializar o ADR/spec aprovado quando necessário, registrar o link imutável e ir para `stage:needs-plan`.
4. **Fase 3:** `plan-writer` publica o plano e encaminha para `stage:needs-plan-review` sem `needs-human`; `plan-reviewer` atribui `stage:needs-plan-fix` em `PEÇO AJUSTES` ou adiciona essa label quando o snapshot aguardar aprovação humana.
5. **Aprovação humana do plano:** ir para `stage:approved`. A execução ainda precisa de pedido explícito e escolha `worktree` ou `later`.
6. **Fases 4–6:** executar o plano aprovado como uma unidade (`in-progress` →
   `needs-delivery-review`); a review da implementação vai para
   `ready-to-merge` ou `needs-changes`; verificar DoD e evidência de
   fechamento, obter aprovação do PR e oferecer integração só quando pedida.

Um Epic/umbrella existente é inelegível para o fluxo de entrega.

## Carregar a fase ativa

| Fase                     | Carregar                                                     |
| ------------------------ | ------------------------------------------------------------ |
| 0 — CONTEXTO DA ISSUE    | [`phases/00-issue-context.md`](phases/00-issue-context.md)   |
| 1 — BRAINSTORM           | [`phases/01-brainstorm.md`](phases/01-brainstorm.md)         |
| 1.1 — COMPANHEIRO VISUAL | [`prompts/visual-companion.md`](prompts/visual-companion.md) |
| 2 — CRIAR ISSUE          | [`phases/02-create-issue.md`](phases/02-create-issue.md)     |
| 3 — PLANO E REVIEW       | [`phases/03-plan.md`](phases/03-plan.md)                     |
| 4 — DISPATCH             | [`phases/04-dispatch.md`](phases/04-dispatch.md)             |
| 5 — REVIEW DA ENTREGA    | [`phases/05-review.md`](phases/05-review.md)                 |
| 6 — VERIFICAR E INTEGRAR | [`phases/06-integrate.md`](phases/06-integrate.md)           |

Leia [`references/github-flow.md`](references/github-flow.md) antes de mudar
stages de issue ou retomar uma issue. Leia
[`templates/evidence-contract-template.md`](templates/evidence-contract-template.md) antes de
publicar evidência, revisar implementação ou fechar a entrega. Para resume e
mutação de labels, use
[`references/orchestrator-cheatsheet.md`](references/orchestrator-cheatsheet.md)
e `scripts/transition-issue.sh`.

## Papéis

Despache apenas estes papéis:

| Agente              | Responsabilidade                                                                                                      |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `issue-writer`      | Contexto, proposta no body da issue, criação/atualização da issue e materialização formal do ADR/spec após aprovação. |
| `issue-reviewer`    | Auditoria independente do source-set quando pedida ou em alto risco (Fase 2); nunca substitui o gate humano.          |
| `plan-writer`       | Um plano de implementação append-only.                                                                                |
| `plan-reviewer`     | Veredito literal independente de um snapshot de plano.                                                                |
| `executor`          | Um plano aprovado, implementado como uma unidade (pode organizar o trabalho internamente).                            |
| `delivery-reviewer` | Review independente da implementação e auditoria final fresca.                                                        |

Mantenha plan-writer e plan-reviewer separados. O delivery-reviewer é distinto
do executor e do plan-writer; o auditor final também é fresco.

A evidência é append-only. Registre todo resultado — incluindo sem mudança,
`BLOCKED`, erros e reviews rejeitadas — antes de mudar estado. Mudar estado
significa mutar labels GitHub `stage:*` / `needs-human` após o comentário
autorizador; texto de comentário sozinho não é atualização de status.
O orquestrador muta `stage:*` após os posts dos papéis, exceto o
`issue-reviewer` em `PEÇO AJUSTES` (`stage:needs-issue-fix`) e o
`plan-reviewer` em `PEÇO AJUSTES` (`stage:needs-plan-fix`); ambos também
ajustam `needs-human` conforme o próprio veredito. O `issue-writer` o remove
na materialização pós-aprovação (ver `references/github-flow.md`). Não criar trackers de task, logs de progresso ou registries de workflow separados.
