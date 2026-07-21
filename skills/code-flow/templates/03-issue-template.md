---
type: <issue | bug | feature | docs>
complexity: <S | M | G | X | XL>
agent: <issue-writer | orchestrator>
phase_scope: issue / source-set
sources_evidence: <padrão local, fontes, código ou testes>
decisions: <complexity e spec impact com racional>
changes_validation: <body criado ou atualizado>
blockers: <blocker ou none>
---

> <resultado humano esperado, próximo gate e motivo da entrega>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

<!-- code-flow:source-set:start -->

## Contexto e valor (opcional)

Como `<usuário ou papel>`, quero `<capacidade>` para `<valor observável>`.
Para mudança técnica, descreva o contexto e o valor sem forçar user story.

## Objetivo

<resultado fechável e critérios de sucesso>

## Limites

<fora de escopo, dependências e restrições>

## Impacto de spec

| Campo                 | Valor                          |
| --------------------- | ------------------------------ |
| Ação                  | `<create                       | update | not required>` |
| Fonte aceita          | `<URL/path ou not applicable>` |
| Padrão do repositório | `<form/template/guidance>`     |

### Proposta de spec (`create`)

<proposta completa ou not applicable>

### Diff de spec (`update`)

```diff
- <antes>
+ <depois>
```

<racional concreto para `not required`, quando aplicável>

<!-- code-flow:source-set:end -->

## Relações

| Epic           | GitHub            |
| -------------- | ----------------- |
| `#<n> ou none` | `subissue of #<n> | standalone delivery issue` |
