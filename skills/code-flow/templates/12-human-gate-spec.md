# Gate humano · source-set

Apresente bloco exato, digest e review independente aplicável.

| Resposta   | Ação do orquestrador                                                   |
| ---------- | ---------------------------------------------------------------------- |
| `Aprovar`  | Registrar URL + digest do bloco; ir a `stage:needs-plan`.              |
| `Ajustar`  | Ir a `stage:needs-issue-fix`, limpar needs-human e devolver ao writer. |
| `Bloquear` | Ir a `stage:blocked + needs-human` com resume target de issue/source.  |

ADR/spec em arquivo só é materializado pelo executor na worktree autorizada.
