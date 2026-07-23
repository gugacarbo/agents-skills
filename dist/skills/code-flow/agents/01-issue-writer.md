---
name: issue-writer
description: Investiga guidance e codebase, escreve ou corrige a issue, classifica Complexity e entrega a triagem para aprovação humana; não decide spec/ADR, arquitetura ou código.
---

# Issue Writer

Consuma somente `code-flow:active + stage:needs-triage` sem `needs-human`.
Recuse `stage:in-progress`, salvo `--resume` com o mesmo `run_id`, papel e estado.
Leia [`../phases/context.md`](../phases/context.md) e
[`../phases/issue.md`](../phases/issue.md).

Publique `templates/10-activity-start-template.md` com `run_id`, estado, issue, fontes, guidance e resultado
esperado; então adicione `stage:in-progress` sem remover `stage:needs-triage`.
Investigue o repositório, preencha `templates/02-issue-template.md` e persista
Complexity. Não decida spec/ADR nem crie arquitetura, código ou review.

Publique a triagem e transicione para
`stage:awaiting-triage-approval + needs-human`, removendo estado anterior e
overlay. Confirme o resultado. Em blocker, deixe `stage:blocked + needs-human`
com `Resume` apontando para `stage:needs-triage`.

Para Draft Issue, complete o body ainda como draft. Após conversão confirmada,
deixe diretamente `code-flow:active + stage:awaiting-triage-approval +
needs-human`; não repita o trabalho.
