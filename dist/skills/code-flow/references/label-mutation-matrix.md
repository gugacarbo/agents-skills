# Matriz de transição e ownership

Evidência precede mutação. O autor do resultado aplica e confirma a própria
transição; o comando `gate` aplica somente a decisão humana fornecida.

| Evento                                               | Ator              | Estado resultante                                        |
| ---------------------------------------------------- | ----------------- | -------------------------------------------------------- |
| start em repository issue                            | adaptador/comando | `code-flow:active + stage:needs-triage`                  |
| papel inicia                                         | papel elegível    | preserva principal + `stage:in-progress`                 |
| triagem publicada                                    | issue-writer      | `stage:awaiting-triage-approval + needs-human`           |
| triagem aprova/ajusta/bloqueia                       | gate              | execução ou arquitetura / needs-triage / blocked+human   |
| arquitetura publicada                                | architect         | ready-for-execution ou awaiting-execution-approval+human |
| execução autoriza/ajusta/bloqueia                    | gate              | ready-for-execution / needs-architect / blocked+human    |
| executor entrega ou NO_CHANGES                       | executor          | `stage:needs-delivery-review`                            |
| review aprova diff                                   | reviewer          | `stage:ready-to-merge + needs-human`                     |
| review aprova NO_CHANGES                             | reviewer          | `stage:integration-authorized`                           |
| review ajusta/não verifica                           | reviewer          | `stage:needs-changes`                                    |
| merge integra/ajusta/aguarda                         | gate              | integration-authorized / needs-changes / permanece       |
| integrator detecta drift material/conflito resolvido | integrator        | `stage:needs-delivery-review`                            |
| integrator exige correção                            | integrator        | `stage:needs-changes`                                    |
| blocker de papel                                     | autor             | `stage:blocked + needs-human`, sem overlay               |
| blocker resolvido                                    | gate resume       | estado comprovado no `Resume`                            |
| activity reset                                       | gate              | preserva principal e remove overlay                      |
| merge/close confirmado                               | integrator        | issue fechada; labels code-flow removidas                |
| stop confirmado                                      | gate/adaptador    | labels removidas; artefatos preservados                  |

Todo blocker registra estado a retomar, papel, impedimento e evidência em
`Resume`. Gate humano nunca coexistirá com `stage:in-progress`.
