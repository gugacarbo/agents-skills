# agents-skills

Script orquestrador na raiz em `./skills.sh`, com scripts internos em `.scripts/`.

Instalacao rapida:

```sh
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install
```

Com argumentos:

```sh
curl -fsSL https://raw.githubusercontent.com/gugacarbo/agents-skills/main/skills.sh | sh -s -- install --global
```

Exemplos:

```sh
./skills.sh install
./skills.sh install --yes
./skills.sh install --path ~/.codex/skills
./skills.sh install --global
./skills.sh install --init --path ~/.agents/skills
./skills.sh install --instructions --path ~/.agents/skills
```
