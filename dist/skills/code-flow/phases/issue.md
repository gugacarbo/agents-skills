# Issue e triagem de complexidade

Use `templates/02-issue-template.md`. O `issue-writer` investiga a codebase,
preenche o body com contexto e objetivo e persiste `Complexity: S | M | G | X | XL`
no bloco de metadata. `Workflow` não é gravado. Relação com Epic fica fora do
body; toda filha usa este mesmo template.

O `issue-writer` **não** decide impacto de spec/ADR, **não** preenche bloco de
spec e **não** materializa ADR/spec: essa triagem é do `architect`.

Para pré-issue de batch, o issue-writer primeiro investiga fontes e codebase e
substitui o body mínimo do Draft Issue pelo template completo, ainda sem
labels/stage. Publique evidência do body e do repositório alvo; então o próprio
issue-writer ou o orquestrador pode converter o item de `DRAFT_ISSUE` para
`ISSUE`. Somente após confirmar a conversão aplique a regra de transição abaixo.

- S interna: orquestrador cria issue mínima em `stage:approved + needs-human`.
- M/G/X/XL: issue-writer publica issue escolada e vai a `stage:needs-architect`.

Mudança posterior no body que altere `Complexity` ou o objetivo invalida o gate
aplicável; metadata externa não.

## Disparo do architect

Quando a Complexidade for `>= M`, o orquestrador despacha o `architect` a partir
de `stage:needs-architect`. O relatório de arquitetura é a entrada do fluxo de
arquitetura em [`phases/plan.md`](plan.md).
