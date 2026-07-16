# Gate humano · source-set / spec

|             |                                                            |
| ----------- | ---------------------------------------------------------- |
| **Fase**    | 2 — criar issue                                            |
| **Stage**   | `stage:spec-approval` + `needs-human`                      |
| **Próximo** | Materializar ADR/spec (se necessário) → `stage:needs-plan` |

---

## Em jogo

A proposta de ADR/spec embutida na issue **ou** o racional
`Spec impact: not required` — em `stage:spec-approval` após a review do
`issue-reviewer`, com `needs-human` aguardando sua decisão.

## Você aprova

Materializar o ADR/spec exatamente como proposto (quando necessário) e liberar
`stage:needs-plan`.

## Resposta

Responda com **uma** opção literal:

| Opção      | Significado                                                         |
| :--------- | :------------------------------------------------------------------ |
| **Yes**    | Aprovar a proposta/racional; `issue-writer` materializa e avança.   |
| **No**     | Rejeitar; manter `spec-approval` + `needs-human` até nova proposta. |
| **Refine** | Pedir edição concreta da proposta antes de materializar.            |

---

> **Regra:** O veredito de `issue-reviewer` abre este gate, mas **não** substitui
> o **Yes**. Não avança stage sem **Yes** explícito.
