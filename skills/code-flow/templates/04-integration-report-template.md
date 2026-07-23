> agent: integrator
> run_id: <uuid>
> event: integration-result
> state_before: stage:integration-authorized + stage:in-progress
> state_after: <closed/labels-cleared | stage:needs-delivery-review | stage:needs-changes | stage:blocked + needs-human>
> sources_evidence: <review, PR/NO_CHANGES, rebase, checks e issue>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

## Resume

<MERGED_AND_CLOSED | CLOSED_NO_CHANGES | REVIEW_REQUIRED | CHANGES_REQUIRED | BLOCKED>

## Decisão de operação

| Entrada | Operação escolhida | Evidência     |
| ------- | ------------------ | ------------- |
| `<PR    | NO_CHANGES>`       | `<merge+close | close>` | `<URL/prova>` |

## Verificação de rebase

| Base anterior | Head anterior | Rebase necessário | Drift material | Motivo        |
| ------------- | ------------- | ----------------- | -------------- | ------------- |
| `<sha>`       | `<sha>`       | `<sim/não>`       | `<sim/não>`    | `<evidência>` |

| Conflitos         | Decisão  | Patch equivalente           | Checks       | Base/Head resultantes |
| ----------------- | -------- | --------------------------- | ------------ | --------------------- |
| `<arquivos/none>` | `<ação>` | `<range-diff/patch-id/n/a>` | `<comandos>` | `<sha/sha>`           |

## Resultado remoto

| Merge SHA   | PR          | Issue fechada  | Labels limpas | Confirmação |
| ----------- | ----------- | -------------- | ------------- | ----------- |
| `<sha/n/a>` | `<URL/n/a>` | `<URL/estado>` | `<lista>`     | `<prova>`   |

## Falha e recuperação

| Causa             | Estado preservado | Operação de retomada |
| ----------------- | ----------------- | -------------------- |
| `<falha ou none>` | `<estado>`        | `<ação>`             |
