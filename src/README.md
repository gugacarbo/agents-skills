# Scripts Internos

Os comandos internos usados pelo orquestrador da raiz ficam em `src/`:

```sh
./skills.sh install
./skills.sh update
./skills.sh build
./skills.sh dev
```

O usuario final deve preferir `./skills.sh <comando>` ou o fluxo remoto com `curl | sh`. Os arquivos daqui sao a implementacao desses comandos e tambem podem ser executados diretamente durante desenvolvimento.

## Comandos

| Arquivo          | Funcao                                                                            |
| ---------------- | --------------------------------------------------------------------------------- |
| `src/install.sh` | Instala skills em um destino local, global, explicito ou repo-local.              |
| `src/update.sh`  | Compara a instalacao local com o snapshot remoto e sobrescreve apos confirmacao.  |
| `src/build.sh`   | Copia `skills/` para `dist/skills/` e publica o resultado em `~/.agents/skills`.  |
| `src/dev.sh`     | Observa `skills/`, executa o build e publica no destino selecionado.              |
| `src/tests/*.sh` | Testes Bash de instalacao, update, bootstrap, orquestrador e regras de gitignore. |

## Desenvolvimento

Scripts de runtime devem continuar POSIX `sh`:

```sh
rtk sh -n skills.sh src/build.sh src/dev.sh src/install.sh src/update.sh
```

Testes devem ser executados com `bash`, porque nem todos os arquivos em `src/tests/` precisam ser executaveis:

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

- Nao leia prompts apenas de stdin; `curl | sh` precisa de `/dev/tty` ou do seam `AGENTS_SKILLS_PROMPT_INPUT`.
- Nao adicione um `install.sh` na raiz; o ponto publico e `skills.sh install`.
- Nao remova arquivos locais extras no `update`; ele sobrescreve/adiciona arquivos remotos sem podar o destino.
- Ao criar arquivos novos, lembre que a raiz usa `.gitignore` allowlist.
