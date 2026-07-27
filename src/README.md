# Scripts Internos

Os comandos internos usados pelo orquestrador da raiz ficam em `src/`:

```sh
./skills.sh install
./skills.sh update
./skills.sh build
./skills.sh dev
```

O usuário final deve preferir `./skills.sh <comando>` ou o fluxo remoto com `curl | sh`. Os arquivos daqui são a implementação desses comandos e também podem ser executados diretamente durante desenvolvimento.

## Comandos

| Arquivo          | Função                                                                               |
| ---------------- | ------------------------------------------------------------------------------------ |
| `src/install.sh` | Instala skills em um destino local, global, explícito ou repo-local.                 |
| `src/update.sh`  | Compara a instalação local com o snapshot remoto e sobrescreve após confirmação.     |
| `src/build.sh`   | Copia `skills/` para `dist/skills/`, limpa `~/.agents/skills` e publica o resultado. |
| `src/dev.sh`     | Observa `skills/` e atualiza somente `dist/skills/`.                                 |
| `src/tests/*.sh` | Testes Bash de instalação, update, bootstrap, orquestrador e regras de gitignore.    |

## Desenvolvimento

Scripts de runtime devem continuar POSIX `sh`:

```sh
rtk sh -n skills.sh src/build.sh src/dev.sh src/install.sh src/update.sh
```

Testes devem ser executados com `bash`, porque nem todos os arquivos em `src/tests/` precisam ser executáveis:

```sh
rtk bash -lc 'for test_script in src/tests/*.sh; do bash "$test_script"; done'
```

Ou individualmente:

```sh
rtk bash src/tests/install.sh
rtk bash src/tests/update.sh
rtk bash src/tests/bootstrap.sh
rtk bash src/tests/build.sh
rtk bash src/tests/dev.sh
rtk bash src/tests/gitignore.sh
rtk bash src/tests/orchestrator.sh
```

## Cuidados

- Não leia prompts apenas de stdin; `curl | sh` precisa de `/dev/tty` ou do seam `AGENTS_SKILLS_PROMPT_INPUT`.
- Não adicione um `install.sh` na raiz; o ponto público é `skills.sh install`.
- Não remova arquivos locais extras no `update`; ele sobrescreve/adiciona arquivos remotos sem podar o destino.
- Ao criar arquivos novos, lembre que a raiz usa `.gitignore` allowlist.
