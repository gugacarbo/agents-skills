## Mapeamento do workflow nativo

| Capacidade exigida       | Estado/gate/evidência nativos  | Resultado |
| ------------------------ | ------------------------------ | --------- |
| Estado retomável         | `<estado/transição>`           | `PASS     | FAIL` |
| Source-set e gate humano | `<estado/aprovação/evidência>` | `PASS     | FAIL` |
| Plano e gate humano      | `<estado/aprovação/evidência>` | `PASS     | FAIL` |
| Execução isolada         | `<worktree/branch/transição>`  | `PASS     | FAIL` |
| Review independente      | `<papel/transição>`            | `PASS     | FAIL` |
| Merge e close explícitos | `<gates/transições>`           | `PASS     | FAIL` |

**Veredito:** `NATIVE_ELIGIBLE` somente com todas as linhas PASS; caso
contrário `NATIVE_INCOMPLETE` e fallback selecionado.

Na seleção inicial elegível, peça opt-in. `Yes` persiste `Workflow: native`;
recusa/ausência persiste fallback. Em retomada válida, reutilize a escolha.
Mudança material revalida; falha posterior declara `NATIVE_INVALID` e oferece
migração explícita/compensável para fallback.
