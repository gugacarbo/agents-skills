## Evidência de implementação

Agent: `executor`
Phase/scope: `<plano ou outline e escopo implementado>`
Summary: `<DONE | DONE_WITH_CONCERNS | BLOCKED | resultado sem mudança>`
Sources/evidence: `<URL do plano/outline, base SHA, branch, commits e PR quando houver>`
Decisions: `<aplicadas, pendentes ou nenhuma>`
Changes/validation: `<arquivos, comandos e resultados>`
Blockers: `<blocker ou none>`
Next action: `<review do delivery-reviewer | resolver blocker, owner>`

### Resumo rápido

| Campo             | Valor                                   |
| ----------------- | --------------------------------------- |
| Plano ou outline  | `<URL>`                                 |
| Status            | `DONE \| DONE_WITH_CONCERNS \| BLOCKED` |
| Base SHA / branch | `<SHA> / <branch>`                      |
| Commits / PR      | `<links>`                               |

### Arquivos alterados

| Arquivo        | Mudança             |
| -------------- | ------------------- |
| `path/to/file` | `<descrição breve>` |

### Verificação

```text
<comando> — <resultado>
```

### Evidência TDD

| Fase | Evidência                              |
| ---- | -------------------------------------- |
| TDD  | `not applicable \| RED: … \| GREEN: …` |

### Ressalvas ou blocker

> `<nenhuma | descrição da ressalva ou blocker>`

---

_Processo: code-flow — evidência append-only do executor para review
independente do escopo autorizado._

`BLOCKED` não está pronto para review. Deve identificar a decisão ou correção
exata e mantém o fluxo bloqueado até resolução.
