---
agent: executor
phase_scope: <plano/outline e escopo>
sources_evidence: <plano/outline, digest, commits, PR e comandos>
decisions: <aplicadas ou none>
changes_validation: <arquivos, comandos e resultados>
blockers: <blocker ou none>
---

> <DONE | DONE_WITH_CONCERNS | NO_CHANGES | BLOCKED — resumo humano e conclusão esperada do reviewer>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Resultado para decisão

<o que mudou, resultado, ressalvas e conclusão que o reviewer deve avaliar>

## Rastreabilidade imutável

| Base SHA | Head SHA | Range/PR              | Ambiente     |
| -------- | -------- | --------------------- | ------------ |
| `<sha>`  | `<sha>`  | `<base..head ou URL>` | `<ambiente>` |

## Critérios de aprovação e evidências

| Critério     | Evidência         | Resultado             |
| ------------ | ----------------- | --------------------- |
| `<critério>` | `<comando/prova>` | `PASS \| FAIL \| n/a` |

## Reconciliação de escopo

| Planejado | Implementado | Não feito / motivo |
| --------- | ------------ | ------------------ |
| `<item>`  | `<item>`     | `<none ou motivo>` |

## Com diff: `DONE` ou `DONE_WITH_CONCERNS`

| Arquivo  | Mudança       | Validação |
| -------- | ------------- | --------- |
| `<path>` | `<descrição>` | `<prova>` |

## Sem diff: `NO_CHANGES`

<consulta objetiva que demonstra escopo já satisfeito; confirme ausência de commit e PR vazio.>

## Blocked

<impedimento, decisão/acesso necessário e evidência disponível ou not applicable>

## Rollback de migração

| Gatilho      | Prova executada   | Estado restaurado |
| ------------ | ----------------- | ----------------- |
| `<condição>` | `<comando/saída>` | `<estado>`        |

## Problemas encontrados

| Nível                                             | Problema     | Solução aplicada | Riscos pendentes | Investigação posterior                                                                                             |
| ------------------------------------------------- | ------------ | ---------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------ |
| `Critical \| Important \| Minor \| Cannot verify` | `<problema>` | `<solução>`      | `<risco>`        | `[Abrir issue](https://github.com/<owner>/<repo>/issues/new?title=<titulo-url-encoded>&body=<resumo-url-encoded>)` |

_Apenas o link abre um formulário pré-preenchido; não cria issue automaticamente.
NO_CHANGES não cria commit/PR vazio e ainda exige review independente._
