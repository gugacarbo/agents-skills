# Review da entrega

Em needs-delivery-review, despache reviewer independente com range/PR
ou prova NO_CHANGES e as evidências de issue review e executor.
Use `templates/08-implementation-review-template.md` e publique sempre a
consolidação append-only de `templates/11-follow-up-issues-report.md` antes da
transição. Fonte exigida ausente é Cannot verify; a consolidação não muda
labels, gates, merge ou fechamento. A review só está completa quando cada
Minor original expõe seu Issue draft (ou `n/a — repositório GitHub não
verificável`) e o grupo final preserva as origens.

Para NO_CHANGES, o reviewer mantém esse nome — nunca `DONE` — e rejeita pedido
de pular review, consolidação ou `Fechar / Ajustar / Aguardar`.

Diff aprovado sem auditoria vai a `stage:ready-to-merge + needs-human`; com
auditoria, `stage:ready-to-merge` sem needs-human até auditor fresco aprovar.
NO_CHANGES aprovado vai a `stage:ready-to-close + needs-human`. Ajustar,
Critical, Important ou Cannot verify vai a `stage:needs-changes`. Blocker usa
Resume.

S encerra na delivery review; M/G audita após ressalva, mudança pós-review ou
risco novo; X/XL/hard trigger sempre exige auditor fresco. A auditoria nunca
faz merge nem fecha issue.
