# Integração e fechamento

O `integrator` é o único consumidor de `stage:integration-authorized`. Publique
início com `run_id`, estado, PR/review ou prova NO_CHANGES e adicione
`stage:in-progress`, preservando o estado principal.

Com diff, use worktree isolada da branch da PR e aplique o contrato de rebase
do papel. O gate anterior é sempre
`stage:ready-to-merge + needs-human`; `integrate` remove `needs-human` e deixa
`stage:integration-authorized`, `adjust` envia a `stage:needs-changes` e `wait`
preserva o gate.

Com NO_CHANGES, confirme a review aprovada e ausência de diff, commit e PR vazio;
feche sem gate humano adicional. Evidência ambígua ou contraditória bloqueia.

Após merge, confirme Merge SHA, PR e issue. Se o vínculo não fechar a issue,
feche-a explicitamente. Publique `templates/04-integration-report-template.md`
e remova `code-flow:active`, estado principal, overlay e `needs-human`.

Falha transitória remove o overlay e preserva `stage:integration-authorized`.
Permissão, branch protection, serviço externo ou decisão pendente deixa
`stage:blocked + needs-human` com `Resume`; nunca declare sucesso parcial.
