---
agent: orchestrator
phase_scope: integração ou fechamento
sources_evidence: <gate humano, PR/range, checks e issue>
decisions: <decisão humana recebida>
changes_validation: <resultado mecânico e confirmação>
blockers: <blocker ou none>
---

> <resultado humano da integração ou fechamento e estado final confirmado>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Pré-condições confirmadas

| Gate humano | PR/range e checks | Branch alvo | Issue   |
| ----------- | ----------------- | ----------- | ------- |
| `<decisão>` | `<evidência>`     | `<branch>`  | `<URL>` |

## Integração com diff

| Base SHA | Head SHA | Merge SHA | PR      | Confirmação pós-operação |
| -------- | -------- | --------- | ------- | ------------------------ |
| `<sha>`  | `<sha>`  | `<sha>`   | `<URL>` | `<alvo, issue e labels>` |

## Fechamento sem diff: `NO_CHANGES`

| Evidência aprovada | Issue fechada | Workflow limpo                  | Confirmação |
| ------------------ | ------------- | ------------------------------- | ----------- |
| `<URL>`            | `<URL>`       | `<stage/needs-human removidos>` | `<prova>`   |

## Falha e recuperação

| Causa             | Estado preservado | Evidência | Operação de retomada |
| ----------------- | ----------------- | --------- | -------------------- |
| `<falha ou none>` | `<estado>`        | `<saída>` | `<operação>`         |

_Auditoria e gate humano são artefatos separados. Falha transitória não registra
sucesso nem fecha a issue._
