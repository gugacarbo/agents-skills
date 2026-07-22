# Review da entrega

Em needs-delivery-review, despache reviewer independente com a **PR publicada**
(não a branch local) ou prova NO_CHANGES e as evidências de issue e executor.
Use `templates/05-delivery-review-template.md` e inclua sempre sua consolidação
de follow-ups no mesmo comentário antes da transição. Fonte exigida ausente é
Cannot verify; a consolidação não muda
labels, gates, merge ou fechamento. A review só está completa quando cada
Minor original expõe seu Issue draft (ou `n/a — repositório GitHub não
verificável`) e o grupo final preserva as origens.

O reviewer confere que todos os DoD da issue e os casos de borda definidos no
relatório de arquitetura foram cumpridos. Quando houver spec/ADR materializada
no PR, verifica que o conteúdo commitado corresponde ao aprovado no relatório
canônico e que a spec cobre a decisão de `create`/`update` declarada.

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
