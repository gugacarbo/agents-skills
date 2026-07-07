---
name: project-init
description: Interactive scaffold for initializing new projects from curated templates. Use with "/project-init" slash command when the user wants to start a new project, scaffold a project structure, or initialize a project from a template. Each template provides AGENTS.md (model guidance) and REQUIREMENTS.md (dependencies, tools, conventions).
user-invocable: true
argument-hint: ""
---

# /project-init

Initialize new projects from curated templates. Each template provides project conventions, model guidance, and dependency/tool requirements.

## Usage

```
/project-init                        # List available templates and scaffold interactively
/project-init typescript             # Scaffold with base TypeScript template
/project-init typescript/node        # Scaffold with TypeScript + Node derivative
/project-init typescript/vite        # Scaffold with TypeScript + Vite derivative
/project-init bun                   # Scaffold with Bun template
```

## Workflow

1. **List templates** — scan `templates/` directories recursively, show available options with descriptions. Derivatives are shown as `family/derivative` (e.g., `typescript/node`).
2. **Select template** — if not provided as argument, ask which template to use. If a family is selected without a derivative (e.g., `typescript`), scaffold only the family base.
3. **Collect project info** — ask for project name and target directory (default: `./<project-name>`).
4. **Ask about optional tools** — use a question tool to let the user select which optional tools from `_base/AGENTS.md` to include (turbo, lint-staged, test-staged, t3oss, vitest). Only add selected tools to the setup instructions.
5. **Scaffold base** — copy `templates/_base/` files (`.gitignore`, `.editorconfig`, `AGENTS.md`) to the target directory. These apply to every project.
6. **Scaffold family** — copy the selected template family files (e.g., `templates/typescript/`). Family `AGENTS.md` and `REQUIREMENTS.md` overwrite base versions.
7. **Scaffold derivative** — if a derivative was selected (e.g., `typescript/node`), copy `templates/typescript/node/` on top. Derivative files overwrite family files.
8. **Print setup instructions** — recommend, in order: (a) running CASA Standard init (`curl -fsSL https://raw.githubusercontent.com/atplus-digital/casa-standard/main/install.sh | sh -s -- . --repo-id <name>`), (b) initializing packages/frameworks via their CLI (e.g., `pnpm create`, `npx create-*`), (c) installing selected optional tools. Do NOT generate starter source files.

## Templates

Templates are organized as families with optional derivatives. Scaffolding applies layers in order: `_base` → family → derivative.

| Template              | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `_base`               | Applied to every project (`.gitignore`, `.editorconfig`, base `AGENTS.md`) |
| `bun`                 | Bun runtime (all-in-one: runtime, package manager, test runner, bundler) |
| `typescript`          | Base TypeScript conventions (runtime-agnostic)       |
| `typescript/node`     | TypeScript + Node.js (tsx, @types/node)              |
| `typescript/vite`     | TypeScript + Vite (dev server, build tool)           |

## Anti-Patterns

- Do NOT generate `package.json`, `tsconfig.json`, or any starter source files
- Do NOT run package managers or framework CLIs — only recommend the commands
- Do NOT modify files after scaffolding
