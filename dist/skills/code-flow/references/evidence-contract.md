# Contrato de evidência

Todo comentário operacional começa com `agent`, `run_id`, `protocol_version`,
`event`, `state_before`, `state_after`, `sources_evidence` e `project_guidance`,
seguido de `## Resume`. `protocol_version` é o `schema_version` de
`workflow-states.json` no momento da publicação; workers com versão incompatível
devem recusar a evidência.

## Início

Antes de adicionar `stage:in-progress`, publique:

- run_id e papel;
- estado principal e issue;
- Base/Head, branch e worktree quando aplicáveis;
- artefatos de entrada e guidance;
- instante de início e resultado esperado;
- `lease_ttl` (segundos) quando o runtime suportar expiração de atividade.

## Resultado

Antes de concluir, publique resultado/veredito, fontes imutáveis, estado de
destino e, em blocker, responsável e impedimento. Depois mute labels e confirme
o estado remoto. Comentário nunca substitui label.

`activity reset` registra a decisão humana e preserva o principal.

## Retomada automática

Ao encontrar `stage:in-progress` existente, o mesmo papel retoma a atividade
comprovada pela última evidência de início ou `Resume` publicada: valide
correspondência exata de `run_id`, papel e estado principal antes de continuar.
Sem correspondência, use o gate humano `activity reset` antes de iniciar outra
execução. A retomada recalcula risco e revalida guidance nearest-wins.

`scripts/validate-evidence.sh` verifica tecnicamente essa correspondência: busca
o último comentário `activity-start`, extrai `run_id`/`agent`/`state_before` e
confronta com as labels atuais e o `actor` do estado principal no
`workflow-states.json`. Para reviewer, também exige que o autor GitHub do início
não seja autor de artefato anterior de issue-writer, architect ou executor. Sem
essa prova disponível, pare para revisão humana externa. Use-o antes de retomar
e no `doctor.sh --issue`.

## Relatório canônico de arquitetura

O relatório vive exatamente uma vez entre:

```text
<!-- code-flow:architect-review:start -->
<!-- code-flow:architect-review:end -->
```

`scripts/source-set-digest.py` calcula SHA-256 somente do conteúdo interno em
UTF-8, CRLF normalizado para LF e exatamente um LF final. Correções editam o
mesmo comentário in-place e publicam uma nota append-only `architect-change`.

Todo Minor não bloqueante usa
[`follow-up-issue-drafts.md`](follow-up-issue-drafts.md). O reviewer consolida
Minors no mesmo comentário sem criar issues nem alterar o veredito.
