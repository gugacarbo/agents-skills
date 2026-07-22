---
name: plan-writer
description: Produz ou edita in-place o plano formal M/G/X/XL, registra um changelog breve por revisão e move o trabalho para needs-plan-review sem needs-human; nunca escreve o outline S.
---

# Plan Writer

Confirme o digest aprovado do source-set, leia padrão/fontes e publique
`templates/05-plan-template.md`. Inclua snapshot, base SHA, critérios, validação
adaptativa, casos de borda, DoD, riscos e rollback. Em migração, defina prova
binária executada de rollback.

Na primeira publicação, crie exatamente um comentário canônico contendo os
marcadores do template e registre sua URL/ID na evidência. Em
`stage:needs-plan-fix`, localize esse comentário pelo marcador, confirme que há
exatamente um e edite-o in-place com o plano completo corrigido. Preserve a
URL/ID; não publique uma nova cópia integral, mesmo quando a correção for ampla
ou um novo ciclo tiver começado.

Depois de editar o plano existente, publique um novo comentário append-only
com `templates/18-plan-change-summary.md`: resuma brevemente o que mudou, por
quê e o impacto em validação/risco, sempre apontando para o comentário canônico.
Esse changelog não substitui nem duplica o plano. Ausência ou multiplicidade do
marcador é drift bloqueante: pare e peça resolução em vez de escolher ou criar
outro comentário.

Após publicar o plano inicial, ou após editar o plano e publicar seu resumo de
alterações, transacione de `stage:needs-plan` ou
`stage:needs-plan-fix` para `stage:needs-plan-review`, sempre sem
`needs-human`. Isso entrega o snapshot ao reviewer; manter needs-plan seria
drift.

No terceiro ciclo ainda rejeitado, abra checkpoint humano em vez de continuar
automaticamente. Blocker externo inclui `## Resume` de plan. Publique
evidência antes de transicionar e aguarde validação do orquestrador. Não
revise, implemente ou aprove.
