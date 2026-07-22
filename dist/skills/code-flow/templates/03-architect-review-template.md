# Relatório de arquitetura da issue `<#n>` — ciclo `<k>/3`

> agent: architect
> sources_evidence: <issue, padrão local, fontes aceitas, código/testes, base SHA>
> project_guidance: <paths nearest-wins e comandos; ou none found + busca>

<!-- code-flow:architect-review:start -->

## Resume

<resultado esperado, decisão de spec/ADR, gaps e blockers, e próximo gate>

## Objetivo

<resultado que esta entrega deve produzir, partindo da issue>

## Limites

<fora de escopo, dependências e restrições>

Base SHA: `<sha>`

## Decisão de spec/ADR

- **Ação:** `<create | update | not required>`
- **Fonte aceita:** `<URL/path ou not applicable>`
- **Padrão do repositório:** `<form/template/guidance ou none>`

### Proposta de spec (`create`)

<conteúdo completo da spec/ADR a ser criada; use o template do repositório quando existir>

### Diff de spec (`update`)

```diff
- <antes>
+ <depois>
```

### Racional (`not required`)

<por que nenhuma especificação documentada precisa mudar>

## Gaps, necessidades e blockers

| Item         | Tipo                     | Detalhe       | Recomendação |
| ------------ | ------------------------ | ------------- | ------------ |
| `<gap/need>` | `<gap, need ou blocker>` | `<descrição>` | `<ação>`     |

## Casos de borda e riscos

| Gatilho, caso ou risco | Resposta/mitigação | Rollback ou `n/a` |
| ---------------------- | ------------------ | ----------------- |
| `<caso>`               | `<ação>`           | `<ação>`          |

## Prova de rollback para migração — somente quando aplicável

| Comando, simulação ou demonstração | Estado restaurado esperado |
| ---------------------------------- | -------------------------- |
| `<prova executável>`               | `<critério binário>`       |

## Blocker e retomada — somente se aplicável

- Operação: `plan`
- Estado a retomar: `<stage:* ou estado nativo>`
- Responsável: `<papel | humano | orquestrador>`
- Impedimento: `<fato e evidência>`

_Este é o único comentário canônico do relatório de arquitetura. Em revisões,
edite-o in-place e publique separadamente apenas o resumo breve das alterações.
A spec/ADR quando `create/update` é materializada no PR do executor, não aqui._

<!-- code-flow:architect-review:end -->
