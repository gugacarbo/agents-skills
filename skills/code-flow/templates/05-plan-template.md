# Plano da issue `<#n>` — ciclo `<k>/3`

> agent: architect
> sources_evidence: <issue, URL do gate, digest aprovado e base SHA>

<!-- code-flow:canonical-plan:start -->

## Resume

<resultado esperado, abordagem e próximo gate>

## Objetivo

<resultado que esta entrega deve produzir>

## Limites

<fora de escopo, dependências e restrições>

Source-set aprovado: `<URL do gate + digest atual confirmado>`

Base SHA: `<sha>`

## Abordagem de implementação

| Área ou arquivo | Mudança planejada | Motivo      | Dependências     |
| --------------- | ----------------- | ----------- | ---------------- |
| `<área>`        | `<ação>`          | `<por quê>` | `<item ou none>` |

## Critérios e validação

| Critério                        | Evidência anterior/falha       | Ação de validação       | Resultado binário esperado |
| ------------------------------- | ------------------------------ | ----------------------- | -------------------------- |
| `<código/docs/config/operação>` | `<RED, antes ou estado atual>` | `<comando/walkthrough>` | `<GREEN/depois/PASS>`      |

## Casos de borda, riscos e rollback

| Gatilho, teste ou risco | Resposta/mitigação | Rollback ou `n/a` |
| ----------------------- | ------------------ | ----------------- |
| `<caso>`                | `<ação>`           | `<ação>`          |

## Prova de rollback para migração — somente quando aplicável

| Comando, simulação ou demonstração | Estado restaurado esperado |
| ---------------------------------- | -------------------------- |
| `<prova executável>`               | `<critério binário>`       |

## Blocker e retomada — somente se aplicável

- Operação: `plan`
- Estado a retomar: `<stage:* ou estado nativo>`
- Responsável: `<papel | humano | orquestrador>`
- Impedimento: `<fato e evidência>`

_Este é o único comentário canônico do plano. Em revisões, edite-o in-place e
publique separadamente apenas o resumo breve das alterações._

<!-- code-flow:canonical-plan:end -->
