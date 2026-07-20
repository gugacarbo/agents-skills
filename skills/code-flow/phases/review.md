# Review da entrega

Em `stage:needs-delivery-review`, o orquestrador prepara pacote interno do
range/PR e despacha `agents/06-delivery-reviewer.md`, independente do executor.

Use `templates/08-implementation-review-template.md`:

- diff aprovado sem auditoria: `stage:ready-to-merge + needs-human`;
- diff aprovado com auditoria: `stage:ready-to-merge` sem `needs-human`;
- `NO_CHANGES` comprovado: `stage:ready-to-close + needs-human`;
- `AJUSTAR`, `Critical`, `Important` ou `Cannot verify`:
  `stage:needs-changes`, sem `needs-human`;
- decisão de produto/acesso: blocker com resume target de review/dispatch.

`APROVAR COM RESSALVAS` só avança com achados Minor não bloqueantes.
Ao aprovar `NO_CHANGES`, anuncie o próximo gate completo:
`Fechar / Ajustar / Aguardar`; fechar e limpar estado só depois de `Fechar`
explícito.

## Auditoria final

- S: delivery review encerra a revisão.
- M/G: auditoria fresca somente após ressalva, mudança posterior à review ou
  risco novo.
- X/XL ou hard trigger: sempre outra instância fresca, distinta de todos os
  reviewers anteriores aplicáveis.

Auditoria aprovadora mantém `stage:ready-to-merge` e adiciona `needs-human`.
Correção volta ao mesmo executor/worktree e exige nova review. Risco promovido
volta ao primeiro gate obrigatório, não apenas ao código.
