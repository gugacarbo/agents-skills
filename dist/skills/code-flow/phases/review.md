# Review da entrega

Em `stage:needs-delivery-review`, despache `agents/06-delivery-reviewer.md`
independente do executor e de qualquer artefato que ele revise. Forneça range,
fontes, plano ou outline, evidência e pacote de `scripts/review-package.sh`.

Use `templates/08-implementation-review-template.md`:

- `APROVO`/`APROVO COM RESSALVAS`: mover a `stage:ready-to-merge`;
- `PEÇO AJUSTES` ou achado Critical/Important: `stage:needs-changes`;
- decisão de produto/acesso: `stage:blocked + needs-human`.

Auditoria final:

- mudança interna: não é uma segunda review; a delivery review cobre o fechamento;
- mudança moderada: somente após ressalva, mudança posterior à review ou risco novo;
- hard trigger: sempre, por outra instância fresca de `delivery-reviewer`.

Se uma ressalva promover risco, retome no primeiro gate obrigatório, não apenas
na correção de código.
