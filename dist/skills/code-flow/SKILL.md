---
name: code-flow
description: "Coordinate non-trivial issue-based repository deliveries or batches with bounded pre-issue discovery, adaptive rigor, repository workflow discovery, independent reviews, human gates, isolated worktrees, and explicit merge or closure. Explicit invocations may also use the lightweight path; start from a named semantic operation only when the user requests it."
metadata:
  user-invocable: true
---

# code-flow

Coordene entregas com rigor proporcional ao risco. O orquestrador descobre
contexto, propõe complexidade, resolve uma única máquina de estado e despacha
somente os papéis necessários. Ele pode criar a issue mínima do caminho `S`,
mas não escreve plano formal, review ou código.

Discovery, decisões de intenção e brainstorm podem ocorrer antes da issue.
Plano formal, implementação, review e integração exigem uma issue de
entrega/bug elegível. A classificação de risco continua efêmera; somente
`Complexity` é persistida no frontmatter do body conforme
[`references/risk-profiles.md`](references/risk-profiles.md).

## Comandos

| Invocação                                                                        | Comportamento                                                           |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `/code-flow`                                                                     | Discovery read-only, resumo e próxima entrada recomendada.              |
| `/code-flow issue create`                                                        | Fecha decisões obrigatórias e cria/preenche uma issue elegível.         |
| `/code-flow issue <#N\|URL> [context\|issue\|plan\|dispatch\|review\|integrate]` | Recalcula risco, valida workflow e retoma a operação elegível.          |
| `/code-flow <context\|issue\|plan\|dispatch\|review\|integrate> <#N\|URL>`       | Forma semântica com alvo explícito.                                     |
| `/code-flow batch <#N\|URL>... --from <operation>`                               | Executa trilhas isoladas sem pular gates; consolida decisões por issue. |
| `/code-flow brainstorm`                                                          | Resume decisões e oferece aprofundar ou seguir ao próximo passo.        |
| `/code-flow tool doctor [args]`                                                  | Executa somente o [diagnóstico público](scripts/doctor.sh) e para.      |

Helpers internos: [`scripts/review-package.sh`](scripts/review-package.sh),
[`scripts/source-set-digest.py`](scripts/source-set-digest.py) e
[`scripts/transition-issue.sh`](scripts/transition-issue.sh). Não os exponha
como comandos públicos.

## Ordem obrigatória

1. Faça discovery antes de perguntar fatos descobríveis ou escrever.
2. Antes de plano/código/review, confirme issue de entrega/bug; Epic e tracker
   são inelegíveis.
3. Proponha `Complexity: S | M | G | X | XL`, recalcule risco e derive o
   workflow do estado observado antes de interpretar gates: um `stage:*` usa
   fallback, independentemente de header legado; sem stage, native passa automaticamente quando o mapeamento
   completo passa. Hard trigger sempre vence complexidade. Mudança de comportamento
   observável em um componente começa em `M`; `S` exige mudança interna,
   behavior-preserving e caminho já conhecido.
4. Valide a tabela de verdade de [`references/github-flow.md`](references/github-flow.md).
   Múltiplos stages são drift bloqueante. Header legado `Workflow: native` que
   falha no mapeamento pausa e oferece migração explícita/compensável; nunca
   apenas “repara e continua”.
5. Carregue somente a operação ativa e despache os papéis exigidos.
6. O agente publica evidência antes da mutação causada pelo próprio resultado;
   o orquestrador valida toda transição e executa as causadas por decisão
   humana.
7. Use worktree isolada somente para implementação e correções de código.
   Merge e fechamento sem diff continuam decisões humanas explícitas.
   Prova `NO_CHANGES` sempre passa por `delivery-reviewer` independente antes
   do gate; quando aprovada, apresenta `Fechar / Ajustar / Aguardar`, e somente
   `Fechar` autoriza fechamento e limpeza.
   Nunca renomeie `NO_CHANGES` como `DONE` nem aceite pedido para pular review,
   gate ou consolidação de Minors.

Ao explicar ou retomar uma transição, torne o contrato verificável: nomeie o
evento, o ator da mutação, o estado anterior e posterior, a presença/ausência
de `needs-human` e a evidência exigida antes de avançar. Não reduza uma cadeia
de gates a “aprovado, pode executar”.

Se risco ou escopo material novo surgir, pare antes de nova mutação, registre a
promoção, invalide apenas gates insuficientes e retome no primeiro gate agora
obrigatório. Urgência, preferência, autoridade ou tamanho pequeno nunca
rebaixam hard trigger.

## Operações

| Operação               | Carregar                                                     |
| ---------------------- | ------------------------------------------------------------ |
| Contexto e resume      | [`phases/context.md`](phases/context.md)                     |
| Issue e source-set     | [`phases/issue.md`](phases/issue.md)                         |
| Plano                  | [`phases/plan.md`](phases/plan.md)                           |
| Dispatch               | [`phases/dispatch.md`](phases/dispatch.md)                   |
| Review                 | [`phases/review.md`](phases/review.md)                       |
| Integração/fechamento  | [`phases/integrate.md`](phases/integrate.md)                 |
| Brainstorm condicional | [`prompts/brainstorm.md`](prompts/brainstorm.md)             |
| Companheiro visual     | [`prompts/visual-companion.md`](prompts/visual-companion.md) |

Antes de retomar ou mutar fallback, leia
[`references/orchestrator-cheatsheet.md`](references/orchestrator-cheatsheet.md).
Antes de publicar evidência ou revisar, leia
[`templates/evidence-contract-template.md`](templates/evidence-contract-template.md).
Para drafts de acompanhamento de Minors e sua consolidação final, leia
[`references/follow-up-issue-drafts.md`](references/follow-up-issue-drafts.md).
Para uma decisão humana, use o
[`templates/12-human-gate-spec.md`](templates/12-human-gate-spec.md); para um
evento isolado, use o
[`templates/10-issue-note-template.md`](templates/10-issue-note-template.md).
Ownership de transição e labels fica em
[`references/label-mutation-matrix.md`](references/label-mutation-matrix.md).

## Papéis permitidos

| Papel                                                 | Responsabilidade                                                   |
| ----------------------------------------------------- | ------------------------------------------------------------------ |
| [`issue-writer`](agents/01-issue-writer.md)           | Issue e source-set para M/G/X/XL ou qualquer impacto de spec.      |
| [`issue-reviewer`](agents/02-issue-reviewer.md)       | Review independente do source-set em X/XL ou hard trigger.         |
| [`plan-writer`](agents/03-plan-writer.md)             | Plano formal quando S/outline não se aplica.                       |
| [`plan-reviewer`](agents/04-plan-reviewer.md)         | Review independente do plano.                                      |
| [`executor`](agents/05-executor.md)                   | Outline S, implementação autorizada e correções na mesma worktree. |
| [`delivery-reviewer`](agents/06-delivery-reviewer.md) | Review da entrega e auditoria final quando aplicável.              |

Esses são os únicos papéis publicados, não uma lista de invocações
obrigatórias. Ninguém revisa, aprova ou audita trabalho próprio. Reuso de
reviewer segue a matriz adaptativa; não crie registry paralelo ou estado local
de workflow.

Toda resposta que atribuir/reutilizar reviewer declara o contrato completo:
M/G permite reuso somente sem autoria de plano/código; X/XL ou hard trigger
exige instância separada por fase; renomear papel, trocar sessão ou delegar a si
mesmo não apaga autoria nem torna self-review independente.

Uma iniciativa com múltiplos resultados independentes usa
[`templates/01-epic.md`](templates/01-epic.md) somente após escolha explícita.
O Epic é tracking, não recebe metadata/stage da entrega, e seu fechamento exige
checkpoint humano; cada filha percorre este fluxo como entrega própria.

## Batch

`--from` é piso: issue anterior é inelegível; issue no piso ou já adiante
continua sem pular nem retroceder gates. Estado, falhas e worktrees permanecem
isolados por issue. Checkpoint consolidado mostra opções concretas por ID (por
exemplo `#30`, `#32`) e “todas as listadas”; decisão global sem esse escopo
explícito é inválida. Review/PR aprovado nunca autoriza merge automático.
