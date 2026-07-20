# Issue e source-set

Após discovery e decisões obrigatórias:

- S interna + `Spec impact: not required`: o orquestrador cria issue mínima em
  `stage:approved + needs-human`.
- M/G ou qualquer source-set: despache `agents/01-issue-writer.md`.
- X/XL ou hard trigger: após issue-writer, despache
  `agents/02-issue-reviewer.md` antes do gate humano.

Use padrão local e `templates/03-issue-template.md`. Header operacional contém
Complexity/Workflow. Source-set vive exclusivamente entre os marcadores
`code-flow:source-set:start/end` e classifica:

- `create`: novo contrato público ou decisão durável que precisa de fonte;
- `update`: fonte aceita governa comportamento que mudará;
- `not required`: nenhuma fonte aceita/contrato público/decisão durável muda.

Comportamento observável localizado, sozinho, não implica `create`.

## Entrada por rigor

- S no-spec: `stage:approved + needs-human`.
- M/G no-spec: sem source gate; `stage:needs-plan` diretamente.
- M/G create/update: `stage:spec-approval + needs-human`.
- X/XL ou hard trigger: `stage:spec-approval` sem `needs-human` até review.

Cada autor publica a evidência antes de transicionar seu resultado; o
orquestrador confirma o estado. Em source review, somente `APROVAR` ou
`APROVAR COM RESSALVAS` com achados Minor abre gate humano. `AJUSTAR`,
`Critical`, `Important` ou `Cannot verify` volta a `stage:needs-issue-fix`;
dependência externa/risco não resolvido vai a blocker com resume target.

## Gate humano

Apresente `templates/12-human-gate-spec.md`:

- `Aprovar`: orquestrador registra URL + digest do bloco aprovado e move a
  `stage:needs-plan`.
- `Ajustar`: orquestrador move a `stage:needs-issue-fix`.
- `Bloquear`: orquestrador move a `stage:blocked + needs-human` com resume
  target de issue/source.

O digest é produzido por `scripts/source-set-digest.py`. Mudança posterior no
bloco invalida o gate; metadata fora dele não. ADR/spec em arquivo é
materializado somente pelo executor na worktree autorizada.

Brainstorm é condicional. Decisões aprovadas entram no source-set, não em
documento paralelo.
