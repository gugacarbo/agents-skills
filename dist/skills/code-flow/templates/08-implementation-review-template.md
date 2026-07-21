---
agent: delivery-reviewer
phase_scope: <plano/outline / range ou prova NO_CHANGES>
sources_evidence: <executor, range/PR/prova e fontes>
decisions: <veredito literal>
changes_validation: <checagens>
blockers: <blocker ou none>
---

> <resumo humano da revisão: escopo, conclusão, ressalvas e próxima decisão>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Resumo da revisão

<o que foi revisado, o veredito e a decisão humana esperada>

| Plano/outline | Evidência | Range/PR                   |
| ------------- | --------- | -------------------------- |
| `<URL>`       | `<URL>`   | `<base..head, URL ou n/a>` |

**Independência:** não produzi plano, código nem evidência revisada.

**Veredito:** `APROVAR | APROVAR COM RESSALVAS | AJUSTAR | BLOQUEAR`

## Cobertura dos critérios

| Critério     | Evidência revisada | Resultado                       | Observação |
| ------------ | ------------------ | ------------------------------- | ---------- |
| `<critério>` | `<prova>`          | `PASS \| FAIL \| Cannot verify` | `<nota>`   |

## Reconciliação de escopo

| Autorizado | Entregue | Divergência/justificativa |
| ---------- | -------- | ------------------------- |
| `<item>`   | `<item>` | `<none ou motivo>`        |

## Achados

| Severidade                                        | Local/prova                | Impacto     | Ação     |
| ------------------------------------------------- | -------------------------- | ----------- | -------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<file:line ou evidência>` | `<impacto>` | `<ação>` |

## Com diff

<range, testes e DoD revisados ou not applicable>

## Sem diff: `NO_CHANGES`

<escopo consultado, prova de ausência e confirmação de nenhum commit/PR vazio>

## Decisão e transição proposta

| Estado atual | Próximo gate | Efeito após decisão humana |
| ------------ | ------------ | -------------------------- |
| `<stage>`    | `<merge      | close                      | auditoria | correção>` | `<transição>` |

_NO_CHANGES aprovado segue para ready-to-close; diff aprovado segue para
ready-to-merge._
