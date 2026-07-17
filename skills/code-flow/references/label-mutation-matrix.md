# Matriz de mutação de labels

Comentário, template publicado ou veredito **nunca** substitui a mutação de
labels da issue. Cada agente é responsável por aplicar a transição de estado
correspondente à sua ação no mesmo turno, em fallback
([`scripts/transition-issue.sh`](../scripts/transition-issue.sh)) ou na transição
equivalente confirmada do workflow nativo, **depois de publicar a evidência
autorizadora**.

Publicar um comentário com o veredito e deixar o `stage:*`/`needs-human`
desatualizado é drift. Em fallback, recalcule o risco antes de interpretar o
stage atual; uma transição nunca pode rebaixar um hard trigger.

## Responsabilidade por agente

| Agente              | Quando mutar                                                            | Ação típica                                            |
| ------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------ |
| `issue-writer`      | Ao criar/atualizar a issue e ao receber `PEÇO AJUSTES` de fonte         | definir stage inicial conforme risco; `stage:needs-issue-fix` |
| `issue-reviewer`    | Ao publicar veredito                                                    | `--needs-human` em aprovação; `stage:needs-issue-fix`; `stage:blocked + needs-human` |
| `plan-writer`       | Ao publicar um ciclo de plano                                           | `stage:needs-plan` sem `needs-human`; `stage:blocked + needs-human` em risco externo |
| `plan-reviewer`     | Ao publicar veredito                                                    | `--needs-human` em aprovação mantendo `stage:needs-plan-review`; `stage:needs-plan-fix`; `stage:blocked + needs-human` |
| `executor`          | Ao iniciar execução e ao publicar evidência                             | `stage:in-progress --clear-needs-human`; `stage:needs-delivery-review`; `stage:blocked --needs-human` |
| `delivery-reviewer` | Ao publicar veredito e auditoria final                                 | `stage:ready-to-merge --needs-human` (sem auditoria); `stage:needs-changes`; `stage:blocked --needs-human` |

## Stage inicial por risco

| Risco recalculado                         | Stage inicial                          | `needs-human` |
| ----------------------------------------- | -------------------------------------- | ------------- |
| Mudança interna, `Spec impact: not required` | `stage:approved`                       | sim           |
| Mudança moderada, `Spec impact: not required` | `stage:needs-plan`                  | não           |
| Mudança moderada, `Spec impact: create/update` | `stage:spec-approval`              | sim           |
| Hard trigger                              | `stage:spec-approval`                  | não (até `issue-reviewer` aprovar) |

## Gates humanos sinalizados por `needs-human`

1. **Gate de fonte** (`stage:spec-approval`): em moderada `create/update` já na
   entrada; em hard trigger somente após o `issue-reviewer` aprovar.
2. **Gate de plano** (`stage:needs-plan-review`): somente após o veredito do
   `plan-reviewer`.
3. **Ordem de execução** (`stage:approved`): sempre.
4. **Merge** (`stage:ready-to-merge`): após a delivery review se nenhuma
   auditoria final for exigida, ou somente após a auditoria aplicável aprovar.

## Regras de remoção

- Ao devolver trabalho a um agente (correção), remova `needs-human`.
- Ao publicar um ciclo de plano, remova `needs-human` (o gate humano do plano
  ainda não foi aberto).
- Após o merge, limpe `stage:*` e `needs-human` com `--clear-stage
  --clear-needs-human`.

## Verificação

Use `--dry-run` para pré-validar e sempre confirme o resultado com:

```bash
gh issue view <N> --json labels
```

O helper rejeita drift (zero/múltiplos `stage:*`) por padrão; use `--allow-repair`
somente para reparar drift explicitamente.