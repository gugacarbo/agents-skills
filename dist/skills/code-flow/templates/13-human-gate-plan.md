# Gate humano · plano formal

Apresente snapshot exato, source-set digest e review independente.

| Resposta   | Ação do orquestrador                                                  |
| ---------- | --------------------------------------------------------------------- |
| `Aprovar`  | `stage:approved + needs-human`; ainda aguardar ordem de execução.     |
| `Ajustar`  | `stage:needs-plan-fix`, limpar needs-human e abrir novo ciclo/review. |
| `Bloquear` | `stage:blocked + needs-human` com resume target de plan.              |

Este gate não se aplica ao outline S já coberto pela autorização de execução.
