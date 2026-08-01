# Impacto e ciclo de vida CASA

Usar esta referência para classificar uma mudança e verificar seu fechamento.

## Mapa de impacto T1

Classificar cada fato em uma casa primária e escolher a ação:

| Fato observável                                                          | `artifact_action`                                                            |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| Escolha estrutural, acoplamento, backend ou estratégia de falha          | Criar ADR; se conflitar com decisão aceita, nova ADR + transição da anterior |
| Schema persistido, constraint ou migração que define invariante T1       | Criar ADR; o artefato registra a decisão estrutural, não o risco técnico     |
| Feature com capacidade/contrato novo e decidido                          | Criar Spec                                                                   |
| Mudança do contrato de feature já especificada                           | Atualizar a Spec existente                                                   |
| Implementação ou restauração de contrato já definido                     | Dispensar mudança de Spec                                                    |
| Refactor, teste, detalhe interno ou ajuste visual sem mudança contratual | Dispensar documento                                                          |
| Estado atual cuja edição foi pedida explicitamente                       | Atualizar o capítulo pertinente em `docs/context/`                           |
| Intenção durável apenas inferida                                         | Sugerir conforme `context-persistence.md`; não editar                        |
| Entrega, milestone ou coordenação                                        | Issue/PR/commit com autorização própria; não criar agregador CASA            |

Feature com contrato é uma capacidade coerente para caller ou usuário, com
inputs, outputs, autorização, erros, fluxo ou casos de borda relevantes. A mera
visibilidade externa de uma linha, comando ou detalhe não transforma a mudança
em feature.

Usar `docs-reserve` quando disponível para criar ADR/Spec. Nunca editar índices gerados à mão.

## T0

Não exigir ADR, Spec nem `docs/context/`. Regra transversal curta pode ser
sugerida para o `AGENTS.md` raiz; regra de subtree, para o `AGENTS.md` aninhado.
Migração, dados, segurança e efeito externo sem escrita documental não acionam
gate CASA. Aplicar separadamente autorizações e salvaguardas gerais pertinentes.

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

## Derivar e reabrir o gate

Criar, atualizar, depreciar, mudar status ou superseder documento CASA torna
`gate_required=true`. Código, testes, schema, migração e riscos sem escrita
documental mantêm `gate_required=false`.

Comparar continuamente o source-set documental com o envelope aprovado. Nova
edição documental já coberta não reabre o gate. Reabrir antes da próxima escrita
somente quando aparecer outra mutação direta de documento CASA fora do envelope.
