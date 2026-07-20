## Revisão independente da entrega

Agent: `delivery-reviewer`
Phase/scope: `<plano/outline / range ou prova NO_CHANGES>`
Summary: `<resultado>`
Sources/evidence: `<executor, range/PR/prova, fontes>`
Decisions: `<veredito literal>`
Changes/validation: `<checagens>`
Blockers: `<blocker ou none>`
Resume operation: `<review/dispatch ou none>`
Resume stage: `<stage:needs-changes ou none>`
Resume owner: `<executor/humano ou none>`
Next action: `<merge gate | close gate | auditoria | correção>`

| Campo         | Valor                                                       |
| ------------- | ----------------------------------------------------------- |
| Plano/outline | `<URL>`                                                     |
| Evidência     | `<URL>`                                                     |
| Range/PR      | `<base..head, URL ou not applicable>`                       |
| Independência | `Não produzi o artefato revisado nem implementei o escopo.` |
| Veredito      | `APROVAR \| APROVAR COM RESSALVAS \| AJUSTAR \| BLOQUEAR`   |

| Severidade                                        | Local/prova                | Impacto e ação |
| ------------------------------------------------- | -------------------------- | -------------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<file:line ou evidência>` | `<ação>`       |

- [ ] Contrato/fontes.
- [ ] Testes/DoD ou prova NO_CHANGES.
- [ ] Escopo/ownership.
- [ ] Rollback de migração executado ou not applicable.

_NO_CHANGES aprovado segue para ready-to-close; diff aprovado segue para
ready-to-merge._
