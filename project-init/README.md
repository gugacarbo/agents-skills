# project-init

Skill para iniciar novos projetos a partir de templates curados via slash command `/project-init`.

## Como usar

No chat do opencode:

```
/project-init
```

O skill lista os templates disponíveis, pergunta o nome do projeto e o diretório alvo, copia os arquivos do template e recomenda comandos CLI para init de packages/frameworks.

## Templates

Templates são organizados em famílias com derivativos. O scaffolding aplica as camadas em ordem: `_base` → família → derivativo.

- **\_base/**: Aplicado a todo projeto — `.gitignore`, `.editorconfig`, `AGENTS.md` com convenções gerais
- **bun/**: Bun runtime (all-in-one: runtime, package manager, test runner, bundler)
- **typescript/**: Base TypeScript (agnóstico de runtime)
- **typescript/node/**: TypeScript + Node.js (tsx, @types/node)
- **typescript/vite/**: TypeScript + Vite (dev server, build tool)

## Adicionar novo template

Crie uma nova pasta em `templates/<familia>/` (template base) ou `templates/<familia>/<derivativo>/` com pelo menos:

- `AGENTS.md` — guia/resumo do template para o modelo
- `REQUIREMENTS.md` — dependências, ferramentas, padrões do template

Derivativos herdam os arquivos da família e sobrescrevem em caso de conflito.
