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
| `/code-flow`                                                   | Discovery read-only e próxima ação recomendada.              |
| `/code-flow start <issue>`                                     | Ativa a issue em `code-flow:active + stage:needs-triage`.    |
| `/code-flow role <papel> <issue>`                              | Executa um papel elegível isoladamente.                      |
| `/code-flow role <papel> <issue> --resume <run-id>`            | Retoma a mesma atividade comprovada.                         |
| `/code-flow gate <issue> triage <approve\|adjust\|block>`      | Aplica a decisão humana de triagem.                          |
| `/code-flow gate <issue> execution <authorize\|adjust\|block>` | Aplica a decisão humana de execução.                         |
| `/code-flow gate <issue> merge <integrate\|adjust\|wait>`      | Aplica a decisão humana de integração.                       |
| `/code-flow gate <issue> resume <stage>`                       | Restaura o estado comprovado no `Resume` de um blocker.      |
| `/code-flow gate <issue> activity reset`                       | Libera atividade abandonada, preservando o estado principal. |
| `/code-flow issue create`                                      | Cria e tria uma issue pelo mesmo protocolo.                  |
| `/code-flow stop <issue>`                                      | Solicita saída segura sem descartar trabalho.                |

### Secundárias

| Invocação                                          | Resultado e fase                                               |
| -------------------------------------------------- | -------------------------------------------------------------- |
| `/code-flow batch create --project <owner/number>` | Cria Draft Issues para triagem interativa — `context.md`.      |
| `/code-flow batch <alvos> --from <operação>`       | Processa trilhas isoladas a partir de um piso — `context.md`.  |
| `/code-flow brainstorm`                            | Resolve decisões materiais não descobríveis — `brainstorm.md`. |
| `/code-flow tool doctor [args]`                    | Executa apenas `scripts/doctor.sh`.                            |

Papéis válidos: `issue-writer`, `architect`, `executor`, `reviewer` e
`integrator`. Não interprete menção casual como invocação. Política:
[`agents/openai.yaml`](agents/openai.yaml).

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
   [`references/risk-profiles.md`](references/risk-profiles.md). Hard trigger
   sempre vence esforço pequeno.
6. Use worktree somente para implementação, correção ou integração. Com diff,
   o executor termina somente com commit, push e PR publicado.
7. Exija uma delivery review independente para qualquer complexidade. Nunca
   faça self-review; não existe auditoria adicional.
8. Faça merge somente após `stage:ready-to-merge + needs-human` e decisão
   `integrate`. `NO_CHANGES` aprovado não exige gate de fechamento.

Ao iniciar atividade, declare `run_id`, papel, estado principal, fontes, Base e
Head quando aplicáveis e resultado esperado. Ao retomar, valide o mesmo papel,
estado e `run_id`. Para sair, aplique a saída segura de `phases/context.md`.

## Router

| Operação                                    | Carregar                                                           |
| ------------------------------------------- | ------------------------------------------------------------------ |
| Contexto, start, batch, resume, gate e stop | [`phases/context.md`](phases/context.md)                           |
| Issue e triagem                             | [`phases/issue.md`](phases/issue.md)                               |
| Arquitetura/autorização                     | [`phases/plan.md`](phases/plan.md)                                 |
| Execução/correção                           | [`phases/dispatch.md`](phases/dispatch.md)                         |
| Review                                      | [`phases/review.md`](phases/review.md)                             |
| Integração/fechamento                       | [`phases/integrate.md`](phases/integrate.md)                       |
| Brainstorm                                  | [`references/brainstorm.md`](references/brainstorm.md)             |
| Visual opcional                             | [`references/visual-companion.md`](references/visual-companion.md) |

Antes de operar labels, leia
[`references/github-flow.md`](references/github-flow.md) e
[`references/evidence-contract.md`](references/evidence-contract.md). Para
modelos/capacidades, leia
[`references/runtime-capabilities.md`](references/runtime-capabilities.md).
Use [`references/workflow-cheatsheet.md`](references/workflow-cheatsheet.md)
para a verificação operacional curta e
[`references/workflow-states.json`](references/workflow-states.json) como fonte
canônica de estados, atores e transições.
Use `scripts/transition-issue.sh` para mutações determinísticas e
`scripts/source-set-digest.py` para o relatório canônico.
Use [`templates/01-issue-template.md`](templates/01-issue-template.md) somente quando o usuário
escolher explicitamente tracking por Epic.

## Papéis

| Papel                                       | Limite                                                           |
| ------------------------------------------- | ---------------------------------------------------------------- |
| [`issue-writer`](agents/01-issue-writer.md) | Investiga, escreve a issue e classifica risco; não decide spec.  |
| [`architect`](agents/02-architect.md)       | Decide spec/ADR e publica relatório; não implementa.             |
| [`executor`](agents/03-executor.md)         | Implementa, corrige, valida e publica PR/NO_CHANGES.             |
| [`reviewer`](agents/04-reviewer.md)         | Faz a única review independente; não corrige nem integra.        |
| [`integrator`](agents/05-integrator.md)     | Revalida, rebasa quando necessário, integra ou fecha NO_CHANGES. |

Esses são papéis, não modelos fixos. O modo interativo pode sequenciá-los, mas
nenhum papel depende da memória, confirmação ou autoria de um orquestrador.
