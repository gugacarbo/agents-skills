# Execução e correção

O `executor` consome `stage:ready-for-execution` ou `stage:needs-changes`.
Crie/reuse sua própria worktree isolada, publique início com `run_id`, Base/Head,
branch e resultado esperado e adicione `stage:in-progress` sem remover o estado
principal. Se o overlay já existir, recuse salvo `--resume` válido.

Em S, publique `templates/03-implementation-outline-template.md`. Nos demais,
referencie o relatório/digest autorizado. Revalide guidance, escopo, base,
aceite, testes e workflow Git. Decisão material, risco novo ou drift material
retorna ao primeiro gate aplicável.

Quando o architect decidir `create/update`, materialize a spec/ADR no mesmo PR.
Não altere silenciosamente o conteúdo aprovado.

Com diff, DONE e DONE_WITH_CONCERNS exigem commit, push e PR publicada. Correção
usa a mesma branch/PR. Branch local, commit sem push ou compare link não bastam.
Somente NO_CHANGES termina sem commit/PR vazio.

Publique `templates/04-implementation-evidence-template.md` antes da transição:

- DONE ou DONE_WITH_CONCERNS → `stage:needs-delivery-review`;
- NO_CHANGES comprovado → `stage:needs-delivery-review`;
- BLOCKED → `stage:blocked + needs-human` com `Resume`;
- falha corrigível durante a mesma execução mantém as labels atuais; se a
  execução terminar, remova o overlay e preserve o estado principal.

Na conclusão, remova o estado de entrada e `stage:in-progress`, adicione o
destino e confirme. Nunca aplique estado de merge ou integração.
