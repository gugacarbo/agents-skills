# Review da entrega

Em needs-delivery-review, despache delivery-reviewer independente com range/PR
ou prova NO_CHANGES. Use `templates/08-implementation-review-template.md`.

Diff aprovado sem auditoria vai a `stage:ready-to-merge + needs-human`; com
auditoria, `stage:ready-to-merge` sem needs-human até auditor fresco aprovar.
NO_CHANGES aprovado vai a `stage:ready-to-close + needs-human`. Ajustar,
Critical, Important ou Cannot verify vai a `stage:needs-changes`. Blocker usa
Resume.

S encerra na delivery review; M/G audita após ressalva, mudança pós-review ou
risco novo; X/XL/hard trigger sempre exige auditor fresco. A auditoria nunca
faz merge nem fecha issue.
