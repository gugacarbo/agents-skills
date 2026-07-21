---
agent: orchestrator
phase_scope: discovery / avaliação de workflow nativo
sources_evidence: <guidance, labels, estados, gates e entregas recentes>
decisions: <NATIVE_ELIGIBLE | NATIVE_INCOMPLETE | NATIVE_INVALID>
changes_validation: <mapeamento avaliado sem mutação>
blockers: <blocker ou none>
---

> <resumo humano da capacidade nativa e da consequência do resultado>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Snapshot avaliado

| Repositório | Issue     | Branch/base SHA | Momento       |
| ----------- | --------- | --------------- | ------------- |
| `<repo>`    | `<issue>` | `<branch/sha>`  | `<timestamp>` |

## Mapeamento do workflow nativo

| Capacidade exigida       | Estado/gate nativo | Evidência observada | Owner     | Resultado      | Impacto do FAIL       |
| ------------------------ | ------------------ | ------------------- | --------- | -------------- | --------------------- |
| Estado retomável         | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Source-set e gate humano | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Plano e gate humano      | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Execução isolada         | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Review independente      | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Merge e close explícitos | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |

**Veredito:** `NATIVE_ELIGIBLE` somente com todas as linhas PASS; caso
contrário `NATIVE_INCOMPLETE`. A seleção e a mutação pertencem às instruções,
não a este template.

## Migração proposta

Preencha somente em `NATIVE_INVALID`: estado original, fallback equivalente,
estratégia de compensação e prova final antes de pedir decisão humana.
