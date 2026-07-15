# Labels `stage:*` + `needs-human`

Uma label de etapa (`stage:*`) por vez em issues de **Entrega** (e Bug com
entrega). Não aplicar em guarda-chuva nem Audit puro.

`needs-human` é **ortogonal**: agente parou e aguarda o usuário.

```bash
gh label create "stage:needs-plan" --color "FBCA04" --description "Aguardando plano de implementação"
gh label create "stage:in-review" --color "0075CA" --description "Plano postado; aguarda review"
gh label create "stage:approved" --color "0E8A16" --description "Plano aprovado (plan-approved); pode implementar sob pedido"
gh label create "stage:in-progress" --color "5319E7" --description "Implementação / PR em andamento"
gh label create "stage:blocked" --color "B60205" --description "Fluxo parado; precisa decisão humana"
gh label create "needs-human" --color "D93F0B" --description "Agente aguarda decisão ou ação humana"
```

Preferir `stage:blocked` (não a label genérica `blocked` do repo, se existir).

## Quando aplicar `needs-human`

| Situação | stage:* | needs-human |
| --- | --- | --- |
| Planner precisa decisão humana | `stage:blocked` | sim |
| Review `NÃO APROVO` / review falhou | `stage:blocked` | sim |
| 3º ciclo ainda `PEÇO AJUSTES` | `stage:blocked` | sim |
| Aguardando 1\|2\|depois (implementar) | `stage:approved` | sim |
| Drift labels↔comentários | `stage:blocked` (pergunte) | sim |
| Opt-out “só cria, não planeja” | `stage:needs-plan` | não (a menos que pergunte outra coisa) |

**Retomada após blocked:** remover `needs-human` + `stage:blocked` →
`stage:needs-plan` → novo B→C (exceto se o humano cancelar o fluxo).

**Após merge/fechar:** remover `stage:*` e `needs-human` (ou issue closed basta).

## Ciclo plan↔review

Um ciclo = 1 comentário de plano + 1 comentário de review. Comentar
`plan-review-cycle: k/3` ao aplicar `PEÇO AJUSTES`.

## Drift labels vs comentários

Comentários ≠ stage. Sem `stage:approved`, não há plan-approved. Não inventar
approved a partir de thread/PR.

## Trocar etapa

```bash
# listar stage:*
gh issue view N --json labels --jq '[.labels[].name] | map(select(startswith("stage:"))) | .[]'
# remover cada uma, depois:
gh issue edit N --add-label "stage:needs-plan"
# bloqueio:
gh issue edit N --add-label "stage:blocked" --add-label "needs-human"
```

Se já houver várias `stage:*`, remova todas antes de adicionar a nova.
