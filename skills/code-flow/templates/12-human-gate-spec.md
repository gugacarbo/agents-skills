# Gate humano · source-set / spec

| | |
|---|---|
| **Fase** | 2 — criar issue |
| **Stage** | `stage:spec-approval` + `needs-human` |
| **Próximo** | Materializar ADR/spec (se necessário) → `stage:needs-plan` |

---

## Em jogo

A proposta de ADR/spec embutida na issue **ou** o racional
`Spec impact: not required` — ainda em `stage:spec-approval` + `needs-human`.

## Você aprova

Materializar o ADR/spec exatamente como proposto (quando necessário) e liberar
`stage:needs-plan`.

## Resposta

Responda com **uma** opção literal:

| Opção | Significado |
|:------|:------------|
| **Yes** | Aprovar a proposta/racional; `issue-writer` materializa e avança. |
| **No** | Rejeitar; manter `spec-approval` + `needs-human` até nova proposta. |
| **Refine** | Pedir edição concreta da proposta antes de materializar. |

---

> **Regra:** Um veredito de `issue-reviewer` (se houver) **não** substitui este
> **Yes**. Não avança stage sem **Yes** explícito.
