# Contexto e retomada

Use antes de criar, retomar ou operar uma issue.

1. Confirme que o alvo é uma entrega/bug; tracker ou Epic é inelegível.
2. Leia guidance, issue form, ADR/spec, código/testes, labels, comentários e PRs.
3. Recalcule risco com `references/risk-profiles.md` antes de interpretar stage.
4. Resolva workflow com `references/github-flow.md` sem mutar durante discovery.
5. Em retomada nativa, mostre o mapeamento revalidado e peça novo opt-in. Sem
   reconfirmação, encerre a atuação da skill sem qualquer mutação.
6. Em fallback, valide que há exatamente um `stage:*` ou trate drift após
   excluir a possibilidade de workflow nativo.

Mudança material de escopo promove o rigor e invalida gates que não cobrem o
novo escopo. `stage:approved` nunca evita reclassificação.

Para batch, mantenha visão efêmera por issue e isole worktrees. Não escreva
registry ou arquivo de progresso.
