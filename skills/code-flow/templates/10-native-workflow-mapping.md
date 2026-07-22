> agent: orchestrator
> sources_evidence: <guidance, labels, estados, gates e entregas recentes>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<resumo humano da capacidade nativa e da consequência do resultado>

## Snapshot avaliado

| Repositório | Issue     | Branch/base SHA | Momento       |
| ----------- | --------- | --------------- | ------------- |
| `<repo>`    | `<issue>` | `<branch/sha>`  | `<timestamp>` |

## Mapeamento do workflow nativo

| Capacidade exigida       | Estado/gate nativo | Evidência observada | Owner     | Resultado      | Impacto do FAIL       |
| ------------------------ | ------------------ | ------------------- | --------- | -------------- | --------------------- |
| Estado retomável         | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Source-set e gate humano | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Arquitetura e gate       | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Execução isolada         | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Review independente      | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |
| Merge e close explícitos | `<estado>`         | `<prova>`           | `<owner>` | `PASS \| FAIL` | `<bloqueio/fallback>` |

**Veredito:** `NATIVE_ELIGIBLE` somente com todas as linhas PASS; caso
contrário `NATIVE_INCOMPLETE`. A seleção e a mutação pertencem às instruções,
não a este template.

## Migração proposta

Preencha somente em `NATIVE_INVALID`: estado original, fallback equivalente,
estratégia de compensação e prova final antes de pedir decisão humana.
