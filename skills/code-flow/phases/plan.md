# Plano e review

Plano formal existe somente quando o risco recalculado o exige.

Antes de planejar, compare o SHA-256 atual do body com o digest registrado no
gate de source-set. Divergência invalida a aprovação e volta ao primeiro gate
de fonte aplicável. O plano referencia digest e URL da decisão.

- Mudança interna: não despache plan-writer. O executor registra
  `templates/15-implementation-outline-template.md` após a ordem de execução.
- Mudança moderada: despache `agents/03-plan-writer.md`, depois um
  `agents/04-plan-reviewer.md` independente e o gate humano de
  `templates/13-human-gate-plan.md`.
- Hard trigger: use a mesma separação, nunca acumulando autoria, review ou
  execução na mesma instância.

O plano usa `templates/05-plan-template.md`, links imutáveis, base SHA,
critérios de aceite, TDD/verificação, riscos e rollback. Não decomponha em task
IDs. Em `PEÇO AJUSTES`, publique novo ciclo; terceiro ciclo não resolvido exige
decisão humana.

`PEÇO AJUSTES` ou `NÃO APROVO` corrigível move a `stage:needs-plan-fix` sem
`needs-human`. Rejeição por decisão externa ou risco não resolvido move a
`stage:blocked + needs-human`.

Após veredito aprovador, mantenha `stage:needs-plan-review` e aplique
`needs-human`. Veredito não autoriza execução. Somente `Yes` no gate humano
move o fallback para `stage:approved + needs-human`; ajustes removem
`needs-human` antes de devolver ao agente.
