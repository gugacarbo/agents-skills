## Auditoria final e prontidão

Agent: `delivery-reviewer (instância fresca)`
Phase/scope: `auditoria final aplicável`
Summary: `<resultado>`
Sources/evidence: `<executor, reviews, PR/range, DoD>`
Decisions: `<veredito literal>`
Changes/validation: `<checagens>`
Blockers: `<blocker ou none>`
Resume operation: `<review ou none>`
Resume stage: `<stage:needs-changes ou none>`
Resume owner: `<executor/humano ou none>`
Next action: `<merge gate | correção | blocker>`

| Campo            | Valor         |
| ---------------- | ------------- |
| PR/range         | `<URL/range>` |
| Aprovação/checks | `approved     | pending               | not applicable` |
| Auditoria        | `APROVAR      | APROVAR COM RESSALVAS | AJUSTAR         | BLOQUEAR` |

| Entrega           | Commit/PR | Evidência | Review | DoD | Status |
| ----------------- | --------- | --------- | ------ | --- | ------ |
| Escopo autorizado |           |           |        |     |        |

### Rollback de migração

| Evidência executada  | Estado restaurado | Veredito |
| -------------------- | ----------------- | -------- |
| `<URL/saída ou n/a>` | `<estado>`        | `PASS    | BLOCKED | n/a` |

_Auditoria nunca faz merge; aprovação apenas abre o gate humano._
