# code-flow eval fixtures

Os evals de code-flow combinam transcript/comportamento do agente e os
contratos versionados do worker. O runner de linguagem pode apontar para uma
issue GitHub descartável; os testes determinísticos usam um `gh` fake em
`tests/tests.sh` para validar eventos, gates e transições sem rede.

## Setup por cenário

| Eval | Issue | Estado inicial                                                     | Fixture                                   |
| ---- | ----- | ------------------------------------------------------------------ | ----------------------------------------- |
| E1   | #42   | sem labels code-flow                                               | n/a (issue limpa)                         |
| E2   | #43   | `code-flow:active + stage:ready-for-execution + stage:in-progress` | overlay e `run_id` informados no prompt   |
| E3   | #44   | `code-flow:active + stage:needs-triage`                            | triagem S sem hard trigger                |
| E4   | #45   | `code-flow:active + stage:needs-delivery-review`                   | `run_ids` produtores informados no prompt |
| E5   | #46   | `code-flow:active + stage:needs-triage`                            | `e5-agents-md/AGENTS.md` (guidance local) |

## Mocks

Para rodar os evals sem um repo real acme/demo, use `gh` fake compatível com o
de `tests/tests.sh`. O `run-evals.mjs` não instala mock automaticamente;
configure `PATH` antes de invocar. Lease, heartbeat e TTL pertencem ao runner
VPS futuro e não são um cenário desta skill.

## e5-agents-md/

Contém um `AGENTS.md` de exemplo com convenções (conventional commits, squash
merge) para o eval E5 validar nearest-wins discovery.
