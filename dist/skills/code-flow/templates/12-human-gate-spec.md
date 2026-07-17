# Gate humano · source-set

Use quando `create/update` ou hard trigger exigir aprovação humana do
source-set. Se houver review independente obrigatória, apresente seu veredito
antes deste gate.

| Resposta | Ação                                                                                      |
| -------- | ----------------------------------------------------------------------------------------- |
| `Yes`    | Registrar URL + SHA-256 do body aprovado; limpar o marcador e ir ao plano; arquivo só na execução. |
| `No`     | Ir a `stage:needs-issue-fix` e limpar `needs-human`.                                      |
| `Refine` | Mesma correção; repetir review aplicável antes do próximo gate.                           |
