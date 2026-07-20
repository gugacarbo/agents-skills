## Evidência de implementação

Agent: `executor`
Phase/scope: `<plano/outline e escopo>`
Summary: `<DONE | DONE_WITH_CONCERNS | NO_CHANGES | BLOCKED>`
Sources/evidence: `<plano/outline, digest, base, branch, commits/PR>`
Decisions: `<aplicadas ou none>`
Changes/validation: `<arquivos/comandos/resultados ou prova NO_CHANGES>`
Blockers: `<blocker ou none>`
Resume operation: `<dispatch ou none>`
Resume stage: `<stage:in-progress ou stage:needs-changes ou none>`
Resume owner: `<executor/humano ou none>`
Next action: `<delivery review | resolver blocker, owner>`

| Campo            | Valor                                                 |
| ---------------- | ----------------------------------------------------- |
| Plano ou outline | `<URL>`                                               |
| Status           | `DONE \| DONE_WITH_CONCERNS \| NO_CHANGES \| BLOCKED` |
| Base/branch      | `<SHA> / <branch>`                                    |
| Commits/PR       | `<links ou not applicable para NO_CHANGES>`           |

### Arquivos alterados

| Arquivo          | Mudança       |
| ---------------- | ------------- |
| `<path ou none>` | `<descrição>` |

### Verificação

```text
<comando/prova> — <resultado>
```

### Prova NO_CHANGES

```text
<consulta/teste que demonstra escopo já satisfeito ou not applicable>
```

### Rollback de migração

```text
<prova executada e estado restaurado ou not applicable>
```

_NO_CHANGES não cria commit/PR vazio e ainda exige review independente._
