# Gate humano · source-set

Use somente quando `create/update` exigir aprovação humana. Se houver review
independente obrigatória, apresente seu veredito antes deste gate.

| Resposta | Ação |
| --- | --- |
| `Yes` | Materializar fonte aprovada e seguir ao plano. |
| `No` | Manter gate e corrigir a proposta. |
| `Refine` | Editar o body e repetir os controles aplicáveis. |
