# Workflow GitHub: nativo ou fallback

Toda entrega usa uma issue elegível. Epic, auditoria e tracker genérico ficam
fora do fluxo e não recebem mutação.

## Resolver a máquina de estado

1. Descubra guidance, forms, labels, estados, gates, evidência e entregas
   recentes sem mutar nada.
2. Recalcule o risco antes de interpretar o estado.
3. Se existir qualquer `stage:*`, use fallback e nunca ofereça workflow nativo.
4. Sem `stage:*`, considere o workflow nativo somente se ele mapear de forma
   inequívoca estado retomável, gates exigidos, evidência, review independente
   e merge explícito.
5. Para issue nova, apresente o mapeamento e peça opt-in. Sem `Yes`, use
   fallback integralmente.
6. Em retomada nativa, revalide e peça novo opt-in. O aceite não é persistido.
   Sem reconfirmação, recusa ou incompatibilidade, encerre a atuação da skill
   sem comentário, label, fechamento ou outra mutação.

Nunca migre automaticamente entre máquinas nem misture marcadores nativos e
fallback na mesma execução. `transition-issue.sh` serve exclusivamente ao
fallback e não decide qual workflow usar.

Qualquer `stage:*` existente fixa o fallback.

## Stages fallback

Exatamente um `stage:*` representa o próximo gate enquanto a issue está ativa.
O significado de `stage:approved` depende do risco recalculado: para mudança
interna sem plano formal, significa “racional no-spec válido, aguardando ordem
de execução”; nos demais caminhos, significa “plano aprovado”.

| Label | Próxima ação |
| --- | --- |
| `stage:spec-approval` | Review/gate de source-set exigido pelo risco. |
| `stage:needs-issue-fix` | `issue-writer` corrige o source-set. |
| `stage:needs-plan` | `plan-writer` produz plano formal. |
| `stage:needs-plan-review` | Review independente e gate humano do plano. |
| `stage:needs-plan-fix` | Corrigir o plano e revisar novamente. |
| `stage:approved` | Recalcular risco; aguardar ordem explícita e criar worktree. |
| `stage:in-progress` | Executor implementa o escopo autorizado. |
| `stage:needs-delivery-review` | Review independente da implementação. |
| `stage:needs-changes` | Executor corrige achados e retorna à review. |
| `stage:ready-to-merge` | Auditoria aplicável, PR aprovado e merge explícito. |
| `stage:blocked` | Decisão humana ou dependência externa necessária. |

`needs-human` é ortogonal e marca o gate humano atual. Após merge, remova
`stage:*` e `needs-human`.

## Entrada por risco

- Mudança interna no-spec: criar issue diretamente em
  `stage:approved + needs-human`.
- Mudança moderada com `Spec impact: not required`: entrar em
  `stage:needs-plan`.
- Mudança moderada `create/update`: entrar em `stage:spec-approval`; após
  aprovação humana, seguir a `stage:needs-plan`.
- Hard trigger: entrar em `stage:spec-approval`, exigir `issue-reviewer` e gate
  humano antes do plano.

## Mutação fallback

Publique a evidência autorizadora e então use o helper no mesmo turno:

```bash
scripts/transition-issue.sh 42 --require-from stage:needs-plan --to stage:needs-plan-review
scripts/transition-issue.sh 42 --to stage:blocked --needs-human --allow-repair
scripts/transition-issue.sh 42 --clear-stage --clear-needs-human
```

O helper remove stages antigos, cria labels allow-listed ausentes somente em
execução real, aplica o alvo e confirma via `gh issue view <n> --json labels`.
`--dry-run` nunca cria nem altera labels. Mencionar um stage em texto não é
mudança de estado.

## Drift e promoção

No fallback, zero ou múltiplos stages em issue já gerenciada são drift. Antes
de reparar, confirme que não há workflow nativo aguardando opt-in. Se o risco
recalculado tornou o stage insuficiente, registre a promoção e mova para o
primeiro gate obrigatório; nunca trate `approved` antigo como aprovação do
escopo novo.
