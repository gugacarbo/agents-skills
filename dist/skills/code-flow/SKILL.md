---
name: code-flow
description: "Coordinate explicitly requested GitHub issue deliveries through independent dispatcher, architect, executor, code-reviewer, and integrator roles. Use only when the user invokes $code-flow or /code-flow."
---

# code-flow

Orquestre issues existentes sem instalar configuração no repositório-alvo.
`/code-flow` é read-only; `/code-flow <issue>` ativa ou retoma e executa até
gate, blocker, conclusão ou dez papéis. Sempre leia [`runtime.md`](runtime.md)
e use [`workflow-states.json`](workflow-states.json) como registry canônico.
No worker, leia também [`worker-runtime.md`](worker-runtime.md) e
[`manifest.json`](manifest.json): uma sessão executa somente um papel.

| Comando                             | Ação                                                  |
| ----------------------------------- | ----------------------------------------------------- |
| `/code-flow`                        | Mostra ajuda e faz discovery read-only.               |
| `/code-flow <issue>`                | Provisiona labels ausentes, ativa/retoma e orquestra. |
| `/code-flow role <papel> <issue>`   | Executa exatamente um papel elegível.                 |
| `/code-flow gate <issue> <decisão>` | Aplica uma decisão humana válida.                     |
| `/code-flow stop <issue>`           | Faz handoff e encerra somente o protocolo.            |
| `/code-flow doctor [args]`          | Executa `scripts/doctor.sh`.                          |

| Estado                                             | Papel                                         |
| -------------------------------------------------- | --------------------------------------------- |
| `stage:needs-triage`                               | [`dispatcher`](agents/01-dispatcher.md)       |
| `stage:needs-architect`                            | [`architect`](agents/02-architect.md)         |
| `stage:ready-for-execution`, `stage:needs-changes` | [`executor`](agents/03-executor.md)           |
| `stage:needs-delivery-review`                      | [`code-reviewer`](agents/04-code-reviewer.md) |
| `stage:integration-authorized`                     | [`integrator`](agents/05-integrator.md)       |

Publique evidência antes de labels e confirme o estado remoto depois. Atividade
usa `stage:in-progress`; gate usa `needs-human`; nunca ambos. Cada papel lê seu
próprio prompt, runtime, registry e templates, sem memória do papel anterior.
Use `scripts/transition-issue.sh`, `scripts/validate-evidence.sh` e
`scripts/source-set-digest.sh` para operações determinísticas.
Workers usam `scripts/apply-event.sh`; comentários de gate têm sintaxe
`/code-flow gate DECISION` e são tratados por [`gate`](agents/06-gate.md).
Comentários seguem [`evidence-template.md`](templates/evidence-template.md);
gates usam [`human-gate-template.md`](templates/human-gate-template.md).
Metadados de invocação ficam em [`agents/openai.yaml`](agents/openai.yaml).
