# super-planning

Crie planos de implementação decompostos em tarefas e execute-os via subagentes — sequenciais ou paralelos — para reduzir a pressão de contexto no agente principal.

## Modos de Invocação

| Comando                      | O que faz                                         |
| ---------------------------- | ------------------------------------------------- |
| `/super-planning`            | Executa o fluxo completo padrão (todas as fases). |
| `/super-planning brainstorm` | Inicia na Fase 1 (Brainstorm) e continua.         |
| `/super-planning spec`       | Inicia na Fase 2 (Spec) e continua.               |
| `/super-planning plan`       | Inicia na Fase 3 (Plan) e continua.               |
| `/super-planning decompose`  | Inicia na Fase 4 (Decompose) e continua.          |
| `/super-planning dispatch`   | Inicia na Fase 5 (Dispatch) e continua.           |
| `/super-planning review`     | Inicia na Fase 6 (Review) e continua.             |
| `/super-planning integrate`  | Inicia na Fase 7 (Integrate).                     |

## Fases

| Fase          | O que produz                                                    | Ponto de verificação                                                                                       |
| ------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| 1. Brainstorm | Requisitos, restrições, decisões de design                      | Fluxo completo de brainstorm integrado                                                                     |
| 2. Spec       | `docs/specs/NNNN-<nome>-spec.md`                                | Aprovação do usuário                                                                                       |
| 3. Plan       | `docs/plans/NNNN-<nome>.md`                                     | Checklist de auto-revisão                                                                                  |
| 4. Decompose  | `docs/jobs/NNNN-<nome>/super-plan.json` e `progress-ledger.md` | Bootstrap dos helpers, descoberta de perfis `general/deep/quick`, `task_profile` por task, e ledger gerado |
| 5. Dispatch   | Trabalho dos subagentes                                         | Checks pré-voo, validação de `agent/model`, e fallback para default                                        |
| 6. Review     | Revisão em dois estágios                                        | Issues críticos/importantes devem ser corrigidos                                                           |
| 7. Integrate  | Revisão final, preparação para merge                            | Suite de testes completa passa                                                                             |

## Documentação Detalhada

- [Fluxos de trabalho e diagramas](docs/workflows.md) — Diagramas Mermaid detalhados de decisão, execução e revisão
- [Regras e red flags](docs/red-flags.md) — Regras críticas que não devem ser violadas
- [Guia de subagentes](docs/subagent-guide.md) — Seleção de modelo, compressão de contexto e handoff
- [Estrutura de arquivos](docs/file-structure.md) — Organização de diretórios e arquivos gerados

## Fluxo Rápido

1. **Brainstorm**: `/super-planning brainstorm` — Explore o problema e defina o escopo
2. **Spec**: `/super-planning spec` — Escreva a especificação e obtenha aprovação
3. **Plan + Decompose**: `/super-planning plan` — Crie o plano e decomponha em tarefas
4. **Dispatch**: `/super-planning dispatch` — Envie tarefas para subagentes
5. **Review + Integrate**: `/super-planning review` — Revise e integre o resultado

> **Nota para o agente**: Comece pelo [`SKILL.md`](SKILL.md) para o ponto de entrada de roteamento. Instruções detalhadas das fases estão em [`phases/`](phases/).
