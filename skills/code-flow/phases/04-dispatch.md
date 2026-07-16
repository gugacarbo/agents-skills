# Fase 4: Dispatch

Despache só após aprovação do plano, ou para corrigir achados quando a issue
estiver em `stage:needs-changes`. No modo issue, a primeira execução exige
`stage:approved`, pedido explícito de implementação e `worktree` ou `later`.
`later` adiciona `needs-human` e não muda código; `worktree` remove essa label
e muta para `stage:in-progress`. Em `needs-changes`, despache o executor sobre
os achados da review sem novo pedido de `worktree` se a worktree já existir.
Nunca oferecer `direct` para issue ou batch.

No modo repositório, pergunte worktree ou `direct`. `direct` usa o checkout
atual e escreve todo envelope, review e DoD só no registro versionado em
`docs/delivery/<slug>.md` (pergunte se deve mudar o caminho). Não cria issue,
label, stage ou comentário GitHub e não pode converter depois para criação de
issue.

Despache apenas `agents/05-executor.md`. Ele recebe URL da issue quando houver,
revisão do plano, base SHA, escopo/limites, critérios de aceite, verificação e
destino da evidência. Implementa o plano aprovado como uma unidade — sem lista
decomposable de tasks — e pode organizar o trabalho internamente. Publica
`templates/07-task-evidence-template.md` no modo issue ou o mesmo envelope de
oito campos no modo `direct`. Um resultado `BLOCKED` para: modo issue muta
labels para `stage:blocked` + `needs-human` após o comentário de evidência;
modo `direct` anexa `Resume: Phase 4` sem estado GitHub.

Use uma worktree/branch/PR por issue. Quando existir evidência não bloqueada do
executor para o plano aprovado, mutue labels para `stage:needs-task-review`.
