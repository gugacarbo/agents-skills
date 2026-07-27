> agent: integrator
> run_id: <uuid>
> event: integration-result
> state_before: stage:integration-authorized + stage:in-progress
> state_after: <closed/labels-cleared | destino>
> sources_evidence: <review, PR/NO_CHANGES, rebase, checks e issue>
> project_guidance: <paths e comandos>

## Resume

<MERGED_AND_CLOSED | CLOSED_NO_CHANGES | REVIEW_REQUIRED | CHANGES_REQUIRED | BLOCKED>

## Decisão de operação

| Entrada | Operação     | Evidência     |
| ------- | ------------ | ------------- |
| `<PR    | NO_CHANGES>` | `<merge+close | close>` | `<prova>` |

## Verificação de rebase

| Base/Head anteriores | Rebase   | Drift material | Conflitos         | Patch equivalente | Checks       | Base/Head finais |
| -------------------- | -------- | -------------- | ----------------- | ----------------- | ------------ | ---------------- |
| `<sha/sha>`          | `<ação>` | `<sim/não>`    | `<arquivos/none>` | `<prova/n/a>`     | `<comandos>` | `<sha/sha>`      |

## Resultado remoto

| Merge SHA   | PR          | Issue fechada | Labels limpas | Confirmação |
| ----------- | ----------- | ------------- | ------------- | ----------- |
| `<sha/n/a>` | `<URL/n/a>` | `<estado>`    | `<lista>`     | `<prova>`   |

## Falha e recuperação

| Causa             | Estado preservado | Retomada |
| ----------------- | ----------------- | -------- |
| `<falha ou none>` | `<estado>`        | `<ação>` |
