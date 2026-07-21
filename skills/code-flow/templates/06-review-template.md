> agent: plan-reviewer
> phase_scope: plan / ciclo <k>/3
> sources_evidence: <snapshot, digest, fontes e base SHA>
> decisions: <veredito literal>
> changes_validation: <checagens ou none>
> blockers: <blocker ou none>

## Resume

<resumo claro do review, achados decisivos e consequência para o plano>

**Independência:** não escrevi este plano nem implementarei seu escopo.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

| Severidade                                        | Seção/fonte    | Impacto     | Ação     | Issue draft                                 |
| ------------------------------------------------- | -------------- | ----------- | -------- | ------------------------------------------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<referência>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

_Veredito aprovador abre gate humano; nunca autoriza execução. Para cada Minor,
use [`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md)._
