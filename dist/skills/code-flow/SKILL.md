---
name: code-flow
description: "Coordinate explicitly requested GitHub issue deliveries with repository-guidance discovery, risk-adaptive architecture, independently runnable roles, human gates, cooperative activity labels, independent delivery review, and explicit integration. Use only when the user invokes $code-flow or /code-flow."
---

# code-flow

Coordene somente entregas iniciadas explicitamente. Use labels e evidências no
GitHub como protocolo compartilhado; não instale configuração, agentes, estado
ou instruções no repositório-alvo. Cada papel deve conseguir retomar a issue sem
memória do orquestrador e sempre redescobrir o guidance nearest-wins do projeto.

## Entradas públicas

### Centrais

| Invocação                                                      | Resultado                                                    |
| -------------------------------------------------------------- | ------------------------------------------------------------ |
| `/code-flow`                                                   | Discovery read-only e próxima ação recomendada.                                        |
| `/code-flow role <papel> <issue>`                              | Executa um papel elegível isoladamente; retoma atividade comprovada quando há overlay. |
| `/code-flow gate <issue> <decisão-humana>`                    | Aplica decisão humana ao estado atual.                                                 |
| `/code-flow stop <issue>`                                     | Solicita saída segura sem descartar trabalho.                                          |

### Secundárias

| Invocação                                          | Resultado e fase                                              |
| -------------------------------------------------- | ------------------------------------------------------------- |
| `/code-flow batch create --project <owner/number>` | Cria Draft Issues para triagem interativa — `context.md`.     |
| `/code-flow batch <alvos> --from <operação>`       | Processa trilhas isoladas a partir de um piso — `context.md`. |
| `/code-flow tool doctor [args]`                    | Executa apenas `scripts/doctor.sh`.                           |

## Contrato global

1. Leia primeiro [`phases/context.md`](phases/context.md), descubra instruções,
   forms, ADR/spec, código, testes e workflow Git e registre `project_guidance`.
2. Exija `code-flow:active` e exatamente um estado principal listado em
   [`references/workflow-states.json`](references/workflow-states.json).
3. Trate `stage:in-progress` somente como overlay cooperativo. Ele não é lock
   atômico e nunca substitui o estado principal.
4. Publique evidência antes de mutar labels. Cada papel inicia, conclui e
   confirma sua própria transição; decisões humanas usam o comando `gate`.
5. Proponha `Complexity: XS | S | M | L | XL`, recalcule risco e aplique
   [`references/runtime.md`](references/runtime.md). Hard trigger
   sempre vence esforço pequeno.
6. Sempre use worktree para implementação, correção ou integração. Com diff,
   o executor termina somente com commit, push e PR publicado.
7. Exija uma delivery review independente para qualquer complexidade. Nunca
   faça self-review; não existe auditoria adicional.
8. Faça merge somente após `stage:ready-to-merge + needs-human` e decisão
   `integrate`. `NO_CHANGES` aprovado não exige gate de fechamento.

Ao iniciar atividade, declare `run_id`, papel, estado principal, fontes, Base e
Head quando aplicáveis e resultado esperado. Ao encontrar overlay existente,
retome a atividade comprovada pela última evidência publicada, validando o
mesmo papel, estado e `run_id` antes de continuar; não inicie nova atividade
sobre overlay alheio. Para sair, aplique a saída segura de `phases/context.md`.

## Router

| Operação                                    | Carregar                                     |
| ------------------------------------------- | -------------------------------------------- |
| Contexto, start, batch, resume, gate e stop | [`phases/context.md`](phases/context.md)     |
| Issue e triagem                             | [`phases/issue.md`](phases/issue.md)         |
| Arquitetura/autorização                     | [`phases/architecture.md`](phases/architecture.md) |
| Execução/correção                           | [`phases/dispatch.md`](phases/dispatch.md)   |
| Review                                      | [`phases/review.md`](phases/review.md)       |
| Integração/fechamento                       | [`phases/integrate.md`](phases/integrate.md) |

Antes de operar labels, leia
[`references/runtime.md`](references/runtime.md) e
[`references/evidence-contract.md`](references/evidence-contract.md). Use
[`references/workflow-states.json`](references/workflow-states.json) como fonte
canônica de estados, atores e transições.
Use `scripts/transition-issue.sh` para mutações determinísticas e
`scripts/source-set-digest.py` para o relatório canônico.
Use [`templates/01-issue-template.md`](templates/01-issue-template.md) para issues e epics,
[`templates/02-review-template.md`](templates/02-review-template.md) para arquitetura e delivery review,
[`templates/03-implementation-evidence-template.md`](templates/03-implementation-evidence-template.md) para evidência de execução,
[`templates/04-integration-report-template.md`](templates/04-integration-report-template.md) para integração e
[`templates/06-note-template.md`](templates/06-note-template.md) para notas operacionais.
A seção `## Entregas coordenadas` diferencia Epics de issues simples.

Papéis, responsáveis por label e regras de independência estão em
[`references/runtime.md`](references/runtime.md). Os agentes especializados são
[`issue-writer`](agents/01-issue-writer.md),
[`architect`](agents/02-architect.md),
[`executor`](agents/03-executor.md),
[`reviewer`](agents/04-reviewer.md) e
[`integrator`](agents/05-integrator.md); a política de invocação está em
[`agents/openai.yaml`](agents/openai.yaml).
