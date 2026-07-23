# Arquitetura e autorização de execução

O `architect` consome `stage:needs-architect`. Publique início com `run_id` e
adicione `stage:in-progress`, preservando o estado principal. Leia guidance,
issue, código/testes, decisões e Base SHA.

Publique `templates/03-architect-review-template.md`: objetivo, limites,
gaps/blockers, casos de borda e `Spec impact: create | update | not required`.
`create/update` inclui o conteúdo a materializar no PR do executor.

O relatório vive em um único comentário canônico entre
`code-flow:architect-review:start/end`. Correções editam esse comentário in-place
e publicam uma nota append-only `architect-change`. Ausência ou duplicidade do
marcador bloqueia. O gate registra URL e digest do bloco canônico.

Depois da evidência final, remova `stage:needs-architect + stage:in-progress`:

- M, `not required` e sem hard trigger → `stage:ready-for-execution`;
- Complexity >= G, hard trigger ou spec `create/update` →
  `stage:awaiting-execution-approval + needs-human`.

O gate execution aplica:

- `authorize`: `stage:ready-for-execution`;
- `adjust`: `stage:needs-architect`;
- `block`: `stage:blocked + needs-human`.

Architect nunca autoriza a própria execução, implementa ou revisa. Drift
material invalida a autorização e retorna ao primeiro gate que não cobre o
novo escopo.
