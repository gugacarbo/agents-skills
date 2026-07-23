# Relatório de arquitetura da issue `<#n>` — ciclo `<k>`

> agent: architect
> run_id: <uuid>
> event: architecture-result
> state_before: stage:needs-architect + stage:in-progress
> state_after: <stage:ready-for-execution | stage:awaiting-execution-approval + needs-human | stage:blocked + needs-human>
> sources_evidence: <issue, guidance, código/testes e Base SHA>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

<!-- code-flow:architect-review:start -->

## Resume

<resultado, decisão de spec/ADR, gaps/blockers e próximo gate>

## Objetivo e limites

<resultado, fora de escopo, dependências e restrições>

Base SHA: `<sha>`

## Decisão de spec/ADR

- **Ação:** `<create | update | not required>`
- **Fonte aceita:** `<URL/path ou not applicable>`
- **Padrão do repositório:** `<form/template/guidance ou none>`

### Proposta de spec (`create`)

<conteúdo completo>

### Diff de spec (`update`)

```diff
- <antes>
+ <depois>
```

### Racional (`not required`)

<por que nenhuma spec/ADR muda>

## Gaps, necessidades e blockers

| Item     | Tipo  | Detalhe | Recomendação |
| -------- | ----- | ------- | ------------ |
| `<item>` | `<gap | need    | blocker>`    | `<descrição>` | `<ação>` |

## Casos de borda e riscos

| Caso/risco | Mitigação | Rollback ou n/a |
| ---------- | --------- | --------------- |
| `<caso>`   | `<ação>`  | `<prova>`       |

## Prova de rollback para migração

<prova executável ou not applicable>

## Blocker e retomada

- Estado a retomar: `<stage:needs-architect ou not applicable>`
- Responsável: `<architect | human | not applicable>`
- Impedimento: `<fato/evidência ou not applicable>`

<!-- code-flow:architect-review:end -->
