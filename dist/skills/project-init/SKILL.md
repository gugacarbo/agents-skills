---
name: project-init
description: Scaffold a new project from curated templates when the user wants to start, bootstrap, or initialize a new project. Use for requests like starting a TypeScript, Bun, Node, or Vite app, especially when layered project conventions should be copied before recommending setup commands. Invoked as "/project-init [template]".
user-invocable: true
argument-hint: "[template]"
---

# project-init

Use this skill to scaffold convention files from layered templates without running framework or package-manager commands.

## Router

1. Resolve `templates/` relative to this skill's own directory, never relative to the user's cwd.
2. Read [templates/README.md](templates/README.md) first. It is the authoritative workflow and template-authoring standard.
3. Resolve the requested stack:
   - `base-only` -> `_base`
   - `<family>` -> `_base` + `<family>`
   - `<family>/<derivative>` -> `_base` + `<family>` + `<family>/<derivative>`
4. Read `AGENTS.md` and `REQUIREMENTS.md` for every resolved layer before generating instructions.
5. Follow the workflow, cascade rules, and section standards from [templates/README.md](templates/README.md).

## Routing rule

Keep this file small. Do not duplicate the detailed workflow, template registry, concern catalog, or setup rules here when they already live under `templates/`.
