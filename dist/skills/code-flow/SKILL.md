---
name: code-flow
description: "Coordinate explicitly requested, non-trivial GitHub issue deliveries or batches with repository-guidance discovery, adaptive rigor, isolated agent roles, optional host-provided model routing, independent review, human gates, and explicit merge, close, handoff, or stop. Use only when the user invokes $code-flow or /code-flow."
---

# code-flow

Coordene somente entregas explicitamente iniciadas pelo usuário. Descubra o
contrato do repositório, derive o workflow do estado observado e use apenas os
papéis e gates exigidos pelo risco. Não instale configuração, agentes, estado ou
instruções da skill no repositório-alvo.

## Entradas

| Invocação                                                                  | Resultado                                                     |
| -------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `/code-flow`                                                               | Discovery read-only e próxima entrada recomendada.            |
| `/code-flow issue create`                                                  | Fecha decisões obrigatórias e cria/preenche a issue elegível. |
| `/code-flow <context\|issue\|plan\|dispatch\|review\|integrate> <#N\|URL>` | Retoma a operação nomeada sem pular gates anteriores.         |
| `/code-flow issue <#N\|URL> [operação]`                                    | Recalcula risco e retoma a operação elegível.                 |
| `/code-flow batch create --project <owner/number>`                         | Cria Draft Issues para investigação posterior.                |
| `/code-flow batch <alvos> --from <operação>`                               | Executa trilhas isoladas a partir de um piso.                 |
| `/code-flow brainstorm`                                                    | Resolve somente decisões materiais não descobríveis.          |
| `/code-flow stop <#N\|URL>`                                                | Solicita saída segura sem fechar issue ou descartar trabalho. |
| `/code-flow tool doctor [args]`                                            | Executa apenas [`scripts/doctor.sh`](scripts/doctor.sh).      |

Não interprete menção casual à skill como invocação. Uma operação nomeada é
ponto de entrada solicitado, não permissão para ignorar precondições.
Política de invocação: [`agents/openai.yaml`](agents/openai.yaml).

## Contrato global

1. Leia primeiro [`phases/context.md`](phases/context.md). Descubra instruções
   aplicáveis, inclusive arquivos nearest-wins, forms, ADR/spec, código, testes e
   workflow Git. Registre `project_guidance` nos artefatos; não pergunte fatos
   descobríveis.
2. Permita discovery, intenção e brainstorm antes da issue. Exija issue de
   entrega/bug antes de arquitetura, código, review ou integração.
3. Proponha `Complexity: S | M | G | X | XL`, recalcule risco e aplique
   [`references/risk-profiles.md`](references/risk-profiles.md). Hard trigger
   sempre vence esforço pequeno.
4. Resolva native/fallback por
   [`references/github-flow.md`](references/github-flow.md). Não persista
   `Workflow`; `Complexity` é a única metadata de controle da code-flow no body.
5. Antes de despachar, leia
   [`references/runtime-capabilities.md`](references/runtime-capabilities.md).
   Papéis são obrigatórios; modelos diferentes são opcionais e nunca justificam
   configuração no repositório-alvo.
6. Publique evidência antes da mutação causada pelo resultado. O autor do evento
   aplica sua transição; o orquestrador valida e aplica decisões humanas.
7. Use worktree somente para implementação/correção. Com diff, conclusão exige
   commit, push e PR publicado. Sem diff, preserve `NO_CHANGES`, review
   independente e gate explícito de fechamento.
8. Nunca faça self-review, merge ou fechamento automático. Escopo/risco material
   novo invalida somente gates insuficientes e retorna ao primeiro gate exigido.

Ao retomar, declarar evento, ator, estado anterior/posterior, `needs-human` e
evidência. Para interromper voluntariamente, aplicar a saída segura de
[`phases/context.md`](phases/context.md); nunca simplesmente abandonar estado.

## Router

| Operação                       | Carregar                                                     |
| ------------------------------ | ------------------------------------------------------------ |
| Contexto, batch, resume e stop | [`phases/context.md`](phases/context.md)                     |
| Issue e triagem                | [`phases/issue.md`](phases/issue.md)                         |
| Arquitetura/autorização        | [`phases/plan.md`](phases/plan.md)                           |
| Dispatch                       | [`phases/dispatch.md`](phases/dispatch.md)                   |
| Review                         | [`phases/review.md`](phases/review.md)                       |
| Integração/fechamento          | [`phases/integrate.md`](phases/integrate.md)                 |
| Brainstorm                     | [`prompts/brainstorm.md`](prompts/brainstorm.md)             |
| Visual opcional                | [`prompts/visual-companion.md`](prompts/visual-companion.md) |

Antes de evidência/review, leia
[`references/evidence-contract.md`](references/evidence-contract.md). Antes de
fallback, leia
[`references/orchestrator-cheatsheet.md`](references/orchestrator-cheatsheet.md)
e valide [`references/workflow-states.json`](references/workflow-states.json) e
[`references/label-mutation-matrix.md`](references/label-mutation-matrix.md).
Use [`references/follow-up-issue-drafts.md`](references/follow-up-issue-drafts.md)
somente para Minors não bloqueantes. Para decisões humanas, use
[`templates/08-human-gate-spec.md`](templates/08-human-gate-spec.md); para Epic,
use [`templates/01-epic.md`](templates/01-epic.md) somente após escolha explícita.

Helpers internos: [`scripts/review-package.sh`](scripts/review-package.sh),
[`scripts/source-set-digest.py`](scripts/source-set-digest.py) e
[`scripts/transition-issue.sh`](scripts/transition-issue.sh). Não os exponha
como comandos públicos.

## Papéis

| Papel                                       | Limite                                                     |
| ------------------------------------------- | ---------------------------------------------------------- |
| [`issue-writer`](agents/01-issue-writer.md) | Escreve issue M+ e Complexity; não decide spec.            |
| [`architect`](agents/02-architect.md)       | Decide spec/ADR e publica relatório M+; não implementa.    |
| [`executor`](agents/03-executor.md)         | Outline S, código, spec no PR e correções.                 |
| [`reviewer`](agents/04-reviewer.md)         | Revisa PR/NO_CHANGES e audita quando exigido; não corrige. |

Esses são papéis, não modelos fixos. Preserve autoria e independência conforme
[`references/risk-profiles.md`](references/risk-profiles.md). Epic é somente
tracking; cada filha percorre o fluxo próprio e relações usam mecanismos nativos
do repositório, não metadata de controle no body.
