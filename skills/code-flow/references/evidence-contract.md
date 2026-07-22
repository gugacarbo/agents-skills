# Contrato de evidência

Todo template de comentário começa com `agent`, `sources_evidence` e uma seção
`## Resume` contendo resultado humano, veredito quando aplicável e próximo gate.

Antes de uma mutação de workflow, o comentário que a fundamenta identifica:

1. `agent`, quando autoria ou independência importam;
2. `sources_evidence`, com as fontes imutáveis usadas;
3. resultado, veredito ou decisão no corpo;
4. em blocker, operação, estado a retomar, responsável e impedimento.

## Blocker e retomada — somente se aplicável

- Operação: `<context | issue | plan | dispatch | review | integrate>`
- Estado a retomar: `<stage:* ou estado nativo>`
- Responsável: `<papel | humano | orquestrador>`
- Impedimento: `<fato e evidência>`

Não replique metadata inferível como `phase_scope`, `decisions`,
`changes_validation` ou `blockers`. Issues, Epics e Draft Issues usam somente a
metadata própria definida em seus templates. Comentário não muda estado.

O relatório de arquitetura do architect vive no body entre os marcadores canônicos:

```text
<!-- code-flow:architect-review:start -->
<!-- code-flow:architect-review:end -->
```

`scripts/source-set-digest.py` calcula SHA-256 somente do conteúdo interno em
UTF-8, CRLF normalizado para LF e exatamente um LF final. `Complexity` e a
relação com Epic ficam fora do bloco; não há `Workflow` persistido. O gate
registra URL e digest; mudança do bloco invalida aprovação, mudança apenas de
metadata não.

Resultados restantes são comentários append-only, exceto o relatório de
arquitetura. O relatório vive em exatamente um comentário entre os marcadores
`code-flow:architect-review:start` e `code-flow:architect-review:end`; o
`architect` cria esse comentário uma vez e edita o mesmo comentário in-place
em toda revisão. Cada edição gera depois um comentário append-only separado com
uma nota `architect-change` de
[`templates/07-workflow-note-template.md`](../templates/07-workflow-note-template.md),
nunca outra cópia
do relatório.

Todo `Minor` não bloqueante usa o draft canônico de
[`references/follow-up-issue-drafts.md`](follow-up-issue-drafts.md).
No fim da delivery review, o reviewer inclui a consolidação de sugestões no
mesmo comentário antes da transição, sem criar issues nem mutar labels ou gates.
