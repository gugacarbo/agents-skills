# agents-skills

Pacote de skills para agentes de codificação (VS Code, Codex, Cursor, etc.), com script orquestrador em `./skills.sh`, scripts internos em `src/` e as skills publicadas em `skills/`.

## Instalação rápida

```sh
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install
```

Para instalar somente uma ou mais skills, informe os nomes depois de `install`:

```sh
./skills.sh install commit-changes
./skills.sh install commit-changes find-docs
```

## Comandos

| Comando   | Descrição                                                            |
| --------- | -------------------------------------------------------------------- |
| `install` | Instala as skills no diretório de destino                            |
| `update`  | Atualiza uma instalação existente com a versão remota                |
| `build`   | Gera `dist/skills/`, limpa e copia as skills para `~/.agents/skills` |
| `dev`     | Observa as fontes e atualiza somente `dist/skills`                   |
| `help`    | Exibe a ajuda com os comandos disponíveis                            |

## Desenvolvimento das skills

As skills com código executável usam packages privados de desenvolvimento no
workspace `pnpm`: `skill-master`, `code-flow` e
`task-completion-notifier`. Os `package.json` ficam somente na árvore de
fontes e são removidos pelo build antes da publicação.

```sh
pnpm install
pnpm test                         # testes globais e testes das skills
pnpm test:skills                  # somente testes das skills com package
pnpm --filter @gugacarbo/skill-master test
pnpm --filter @gugacarbo/skill-code-flow test
pnpm --filter @gugacarbo/skill-task-completion-notifier test
pnpm validate:skills              # validações opcionais declaradas por skill
pnpm build                        # valida skills e gera dist/skills/
```

O workspace organiza o desenvolvimento, mas a distribuição continua sendo
uma pasta de skill contendo `SKILL.md` e seus arquivos de runtime. Dependências
e manifests de desenvolvimento não fazem parte do artefato instalado.

## Opções do `install`

| Opção             | Descrição                                                                           |
| ----------------- | ----------------------------------------------------------------------------------- |
| `-p, --path PATH` | Instala as skills no caminho especificado                                           |
| `-g, --global`    | Força `~/.agents/skills` como destino (sempre pede confirmação)                     |
| `--init`          | Clona o repositório via `git clone` em vez de copiar os arquivos                    |
| `--instructions`  | Copia o `README.md` do repositório para o destino                                   |
| `--fresh`         | Remove as skills existentes no destino antes de instalar (preserva outros arquivos) |
| `-y, --yes`       | Aprova automaticamente a instalação local (não pula confirmação global)             |
| `-h, --help`      | Exibe a ajuda do comando                                                            |

Além das opções, o comando aceita um ou mais nomes de skills. Quando nenhum
nome é informado, todas as skills disponíveis são instaladas.

## Opções do `update`

| Opção             | Descrição                                        |
| ----------------- | ------------------------------------------------ |
| `-p, --path PATH` | Atualiza as skills no caminho especificado       |
| `-g, --global`    | Atualiza `~/.agents/skills`                      |
| `-y, --yes`       | Sobrescreve automaticamente se houver diferenças |
| `-h, --help`      | Exibe a ajuda do comando                         |

## Variáveis de ambiente

| Variável                     | Padrão                                                           | Descrição                                              |
| ---------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------ |
| `AGENTS_SKILLS_OWNER`        | `gugacarbo`                                                      | Owner do GitHub para clone e download                  |
| `AGENTS_SKILLS_REPO`         | `agents-skills`                                                  | Nome do repositório no GitHub                          |
| `AGENTS_SKILLS_REF`          | `main`                                                           | Branch ou tag usada para clone e download              |
| `AGENTS_SKILLS_REPO_URL`     | `https://github.com/$OWNER/$REPO.git`                            | URL completa do repositório Git                        |
| `AGENTS_SKILLS_ARCHIVE_URL`  | `https://github.com/$OWNER/$REPO/archive/refs/heads/$REF.tar.gz` | URL do tarball para bootstrap via `curl \| sh`         |
| `AGENTS_SKILLS_PROMPT_INPUT` | `/dev/tty`                                                       | Origem de entrada para prompts interativos (test seam) |
| `NO_COLOR`                   | —                                                                | Desabilita saída colorida no terminal                  |

## Skills incluídas

| Skill                      | Descrição                                                         |
| -------------------------- | ----------------------------------------------------------------- |
| `commit-changes`           | Cria commits com mensagens no padrão Conventional Commits         |
| `find-docs`                | Busca documentação atualizada de bibliotecas e frameworks         |
| `init-deep`                | Gera arquivos `AGENTS.md` hierárquicos no código (modo `--light`) |
| `project-init`             | Scaffold de novos projetos a partir de templates curados          |
| `skill-master`             | Criação, edição e avaliação de skills reutilizáveis para agentes  |
| `code-flow`                | Entregas por issue com rigor adaptativo, reviews e gates humanos  |
| `task-completion-notifier` | Notificação de conclusão de tarefas no desktop                    |

## Exemplos

### Instalação

```sh
# Instala na pasta atual se ela terminar em skills; caso contrário, em ~/.agents/skills
./skills.sh install

# Instalação com aprovação automática (apenas local)
./skills.sh install --yes

# Instalar em um caminho específico
./skills.sh install --path ~/.codex/skills

# Instalar somente uma skill
./skills.sh install commit-changes --path ~/.codex/skills

# Instalar mais de uma skill
./skills.sh install commit-changes find-docs --path ~/.codex/skills

# Instalação global
./skills.sh install --global

# Clonar o repositório em vez de copiar
./skills.sh install --init --path ~/.agents/skills

# Copiar também o README.md
./skills.sh install --instructions --path ~/.agents/skills

# Substituir as skills instaladas, preservando arquivos auxiliares do destino
./skills.sh install --fresh --path ~/.agents/skills

# Via curl (bootstrap remoto)
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install commit-changes find-docs
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install --global
```

### Desenvolvimento local

```sh
# Gera dist/skills/ e copia as skills para ~/.agents/skills.
./skills.sh build

# Pergunta o destino (padrão: ~/.agents/skills), publica o build inicial
# e o atualiza sempre que skills/ mudar.
./skills.sh dev
```

### Atualização

```sh
# Atualização interativa (detecta destino automaticamente)
./skills.sh update

# Atualização com sobrescrita automática
./skills.sh update --yes

# Atualizar um caminho específico
./skills.sh update --path ~/.agents/skills

# Atualização global
./skills.sh update --global

# Via curl
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- update --global
```

### Usando um fork ou branch alternativa

```sh
AGENTS_SKILLS_OWNER=meu-fork AGENTS_SKILLS_REF=develop ./skills.sh install --global
```

## Estrutura do projeto

```
.
├── skills.sh              # Entrypoint público; suporta bootstrap via curl | sh
├── src/                   # Scripts de instalação, atualização e desenvolvimento
├── scripts/               # Utilitários de documentação e hooks
├── dist/skills/            # Artefato gerado e versionado, usado pelo instalador
└── skills/                # Fonte das skills instaláveis
    ├── commit-changes/        # Commits com Conventional Commits
    ├── find-docs/             # Busca de documentação
    ├── init-deep/             # Geração de AGENTS.md
    ├── project-init/          # Scaffold de projetos
    ├── skill-master/          # Autoria e avaliação de skills
    ├── code-flow/          # Entregas por issue com workflow verificável
    └── task-completion-notifier/ # Notificação de conclusão
```

O comando `./skills.sh install` copia as skills de `dist/skills/` diretamente
para o destino escolhido. Nomes posicionais limitam a cópia às skills
selecionadas. A pasta `skills/` é a fonte; execute `./skills.sh build` antes de
publicar alterações.
