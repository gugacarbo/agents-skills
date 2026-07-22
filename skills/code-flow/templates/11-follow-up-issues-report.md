> agent: reviewer
> sources_evidence: <links dos reviews, evidência do executor e achados próprios>

## Resume

<quantidade coletada, duplicatas removidas, grupos finais e consequência para o gate>

## Cobertura da coleta

| Fonte               | Evidência      | Minors coletados | Resultado               |
| ------------------- | -------------- | ---------------- | ----------------------- |
| `<issue review>`    | `<URL ou n/a>` | `<n>`            | `PASS \| Cannot verify` |
| `<executor>`        | `<URL ou n/a>` | `<n>`            | `PASS \| Cannot verify` |
| `<delivery review>` | `<URL>`        | `<n>`            | `PASS`                  |

## Lista final de issues sugeridas

| Grupo                          | Sugestões e origens             | Justificativa                                                  | Issue draft                                                                                                             |
| ------------------------------ | ------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `<grupo ou item independente>` | `<resumos e links das origens>` | `<duplicata removida, agrupamento compatível ou independente>` | `[Abrir issue](https://github.com/<owner>/<repo>/issues/new?title=<title-percent-encoded>&body=<body-percent-encoded>)` |

Sem itens, publique literalmente: `Nenhuma sugestão de issue não bloqueante encontrada`.

_Use `n/a — repositório GitHub não verificável` sem inventar URL. Este comentário
é append-only: não cria issue automaticamente e não muda veredito, labels,
gates, merge ou fechamento. NO_CHANGES permanece NO_CHANGES e não autoriza
fechamento sem o gate humano._
