# Gate humano: plano (Fase 3)

**Em jogo:** o snapshot exato do comentário de plano (cite a URL), já com
veredito independente aprovador, em `stage:needs-plan-review` + `needs-human`.

**Você aprova:** este plano (ciclo k/3, base SHA, fontes) como unidade de
implementação — ainda sem executar código.

Responda com uma opção literal:

- **Yes** — mutar para `stage:approved`; depois ainda pedir execução e
  `worktree` ou `later`.
- **No** — rejeitar; devolver a `stage:needs-plan` (ou bloquear no ciclo 3).
- **Refine** — pedir ajustes; novo ciclo de plano + reviewer fresco.

O veredito do `plan-reviewer` é consultivo; só o Yes humano autoriza
`stage:approved`.
