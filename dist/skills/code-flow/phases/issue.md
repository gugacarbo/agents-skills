# Issue e triagem

O `issue-writer` consome `stage:needs-triage`. Antes de investigar, publique
evidência de início com `run_id` e adicione `stage:in-progress`, preservando
`stage:needs-triage`.

Use `templates/02-issue-template.md`. Descubra guidance e codebase, preencha
contexto, objetivo e DoD e persista `Complexity: S | M | G | X | XL`. Não grave
`Workflow`. Relações com Epic, Parent e sub-issues usam mecanismos nativos.

Issue-writer não decide `create | update | not required` de spec/ADR e não cria
arquitetura, código ou review. Publique a evidência da triagem antes de remover
`stage:needs-triage + stage:in-progress` e deixar
`stage:awaiting-triage-approval + needs-human`.

O gate de triagem aplica:

- `approve`: S sem hard trigger → `stage:ready-for-execution`; M+, hard trigger
  ou rigor promovido → `stage:needs-architect`;
- `adjust`: `stage:needs-triage`;
- `block`: `stage:blocked + needs-human` com `Resume`.

Para Draft Issue já investigada, a conversão deixa diretamente
`stage:awaiting-triage-approval + needs-human`; nunca execute a triagem duas
vezes. Mudança posterior do body que altere objetivo, Complexity ou hard trigger
invalida gates insuficientes e retorna a `stage:needs-triage`.
