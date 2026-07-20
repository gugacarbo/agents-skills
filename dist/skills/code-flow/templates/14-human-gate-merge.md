# Gate humano · integração

Merge nunca é automático.

| Resposta   | Ação do orquestrador                                         |
| ---------- | ------------------------------------------------------------ |
| `Integrar` | Fazer merge, verificar alvo, fechar issue e limpar workflow. |
| `Ajustar`  | Voltar a `stage:needs-changes`, limpar needs-human.          |
| `Aguardar` | Manter `stage:ready-to-merge + needs-human` sem mutar PR.    |
