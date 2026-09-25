# Impacto e ciclo de vida CASA

Usar esta referência para classificar uma mudança e verificar seu fechamento.

## Mapa de impacto T1

Classifique o fato antes do arquivo tocado. Procure primeiro ADRs e Specs
existentes; restauração ou implementação de contrato já decidido não cria outro
documento.

Use esta ordem:

1. Entrada, saída, autorização, erro, mensagem, fluxo, estado de UI ou caso de
   borda observável → Spec.
2. Escolha interna durável entre alternativas de ownership, backend, fronteira,
   acoplamento, modelo de consistência ou estratégia de falha → ADR, somente se
   a escolha ainda não estiver determinada por documento existente.
3. Schema, constraint, índice e migration → implementação por padrão. Classifique
   o invariante que eles aplicam: comportamento observável vai para Spec; uma
   escolha estrutural nova e independente pode exigir ADR.
4. Quando ambos existirem, sempre declare as casas primárias e a relação: a Spec
   referencia a ADR por `builds-on`, sem copiar a decisão.

Política de negócio continua sendo Spec quando define o que usuário ou caller
pode observar, mesmo que envolva segurança, dados, auditoria ou concorrência.
Código HTTP, texto de UI, papéis permitidos e frases `QUANDO … DEVE …` dentro de
uma ADR são sinais de contrato duplicado. Importância, quantidade de linhas e
risco técnico não transformam comportamento em arquitetura.

Depois escolha a ação:

| Fato observável                                                          | `artifact_action`                                                            |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| Escolha estrutural, acoplamento, backend ou estratégia de falha          | Criar ADR; se conflitar com decisão aceita, nova ADR + transição da anterior |
| Feature com capacidade/contrato novo e decidido                          | Criar Spec                                                                   |
| Mudança do contrato de feature já especificada                           | Atualizar a Spec existente                                                   |
| Schema/migration que aplica decisão ou contrato existente                | Dispensar documento; implementar e testar                                    |
| Implementação ou restauração de contrato já definido                     | Dispensar documento                                                          |
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

- Exigir alternativa estrutural real e consequência durável que não seja
  derivável de ADR/Spec existente; “é importante” não basta.
- Tratar o corpo de ADR aceita como imutável.
- Para mudança, criar nova ADR que registre contexto, direcionadores, opções, decisão, consequências e confirmação.
- Atualizar a anterior somente nos campos/bloco permitidos pelo contrato pinado.
- Não transformar decisão aberta em ADR aceita. Registrar a pendência no tracker ou backlog aplicável.

## Spec

- Fazer da Spec a casa primária de políticas de produto e contratos observáveis;
  não criar ADR paralela apenas para registrar os mesmos invariantes.
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

Mutação documental CASA inferida, não pedida, fora do escopo autorizado ou
dependente de decisão aberta torna `gate_required=true`. Pedido direto para
criar, atualizar, depreciar ou fechar artefato de escopo identificável mantém
`gate_required=false`; as salvaguardas de imutabilidade e fechamento continuam.
Código, testes, schema, migration, auditoria read-only e riscos sem escrita
documental também mantêm `gate_required=false`.

Depois calcule `gate_bypass`. Bypass explícito ou o marker exato no `AGENTS.md`
dispensa a confirmação, mas não muda `artifact_action`: documento obrigatório
continua obrigatório, sugestão continua sugestão, ADR aceita continua imutável e
Spec só fecha com evidência.

Comparar continuamente o source-set documental com o envelope aprovado. Nova
edição documental já coberta não reabre o gate. Reabrir antes da próxima escrita
somente quando aparecer mutação fora do envelope autorizado.
