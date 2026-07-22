# Relatório de arquitetura e autorização de execução

S sem hard trigger usa outline após ordem explícita. M/G/X/XL disparam o
`architect`, que publica um **relatório de arquitetura** (não um plano de
implementação completo), decide impacto de spec/ADR e, depois, ordem humana de
execução quando o gate se aplica. O relatório usa
`templates/03-architect-review-template.md`. Não há reviewer autônomo nem gate
formal de plano: o relatório publicado é a entrada para a decisão humana de
execução quando ela se aplica.

Architect publica o primeiro relatório em um único comentário canônico marcado
(`code-flow:architect-review:start`/`end`) e registra sua URL/ID. Em correções,
edita esse comentário in-place e publica somente um comentário append-only com
resumo breve das alterações, usando
`templates/07-workflow-note-template.md` com `note_type: architect-change`; não
adiciona outra cópia integral
do relatório. Marcador ausente ou duplicado bloqueia a entrega até resolver o
drift. `scripts/source-set-digest.py` hasheia o bloco do relatório entre os
marcadores; o gate registra URL+digest e a edição invalida a autorização.

## Decisão de spec/ADR

O architect é dono da triagem `create | update | not required`:

- `create`/`update`: o conteúdo da spec/ADR é escrito no relatório canônico e
  **materializado no PR do executor** (não em branch própria de spec).
- `not required`: o racional fica no relatório.

Somente após o relatório canônico e, quando aplicável, seu changelog estarem
publicados, transicione `stage:needs-architect` para `stage:approved`:

- Gate humano `Autorizar / Ajustar / Bloquear` **obrigatório** quando a decisão
  de spec/ADR for `create`/`update` **ou** quando a Complexidade for `>= G`:
  `stage:approved + needs-human`, aguardando ordem explícita de execução.
- M com `not required` e sem hard trigger: `stage:approved` sem needs-human; o
  executor parte após ordem explícita simples.

O architect nunca autoriza execução, apenas entrega o relatório para a decisão
humana quando o gate se aplica. Manter `needs-architect` seria drift.

Quando o humano pede ajuste, o orquestrador devolve a
`stage:needs-architect` sem `needs-human`. O architect corrige o comentário
canônico in-place, publica o resumo de alterações e retorna a `stage:approved`,
reaplicando `needs-human` somente se o gate continuar obrigatório. Se o executor
ou o orquestrador identificar
decisão material depois da publicação, pare, promova rigor e só retome com novo
relatório publicado.

## Autorização humana de execução

Apresente o checkpoint compartilhado com `Autorizar / Ajustar / Bloquear`
somente quando aplicável (spec `create`/`update` ou Complexidade `>= G`):
autorizar move a `stage:in-progress` (depois da evidência de início do
executor) e consome a autorização; ajustar devolve a `needs-architect` ao
architect para editar o canônico e republicar o resumo; bloquear preserva
`Resume`. Aprovação do relatório e autorização de execução são a mesma decisão
humana: nunca inicie código sem ordem explícita e worktree isolada. O checkpoint
não se aplica ao outline S, que já depende de ordem explícita.
