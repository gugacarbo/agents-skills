# Workflow GitHub: seleção dinâmica nativa ou fallback

Plano, código, review e integração exigem issue de entrega/bug. Epic e tracker
não recebem mutação de entrega.

## Estado observável

`Complexity: S|M|G|X|XL` permanece no frontmatter da issue e fica fora do
source-set. `Workflow` não é persistido.

| Estado observado                                                      | Resultado obrigatório                                                              |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| exatamente um `stage:*`                                               | fallback ativo; retome o stage                                                     |
| header legado + exatamente um `stage:*`                               | fallback ativo; o stage é autoritativo e o header nunca seleciona native           |
| zero `stage:*` + mapeamento nativo `PASS`                             | native ativo automaticamente nesta entrada                                         |
| zero `stage:*` + mapeamento nativo `FAIL` em issue nova               | declare `NATIVE_INCOMPLETE`, inicialize fallback equivalente                       |
| múltiplos `stage:*`                                                   | `WORKFLOW_DRIFT`; pare e peça reparo                                               |
| header legado `Workflow: fallback`                                    | ignore para controle; preserve stage e remova somente em edição legítima do body   |
| header legado `Workflow: native` + zero `stage:*` + mapeamento `PASS` | ignore para controle; use native nesta entrada e remova somente em edição legítima |
| header legado `Workflow: native` + mapeamento `FAIL`                  | `NATIVE_INVALID`; pause e apresente migração equivalente para decisão humana       |

Nunca escreva `Workflow`. Com um stage, ele sempre prevalece sobre qualquer
header legado. Header legado não entra no digest e não é normalizado por uma
mutação sem outro motivo.

## Avaliação nativa

1. Descubra guidance, forms, labels, estados, gates, evidência e entregas
   recentes sem mutar.
2. Recalcule risco e Complexity antes de interpretar o estado.
3. Preencha `templates/16-native-workflow-mapping.md` com evidência por
   capacidade.
4. Todas as linhas PASS usam native automaticamente; qualquer FAIL em issue
   nova seleciona fallback e cria somente o stage equivalente necessário.

## Migração legada native → fallback

Para `NATIVE_INVALID`, não migre silenciosamente. O gate humano recebe o estado original,
fallback equivalente, estratégia de compensação e prova final para
uma migração explícita. Após
aceite, publique evidência, aplique um único `stage:*`, confirme labels/status
e só então remova o header legado em atualização legítima do body.

## Stages fallback

Exatamente um `stage:*` representa o próximo ator/gate enquanto a issue está
ativa. `needs-human` é ortogonal e existe somente quando o próximo ator é
humano; remova-o ao devolver trabalho a agente e limpe ambos após merge/close.

| Label                         | Próxima ação                                 |
| ----------------------------- | -------------------------------------------- |
| `stage:spec-approval`         | Review/gate de source-set conforme rigor.    |
| `stage:needs-issue-fix`       | Corrigir source-set.                         |
| `stage:needs-plan`            | Produzir plano formal.                       |
| `stage:needs-plan-review`     | Review independente e depois gate humano.    |
| `stage:needs-plan-fix`        | Novo ciclo de plano.                         |
| `stage:approved`              | Aguardar ordem explícita; criar worktree.    |
| `stage:in-progress`           | Implementar/corrigir escopo autorizado.      |
| `stage:needs-delivery-review` | Review independente da entrega.              |
| `stage:needs-changes`         | Executor corrige achados.                    |
| `stage:ready-to-merge`        | Auditoria aplicável e gate final.            |
| `stage:ready-to-close`        | Gate de fechamento para NO_CHANGES aprovado. |
| `stage:blocked`               | Resolver blocker pelo Resume publicado.      |

## Ownership e mutação

Agente aplica a transição causada pelo artefato/veredito que publicou;
orquestrador valida precondição, evidência e estado final. Decisões humanas
transicionam pelo orquestrador. Use `transition-issue.sh` com `--require-from`,
dry-run e confirmação por `gh issue view` no fallback.
