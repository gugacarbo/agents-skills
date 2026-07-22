> agent: <papel que publica a nota>
> sources_evidence: <links, comandos ou fontes>
> note_type: <general | architect-change>

## Resume

<resumo humano do evento isolado e sua consequência>

## Contexto

<correção de source-set, promoção de risco/drift, migração, blocker ou falha transitória>

## Evidência e impacto

| Fato     | Evidência      | Impacto     | Próximo passo |
| -------- | -------------- | ----------- | ------------- |
| `<fato>` | `<link/saída>` | `<impacto>` | `<ação>`      |

## Alterações no relatório de arquitetura — somente para `architect-change`

- <mudança essencial>
- <mudança essencial, se houver>
- <mudança essencial, se houver>

### Motivo e impacto

<por que o relatório canônico mudou e o efeito em escopo, risco, decisão de
spec ou blockers, de forma breve>

_Esta nota é append-only e não substitui issue, relatório de arquitetura,
review, gate humano, evidência de implementação ou resultado de integração.
Em `architect-change`, `sources_evidence` aponta para o comentário canônico e a
Base SHA; o relatório completo permanece no comentário editado in-place._
