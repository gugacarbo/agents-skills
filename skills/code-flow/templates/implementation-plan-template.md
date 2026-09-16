<!--
Publique como Markdown cru, exatamente um par de marcadores. Este é o plano
aprovado que o executor seguirá; não inclua alterações de código neste comentário.
-->
> agent: planner
> run_id: <uuid>
> event: implementation-plan-result
> state_before: stage:needs-plan + stage:in-progress
> state_after: <stage:ready-for-execution | stage:blocked>
> sources_evidence: <issue, arquitetura aprovada, guidance e Base SHA>
> project_guidance: <paths nearest-wins e comandos>

<!-- code-flow:event:v1 {"event_id":"<uuid>","run_id":"<uuid>","role":"planner","event":"implementation-plan-result"} -->

## Resume

<plano publicado, estado de aprovação, como o executor deve retomar>

<!-- code-flow:implementation-plan:start -->

## Base SHA, escopo e definição de pronto

Base SHA: `<sha>`

Escopo: <limites autorizados pela issue e arquitetura>

Definição de pronto: <resultados observáveis e provas exigidas>

## Ondas e tarefas

### Onda 1 — `<nome>`

Paralelismo seguro: <sim/não e racional; arquivos sem sobreposição e dependências satisfeitas>

| Task ID | Owner/subagent | Dependências | Áreas/arquivos esperados | Validação |
| ------- | -------------- | ------------ | ------------------------- | --------- |
| `T1`    | `<owner>`       | `<none ou IDs>` | `<paths>`              | `<comandos/provas>` |

### Onda 2 — `<nome>`

Paralelismo seguro: <sim/não e racional>

| Task ID | Owner/subagent | Dependências | Áreas/arquivos esperados | Validação |
| ------- | -------------- | ------------ | ------------------------- | --------- |
| `T2`    | `<owner>`       | `<T1>`       | `<paths>`                 | `<comandos/provas>` |

## Barreiras de integração

| Barreira | Tarefas/ondas | Condição de entrada | Prova/owner |
| -------- | ------------- | ------------------- | ----------- |
| `<ID>`   | `<IDs>`       | `<dependência>`     | `<prova>`   |

## Validação global

<ordem dos checks, testes por onda, checks finais e evidência esperada>

## Rollback/reconciliação

| Cenário | Rollback | Reconciliação / decisão |
| ------- | -------- | ----------------------- |
| `<drift, falha ou risco>` | `<ação segura>` | `<owner, evidência e retorno ao architect se necessário>` |

## Handoff final

Responsável: `<executor/owner>`

Próximo estado: `stage:ready-for-execution`

Instruções: <como seguir as ondas, dependências, barreiras e registrar desvios materiais>

<!-- code-flow:implementation-plan:end -->
