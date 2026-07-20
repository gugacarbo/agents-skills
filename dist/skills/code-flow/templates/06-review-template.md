## Revisão independente do plano

Agent: `plan-reviewer`
Phase/scope: `plan / ciclo <k>/3`
Summary: `<resultado>`
Sources/evidence: `<snapshot, digest, fontes e base SHA>`
Decisions: `<veredito literal>`
Changes/validation: `<checagens ou none>`
Blockers: `<blocker ou none>`
Resume operation: `<plan ou none>`
Resume stage: `<stage:needs-plan-fix ou none>`
Resume owner: `<plan-writer ou none>`
Next action: `<gate humano | novo ciclo | blocker, owner>`

**Independência:** não escrevi este plano nem implementarei seu escopo.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

| Severidade                                        | Seção/fonte    | Impacto e ação |
| ------------------------------------------------- | -------------- | -------------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<referência>` | `<ação>`       |

_Veredito aprovador abre gate humano; nunca autoriza execução._
