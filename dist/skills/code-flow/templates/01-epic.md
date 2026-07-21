---
type: epic
agent: orchestrator
phase_scope: epic / tracking e coordenação
sources_evidence: <filhas, dependências, métricas e decisões>
decisions: <aceite, replanejamento ou fechamento>
changes_validation: <checkpoint e situação das filhas>
blockers: <blocker ou none>
owner: <time ou pessoa>
status: <rascunho | em andamento | concluído>
---

> <resumo humano da iniciativa, resultado esperado e motivo para coordená-la>

## Resume

`none`, ou, em blocker: operação, estado a retomar e responsável.

## Incluído

<capacidades ou resultados de entrega incluídos>

## Fora de escopo

<exclusões explícitas>

## Restrições

<tempo, compatibilidade, acesso, segurança ou produto>

## Resultado e medidas de sucesso

| Resultado observável | Medida, alvo e método |
| -------------------- | --------------------- |
| `<resultado>`        | `<métrica>`           |

## Issues de entrega filhas

| Issue  | Resultado            | Owner           | Dependências   | Situação        | Próximo marco    |
| ------ | -------------------- | --------------- | -------------- | --------------- | ---------------- |
| `#<n>` | `<entrega fechável>` | `<time/pessoa>` | `<#n ou none>` | `<link/resumo>` | `<gate ou data>` |

Cada filha usa `templates/03-issue-template.md` e percorre o fluxo completo.
Este Epic não recebe `Complexity`, `Workflow`, `stage:*` nem `needs-human`.

## Plano de coordenação

| Decisão, dependência ou risco transversal | Responsável | Desbloqueio ou ponto de review |
| ----------------------------------------- | ----------- | ------------------------------ |
| `<item>`                                  | `<owner>`   | `<condição ou link>`           |

## Checkpoint de conclusão

- [ ] Filhas in-scope fechadas ou removidas por decisão registrada.
- [ ] Medidas de sucesso avaliadas.
- [ ] Decisões transversais abertas resolvidas ou aceitas.

Apresente o gate humano compartilhado com `Fechar Epic / Replanejar / Aguardar`.
As regras de fechamento vivem nas instruções de Epic; nunca feche automaticamente.
