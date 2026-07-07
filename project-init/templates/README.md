# Template System

This directory is the authoritative source for how `/project-init` works.

Keep `SKILL.md` small. It should route into this directory, resolve the layer stack, and then follow the instructions defined here and in the selected template files. Do not duplicate workflow details back into `SKILL.md`.

## Purpose

`/project-init` scaffolds convention files from layered templates and then recommends next-step CLI commands without running them.

The layer stack always resolves in this order:

```text
_base -> <family> -> <family>/<derivative>
```

`base-only` is a reserved alias that resolves to `_base` only. It is not a real folder under `templates/`.

## Authoritative files

- `README.md` (this file): router workflow, cascade rules, and authoring standard
- `_base/AGENTS.md`: shared conventions and default optional-tool registry
- `_base/REQUIREMENTS.md`: shared scaffolded-file inventory and base requirements
- `<family>/AGENTS.md`: family-level conventions and setup concerns
- `<family>/REQUIREMENTS.md`: family-level dependency and project requirements
- `<family>/<derivative>/AGENTS.md`: derivative-specific overrides
- `<family>/<derivative>/REQUIREMENTS.md`: derivative-specific dependency and runtime requirements

## Router workflow

1. Resolve the templates root from the skill's own directory.
2. Read this file before resolving any specific template.
3. List available templates by scanning this directory recursively.
4. For each family or derivative shown to the user, read the first paragraph of that template's `AGENTS.md` for the description.
5. Resolve the selected stack:
   - `base-only` -> `_base`
   - `<family>` -> `_base` + `<family>`
   - `<family>/<derivative>` -> `_base` + `<family>` + `<family>/<derivative>`
6. Ask for project name and target directory.
7. If the target directory exists and is not empty, list the files that would be overwritten and require explicit approval before continuing.
8. Read `AGENTS.md` and `REQUIREMENTS.md` for every resolved layer before producing setup instructions.
9. Copy resolved layers in order, preserving dotfiles. Deeper layers overwrite shallower files at the same path.
10. Merge optional tools across resolved layers by the `Tool` column. A deeper layer may override a tool's description or install command, but tools omitted deeper stay inherited.
11. Do not offer a tool as optional when it is already mandatory in the resolved stack.
12. Resolve setup instructions by concern section: the deepest layer that defines a concern wins for that concern.
13. Recommend commands only. Do not run package managers, framework CLIs, or generate starter source files.
14. Summarize the scaffolded files and the resolved next steps.

## Cascade rules

Two things cascade:

- Files: deeper path wins on conflict.
- Instructions: deeper concern section wins on conflict.

Concerns only defined by shallower layers remain active. Non-conflicting concerns accumulate.

This is what prevents duplicate framework init commands or stale inherited guidance.

## Optional-tools rule

Optional tools are merged by tool id, not by replacing a whole table.

- Base defines the default registry.
- Families and derivatives can override individual tools by reusing the same `Tool` value.
- Families and derivatives can add new tools by introducing a new `Tool` value.
- A tool that becomes mandatory through the resolved stack must not be shown as optional.

## Directory and CLI safety

- Do not scaffold into a non-empty directory without approval.
- Some framework init CLIs require an empty directory, including `pnpm create vite .` and `bun init`.
- If scaffolded convention files would block such a CLI, instruct the user to temporarily move the scaffolded files aside, run the CLI, and then restore the scaffolded files on top.

## Standard section names

Use these sections in `AGENTS.md` and `REQUIREMENTS.md` so concern resolution stays stable:

- `## Setup`
- `## General`
- `## Code Style`
- `## Git`
- `## CI/CD`
- `## Agent Behavior`
- `## Runtime`
- `## Build tool`
- `## Package manager`
- `## Module system`
- `## Env contract`
- `## Entry point`
- `## Scripts contract`
- `## Test runner`
- `## Lint & Format`
- `## Type checking`
- `## Dead code`
- `## Git hooks`
- `## Framework init`
- `## Dependencies`
- `## Optional Tools`
- `## Project Structure`
- `## Skills`

Not every template needs every section. Only define the concerns that layer actually owns.

## Template authoring standard

- Put a clear purpose line or first paragraph at the top of every template `AGENTS.md`; the router uses it when listing choices.
- Keep runtime-agnostic guidance in the family layer and runtime-specific boundaries in derivatives.
- Put user-facing conventions in `AGENTS.md`.
- Put dependency, file inventory, and install requirements in `REQUIREMENTS.md`.
- Prefer overriding one concern cleanly instead of restating unrelated concerns.
- When adding a new concern, add it here first so the router contract stays explicit.
