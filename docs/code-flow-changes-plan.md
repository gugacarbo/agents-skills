# Plano de mudanças da `code-flow`

## Decisões aprovadas

- A skill terá perfis adaptativos `light`, `standard` e `assured`.
- O perfil será reavaliado em todo início ou retomada e não será persistido em
  labels, body ou comentários de controle.
- Toda execução continuará exigindo uma issue de entrega elegível.
- O brainstorming deixará de ser uma fase e passará para
  `prompts/brainstorm.md`.
- O brainstorming será oferecido somente quando houver decisões importantes em
  aberto e dependerá do aceite explícito do usuário.
- Papéis poderão ser combinados conforme o perfil, mas ninguém poderá revisar
  ou aprovar o próprio trabalho.
- Antes de usar labels, a skill procurará o workflow nativo do repositório.
- Um workflow nativo só será usado quando for suficientemente completo e
  inequívoco. Na ausência de um padrão adequado, será usado integralmente o
  fallback `stage:*` da `code-flow`.
- A skill não exigirá bootstrap, arquivos ou configuração instalados no
  repositório consumidor.

## 1. Criar baseline verificável

Antes das alterações:

- preservar um snapshot da versão atual da `code-flow`;
- selecionar cenários representativos do comportamento atual;
- executar baseline para registrar cerimônia, perfil incorreto e gates
  desnecessários;
- não considerar os testes estruturais existentes como prova comportamental.

Cenários RED mínimos:

- refactor interno tratado pelo fluxo completo;
- mudança moderada recebendo todos os reviewers;
- mudança de auth sendo subavaliada;
- retomada confiando numa classificação anterior;
- repositório com workflow nativo sendo forçado a usar `stage:*`;
- brainstorming iniciado sem consentimento.

## 2. Reestruturar o router e as fases

Arquivos principais:

- `skills/code-flow/SKILL.md`;
- `skills/code-flow/phases/01-brainstorm.md`;
- `skills/code-flow/README.md`.

Alterações:

- remover “seis papéis independentes” da descrição;
- descrever os triggers por risco e entrega governada;
- mover `phases/01-brainstorm.md` para `prompts/brainstorm.md`;
- tornar o brainstorming condicional e dependente de aceite explícito;
- manter `/code-flow brainstorm` como convite explícito ao prompt;
- renomear os arquivos restantes de `phases/` para nomes sem numeração,
  evitando uma sequência quebrada;
- trocar referências a “Fase N” por operações semânticas: contexto, issue,
  plano, dispatch, review e integração.

## 3. Implementar a classificação adaptativa

Criar `skills/code-flow/references/risk-profiles.md` com:

- critérios observáveis de `light`, `standard` e `assured`;
- hard triggers de `assured`;
- regras de promoção e override;
- matriz de agentes, reviews e gates por nível;
- reavaliação obrigatória em cada início ou retomada;
- proibição de persistir o perfil em labels, body ou comentários de controle;
- tratamento de mudança material de escopo;
- promoção retroativa quando um risco novo revelar gates ausentes.

O `SKILL.md` deverá apenas rotear para essa referência.

### Perfil `light`

- Somente para mudanças internas, limitadas, reversíveis e com
  `spec impact: not required`.
- Um agente produz um plano compacto e implementa.
- A execução exige autorização explícita e worktree isolada.
- Um reviewer fresco e independente revisa a entrega.
- O merge continua explícito.

### Perfil `standard`

- Para mudança observável ou transversal moderada, reversível e concentrada em
  um repositório.
- O source-set e seu gate humano são exigidos somente quando houver `create` ou
  `update` de ADR/spec.
- Planejamento e execução são separados.
- Um reviewer independente revisa o plano.
- O humano aprova o plano.
- Um reviewer independente do executor revisa a entrega.
- O mesmo reviewer pode revisar plano e entrega, desde que não tenha produzido
  nenhum dos dois.
- A auditoria final é condicional a mudança posterior, ressalva ou risco novo.

### Perfil `assured`

- Obrigatório para auth, segurança, permissões, migrações, contratos públicos,
  conflito entre fontes, mudanças cross-repo, irreversibilidade ou alto blast
  radius.
- Mantém review independente do source-set e aprovação humana da fonte.
- Mantém `plan-writer` e `plan-reviewer` distintos, com aprovação humana do
  plano.
- Usa executor separado, delivery review fresca e auditoria final por outra
  instância fresca.
- O merge continua explícito.

## 4. Adaptar o contrato GitHub

Arquivos principais:

- `skills/code-flow/references/github-flow.md`;
- `skills/code-flow/references/orchestrator-cheatsheet.md`;
- arquivos ativos de `skills/code-flow/phases/`.

Implementar esta ordem:

1. descobrir guidance, issue forms, labels e entregas recentes;
2. reconhecer workflow nativo somente quando completo e inequívoco;
3. usar integralmente o workflow nativo ou integralmente o fallback;
4. nunca misturar os dois na mesma issue;
5. reavaliar o perfil e o próximo estágio em toda retomada.

A máquina fallback continuará usando `stage:*`, mas cada perfil percorrerá
somente o subconjunto necessário:

- `light`: plano compacto → execução → delivery review → merge;
- `standard`: source gate quando aplicável → plan review → execução → delivery
  review;
- `assured`: fluxo completo atual.

## 5. Tornar os papéis adaptativos

Atualizar todos os contratos em `skills/code-flow/agents/`:

- `issue-writer`: criação e source-set, sem review obrigatória em todo caso;
- `issue-reviewer`: obrigatório somente no perfil `assured`;
- `plan-writer`: usado em `standard` e `assured`;
- `plan-reviewer`: independente e obrigatório em `standard` e `assured`;
- `executor`: pode criar o plano compacto e implementá-lo em `light`;
- `delivery-reviewer`: sempre independente do executor; auditoria final fresca
  somente em `assured` ou quando riscos novos exigirem promoção.

Adicionar uma matriz de compatibilidade que determine:

- quais responsabilidades podem compartilhar a mesma instância;
- quais combinações são proibidas;
- quais instâncias precisam ser frescas;
- como retomar quando a instância original não estiver disponível.

Regra estrutural: ninguém revisa trabalho que produziu.

## 6. Ajustar templates e evidência

Atualizar `skills/code-flow/templates/` para:

- criar um template compacto de plano/outline para `light`, sem registrar o
  nome do perfil;
- tornar o gate de design aplicável somente após aceite do brainstorming;
- tornar o gate de source-set condicional;
- manter o gate de plano apenas em `standard` e `assured`;
- tornar a auditoria final condicional em `standard`;
- preservar merge explícito em todos os níveis;
- garantir que nenhum template persista `light`, `standard` ou `assured`;
- manter o envelope de evidência e os links imutáveis.

## 7. Remover dependência instalada no repositório

Arquivos principais:

- excluir `skills/code-flow/scripts/bootstrap.sh`;
- atualizar `skills/code-flow/scripts/doctor.sh`;
- atualizar `skills/code-flow/scripts/transition-issue.sh`;
- atualizar `skills/code-flow/SKILL.md`.

Alterações:

- remover `/code-flow tool bootstrap`;
- eliminar suporte a instalação vendorizada em `.code-flow`;
- executar helpers diretamente da instalação da skill;
- fazer `doctor.sh` inspecionar o repositório sem exigir arquivos próprios;
- limitar `transition-issue.sh` ao workflow fallback;
- criar labels fallback sob demanda quando ausentes;
- não criar labels fallback quando um workflow nativo tiver sido selecionado;
- manter `--require-from`, confirmação pós-mutação e reparo de drift.

## 8. Refazer testes estruturais

Atualizar `skills/code-flow/dev/tests.sh` para:

- remover a asserção de exatamente seis agentes obrigatórios;
- remover testes de bootstrap e `.code-flow`;
- verificar que brainstorming existe somente em `prompts/`;
- verificar ausência de perfil persistido nos templates;
- testar seleção nativa versus fallback;
- testar criação sob demanda das labels fallback;
- testar os três caminhos de stages;
- testar promoção por risco novo;
- testar que reviewer nunca revisa o próprio trabalho;
- procurar referências obsoletas a fases numeradas e review obrigatória
  universal.

## 9. Revisar avaliações comportamentais

Atualizar `skills/code-flow/evals/evals.json` com cenários para:

- seleção correta dos três níveis;
- override válido e downgrade inseguro;
- reclassificação durante retomada;
- ausência de persistência do perfil;
- aceite e recusa do brainstorming;
- workflow nativo completo;
- workflow parcial usando fallback;
- `light` sem source/plan reviews desnecessárias;
- promoção de `light` quando surgir impacto de spec;
- `assured` preservando todos os gates.

Executar:

- cinco amostras em fresh context para a redação da classificação;
- avaliações pareadas entre snapshot atual e versão nova;
- grading de comportamento, não apenas presença de palavras;
- comparação de acerto, tokens, latência, agentes despachados, gates humanos e
  falsos bloqueios.

## 10. Verificação final

Executar, nesta ordem:

```bash
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-code-flow build
pnpm test
pnpm build
pnpm skills-check
```

## Critérios de conclusão

- [ ] Nenhum perfil é persistido.
- [ ] Nenhum bootstrap ou arquivo é exigido no repositório consumidor.
- [ ] O brainstorming só ocorre com consentimento.
- [ ] Padrões nativos têm precedência quando forem completos e inequívocos.
- [ ] O fallback funciona sem preparação prévia.
- [ ] Cada nível reduz ou aumenta rigor conforme o design aprovado.
- [ ] Ninguém revisa ou aprova o próprio trabalho.
- [ ] Avaliações pareadas mostram redução de cerimônia sem regressão nos
      cenários de alto risco.
- [ ] Documentação, agentes, templates, scripts e evals descrevem o mesmo
      fluxo.

