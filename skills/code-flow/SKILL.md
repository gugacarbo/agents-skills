---
name: code-flow
description: "Coordinate issue-based repository deliveries with adaptive risk, repository workflow discovery, independent reviews, human gates, worktree execution, and explicit merge. Use for non-trivial delivery issues or batches; start from a named semantic operation only when the user explicitly requests it."
metadata:
  user-invocable: true
---

# code-flow

Coordene entregas por issue com rigor proporcional ao risco. O orquestrador
descobre contexto, recalcula risco, escolhe uma única máquina de estado e
despacha somente os papéis necessários. Ele não escreve plano, não revisa o
próprio trabalho e não implementa.

Não há modo sem issue. Não persista o nome do perfil em label, body,
comentário ou arquivo; ele é uma decisão efêmera recalculada em todo início e
resume conforme [`references/risk-profiles.md`](references/risk-profiles.md).

## Comandos

| Invocação                                                    | Comportamento                                                                |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `/code-flow`                                                 | Exige uma issue de entrega; ofereça `issue create`, `issue <#N>` ou `batch`. |
| `/code-flow issue create`                                    | Descobre contexto, classifica risco e cria/preenche uma issue elegível.      |
| `/code-flow create-issue`                                    | Alias de `/code-flow issue create`.                                          |
| `/code-flow issue <#N\|URL> [operation]`                     | Recalcula risco, resolve workflow e retoma uma issue elegível.               |
| `/code-flow batch <#N\|URL>... --from <operation>`           | Executa trilhas isoladas de issues elegíveis.                                |
| `/code-flow brainstorm`                                      | Oferece explicitamente o prompt de brainstorm; só roda após aceite.          |
| `/code-flow <plan\|dispatch\|review\|integrate>`             | Exige issue elegível e respeita gates aplicáveis.                            |
| `/code-flow tool <doctor\|review-package\|transition-issue>` | Executa um helper e para.                                                    |

Helpers: [`scripts/doctor.sh`](scripts/doctor.sh),
[`scripts/review-package.sh`](scripts/review-package.sh) e
[`scripts/transition-issue.sh`](scripts/transition-issue.sh).

## Ordem obrigatória

1. Confirme que o alvo é uma issue de entrega/bug, não Epic ou tracker.
2. Descubra guidance, issue forms, labels, workflow documentado, ADRs/specs e
   entregas recentes antes de escrever.
3. Recalcule o risco antes de interpretar labels ou comentários. O nível mais
   restritivo vence; só promoção automática é permitida.
4. Resolva uma única máquina de estado conforme
   [`references/github-flow.md`](references/github-flow.md): qualquer
   `stage:*` fixa fallback; workflow nativo elegível exige opt-in explícito.
5. Carregue a operação semântica ativa e despache somente os papéis exigidos.
6. Publique evidência antes de toda mutação. Comentário não muda status.
7. Execute somente em worktree isolada; merge continua uma decisão humana
   explícita.

Se risco novo exigir mais rigor, pare, registre a promoção, invalide gates
insuficientes e retome no primeiro gate que passou a ser obrigatório. Hard
trigger nunca pode ser rebaixado por urgência, preferência ou autoridade.

## Operações

| Operação               | Carregar                                                     |
| ---------------------- | ------------------------------------------------------------ |
| Contexto e resume      | [`phases/context.md`](phases/context.md)                     |
| Issue e source-set     | [`phases/issue.md`](phases/issue.md)                         |
| Plano                  | [`phases/plan.md`](phases/plan.md)                           |
| Dispatch               | [`phases/dispatch.md`](phases/dispatch.md)                   |
| Review                 | [`phases/review.md`](phases/review.md)                       |
| Integração             | [`phases/integrate.md`](phases/integrate.md)                 |
| Brainstorm condicional | [`prompts/brainstorm.md`](prompts/brainstorm.md)             |
| Companheiro visual     | [`prompts/visual-companion.md`](prompts/visual-companion.md) |

Antes de retomar ou mutar fallback, leia
[`references/orchestrator-cheatsheet.md`](references/orchestrator-cheatsheet.md).
Sem `stage:*`, publique o mapeamento de
[`templates/16-native-workflow-mapping.md`](templates/16-native-workflow-mapping.md)
antes de pedir opt-in ou selecionar fallback.
Antes de publicar evidência ou revisar, leia
[`templates/evidence-contract-template.md`](templates/evidence-contract-template.md).

## Papéis permitidos

| Papel               | Responsabilidade                                                |
| ------------------- | --------------------------------------------------------------- |
| `issue-writer`      | Contexto, issue e source-set condicional.                       |
| `issue-reviewer`    | Review independente do source-set quando o risco máximo exigir. |
| `plan-writer`       | Plano de implementação para mudanças que exigem plano formal.   |
| `plan-reviewer`     | Review independente do plano.                                   |
| `executor`          | Outline compacto quando aplicável e implementação autorizada.   |
| `delivery-reviewer` | Review da implementação e auditoria final quando aplicável.     |

Esses são os únicos papéis publicados, não uma lista de invocações
obrigatórias. Ninguém revisa, aprova ou audita trabalho próprio. Não criar
trackers de task, registries paralelos ou estado local de workflow.

Uma iniciativa com múltiplos resultados independentes usa
[`templates/01-epic.md`](templates/01-epic.md) somente após escolha explícita do
usuário. O Epic é tracking; cada filha segue este fluxo como entrega própria.
