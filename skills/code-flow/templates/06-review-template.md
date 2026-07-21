---
agent: plan-reviewer
phase_scope: plan / ciclo <k>/3
sources_evidence: <snapshot, digest, fontes e base SHA>
decisions: <veredito literal>
changes_validation: <checagens ou none>
blockers: <blocker ou none>
---

> <resumo claro do review, achados decisivos e consequência para o plano>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

**Independência:** não escrevi este plano nem implementarei seu escopo.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

| Severidade                                        | Seção/fonte    | Impacto     | Ação     |
| ------------------------------------------------- | -------------- | ----------- | -------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<referência>` | `<impacto>` | `<ação>` |

_Veredito aprovador abre gate humano; nunca autoriza execução._
