# Gate humano · plano

|             |                                                 |
| ----------- | ----------------------------------------------- |
| **Fase**    | 3 — plano                                       |
| **Stage**   | `stage:needs-plan-review` + `needs-human`       |
| **Próximo** | `stage:approved` → execução (worktree ou later) |

---

## Em jogo

O snapshot exato do comentário de plano (cite a URL), já com veredito
independente do aprovador, em `stage:needs-plan-review` + `needs-human`.

## Você aprova

Este plano (ciclo k/3, base SHA, fontes) como unidade de implementação — ainda
sem executar código.

## Resposta

Responda com **uma** opção literal:

| Opção      | Significado                                                                       |
| :--------- | :-------------------------------------------------------------------------------- |
| **Yes**    | Mutar para `stage:approved`; depois ainda pedir execução e `worktree` ou `later`. |
| **No**     | Rejeitar; devolver a `stage:needs-plan-fix` (ou bloquear no ciclo 3).             |
| **Refine** | Pedir ajustes; `stage:needs-plan-fix`, novo ciclo de plano + reviewer fresco.     |

---

> **Regra:** O veredito do `plan-reviewer` é consultivo; só o **Yes** humano
> autoriza `stage:approved`.
