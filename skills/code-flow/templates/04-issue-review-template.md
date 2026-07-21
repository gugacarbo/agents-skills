> agent: issue-reviewer
> phase_scope: issue / source-set X/XL ou hard trigger
> sources_evidence: <issue, digest, proposta e fontes>
> decisions: <veredito literal>
> changes_validation: <checagens ou none>
> blockers: <blocker ou none>

## Status

**APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR**

## Resume

<resultado claro do review e consequência para o próximo gate>

`none`, ou, em blocker: operação, estado a retomar e responsável.

**Independência:** não escrevi nem aprovei o source-set.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

| Severidade                                        | Fonte/seção    | Impacto     | Ação     | Issue draft                                 |
| ------------------------------------------------- | -------------- | ----------- | -------- | ------------------------------------------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<referência>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

_Ressalvas aprovadoras são somente Minor não bloqueantes. O veredito não
substitui o gate humano. Para cada Minor, use
[`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md)._
