# Contexto, ativação, gates e retomada

Discovery sem issue ativa é read-only. Resolva instruções nearest-wins, forms,
ADR/spec, código/testes, labels, comentários, PRs e workflow Git. Registre em
`project_guidance` os paths e comandos consultados; não pergunte fatos
descobríveis.

## Ativação

Ativação somente explícita via `/code-flow` ou `transition-issue.sh --activate`.
Antes de ativar, valide que a issue não tem `code-flow:active`, nenhum `stage:*`
canônico, nenhum overlay e nenhum `needs-human`. Labels legados exigem a
migração segura de `references/runtime.md` antes de ativar. Nunca adote uma
issue somente por interagir com ela; discovery read-only não muta labels.

Enquanto `code-flow:active` existir, o protocolo da skill é autoritativo. Ainda
assim, preserve o workflow Git, branch protection, forms e comandos do projeto.

## Gates determinísticos

`/code-flow gate` não toma decisão: recebe uma resposta humana, valida o estado
esperado, publica `templates/05-human-gate-spec.md`, aplica a transição da matriz
e confirma labels. Recuse gate com `stage:in-progress`, evidência ausente,
digest/base obsoletos ou opção não permitida.

- triage: `approve | adjust | block` (XS sem hard trigger pode ser
  auto-aprovado pelo issue-writer sem gate humano);
- execution: `authorize | adjust | block`;
- merge: `integrate | adjust | wait`;
- resume: restaura somente o estado registrado no `Resume` publicado;
- activity: `reset` preserva o estado principal, remove somente
  `stage:in-progress` e registra por que a execução anterior foi abandonada.

## Retomada

Uma atividade iniciada contém `run_id`, papel e estado principal. Ao encontrar
`stage:in-progress` existente, o mesmo papel deve retomar a atividade comprovada
pela última evidência de início ou `Resume` publicada: valide correspondência
exata de papel, estado principal e `run_id` antes de continuar; não troca papel,
estado ou escopo. Sem correspondência, use o gate humano `activity reset` antes
de iniciar outra execução.

Blocker deixa `stage:blocked + needs-human`, sem overlay, e registra no `Resume`
o estado principal a restaurar, papel, impedimento e evidência. A retomada
recalcula risco e valida o destino antes do gate humano genérico
`/code-flow gate <issue> <decisão-humana>` restaurar o estado registrado e
remover `needs-human` quando o destino for de agente.

## Batch

Crie pré-issues como Project V2 `DRAFT_ISSUE` usando
`templates/01-issue-template.md`. No draft, preencha apenas as seções com
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
