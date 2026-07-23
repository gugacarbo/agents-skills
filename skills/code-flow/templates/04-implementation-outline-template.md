 > agent: executor
 > run_id: <uuid>
 > event: implementation-outline
 > state_before: stage:ready-for-execution + stage:in-progress
 > state_after: stage:ready-for-execution + stage:in-progress
 > sources_evidence: <issue, Base SHA, código e testes>
 > project_guidance: <paths nearest-wins e comandos; ou none found + busca>
 
 ## Resume
 
 <objetivo, mudanças, validação e condições de parada>
 
 ## Contorno
 
 | Escopo   | Arquivos/áreas | Validação    |
 | -------- | -------------- | ------------ |
 | `<item>` | `<paths>`      | `<comandos>` |
 
 | Worktree/branch | Base SHA | Rollback |
 | --------------- | -------- | -------- |
 | `<valor>`       | `<sha>`  | `<ação>` |
 
 Pare para nova arquitetura diante de contrato público, hard trigger, decisão
 material ou drift não coberto.
