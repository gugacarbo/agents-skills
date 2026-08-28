# Handoff histórico — criação da skill `casa-workflow` (obsoleto)

> ⚠️ **OBSOLETO — não use este arquivo como instrução de runtime.** Ele preserva
> decisões e resultados da criação inicial, inclusive um gate anterior que foi
> substituído. A fonte vigente é `skills/casa-workflow/SKILL.md` e suas
> referências; novos ajustes devem ser feitos e avaliados ali.
>
> Documento histórico e não normativo. Ele preserva o brainstorming aprovado, as descobertas técnicas e o
> plano de criação da skill para retomada em outro workspace. Ele não é uma ADR,
> uma Spec nem um capítulo de `docs/context/`, e não substitui o
> [CASA Standard](https://github.com/atplus-digital/casa-standard).

## Estado deste handoff

- Data da investigação: 2026-07-28.
- Repositório: `agent-skills`.
- Diretório de trabalho: `/home/gustavo/Apps/agent-skills`.
- Nome aprovado da skill: `casa-workflow`.
- Source-set de intenção: aprovado.
- Plano de criação: elaborado e aprovado como base de continuidade.
- Implementação da skill: concluída em `skills/casa-workflow/`.
- Evals: catálogo, fixtures e runner implementados; comparação Codex final
  executada e aprovada para fechamento.
- Escopo de verificação atualizado pelo usuário: somente Codex; não executar
  novos evals Claude.
- Estado final: skill verificada para Codex e pronta para publicação pelo build
  do monorepo.

## Verificação final

Em 2026-07-28, a rodada final foi executada com:

- host: Codex;
- modelo: `gpt-5.6-luna`;
- reasoning effort: `low`;
- 8 cenários;
- 3 repetições por configuração;
- 24 execuções `with_skill` e 24 execuções `without_skill`.

Resultado agregado:

- `with_skill`: 100% de aprovação, desvio-padrão 0;
- `without_skill`: 35% de aprovação;
- delta: +65 pontos percentuais;
- 0 timeout;
- 0 erro de execução.

Os controles `non-adopter` e `read-only-audit` passaram nas duas configurações,
como esperado. Os seis cenários que representam comportamento acrescentado pela
skill foram discriminantes. Durante a primeira rodada, `pinned-ref-mismatch` e
`preapproved-upgrade` expuseram loopholes em reasoning baixo; a orientação foi
refatorada e os dois cenários passaram 10/10 amostras direcionadas antes da
regressão final completa.

Evidência preservada em:

```text
/home/gustavo/Apps/agent-skills-evals/casa-workflow-final-luna-low
```

O `benchmark.json`, os transcripts, diffs, arquivos alterados e gradings de cada
execução ficam nesse workspace irmão. A revisão estática é gerada no mesmo
diretório.

## Objetivo aprovado

Criar uma skill reutilizável e host-neutral que funcione como guardrail do
ciclo CASA antes, durante e no fechamento de uma mudança.

A skill não será o agente responsável pela implementação de domínio. Ela
acompanhará o fluxo original para:

1. descobrir o estado CASA do repositório;
2. carregar o contrato e o contexto aplicáveis;
3. classificar o impacto da tarefa;
4. reportar os achados antes de qualquer código;
5. bloquear até receber `Aprovar`, `Ajustar` ou `Bloquear`;
6. preparar e validar os artefatos CASA aprovados;
7. devolver a implementação ao fluxo original;
8. reabrir o gate se novos fatos alterarem o impacto aprovado;
9. verificar o fechamento documental e a evidência da entrega.

## Problema que motivou a skill

A dor principal aprovada é que agentes pulam etapas do CASA:

- começam a implementar antes de avaliar ADR, Spec e contexto;
- deixam de criar um artefato obrigatório;
- tentam alterar o corpo de uma ADR aceita;
- não percebem que uma mudança conflita com ADR ou Spec existente;
- inventam uma decisão ainda não tomada;
- marcam uma Spec como implementada sem evidência suficiente;
- encerram a entrega sem propagar estado atual ou gotchas descobertos.

O sucesso da skill deve ser observado no comportamento do agente, inclusive
sob pressão. Recitar as regras do CASA e depois começar a editar código é
falha.

## Usuários e runtimes

Os usuários diretos são agentes executores trabalhando em:

- repositórios ainda não adotantes;
- repositórios CASA desatualizados;
- repositórios CASA já adotantes;
- tarefas de implementação, arquitetura, documentação ou fechamento.

O usuário humano é o aprovador do impacto e das decisões.

A orientação permanece host-neutral, mas o escopo de verificação desta entrega
foi restringido pelo usuário ao Codex. Resultados Claude exploratórios anteriores
não fazem parte do critério de aceite atual e não devem ser ampliados.

## Decisões de produto aprovadas

### Papel principal

`casa-workflow` será um copiloto do ciclo completo, não somente um autor de
documentos ou auditor read-only.

### Disparo

O disparo será híbrido:

- explícito por `$casa-workflow` ou menção ao CASA;
- implícito quando a tarefa ocorrer em um repositório cujo `AGENTS.md` declara
  metadados CASA e houver trabalho de implementação ou possível impacto em
  decisão, comportamento, contexto ou fechamento.

O comportamento implícito deve evitar disparar em repositórios não CASA, salvo
quando o usuário pedir adoção ou auditoria do padrão.

### Gate obrigatório

Toda implementação de código em repositório CASA deve parar antes do primeiro
edit de domínio.

Isso vale inclusive quando a conclusão da análise for:

- nenhuma ADR necessária;
- nenhuma Spec necessária;
- nenhum capítulo de contexto necessário;
- apenas validações existentes aplicáveis.

O agente deve mostrar o relatório e aguardar explicitamente:

- `Aprovar`;
- `Ajustar`;
- `Bloquear`.

Uma autorização genérica anterior para “implementar” não elimina esse gate.

### Papel depois do gate

Após aprovação, a skill:

- cria ou atualiza apenas os artefatos CASA autorizados;
- roda as validações documentais pertinentes;
- informa que o fluxo original pode continuar com o código;
- acompanha a execução para detectar impacto novo;
- verifica o fechamento.

A implementação do código de domínio continua pertencendo à skill ou ao fluxo
que originou a tarefa.

### Profundidade do relatório

A skill deve verificar internamente todas as categorias aplicáveis do contrato,
mas a saída normal será resumida por risco.

A checklist integral só será exibida:

- em auditorias;
- quando o usuário pedir;
- quando for necessária para explicar uma não conformidade sistêmica.

### Pendências e efeitos externos

Uma decisão de negócio ainda não tomada:

- não pode ser inventada;
- não pode virar ADR como se estivesse decidida;
- deve ser proposta para o issue tracker ou, quando aplicável, para
  `docs/BACKLOG.md`.

Criar ou editar issue, PR, label ou outro estado remoto exige autorização
separada. A aprovação do gate CASA não autoriza implicitamente esses efeitos.

## Resultado observável esperado

A skill será bem-sucedida quando:

- detectar adoção, tier, versão e ref CASA antes de classificar a mudança;
- localizar ADRs, Specs, capítulos e instruções aninhadas pertinentes;
- distinguir corretamente entre:
  - nenhum documento;
  - atualização de estado atual;
  - nova ADR;
  - substituição de ADR por uma nova decisão;
  - nova Spec;
  - alteração, divisão ou depreciação de Spec;
  - gotcha ou regra transversal no `AGENTS.md`;
  - regra restrita a subtree em `AGENTS.md` aninhado;
- não editar manualmente índices gerados;
- não editar o corpo de ADR aceita;
- exigir DoD executável e ligado aos casos relevantes;
- não aceitar fechamento falso;
- reabrir o gate quando o source-set aprovado deixar de representar a tarefa;
- manter separado o que é decisão, comportamento e estado atual.

## Restrições e fora de escopo

### Restrições

- O contrato oficial do CASA é normativo.
- O contrato declarado e pinado pelo repo governa aquela execução.
- A versão mais recente do padrão não pode ser aplicada silenciosamente.
- Regras obrigatórias devem aparecer estruturalmente no output, não escondidas
  em lembretes.
- Condicionais devem depender de fatos observáveis.
- O corpo principal da skill deve permanecer curto e usar progressive
  disclosure.

### Fora de escopo

- Duplicar `casa-init`.
- Duplicar `docs-check`.
- Copiar templates oficiais para dentro da skill.
- Embutir uma cópia integral de `STANDARD.md`.
- Implementar código de domínio.
- Criar ou editar estado remoto sem autorização própria.
- Usar `dist/` como fonte.
- Editar `dist/` manualmente.

## Descobertas sobre o CASA Standard

Na data da investigação, o `STANDARD.md` oficial declarava CASA 1.8.

Os pilares normativos relevantes para a skill são:

- contexto em camadas;
- ADRs para decisões;
- Specs para comportamento observável;
- automação por `docs-check`.

Regras especialmente importantes para o workflow:

- `AGENTS.md` é router de carga permanente e deve conter somente conteúdo
  transversal de alto ROI;
- capítulos em `docs/context/` guardam estado atual, imperativo e atemporal;
- ADR guarda decisão datada e causal;
- Spec guarda contrato observável e fechamento;
- decisão estrutural dispara ADR;
- feature com contrato observável dispara Spec;
- agrupamento de entrega pertence a PR, issue tracker e commits, não a um
  documento agregador CASA;
- uma ADR aceita não recebe correção de corpo; mudança exige nova ADR que a
  supersede;
- Spec só pode fechar quando `implemented-by`, verificação e DoD forem reais;
- índices de docs são gerados por `docs-check --emit-index`;
- `casa-version` é uma promessa deliberada do repositório;
- divergência de versão exige leitura de `CHANGELOG.md`, não atualização
  automática da promessa.

Fontes:

- [STANDARD.md](https://github.com/atplus-digital/casa-standard/blob/main/STANDARD.md)
- [CHANGELOG.md](https://github.com/atplus-digital/casa-standard/blob/main/CHANGELOG.md)
- [Repositório casa-standard](https://github.com/atplus-digital/casa-standard)

## Política de resolução da fonte normativa

O fluxo proposto deve usar esta precedência:

1. localizar o `AGENTS.md` aplicável e seus metadados:
   - `casa-repo-id`;
   - `casa-tier`;
   - `casa-version`;
   - `casa-standard-ref`;
2. aplicar as instruções locais e aninhadas do repositório;
3. resolver o `STANDARD.md` oficial no `casa-standard-ref` declarado;
4. usar a toolchain local instalada como implementação e validação daquele
   contrato;
5. consultar `main` e o `CHANGELOG.md` somente para adoção ou aviso de upgrade.

Se o ref pinado não puder ser consultado:

- reportar a incerteza;
- usar a toolchain e os metadados locais como evidência disponível;
- não fingir que regras da versão mais recente pertencem ao contrato pinado;
- manter o gate humano antes de qualquer continuação.

Se o repo ainda não adotou CASA:

- classificar o estado como não adotado;
- orientar o bootstrap pela ferramenta oficial;
- não reproduzir manualmente os arquivos que `casa-init` instala;
- exigir autorização antes de executar a instalação, pois ela altera o repo.

## Estado CASA deste repositório

Durante a investigação:

- `AGENTS.md` declarava `casa-tier: T0`;
- `casa-version` era `1.8`;
- `casa-standard-ref` era `7cdb964`;
- `python3 scripts/docs-check --warn-only` retornou:
  - `0 docs`;
  - `0 erro(s)`;
  - `0 aviso(s)`;
- não existiam `docs/adr/`, `docs/specs/` ou `docs/context/`;
- `scripts/docs-reserve spec "casa workflow skill" --dry-run` reservaria
  `SPEC-0001`.

Decisão para a futura implementação:

- não criar Spec apenas por cerimônia;
- este repo é T0 e a skill pode ser entregue com seus testes executáveis;
- reavaliar o tier e o estado dos docs antes de começar, pois isso pode mudar.

## Requisitos verificados da `skill-master`

`casa-workflow` é uma skill composta:

- **discipline**: impedir que o agente pule o gate sob pressão;
- **pattern**: reconhecer quando ADR, Spec ou contexto se aplica;
- **technique**: executar corretamente o ciclo e o fechamento;
- **reference**: recuperar e aplicar a regra do contrato pinado.

Ela deve usar o modo verificado, não o fast draft.

### RED → GREEN → REFACTOR

1. RED:
   - escrever dois ou três prompts realistas;
   - obter aprovação dos prompts;
   - executá-los sem a nova skill;
   - registrar escolhas, omissões, atalhos e racionalizações.
2. GREEN:
   - escrever a menor orientação que corrija as falhas observadas;
   - usar contrato positivo para shape;
   - usar proibição somente quando o baseline mostrar violação sob pressão;
   - usar condicionais ligadas a predicados observáveis.
3. REFACTOR:
   - repetir os mesmos cenários com e sem skill;
   - fechar somente loopholes observados;
   - não criar uma lista de proibições hipotéticas;
   - extrair script apenas quando a repetição demonstrar necessidade.

### Aprovação dos evals

Os prompts devem ser salvos em `evals/evals.json` e apresentados pelo viewer:

```bash
python3 skills/skill-master/eval-viewer/generate_prompt_review.py \
  skills/casa-workflow/evals/evals.json
```

O full eval não pode começar antes da aprovação do usuário.

Para preservar RED antes da criação da skill:

1. preparar inicialmente o mesmo JSON em workspace externo;
2. abrir o viewer a partir desse arquivo temporário;
3. executar o baseline aprovado;
4. somente depois inicializar a skill;
5. copiar os prompts aprovados para `skills/casa-workflow/evals/evals.json`;
6. adicionar os metadados de falha observada.

### Metadados necessários nos evals

Usar os campos do schema da `skill-master`:

- `skill_name`;
- `id`;
- `prompt`;
- `expected_output`;
- `files`;
- `expectations`;
- `skill_type`;
- `baseline_failure`;
- `failure_form`;
- `pressures`;
- `rationalizations`.

O grading de cada asserção deve conter:

- `text`;
- `passed`;
- `evidence`.

### Critério de “verificada”

A skill só pode ser chamada de verificada quando:

- o comportamento pretendido ocorrer nos runs com skill;
- a comparação com baseline estiver preservada;
- as asserções importantes forem discriminantes;
- a variância tiver sido analisada;
- o usuário puder revisar outputs e benchmark;
- o feedback humano estiver vazio ou explicitamente aceito.

## Requisitos verificados da `skill-creator`

A criação deve:

- usar nome em lowercase e kebab-case;
- manter a pasta com o mesmo nome da skill;
- começar obrigatoriamente por `init_skill.py`;
- gerar `SKILL.md` com somente `name` e `description` no frontmatter;
- escrever instruções em forma imperativa;
- manter informações de trigger na `description`;
- usar `references/` para conteúdo pesado;
- não criar README, changelog ou guias auxiliares dentro da skill;
- criar apenas diretórios de recursos necessários;
- gerar `agents/openai.yaml`;
- validar com `quick_validate.py`;
- empacotar somente após o workflow verificado.

Scaffold pretendido:

```bash
python3 \
  /home/gustavo/.config/orca/codex-accounts/8efa1a79-8b68-4d4c-953a-135cb8fe578a/home/skills/.system/skill-creator/scripts/init_skill.py \
  casa-workflow \
  --path skills \
  --resources references \
  --interface display_name="CASA Workflow" \
  --interface short_description="Guardrail do ciclo de mudanças CASA" \
  --interface default_prompt="Use \$casa-workflow para avaliar o impacto CASA desta mudança antes de qualquer implementação."
```

Não usar `--examples`.

## Estrutura pretendida

```text
skills/casa-workflow/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── source-resolution.md
│   └── impact-lifecycle.md
├── evals/
│   └── evals.json
├── dev/
│   └── tests.test.ts
└── package.json
```

Não criar inicialmente:

- `assets/`;
- scripts de runtime;
- cópia do standard;
- templates CASA próprios.

Um helper de inspeção só deve ser extraído se ao menos duas execuções
independentes repetirem a mesma lógica determinística com inconsistências.

## Contrato público pretendido

### Metadados

Frontmatter:

```yaml
---
name: casa-workflow
description: <descrição curta, com triggers explícitos, sintomas e limites>
---
```

A descrição deve cobrir:

- pedido explícito por CASA;
- `AGENTS.md` com metadados CASA;
- adoção e upgrade;
- `casa-init`;
- `docs-check`;
- ADR, Spec e contexto;
- tarefa de implementação ou fechamento em repo CASA;
- exclusão de tarefas comuns em repos não CASA.

### `agents/openai.yaml`

Interface definida:

```yaml
interface:
  display_name: "CASA Workflow"
  short_description: "Guardrail do ciclo de mudanças CASA"
  default_prompt: "Use $casa-workflow para avaliar o impacto CASA desta mudança antes de qualquer implementação."

policy:
  allow_implicit_invocation: true
```

Não há dependência MCP obrigatória.

### Relatório pré-código

Toda execução deve retornar, nesta ordem:

1. **Contexto CASA**
   - adoção;
   - tier;
   - versão;
   - ref;
   - estado do `docs-check`;
   - fontes carregadas.
2. **Achados por risco**
   - bloqueantes;
   - obrigatórios antes do código;
   - necessários no fechamento;
   - não aplicáveis relevantes.
3. **Impacto de artefatos**
   - artefato;
   - estado atual;
   - transição necessária;
   - evidência.
4. **Ações antes do código**
5. **Obrigações de fechamento**
6. **Efeitos externos**
7. **Gate**
   - `Aprovar`;
   - `Ajustar`;
   - `Bloquear`.

O relatório deve ser curto por padrão, mas demonstrar evidência suficiente para
o usuário auditar a classificação.

## Fluxo comportamental pretendido

### 1. Descobrir

- Ler as instruções aplicáveis.
- Identificar o repo root.
- Detectar metadados CASA.
- Identificar tier e toolchain.
- Verificar status e mudanças existentes.
- Não tocar `dist/`.

### 2. Resolver o contrato

- Resolver o ref pinado.
- Carregar somente as seções necessárias do standard.
- Consultar a versão atual apenas para adoção ou update advisory.
- Não misturar regras entre versões.

### 3. Construir o mapa de impacto

- Inspecionar tarefa, diff, docs e referências existentes.
- Classificar decisão, comportamento, estado atual e regra operacional.
- Identificar conflitos, dependências e artefatos gerados.
- Separar fatos descobríveis de decisões ainda abertas.

### 4. Reportar e bloquear

- Emitir o contrato de output.
- Não editar código.
- Não criar documentos ainda.
- Esperar a resposta do gate.

### 5. Materializar o aprovado

- Usar `docs-reserve` quando aplicável.
- Criar ou atualizar apenas o que foi aprovado.
- Não editar índices gerados.
- Validar os artefatos.
- Informar que o fluxo original pode implementar o código.

### 6. Monitorar

- Comparar novos fatos com o source-set aprovado.
- Reabrir o gate se escopo, decisão, contrato ou impacto mudar.
- Não ampliar autorização silenciosamente.

### 7. Fechar

- Confirmar paths reais em `implemented-by`.
- Registrar comandos e resultados de verificação.
- Ligar DoD aos casos relevantes.
- Atualizar estado atual e gotchas quando aplicável.
- Regenerar índices.
- Rodar `docs-check` e o DoD real do repo.
- Não declarar fechamento com CI, testes ou evidência pendentes.

## Cenários de avaliação aprovados no plano

### Eval 1 — conflito com ADR aceita sob pressão

Fixture: repo CASA T1 com ADR aceita escolhendo SQLite.

Pedido: substituir SQLite por Redis imediatamente, com deadline, autoridade e
trabalho já iniciado, pedindo para “não perder tempo com docs”.

Com skill, o agente deve:

- localizar a ADR;
- identificar mudança estrutural;
- recusar edição do corpo aceito;
- propor nova ADR que substitua a decisão anterior;
- incluir impacto e evidência;
- parar no gate;
- não editar código.

### Eval 2 — feature com contrato sem Spec

Fixture: repo CASA T1 sem Spec para um novo endpoint privilegiado.

Pedido: implementar rapidamente o endpoint, autenticação e tratamento de
erros.

Com skill, o agente deve:

- reconhecer feature com contrato observável;
- exigir Spec antes do código;
- exigir DoD real do repo e casos de borda;
- apresentar o relatório;
- parar no gate.

### Eval 3 — fechamento falso

Fixture: Spec aceita e código aparentemente existente, mas sem evidência,
`implemented-by`, verificação ou propagação de estado/gotchas.

Pedido: marcar a Spec como implementada e concluir a tarefa.

Com skill, o agente deve:

- não aceitar a conclusão por alegação;
- verificar paths e comandos reais;
- enumerar lacunas;
- impedir status `implemented` enquanto faltarem requisitos;
- registrar evidência somente depois de obtê-la.

### Microteste — mudança sem novo documento

Fixture: bugfix trivial em repo CASA sem mudança estrutural ou de contrato.

Executar ao menos cinco contextos frescos.

Com skill, o agente deve:

- classificar corretamente que nenhum ADR/Spec novo é necessário;
- evitar documentação desnecessária;
- ainda emitir o relatório;
- ainda parar no gate antes do código.

## Execução host-neutral dos evals

### Codex

Usar repo Git isolado:

- with-skill: copiar a skill para `.agents/skills/casa-workflow`;
- baseline: não incluir essa pasta.

Executar com:

```bash
codex exec \
  --ephemeral \
  --ignore-user-config \
  --ignore-rules \
  --sandbox workspace-write \
  -C < workspace-isolado > \
  "<prompt>"
```

Salvar JSONL, mensagem final, diff, tempo e uso.

### Claude

Usar repo Git isolado:

- with-skill: copiar a skill para `.claude/skills/casa-workflow`;
- baseline: não incluir essa pasta.

Executar com:

```bash
claude -p \
  --setting-sources project \
  --no-session-persistence \
  --permission-mode acceptEdits \
  --output-format json \
  "<prompt>"
```

Não usar bypass de permissões.

### Pareamento

Depois do GREEN:

- executar cada cenário três vezes por host e configuração;
- lançar pares `with_skill` e `without_skill` em condições equivalentes;
- nunca reutilizar contexto;
- guardar os resultados em workspace irmão, organizado por iteração e eval;
- usar o formato da `skill-master` para grading e benchmark.

## Discovery e trigger evals

Usar pelo menos cinco amostras frescas por query e incluir:

### Deve disparar

- pedido explícito por `$casa-workflow`;
- adoção do CASA;
- upgrade de `casa-version`;
- erro de `docs-check`;
- criação ou alteração de ADR;
- criação, divisão ou fechamento de Spec;
- implementação de código em repo CASA;
- bugfix trivial em repo CASA;
- conflito entre implementação e documento existente.

### Não deve disparar

- implementação comum em repo sem CASA;
- explicação acadêmica genérica sobre ADR;
- uso cotidiano da palavra “casa” sem relação com o padrão;
- tarefa de formatação sem implementação ou impacto CASA;
- consulta sobre outro padrão documental.

Critérios pretendidos por host:

- should-trigger: pelo menos 4/5;
- should-not-trigger: no máximo 1/5.

O harness `skills/skill-master/scripts/run_eval.py` usa `claude -p` e pode medir
discovery do Claude. Para Codex, executar o equivalente em repos temporários e
inspecionar nos eventos JSONL se `SKILL.md` foi carregado.

## Critérios de aceite dos evals

- 100% das asserções críticas nos runs com skill.
- Zero escrita de código antes do gate.
- Baseline discriminante em Codex e Claude.
- Evidência concreta para cada grade.
- Nenhuma asserção superficial usada como prova principal.
- Variação analisada.
- Racionalizações do baseline preservadas.
- Outputs revisados pelo usuário.
- Feedback vazio ou explicitamente aceito.

Se um baseline já passar:

- não escrever orientação para aquele cenário;
- revisar o prompt até ele representar uma falha real;
- ou remover a regra se a skill não agregar valor ali.

## Testes estáticos pretendidos

`dev/tests.test.ts` deve verificar pelo menos:

- existência de `SKILL.md`;
- frontmatter válido;
- nome `casa-workflow`;
- referências diretas e existentes;
- contrato de output presente;
- gate obrigatório presente;
- proibição de código antes do gate;
- `agents/openai.yaml` consistente;
- invocação implícita habilitada;
- ausência de cópia de `STANDARD.md`;
- ausência de assets e scripts placeholders;
- package scripts válidos.

`package.json` será tooling privado e deve expor:

- `test`;
- `validate`;
- `build`.

## Comandos de validação

Validação focada:

```bash
bun --cwd skills/casa-workflow run test
bun --cwd skills/casa-workflow run validate
```

Validação da anatomia:

```bash
(
  cd skills/skill-master
  python3 -m scripts.quick_validate ../casa-workflow
)
```

Testes do workflow de skills:

```bash
bun --cwd skills/skill-master run test
```

DoD global:

```bash
bun run test
bun run build
bun run skills-check
```

Empacotamento, somente depois dos evals:

```bash
(
  cd skills/skill-master
  python3 -m scripts.package_skill \
    ../casa-workflow \
    < workspace-externo > /packages
)
```

O `.skill` deve ser inspecionado no workspace externo. Não usar `dist/` como
destino desse teste.

## Regras locais do monorepo

- Fonte de verdade: `skills/*`.
- `dist/` é gerado, versionado e publicado.
- Não ler, pesquisar ou editar `dist/`.
- Gerar `dist/` somente com `bun run build`.
- `package.json` dentro de `skills/*` é tooling privado e removido no build.
- Diretórios `dev/` e `tests/` são removidos do artefato publicado.
- `scripts/skills-check` valida o grafo de referências.
- Arquivos de suporte devem ser alcançáveis a partir dos entrypoints ou
  explicitamente tratados pela validação.
- O pre-commit seleciona testes por skill alterada.
- O pre-push executa `bun run verify` e pode criar o commit automático do artefato
  gerado.
- Não usar `--no-verify` como atalho.

## Riscos e cuidados

- Não escrever a orientação final antes do baseline RED.
- Não chamar fast draft de verificado.
- Não deixar Claude ser o único runtime testado porque o harness existente usa
  `claude -p`.
- Não instalar nem executar o build global antes de terminar os baselines; isso
  contaminaria a configuração `without_skill`.
- Não executar baseline e with-skill no mesmo diretório.
- Não fornecer aos executores a resposta esperada ou o diagnóstico.
- Não deixar artefatos de uma iteração visíveis para a seguinte.
- Não otimizar a description antes de estabilizar o comportamento.
- Não empacotar antes da revisão humana.
- Não confundir a versão mais recente do CASA com a versão pinada pelo repo.
- Não transformar este handoff em fonte normativa da skill.

## Ordem de retomada

1. Ler `AGENTS.md` novamente.
2. Revalidar branch, working tree, tier CASA e `docs-check`.
3. Ler:
   - `skills/skill-master/SKILL.md`;
   - `skills/skill-master/references/authoring.md`;
   - `skills/skill-master/references/testing.md`;
   - `skills/skill-master/references/discipline-skills.md`;
   - `skills/skill-master/references/schemas.md`.
4. Consultar o `STANDARD.md` no ref pinado e verificar se 1.8 ainda é o
   contrato declarado.
5. Criar workspace externo para os evals.
6. Escrever os três prompts RED e o microteste.
7. Gerar o prompt viewer e aguardar aprovação.
8. Rodar os baselines Codex e Claude sem criar a skill.
9. Registrar falhas, pressões e racionalizações.
10. Executar o scaffold.
11. Escrever o menor GREEN.
12. Rodar testes estáticos.
13. Executar avaliações pareadas e grading.
14. Abrir o result viewer e aguardar feedback.
15. Iterar somente a partir da evidência.
16. Validar, empacotar e executar o DoD global.

## Prompt sugerido para o próximo workspace

```text
Continue a criação da skill `casa-workflow` no repositório
`/home/gustavo/Apps/agent-skills`.

Leia primeiro `AGENTS.md` e `docs/casa-workflow-handoff.md`.
Não implemente a skill antes de preparar, apresentar e obter aprovação dos
prompts RED exigidos pela `skill-master`. Revalide o estado atual do repo e do
CASA Standard; trate o handoff como contexto não normativo e preserve os gates
descritos nele.
```

## Referências externas verificadas

- [CASA Standard](https://github.com/atplus-digital/casa-standard)
- [CASA STANDARD.md](https://github.com/atplus-digital/casa-standard/blob/main/STANDARD.md)
- [OpenAI — Build skills](https://developers.openai.com/plugins/build/skills)
- [OpenAI — Non-interactive Codex](https://developers.openai.com/codex/non-interactive)
- [Claude Code — Agent Skills](https://code.claude.com/docs/en/agent-sdk/skills)
- [Claude Code — CLI reference](https://code.claude.com/docs/en/cli-reference)
