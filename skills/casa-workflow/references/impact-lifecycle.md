# Impacto e ciclo de vida CASA

Usar esta referência para classificar uma mudança e verificar seu fechamento.

## Mapa de impacto

Classificar cada fato em uma única casa primária:

| Fato observável                                                 | Artefato ou ação                                                            |
| --------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Escolha estrutural, acoplamento, backend ou estratégia de falha | Nova ADR; se substituir decisão aceita, nova ADR + transição da anterior    |
| API, fluxo, UI ou caso de borda com contrato observável         | Nova/alterada/dividida/depreciada Spec conforme o ciclo                     |
| Estado operacional atual, imperativo e atemporal                | Capítulo pertinente em `docs/context/`                                      |
| Regra transversal ou gotcha recorrente                          | Router `AGENTS.md`; regra de subtree vai ao `AGENTS.md` aninhado            |
| Entrega, milestone ou coordenação                               | Issue/PR/commit, com autorização externa própria; não criar agregador CASA  |
| Nenhum gatilho estrutural ou comportamental                     | Nenhum documento novo; manter gate antes do código se a tarefa mutar código |

Usar `docs-reserve` quando disponível para criar ADR/Spec. Nunca editar índices gerados à mão.

## ADR

- Tratar o corpo de ADR aceita como imutável.
- Para mudança, criar nova ADR que registre contexto, direcionadores, opções, decisão, consequências e confirmação.
- Atualizar a anterior somente nos campos/bloco permitidos pelo contrato pinado.
- Não transformar decisão aberta em ADR aceita. Registrar a pendência no tracker ou backlog aplicável.

## Spec

- Especificar contrato, casos relevantes e DoD executável antes do código.
- Ligar cada caso de borda a comando ou teste real do repo.
- Manter questão aberta como bloqueio; não improvisar.
- Dividir entrega incremental ou cortar escopo de forma explícita; não marcar guarda-chuva parcialmente entregue como implementada.

## Fechamento

Antes de mudar uma Spec para `implemented`, exigir em conjunto:

1. `implemented-by` com paths existentes e pertinentes;
2. comandos do DoD realmente executados e seus resultados;
3. `## Verificação` com evidência concreta, sem placeholder;
4. vínculo entre casos relevantes e validações;
5. estado atual propagado ao capítulo correto, quando mudou;
6. gotchas propagados ao `AGENTS.md` apropriado, quando descobertos;
7. índices regenerados pela ferramenta e `docs-check` verde.

CI futuro, alegação do usuário ou existência aparente de código não substituem evidência. Se um item faltar, manter o estado atual e listar a lacuna.

## Reabrir o gate

Comparar continuamente tarefa, diff, artefatos e decisões com o source-set aprovado. Reabrir antes da próxima escrita quando aparecer nova decisão estrutural, mudança de contrato, novo documento obrigatório, escopo adicional ou impossibilidade de cumprir o fechamento aprovado.
