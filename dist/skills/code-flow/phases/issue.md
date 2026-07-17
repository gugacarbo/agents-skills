# Issue e source-set

Despache `agents/01-issue-writer.md` após contexto e decisões obrigatórias.
Use o padrão local e `templates/03-issue-template.md` apenas como complemento.

Classifique `Spec impact`:

- `create`: novo contrato público ou decisão durável que precisa de fonte
  canônica;
- `update`: fonte aceita governa comportamento que mudará;
- `not required`: nenhuma fonte aceita é afetada e nenhum contrato público ou
  decisão durável é criado. Comportamento observável localizado, por si só,
  não implica `create`.

Escolha a entrada pelo risco recalculado:

- mudança interna + `not required`: issue mínima em
  `stage:approved + needs-human`; sem review/gate de fonte;
- mudança moderada + `not required`: issue em `stage:needs-plan`;
- mudança moderada + `create/update`: proposta no body em
  `stage:spec-approval + needs-human`; gate humano de fonte, sem issue-review
  obrigatório;
- hard trigger: proposta no body em `stage:spec-approval`; review independente obrigatória
  por `agents/02-issue-reviewer.md`; somente após seu veredito aplique
  `needs-human` para o gate separado.

Após o gate, o source-set aprovado no body é a fonte autoritativa para o plano.
Registre no comentário do gate a URL da decisão e o SHA-256 do body aprovado,
sem duplicar seu conteúdo. Mudança posterior do digest invalida o gate.
ADR/spec em arquivo, quando necessário, entra no plano e só é materializado
pelo executor na worktree autorizada; não edite o repositório nesta operação.
Correções usam `templates/10-issue-note-template.md`. O nome interno da
classificação nunca aparece no artefato.

Quando o gate humano de fonte for exigido, apresente
`templates/12-human-gate-spec.md` após qualquer review independente aplicável.
`PEÇO AJUSTES` ou `NÃO APROVO` corrigível move a
`stage:needs-issue-fix` sem `needs-human`; rejeição por decisão externa ou risco
não resolvido move a `stage:blocked + needs-human`.

Brainstorm não é uma etapa universal. Se decisões importantes estiverem
abertas, ofereça `prompts/brainstorm.md` e aguarde aceite; caso contrário siga
direto com os fatos já aprovados.
