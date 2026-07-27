# code-flow eval fixtures

Os evals de code-flow são baseados em **transcript e comportamento do agente**,
não em arquivos criados no filesystem. Os cenários assumem issues reais ou
simuladas no GitHub (acme/demo) acessíveis ao agente durante a execução.

## Setup por cenário

| Eval | Issue | Estado inicial                                                     | Fixture                                                                      |
| ---- | ----- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| E1   | #42   | sem labels code-flow                                               | n/a (issue limpa)                                                            |
| E2   | #43   | `code-flow:active + stage:ready-for-execution + stage:in-progress` | `e2-overlay.json` (mock de issue com overlay)                                |
| E3   | #44   | `code-flow:active + stage:ready-for-execution + stage:in-progress` | `e3-lease-expired.json` (mock com lease expirado)                            |
| E4   | #45   | `code-flow:active + stage:needs-delivery-review`                   | `e4-self-authorship.json` (mock com run_id def-456 em dispatcher + executor) |
| E5   | #46   | `code-flow:active + stage:needs-triage`                            | `e5-agents-md/AGENTS.md` (guidance local)                                    |

## Mocks

Para rodar os evals sem um repo real acme/demo, use `gh` fake (como em
`tests/tests.sh`) apontando para os mocks JSON aqui. O `run-evals.mjs` não inclui
o mock automaticamente; configure `PATH` ou `GH_FAKE_DIR` antes de invocar.

## e5-agents-md/

Contém um `AGENTS.md` de exemplo com convenções (conventional commits, squash
merge) para o eval E5 validar nearest-wins discovery.
