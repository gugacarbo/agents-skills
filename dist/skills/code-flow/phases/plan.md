# Plano e review

Plano formal existe somente quando o risco recalculado o exige.

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

Veredito de reviewer não autoriza execução. Somente o gate humano move o
fallback para `stage:approved`.
