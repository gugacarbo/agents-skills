# Fase 5: Review da entrega

A partir de `stage:needs-delivery-review`, para cada evidência `DONE` ou
`DONE_WITH_CONCERNS` do plano aprovado, despache um
`agents/06-delivery-reviewer.md` fresco, distinto do executor e do plan-writer.
Dê a ele o range, source-set, plano, envelope do executor e o pacote de review
de `scripts/review-package.sh` (`/code-flow tool review-package` quando útil).
`BLOCKED` nunca está pronto para review.

O reviewer publica `templates/08-implementation-review-template.md`. Usa
`APROVO`, `APROVO COM RESSALVAS`, `PEÇO AJUSTES` ou `NÃO APROVO` e checa escopo,
contrato, validação, caminhos de erro e ownership.

O orquestrador muta labels após o comentário de review:

| Resultado                                   | Ação                                                                                                  |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `APROVO` / `APROVO COM RESSALVAS`           | Mutar para `stage:ready-to-merge` e seguir para a Fase 6.                                             |
| `PEÇO AJUSTES` ou achado Critical/Important | Mutar para `stage:needs-changes` e devolver a implementação à Fase 4.                                 |
| `NÃO APROVO` com decisão de produto/acesso  | Mutar para `stage:blocked` + `needs-human`.                                                           |
| Achado Minor                                | Reter na review e na evidência de fechamento; não muda o stage por si só se o veredito for aprovador. |

Review limpa mapeia o plano aprovado a commit/PR e evidência.
