# Gate humano · fechamento sem diff

Use somente após `NO_CHANGES` aprovado independentemente.

| Resposta   | Ação do orquestrador                                                     |
| ---------- | ------------------------------------------------------------------------ |
| `Fechar`   | Registrar evidência, fechar issue e limpar workflow sem commit/PR/merge. |
| `Ajustar`  | Voltar a `stage:needs-changes`, limpar needs-human.                      |
| `Aguardar` | Manter `stage:ready-to-close + needs-human`.                             |
