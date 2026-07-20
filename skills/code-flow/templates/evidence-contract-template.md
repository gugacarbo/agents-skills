---
Agent: <agent>
Phase/scope: <operação, ciclo ou range>
Summary: <resultado>
Sources/evidence: <links imutáveis, comandos e saída>
Decisions: <aplicadas, pendentes ou none>
Changes/validation: <mudanças e validação ou none>
Blockers: <blocker ou none>
Resume operation: <operação ou none>
Resume stage: <stage/estado nativo ou none>
Resume owner: <owner ou none>
Next action: <ação e owner>
---

# Contrato de evidência

Todo resultado de papel usa o envelope antes de mutação de workflow, inclusive
no-op, erro, blocker e rejeição. Comentário não muda estado. Campos Resume são
`none` fora de blocker e obrigatórios quando `Blockers` não é `none`.

O source-set do issue-writer vive no body entre:

```text
<!-- code-flow:source-set:start -->
<!-- code-flow:source-set:end -->
```

`scripts/source-set-digest.py` calcula SHA-256 dos bytes entre os marcadores,
sem incluí-los: UTF-8, CRLF normalizado para LF e exatamente um LF final.
Complexity/Workflow ficam fora do bloco. Gate registra URL e digest; mudança do
bloco invalida aprovação, mudança apenas de metadata não. Digest divergente
invalida o gate até o source-set ser revisado novamente.

Resultados restantes são comentários append-only. O agente aplica a transição
causada por seu artefato; o orquestrador confirma. Decisão humana é publicada e
transicionada pelo orquestrador.

Implementação cita plano/outline, digest, base SHA, branch, commits/PR quando
aplicável e validação. Review cita range ou prova NO_CHANGES e veredito literal.
