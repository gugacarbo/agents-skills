# Gate humano · plano formal

Apresente o snapshot exato e a review independente. Este gate não se aplica ao
outline compacto produzido no início de uma execução já autorizada.

| Resposta | Ação |
| --- | --- |
| `Yes` | Mover a `stage:approved`; execução ainda exige ordem explícita. |
| `No` | Devolver a `stage:needs-plan-fix`. |
| `Refine` | Novo ciclo e nova review. |
