# Dispatch e execução

Antes da ordem, recalcule risco, valide Workflow/estado, source-set digest,
snapshot do plano/outline e base SHA.

Registre a ordem explícita que autorizou o dispatch antes de criar a worktree;
um pedido que já contenha ordem inequívoca pode ser essa evidência, mas nunca
deixe a autorização implícita.

Se alguém tentar saltar do comentário do plan-reviewer para execução, recuse e
reconstrua a cadeia inteira: plan-writer →
`stage:needs-plan-review` sem `needs-human`; plan-reviewer aprovador → mesmo
stage com `needs-human`; humano decide e orquestrador aplica a transição;
ordem de execução separada → evidência inicial do executor → validação do
orquestrador → `stage:in-progress`.

## Início

1. Humano dá ordem explícita separada do gate de plano.
2. Orquestrador cria/atribui worktree isolada automaticamente; não ofereça
   execução na árvore atual.
3. Em S, executor publica `templates/15-implementation-outline-template.md`;
   nos demais caminhos referencia o plano aprovado.
4. Executor publica evidência de início, move a `stage:in-progress`, limpa
   `needs-human`; orquestrador confirma; só então código começa.

## Durante a execução

- Siga o workflow Git local; crie commits e draft PR quando o repo usar PR.
- Drift de base não material atualiza base e repete validação. Conflito ou
  mudança material volta ao primeiro gate afetado.
- Decisão material/risco novo interrompe código e promove o fluxo.
- Falha corrigível permanece in-progress; `BLOCKED` só para decisão, acesso,
  dependência externa ou risco não resolvido, sempre com resume target.

O executor publica `templates/07-implementation-evidence-template.md` com:

- `DONE`: diff validado;
- `DONE_WITH_CONCERNS`: somente ressalvas não bloqueantes;
- `NO_CHANGES`: prova objetiva de escopo já satisfeito, sem commit/PR vazio;
- `BLOCKED`: não pronto para review.

Os três primeiros movem a `stage:needs-delivery-review`. Correções em
`stage:needs-changes` voltam ao mesmo executor/worktree e depois à review.
