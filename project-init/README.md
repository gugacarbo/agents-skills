# project-init

Skill to initialize new projects from curated templates via the `/project-init` slash command.

## Usage

In the opencode chat:

```
/project-init
/project-init base-only
/project-init typescript
/project-init typescript/node
/project-init typescript/vite
/project-init bun
```

The skill lists available templates, asks for the project name and target directory, copies template files, and recommends CLI commands for package/framework initialization. It scaffolds layered conventions only; it does not run package managers or framework CLIs for the user.

## Templates

Templates are organized as families with derivatives. Scaffolding applies layers in order: `_base` → family → derivative.

- **\_base/**: Applied to every project — `.gitignore`, `.editorconfig`, `AGENTS.md` with general conventions
- **bun/**: Bun runtime (all-in-one: runtime, package manager, test runner, bundler)
- **typescript/**: Base TypeScript (runtime-agnostic)
- **typescript/node/**: TypeScript + Node.js (tsx, @types/node)
- **typescript/vite/**: TypeScript + Vite (dev server, build tool)

Families without derivatives (e.g., `bun`) are valid — the resolved layer stack is `_base` → family.

`base-only` is a reserved alias that resolves to the `_base` layer without selecting a family. It is not a real directory inside `templates/`.

## Resolution rules

- Files merge in cascade order: `_base` → family → derivative, with deeper layers overwriting conflicting paths.
- Instructions resolve by concern section (`## Setup`, `## Framework init`, `## Package manager`, and so on), with the deepest section for a concern winning.
- Optional tools merge by tool name across layers. A deeper layer can override a tool's install command without replacing the entire inherited tool list.

## Adding a new template

Create a new folder under `templates/<family>/` (base template) or `templates/<family>/<derivative>/` with at least:

- `AGENTS.md` — template guide/summary for the model
- `REQUIREMENTS.md` — dependencies, tools, and patterns for the template

Derivatives inherit files from the family and override on conflict.
