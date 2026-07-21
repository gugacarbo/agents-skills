> agent: <papel>
> phase_scope: <operação, ciclo ou range>
> sources_evidence: <links imutáveis, comandos e saída>
> decisions: <aplicadas, pendentes ou none>
> changes_validation: <mudanças e validação ou none>
> blockers: <blocker ou none>

## Resume

<resumo humano do resultado>

Fora de blocker: `none`.

Em blocker:

- Operação: `<context | issue | plan | dispatch | review | integrate>`
- Estado a retomar: `<stage:* ou estado nativo>`
- Responsável: `<papel | humano | orquestrador>`

# Contrato de evidência

Todo resultado de papel usa este envelope antes de mutação de workflow,
inclusive no-op, erro, blocker e rejeição. Comentário não muda estado.

O source-set do issue-writer vive no body entre os marcadores canônicos:

```text
<!-- code-flow:source-set:start -->
<!-- code-flow:source-set:end -->
```

`scripts/source-set-digest.py` calcula SHA-256 somente do conteúdo interno em
UTF-8, CRLF normalizado para LF e exatamente um LF final. Complexity e a
relação com Epic ficam fora do bloco; não há Workflow persistido. Gate registra
URL e digest; mudança do bloco invalida aprovação, mudança apenas de metadata
não.

Resultados restantes são comentários append-only. O agente aplica a transição
causada por seu artefato; o orquestrador confirma. Decisão humana usa o gate
compartilhado; evento isolado usa a nota compartilhada, sem duplicar regras de
fase.

Todo `Minor` não bloqueante usa o draft canônico de
[`references/follow-up-issue-drafts.md`](../references/follow-up-issue-drafts.md).
No fim da delivery review, o reviewer publica a consolidação append-only de
sugestões antes da transição, sem criar issues nem mutar labels/gates.
