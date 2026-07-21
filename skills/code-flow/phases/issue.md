# Issue e source-set

Use `templates/03-issue-template.md`. Complexity fica no frontmatter; Workflow
não é gravado. Relação com Epic fica fora do source-set; toda filha usa este
mesmo template.

- S interna + `not required`: orquestrador cria issue mínima em
  `stage:approved + needs-human`.
- M/G no-spec: issue-writer publica issue e vai a `stage:needs-plan`.
- M/G `create/update`: issue-writer publica source-set e vai a
  `stage:spec-approval + needs-human`.
- X/XL/hard trigger: issue-writer vai a `stage:spec-approval` sem
  needs-human até review independente.

`create` contém proposta de spec; `update` contém diff antes/depois;
`not required` explica o racional. Mudança posterior no bloco invalida o gate;
metadata externa não.

## Gate humano de source-set

Apresente o gate compartilhado com `Aprovar / Ajustar / Bloquear` e os efeitos
literais: aprovar registra URL+digest e move a needs-plan; ajustar volta a
needs-issue-fix; bloquear vai a blocked+needs-human com Resume. Brainstorm
aprovado entra no source-set, nunca em documento paralelo.
