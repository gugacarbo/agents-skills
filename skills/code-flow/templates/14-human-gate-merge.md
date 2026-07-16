# Gate humano · merge / integração

| | |
|---|---|
| **Fase** | 6 — integrar |
| **Stage** | `stage:ready-to-merge` + `needs-human` |
| **Próximo** | Merge/integração → fechar issue e limpar labels |

---

## Em jogo

PR aprovado, auditoria final e DoD ok; issue em `stage:ready-to-merge` (+
`needs-human` após aprovação do PR).

## Você decide

Se e quando integrar/mergear. Merge **nunca** é automático.

## Resposta

Responda com **uma** opção literal:

| Opção | Significado |
|:------|:------------|
| **Yes** | Merge/integração confirmados; fechar issue e limpar `stage:*` + `needs-human` via `scripts/transition-issue.sh --clear-stage --clear-needs-human`. |
| **No** | Não mergear agora; manter `ready-to-merge` (+ `needs-human`). |
| **Refine** | Pedir ajuste (volta a `needs-changes` / executor se for código). |

---

> **Regra:** Sem **Yes** explícito, não mergear. Pós-merge, preferir
> `scripts/transition-issue.sh` para limpeza de labels.
