> type: <issue | bug | feature | docs>
> complexity: <S | M | G | X | XL>
> agent: <issue-writer | orchestrator>
> phase_scope: issue / source-set
> sources_evidence: <padrão local, fontes, código ou testes>
> decisions: <complexity e spec impact com racional>
> changes_validation: <body criado ou atualizado>
> blockers: <blocker ou none>

<!-- code-flow:source-set:start -->

## Resume

<resultado humano esperado, próximo gate e motivo da entrega>

## Contexto (opcional)

Como `<usuário ou papel>`, quero `<capacidade>` para `<valor observável>`.
Para mudança técnica, descreva o contexto e o valor sem forçar user story.

## Objetivo

<resultado observável e critérios de sucesso claros para serem avaliados por gate humano>

## Limites

<fora de escopo, dependências e restrições>

## Impacto de spec

| Campo                 | Valor                          |
| --------------------- | ------------------------------ |
| Ação                  | `<create                       | update | not required>` |
| Fonte aceita          | `<URL/path ou not applicable>` |
| Padrão do repositório | `<form/template/guidance>`     |

### Proposta de spec (`create`)

<proposta completa ou not applicable; usar template padrão do repositório, se existir>

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
