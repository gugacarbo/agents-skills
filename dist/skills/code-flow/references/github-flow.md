# Contrato do fluxo GitHub

Use esta referência depois que a issue de entrega existir. As Fases 0–2 investigam
e decidem o impacto de spec antes da criação; a issue resultante carrega a
proposta de ADR/spec ou o racional no-spec para aprovação humana. Não escrever
nem atualizar o ADR/spec formal primeiro.

## Elegibilidade e criação da issue

Só uma issue de entrega existente ou uma bug issue com entrega de implementação
pode usar este fluxo. Uma issue umbrella, auditoria ou tracking genérico é
inelegível: explique por quê e pare sem adicionar, remover ou substituir qualquer
label `stage:*`. `batch` recebe apenas números/URLs de issues existentes.

Quando este fluxo cria ou preenche uma issue de entrega, prepare o contexto do
repositório e uma proposta no padrão do repositório primeiro. Crie a issue (ou
edite o body de uma existente, incl. draft) em `stage:spec-approval` mais
`needs-human`; o **body** da issue deve incluir o conteúdo proposto de ADR/spec
ou declarar `Spec impact: not required` com o motivo, e pedir aprovação humana
explicitamente. O `issue-writer` nunca publica o source-set em comentário.
Após essa aprovação, materialize o ADR/spec (quando necessário) e anexe seu link
imutável antes de planejar.

## Stages precisos

Exatamente uma label `stage:*` aplica-se a uma issue de entrega. Ela identifica
o próximo gate; comentários append-only retêm o status exato do trabalho.

| Label                         | Significado preciso                                                                                 | Próxima ação                                                                                                               |
| ----------------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `stage:spec-approval`         | A issue contém ADR/spec proposto ou racional no-spec explícito, aguardando aprovação humana         | Humano aprova a proposta; `issue-writer` materializa o ADR/spec aprovado quando necessário e move para `stage:needs-plan`. |
| `stage:needs-plan`            | Source-set aprovado sem snapshot atual de plano                                                     | Despachar/aguardar plan-writer.                                                                                            |
| `stage:needs-plan-review`     | Snapshot atual do plano aguarda veredito independente ou aprovação humana após veredito aprovador   | Despachar/aguardar plan-reviewer, depois aguardar aprovação humana do plano.                                               |
| `stage:approved`              | Plano atual tem veredito aprovador literal e aprovação humana explícita                             | Humano escolhe `worktree` ou `later`; execução nunca usa o checkout compartilhado sem worktree.                            |
| `stage:in-progress`           | O plano aprovado está sendo implementado pela primeira vez como uma unidade                         | Aguardar evidência do executor ou blockers.                                                                                |
| `stage:needs-delivery-review` | Existe evidência não bloqueada do executor; a review independente da implementação ainda não fechou | Despachar/aguardar `delivery-reviewer` (Fase 5).                                                                           |
| `stage:needs-changes`         | A review da implementação (ou auditoria final) pediu ajustes corrigíveis                            | Despachar/retomar o executor sobre os achados; nova evidência volta a `needs-delivery-review`.                             |
| `stage:ready-to-merge`        | Review da implementação aprovou; restam auditoria final, DoD, aprovação do PR e decisão de merge    | Despachar auditoria final (Fase 6), depois oferecer integração opcional.                                                   |
| `stage:blocked`               | Decisão humana ou correção externa é necessária                                                     | Apresentar o blocker registrado; não adivinhar.                                                                            |

`needs-human` é ortogonal. Adicione-a em `spec-approval`, `needs-plan-review`
após veredito aprovador, `approved` + `later`, decisões bloqueadas, falha de
review que exige produto/acesso, o terceiro ciclo de pedido de ajuste do plano e
a decisão opcional de integração pós-PR. Antes de adicionar um stage, remova
toda label `stage:*` existente. Após entrega merged/fechada, remova o stage e
`needs-human`.

## Mutação de labels (obrigatória)

O status da issue é o conjunto de labels do GitHub, não o texto do comentário.
Escrever `stage:*`, `needs-human` ou uma frase de transição dentro de um
comentário append-only não muda a issue. Após o comentário de evidência
autorizador existir, mutue as labels imediatamente.

**Preferido:** `scripts/transition-issue.sh` (também via
`/code-flow tool transition-issue`):

```bash
# Após comentário autorizador: remove stage:* antigo, aplica o próximo, confirma
./scripts/transition-issue.sh 42 --require-from stage:needs-plan --to stage:needs-plan-review

./scripts/transition-issue.sh 42 --to stage:blocked --needs-human
./scripts/transition-issue.sh 42 --to stage:needs-plan --clear-needs-human
./scripts/transition-issue.sh 42 --clear-stage --clear-needs-human   # pós-merge
./scripts/transition-issue.sh 42 --to stage:approved --dry-run
```

O helper lê labels, remove todo `stage:*`, aplica exatamente um `--to` (whitelist
da tabela), ajusta `needs-human`, confirma com `gh issue view --json labels` e
imprime JSON (`issue`, `from`, `to`, `needs_human`, `labels`). Não posta
comentários e não escolhe o próximo stage.

A mutação é **best-effort**, não uma chamada atômica da API: cada
`gh issue edit` é separado. Se o add falhar após o remove, a issue pode ficar
com zero `stage:*` (drift → `blocked` + `needs-human` na Fase 0). O helper
confirma após o remove e após o fim; se a confirmação falhar, repare com
`--allow-repair --to <stage>` (ou o fallback manual abaixo) no mesmo turno.

**Fallback manual** (se o script estiver indisponível):

```bash
# 1) Remova toda label stage:* existente (liste antes)
gh issue view 42 --json labels -q '.labels[].name'
gh issue edit 42 --remove-label "stage:needs-plan"

# 2) Adicione exatamente um próximo stage
gh issue edit 42 --add-label "stage:needs-plan-review"

# 3) Adicione ou remova needs-human conforme a transição
gh issue edit 42 --add-label "needs-human"
# ou: gh issue edit 42 --remove-label "needs-human"

# 4) Confirme antes de continuar
gh issue view 42 --json labels
```

Sequência obrigatória (com ou sem helper):

1. Remova toda label `stage:*` existente.
2. Adicione exatamente uma próxima label `stage:*` da tabela acima.
3. Adicione ou remova `needs-human` conforme a transição exigir.
4. Confirme com `gh issue view <n> --json labels` antes de continuar.

O orquestrador aplica essas mutações depois dos posts dos papéis (e o
`issue-writer` as aplica na criação e na materialização pós-aprovação). Papéis
que dizem que não devem mudar labels continuam sem mudar; o orquestrador
atualiza por eles. Nunca pare após apenas registrar o novo stage no body do
comentário.

| Racionalização                                               | Contraponto                                                    |
| ------------------------------------------------------------ | -------------------------------------------------------------- |
| “O comentário já diz o novo stage.”                          | Texto de comentário é narrativa; só labels são status durável. |
| “Next action nomeia o stage, então a issue está atualizada.” | `Next action` não é mutação de label.                          |
| “Vou atualizar as labels depois / após o próximo passo.”     | Mutue labels no mesmo turno do comentário autorizador.         |

## Tabela de transição

```text
fase 0 → fase 1 → fase 2: investigar → decidir impacto de spec → preparar proposta
criar/preencher issue de entrega: proposta/racional no-spec no body + spec-approval + needs-human
aprovação humana da proposta → materializar ADR/spec quando necessário → needs-plan → needs-plan-review
  ├─ reviewer independente aprova → aguardar aprovação humana do plano → approved → worktree in-progress
  ├─ pede ajustes (ciclo < 3) → needs-plan
  └─ rejeita/erros/terceiro ajuste → blocked + needs-human
in-progress → needs-delivery-review → review da implementação
  ├─ APROVO / APROVO COM RESSALVAS → ready-to-merge → auditoria final/DoD → aprovação do PR
  │    └─ integração/merge opcional confirmada pelo usuário → fechar
  ├─ PEÇO AJUSTES / achados Critical|Important → needs-changes → executor → needs-delivery-review
  └─ NÃO APROVO com decisão de produto/acesso → blocked + needs-human
auditoria final pede ajustes → needs-changes → executor → needs-delivery-review
```

## Regras de resume

| Estado observado                                                | Ação de resume                                                                                                                     |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `stage:spec-approval`                                           | Apresentar a proposta de ADR/spec ou racional no-spec para aprovação humana; não escrever ADR/spec formal nem plano.               |
| `stage:needs-plan`                                              | Iniciar ou aguardar o plan-writer da Fase 3.                                                                                       |
| `stage:needs-plan-review`                                       | Despachar/aguardar a review independente do plano atual, depois apresentar um snapshot aprovador para aprovação humana.            |
| `stage:approved`                                                | Perguntar `worktree` ou `later`; ainda não editar código.                                                                          |
| `stage:in-progress`                                             | Despachar/retomar o executor único do plano aprovado, ou resolver seu blocker.                                                     |
| `stage:needs-delivery-review`                                   | Despachar/aguardar a review independente da implementação (Fase 5).                                                                |
| `stage:needs-changes`                                           | Despachar o executor para corrigir os achados da review/auditoria; após evidência não bloqueada, voltar a `needs-delivery-review`. |
| `stage:ready-to-merge`                                          | Despachar auditoria final, DoD e aprovação do PR (Fase 6). Após isso, oferecer — não executar automaticamente — merge/integração.  |
| `stage:blocked`                                                 | Apresentar a decisão humana registrada; não adivinhar.                                                                             |
| Issue elegível com zero/múltiplos stages ou drift de comentário | Definir `stage:blocked` + `needs-human` e explicar o mismatch.                                                                     |
| Issue inelegível                                                | Explicar que está fora do fluxo de entrega e parar sem tocar labels.                                                               |

## Ciclos de plano

Um ciclo é um comentário append-only de plano mais um comentário append-only de
review. O plano deve identificar `Plan cycle: k/3`, o base SHA do repositório e
os links das fontes. Não decompor em task IDs. A review deve citar a URL desse
comentário de plano e usar um veredito literal:

`APROVO` | `APROVO COM RESSALVAS` | `PEÇO AJUSTES` | `NÃO APROVO`

Não editar um comentário de plano ou review já submetido. Uma mudança material
de plano, rejeição humana ou pedido humano de ajustes inicia um novo ciclo,
substitui `stage:approved` ou `stage:needs-plan-review` por `stage:needs-plan`
e exige um novo reviewer. Se o reviewer exigir escolha de produto/acesso, use
`NÃO APROVO` e bloqueie em vez de consumir um ciclo de ajuste. O plan-reviewer
deve ser distinto do plan-writer. Toda instância de `delivery-reviewer` também
deve ser distinta do plan-writer e do executor cujo trabalho está no range
revisado.

## Regras de batch

Mantenha uma visão efêmera de orquestração por issue: URL, stage observado,
ciclo de plano, base SHA, agentes atribuídos, blockers, branch/worktree, PR e
próxima ação. Não persistir como registry ou arquivo de progresso; labels/comentários
da issue e o PR são a evidência durável. Uma issue bloqueada não para issues
não relacionadas. Agentes de plano/review podem rodar em paralelo. Cada issue
usa uma worktree, branch e PR isolados.
