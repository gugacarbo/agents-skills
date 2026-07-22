> agent: reviewer
> sources_evidence: <executor, range/PR/prova e fontes>

## Resume

<resumo humano da revisão: escopo, conclusão, ressalvas e próxima decisão>

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

| Severidade                                        | Local/prova                | Impacto     | Ação     | Issue draft                                 |
| ------------------------------------------------- | -------------------------- | ----------- | -------- | ------------------------------------------- |
| `Critical \| Important \| Minor \| Cannot verify` | `<file:line ou evidência>` | `<impacto>` | `<ação>` | `<Minor não bloqueante: link; demais: n/a>` |

## Com diff

<range, testes e DoD revisados ou not applicable>

## Sem diff: `NO_CHANGES`

<escopo consultado, prova de ausência e confirmação de nenhum commit/PR vazio>

## Decisão e transição proposta

| Estado atual | Próximo gate                                | Efeito após decisão humana |
| ------------ | ------------------------------------------- | -------------------------- |
| `<stage>`    | `<merge \| close \| auditoria \| correção>` | `<transição>`              |

_NO_CHANGES aprovado segue para ready-to-close; diff aprovado segue para
ready-to-merge. Para cada Minor, use
[`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md).
NO_CHANGES nunca é DONE e não pula review, consolidação nem gate humano._
