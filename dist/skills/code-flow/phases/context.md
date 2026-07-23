# Contexto, ativação, gates e retomada

Discovery sem issue ativa é read-only. Resolva instruções nearest-wins, forms,
ADR/spec, código/testes, labels, comentários, PRs e workflow Git. Registre em
`project_guidance` os paths e comandos consultados; não pergunte fatos
descobríveis.

## Ativação

`/code-flow start <issue>` exige uma repository issue elegível, publica a
evidência de ativação e adiciona `code-flow:active + stage:needs-triage`. Recuse
ativação quando houver outro `stage:*`, labels legadas ou issue tracker/Epic.
Labels legadas usam a migração segura de `references/github-flow.md`.

Enquanto `code-flow:active` existir, o protocolo da skill é autoritativo. Ainda
assim, preserve o workflow Git, branch protection, forms e comandos do projeto.

## Gates determinísticos

`/code-flow gate` não toma decisão: recebe uma resposta humana, valida o estado
esperado, publica `templates/07-human-gate-spec.md`, aplica a transição da matriz
e confirma labels. Recuse gate com `stage:in-progress`, evidência ausente,
digest/base obsoletos ou opção não permitida.

- triage: `approve | adjust | block`;
- execution: `authorize | adjust | block`;
- merge: `integrate | adjust | wait`;
- resume: restaura somente o estado registrado no `Resume` publicado;
- activity: `reset` preserva o estado principal, remove somente
  `stage:in-progress` e registra por que a execução anterior foi abandonada.

## Retomada

Uma atividade iniciada contém `run_id`, papel e estado principal. A entrada
`--resume <run-id>` exige correspondência exata com a última evidência de início
ou `Resume`; não troca papel, estado ou escopo. Sem correspondência, use o gate
humano `activity reset` antes de iniciar outra execução.

Blocker deixa `stage:blocked + needs-human`, sem overlay, e registra no `Resume`
o estado principal a restaurar, papel, impedimento e evidência. A retomada
recalcula risco e valida o destino antes de `/code-flow gate <issue> resume
<stage>` remover `needs-human` quando o destino for de agente.

## Batch

Crie pré-issues como Project V2 `DRAFT_ISSUE` usando
`templates/02-issue-template.md`. No draft, preencha apenas as seções com
informação disponível no momento (título, intenção, contexto fornecido); deixe as
demais como placeholders a completar. Draft não recebe labels. O issue-writer
investiga e completa o body antes da conversão. Depois de confirmar URL, número,
repositório e tipo `ISSUE`, não repita a triagem: publique a promoção e adicione
`code-flow:active + stage:awaiting-triage-approval + needs-human`.

Se o Project V2 estiver ausente, ambíguo ou sem escrita, pare; não simule draft
com repository issue, título ou label. `--from` é piso e cada issue mantém
estado, worktree, falha e gate isolados.

## Saída segura

`/code-flow stop <issue>` mostra issue, PR, worktree, estado, overlay e trabalho
não integrado e apresenta `Encerrar code-flow / Manter ativo`.

- Com atividade, exija handoff antes de limpar labels.
- Encerrar publica a nota e remove somente `code-flow:active`, estado principal,
  `stage:in-progress` e `needs-human`.
- Não feche issue/PR, apague branch/worktree ou reverta código.
- Manter ativo preserva tudo. Falha parcial preserva o estado observável e
  registra como reparar; não declare encerramento incompleto como sucesso.
