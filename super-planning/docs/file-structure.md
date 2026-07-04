# Estrutura de Arquivos

Organização de diretórios e arquivos gerados pelo super-planning.

## Estrutura de Handoff

```mermaid
flowchart TB
    subgraph docs/
        subgraph specs/
            SPEC[NNNN-<feature-name>-spec.md<br/>Spec - contract with user]
        end
        subgraph plans/
            PLAN[NNNN-<feature-name>.md<br/>Plan - linked to spec by number]
        end
        subgraph tasks/NNNN-<feature-name>/
            TASKS[super-plan.json<br/>Created and mutated by .super-planning/super-plan.sh<br/>Single source of truth]
            LEDGER[progress-ledger.md<br/>Regenerated from super-plan.json]
            subgraph Task-A-0001/
                REPORT1[report.md<br/>Subagent output]
                REVIEW1[review-package.diff.md<br/>Reviewer input]
                LOG1[progress.log<br/>Task progress]
                HELPER1[log-task.sh<br/>Task-local logger]
            end
        end
    end
    SPEC --> PLAN
    PLAN --> TASKS
```

## Relação entre Arquivos

- **Spec** (`docs/specs/NNNN-<nome>-spec.md`): Contrato com o usuário — o que será construído
- **Plan** (`docs/plans/NNNN-<nome>.md`): Vinculado à spec pelo número — como será construído
- **super-plan.json** (`docs/tasks/NNNN-<nome>/super-plan.json`): Fonte única da verdade, criado e modificado por `.super-planning/super-plan.sh`
- **progress-ledger.md**: Regenerado a partir do `super-plan.json` a cada escrita
- **Task dirs**: Cada tarefa tem seu próprio diretório com `report.md`, `review-package.diff.md`, `progress.log` e `log-task.sh`
