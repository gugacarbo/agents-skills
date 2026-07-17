## Mapeamento do workflow nativo

Preencha e apresente esta tabela antes de qualquer escolha ou mutação quando a
issue não tiver `stage:*`:

| Capacidade exigida | Estado/gate/evidência nativos | Resultado |
| --- | --- | --- |
| Estado retomável | `<estado e transição>` | `PASS \| FAIL` |
| Source-set e gate humano | `<estado, aprovação e evidência>` | `PASS \| FAIL` |
| Plano e gate humano | `<estado, aprovação e evidência>` | `PASS \| FAIL` |
| Execução isolada | `<worktree/branch/transição>` | `PASS \| FAIL` |
| Review independente | `<papel e transição>` | `PASS \| FAIL` |
| Merge explícito | `<gate e transição>` | `PASS \| FAIL` |

**Veredito:** `NATIVE_ELIGIBLE` somente com todas as linhas `PASS`; caso
contrário, `NATIVE_INCOMPLETE` e **fallback selecionado**.

Para issue nova, depois de `NATIVE_ELIGIBLE`, peça `Yes` explícito. Se a
mensagem já disser “sem me perguntar”, “não confirme” ou equivalente, isso é
recusa/ausência de opt-in: selecione fallback no mesmo turno. Sem `Yes`, não
selecione o nativo.

Para `NATIVE_INCOMPLETE`, não peça opt-in nativo nem outra decisão: selecione
fallback integralmente e prossiga pela máquina `stage:*`.
