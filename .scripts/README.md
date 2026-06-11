# Scripts Internos

Esta pasta contem os comandos internos usados pelo orquestrador da raiz:

```sh
./skills.sh install
./skills.sh update
```

O usuario final deve preferir `./skills.sh <comando>` ou o fluxo remoto com `curl | sh`. Os arquivos daqui sao a implementacao desses comandos e tambem podem ser executados diretamente durante desenvolvimento.

## Comandos

| Arquivo      | Funcao                                                                            |
| ------------ | --------------------------------------------------------------------------------- |
| `install.sh` | Instala skills em um destino local, global, explicito ou repo-local.              |
| `update.sh`  | Compara a instalacao local com o snapshot remoto e sobrescreve apos confirmacao.  |
| `tests/*.sh` | Testes Bash de instalacao, update, bootstrap, orquestrador e regras de gitignore. |

## Desenvolvimento

Scripts de runtime devem continuar POSIX `sh`:

```sh
rtk sh -n skills.sh .scripts/install.sh .scripts/update.sh
```

Testes devem ser executados com `bash`, porque nem todos os arquivos em `tests/` precisam ser executaveis:

```sh
rtk bash -lc 'for test_script in .scripts/tests/*.sh; do bash "$test_script"; done'
```

Ou individualmente:

```sh
rtk bash .scripts/tests/install.sh
rtk bash .scripts/tests/update.sh
rtk bash .scripts/tests/bootstrap.sh
rtk bash .scripts/tests/gitignore.sh
rtk bash .scripts/tests/orchestrator.sh
```

## Cuidados

- Nao leia prompts apenas de stdin; `curl | sh` precisa de `/dev/tty` ou do seam `AGENTS_SKILLS_PROMPT_INPUT`.
- Nao adicione um `install.sh` na raiz; o ponto publico e `skills.sh install`.
- Nao remova arquivos locais extras no `update`; ele sobrescreve/adiciona arquivos remotos sem podar o destino.
- Ao criar arquivos novos, lembre que a raiz usa `.gitignore` allowlist.
