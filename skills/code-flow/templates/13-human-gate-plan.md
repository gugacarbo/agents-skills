# Gate humano · plano formal

Apresente o snapshot exato e a review independente. Este gate não se aplica ao
outline compacto produzido no início de uma execução já autorizada.

| Resposta | Ação                                                                             |
| -------- | -------------------------------------------------------------------------------- |
| `Yes`    | Mover a `stage:approved + needs-human`; aguardar ordem explícita de execução.    |
| `No`     | Mover a `stage:needs-plan-fix` e limpar `needs-human`.                           |
| `Refine` | Limpar `needs-human`, abrir novo ciclo e exigir nova review antes de outro gate. |
