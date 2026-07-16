# Memória do workspace `agent-skills`

Este repositório substitui o checkout antigo em `~/.agents/skills`. Para tarefas
feitas a partir deste diretório, use `/home/gustavo/Apps/agent-skills` como o
caminho canônico; referências históricas ao caminho antigo pertencem ao mesmo
projeto e não indicam uma instalação ainda existente.

## Decisões preservadas

- `code-toolbox` é uma skill autocontida: o fluxo de brainstorming está
  integrado nela, incluindo seus prompts, scripts e documentação auxiliar.
- A documentação do companion visual fica em
  `skills/code-toolbox/phases/01_1-visual-companion.md`.
- `/code-toolbox` sem argumento executa o fluxo completo. Com uma fase
  (`brainstorm`, `spec`, `plan`, `decompose`, `dispatch`, `review` ou
  `integrate`), começa naquela fase e continua pelas fases seguintes.
- `skills/code-toolbox/SKILL.md` é a fonte autoritativa do roteamento; o
  `README.md` deve permanecer alinhado a ele.
- O fluxo de dispatch usa o prompt mantido em
  `skills/code-toolbox/prompts/worker-prompt-template.md`.
- O notifier deve sinalizar conclusão verificada, não apenas eventos de parada;
  o runtime instalado deve ser executável mesmo quando os arquivos copiados
  não preservam o bit de execução.

## Verificação e convenções

- Prefixe comandos shell com `rtk`, conforme `AGENTS.md` e `RTK.md`.
- Scripts de runtime permanecem POSIX `sh`; testes permanecem Bash.
- Para alterações em skills, valide a fonte e o artefato `dist/skills/` quando
  aplicável, além dos testes focados da skill.
- Em mudanças de organização, procure referências antigas com `rg` antes de
  concluir para evitar documentação divergente.

## Histórico recuperado

O histórico detalhado continua no armazenamento de memória do Codex. Os
rollouts principais para este repositório foram:

- integração de brainstorming e organização do companion visual;
- roteamento por fase do `code-toolbox`;
- refinamentos de documentação, diagramas, bootstrap e `.gitignore` do
  companion visual;
- atualização por referência remota e sincronização dos helpers;
- substituição do prompt de worker;
- aprovação de prompts e artefatos do `skill-master`;
- revisão e correção do `task-completion-notifier`.
