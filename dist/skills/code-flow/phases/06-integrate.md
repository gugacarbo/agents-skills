# Fase 6: Verificar, aprovar PR e oferecer integração

A partir de `stage:ready-to-merge`, despache um
`agents/06-delivery-reviewer.md` fresco para a auditoria final. Esta instância
não deve ter feito a review da Fase 5 e é distinta do plan-writer e do executor.
Ela audita ADR/spec aceito (ou plano aprovado), envelope/review do executor,
range final, DoD e evidência de fechamento.

Rode as suites necessárias, verifique cada item do DoD, resolva achados
Critical/Important ou cannot-verify, e publique
`templates/09-integration-report-template.md` no modo issue ou a seção
equivalente de oito campos no registro do modo `direct`. A evidência de
fechamento mapeia o plano aprovado a commit/PR, evidência do executor, review
da entrega e status do DoD.

Se a auditoria final pedir ajustes corrigíveis (`PEÇO AJUSTES` ou
Critical/Important), o orquestrador muta para `stage:needs-changes` e devolve
à Fase 4. Se exigir decisão de produto/acesso, muta para `stage:blocked` +
`needs-human`.

No modo issue, obtenha a aprovação necessária do PR mas nunca faça merge
automaticamente. Após aprovação do PR, mantenha
`stage:ready-to-merge`, adicione `needs-human` e ofereça
integração/merge como decisão opcional explícita do usuário. Só depois que o
usuário pedir integração o PR aprovado pode ser merged, o alvo verificado e a
issue fechada com labels de stage e `needs-human` removidas.

Modo `direct` não cria issue, labels, stages ou comentários GitHub. Pode
concluir após a auditoria final e o DoD registrados; se tiver PR, ofereça merge
só após aprovação do PR e confirmação explícita do usuário.
