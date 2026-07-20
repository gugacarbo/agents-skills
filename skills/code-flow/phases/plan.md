# Plano e review

Plano formal existe somente quando o rigor recalculado o exige. Antes de
planejar, confirme o digest atual do bloco source-set contra a decisão humana.
Divergência volta ao primeiro gate de fonte aplicável.

- S sem hard trigger: não despache plan-writer; executor publica outline após
  autorização de execução.
- M/G: plan-writer → plan-reviewer independente → gate humano.
- X/XL ou hard trigger: mesmos passos, com instâncias separadas por fase.

O plano usa [`templates/05-plan-template.md`](../templates/05-plan-template.md),
snapshot/digest, base SHA,
critérios de aceite, verificação adaptativa, riscos e rollback. Código
comportamental usa RED/GREEN; docs/config/operação usa prova antes/depois ou
checagem binária equivalente. Migração define e prova rollback.

## Transições

1. `plan-writer` publica um snapshot e move de `stage:needs-plan` ou
   `stage:needs-plan-fix` para `stage:needs-plan-review`, sem `needs-human`.
2. `plan-reviewer` aprovador mantém o stage e adiciona `needs-human`.
3. `AJUSTAR`, `Critical`, `Important` ou `Cannot verify` move a
   `stage:needs-plan-fix`, sem `needs-human`.
4. Gate humano `Aprovar`: orquestrador move a
   `stage:approved + needs-human`; `Ajustar`: needs-plan-fix; `Bloquear`:
   blocker com resume target de plan.

Terceiro ciclo ainda rejeitado abre checkpoint humano para reescopar,
autorizar outro ciclo ou bloquear. Plano aprovado nunca autoriza execução por
si só.

Em retomada no meio da cadeia, reconstrua-a explicitamente: o plan-writer move
o plano publicado a `stage:needs-plan-review` sem `needs-human`; o
plan-reviewer aprovador adiciona `needs-human`, mas não substitui o humano; o
orquestrador aplica a decisão humana; somente outra ordem explícita permite ao
executor publicar evidência de início e, após validação do orquestrador,
entrar em `stage:in-progress`.

Publique review com
[`templates/06-review-template.md`](../templates/06-review-template.md) e o
gate humano com
[`templates/13-human-gate-plan.md`](../templates/13-human-gate-plan.md).
