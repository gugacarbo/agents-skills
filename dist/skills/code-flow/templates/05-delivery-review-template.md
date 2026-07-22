> agent: reviewer
> sources_evidence: <issue review, executor, PR publicada/prova e fontes>

## Resume

<resumo humano da revisão: escopo, conclusão, ressalvas e próxima decisão>

## Resumo da revisão

<o que foi revisado, o veredito e a decisão humana esperada>

| Relatório/outline | Evidência | PR                         |
| ----------------- | --------- | -------------------------- |
| `<URL>`           | `<URL>`   | `<base..head, URL ou n/a>` |

**Independência:** não produzi relatório de arquitetura, código nem evidência revisada.

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

## Consolidação de follow-ups

### Cobertura da coleta

| Fonte                   | Evidência               | Minors coletados | Resultado               |
| ----------------------- | ----------------------- | ---------------- | ----------------------- |
| `<issue review>`        | `<URL ou n/a>`          | `<n>`            | `PASS \| Cannot verify` |
| `<executor>`            | `<URL ou n/a>`          | `<n>`            | `PASS \| Cannot verify` |
| `achados desta revisão` | `<seção Achados acima>` | `<n>`            | `PASS`                  |

### Lista final de issues sugeridas

| Grupo                          | Sugestões e origens             | Justificativa                                                  | Issue draft                                                                                                             |
| ------------------------------ | ------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `<grupo ou item independente>` | `<resumos e links das origens>` | `<duplicata removida, agrupamento compatível ou independente>` | `[Abrir issue](https://github.com/<owner>/<repo>/issues/new?title=<title-percent-encoded>&body=<body-percent-encoded>)` |

Sem itens, publique literalmente: `Nenhuma sugestão de issue não bloqueante encontrada`.

_NO_CHANGES aprovado segue para ready-to-close; diff aprovado segue para
ready-to-merge. Para cada Minor, use
[`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md).
Use `n/a — repositório GitHub não verificável` sem inventar URL. A consolidação
não cria issue automaticamente nem muda o veredito. NO_CHANGES nunca é DONE e
não pula review, consolidação nem gate humano._
