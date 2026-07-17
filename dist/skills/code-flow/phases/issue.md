# Issue e source-set

Despache `agents/01-issue-writer.md` após contexto e decisões obrigatórias.
Use o padrão local e `templates/03-issue-template.md` apenas como complemento.

Classifique `Spec impact`:

- `create`: novo contrato, comportamento observável ou decisão durável;
- `update`: fonte aceita governa comportamento que mudará;
- `not required`: mudança interna sem contrato observável.

Escolha a entrada pelo risco recalculado:

- mudança interna + `not required`: issue mínima em
  `stage:approved + needs-human`; sem review/gate de fonte;
- mudança moderada + `not required`: issue em `stage:needs-plan`;
- mudança moderada + `create/update`: proposta no body em
  `stage:spec-approval`; gate humano de fonte, sem issue-review obrigatório;
- hard trigger: proposta no body em `stage:spec-approval`; review independente obrigatória
  por `agents/02-issue-reviewer.md` e gate humano separado.

ADR/spec formal só é materializado depois do gate aplicável. O source-set fica
no body; correções usam `templates/10-issue-note-template.md`. O nome interno da
classificação nunca aparece no artefato.

Quando o gate humano de fonte for exigido, apresente
`templates/12-human-gate-spec.md` após qualquer review independente aplicável.

Brainstorm não é uma etapa universal. Se decisões importantes estiverem
abertas, ofereça `prompts/brainstorm.md` e aguarde aceite; caso contrário siga
direto com os fatos já aprovados.
