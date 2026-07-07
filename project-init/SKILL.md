---
name: project-init
description: Scaffold a new project from curated templates when the user wants to start/bootstrap/initialize a new project. Invoked as "/project-init [template]". Copies layered conventions (base, family, derivative) and prints CLI setup instructions without running them.
user-invocable: true
argument-hint: "[template]"
---

# project-init

Initialize new projects from curated templates. Each template provides project conventions, model guidance, and dependency/tool requirements.

## Usage

```
/project-init                        # List available templates and scaffold interactively
/project-init base-only              # Scaffold with base template only (no family/derivative)
/project-init typescript             # Scaffold with base TypeScript template
/project-init typescript/node        # Scaffold with TypeScript + Node derivative
/project-init typescript/vite        # Scaffold with TypeScript + Vite derivative
/project-init bun                   # Scaffold with Bun template
```

## Templates Location

Templates root is the directory of this `SKILL.md` file joined with `templates/`. Always resolve it as an absolute path derived from the skill's own location — do not scan `templates/` relative to the user's current working directory, which may be arbitrary.

## Cascade Principle

Template layers are resolved in cascade order, from shallowest to deepest:

```
_base  →  <family>  →  <family>/<derivative>
```

Two things cascade, and in both the **deepest layer wins** for any given concern:

1. **Files** — when two layers contain a file at the same relative path, the deeper layer's version overwrites the shallower one. The final scaffolded tree is the merge of all resolved layers, deepest-wins per path.

2. **Instructions** — each layer's `AGENTS.md` (and `REQUIREMENTS.md`) is read in cascade order and merged. Instructions are grouped by *concern* (e.g., "framework init CLI", "package manager", "runtime deps", "test runner", "lint setup", "CASA Standard init"). For each concern:
   - The **deepest layer that addresses that concern wins**; shallower layers' instructions for that same concern are discarded.
   - Concerns only addressed by shallower layers (and not overridden deeper) are kept as-is.
   - Non-conflicting instructions accumulate across all layers.

This prevents two classes of mistake:
- **Duplication**: e.g., running both a TypeScript init CLI and a Vite init CLI. Vite's CLI subsumes TypeScript project scaffolding, so the Vite layer's "framework init" instruction replaces TypeScript's for that concern.
- **Stale conventions**: e.g., a derivative that switches the test runner must override the family's test-runner choice, not augment it.

The agent must resolve **all** applicable layers in cascade before printing setup instructions — never stop at the family when a derivative exists, and never apply only the deepest layer (shallower conventions still contribute concerns the deeper layers don't touch).

## Workflow

1. **Resolve templates root** — compute `<this-skill-dir>/templates/` as an absolute path. All template lookups happen under this root.
2. **List templates** — scan `templates/` recursively and show available options. Derivatives are shown as `family/derivative` (e.g., `typescript/node`). For each entry's description, read the dedicated purpose line / first paragraph of that template's `AGENTS.md` — do not hardcode descriptions.
3. **Select template** — if an argument was provided, resolve it against the template tree. If the argument does not match any family or derivative, list the available templates and re-ask interactively instead of failing. If a family is selected without a derivative (e.g., `typescript`), the resolved layer stack is `_base` → family. If a derivative is selected (e.g., `typescript/vite`), the resolved layer stack is `_base` → `typescript` → `typescript/vite`. The agent always resolves and applies the full stack — see Cascade Principle.
4. **Collect project info** — ask for project name and target directory (default: `./<project-name>`).
5. **Validate target directory**:
   - If the directory does not exist, create it with `mkdir -p`.
   - If the directory exists and is **not empty**, confirm with the user before overwriting any files. List which files would be overwritten and require explicit approval to proceed.
6. **Load the layer stack** — for each resolved layer in cascade order (`_base`, family, derivative), read its `AGENTS.md` (and `REQUIREMENTS.md` if present). Keep them in memory; steps 7 and 9 consume them.
7. **Scaffold files in cascade** — copy the resolved layers in cascade order (`_base` → family → derivative) into the target directory, preserving dotfiles. At each step, files already present from a shallower layer at the same relative path are overwritten by the deeper layer. The agent must apply **all** applicable layers, never only the deepest. The resulting scaffolded `AGENTS.md` (after overwrite) is the project's starting conventions file.
8. **Ask about optional tools** — read the "Optional Tools" table from `templates/_base/AGENTS.md` and use a question tool to let the user select which tools to include. Only add selected tools to the setup instructions. Do not hardcode the list here — always read it from `_base/AGENTS.md` to avoid drift. (If a family/derivative's `AGENTS.md` overrides the optional-tools set, the deepest definition wins per the Cascade Principle.)
9. **Resolve setup instructions in cascade** — read the `AGENTS.md` (and `REQUIREMENTS.md` where present) of every resolved layer in cascade order. For each concern (framework init CLI, package manager, runtime/dev deps, test runner, lint, CASA Standard init, etc.), keep only the instruction from the **deepest layer that addresses that concern**; discard shallower layers' instructions for that same concern. Accumulate concerns that no deeper layer overrides. The result is a single, deduplicated, conflict-free instruction set.
10. **Print setup instructions** — output the resolved instruction set from step 9, in the order the deepest layer that owns the first concern documents it. Concretely this typically includes:
    (a) CASA Standard / docs-router init (from `_base` unless overridden), with the conflict note from the Cascade Principle: if that installer would overwrite the just-scaffolded `AGENTS.md`, prefer merging/extending over replacing; if it is non-interactive and non-merging, ask the user how to resolve before recommending the command.
    (b) Framework/package init — exactly **one** CLI command for the framework-init concern, sourced from the deepest layer that addresses it (e.g., for `typescript/vite` use the Vite CLI, not a TypeScript CLI followed by Vite).
    (c) Optional tool installs — for each tool selected in step 8, the install command from the deepest `AGENTS.md` "Optional Tools" definition that lists it.

    Do NOT generate starter source files (no `package.json`, `tsconfig.json`, source folders, etc.) and do NOT run any of the recommended commands.
11. **Verify and summarize** — print a summary of what was created:
    - The list of files scaffolded, relative to the target directory.
    - Confirmation that scaffolding completed.
    - The resolved next steps (the commands from step 10).

## Templates

Templates are organized as families with optional derivatives, applied as a cascade (see Cascade Principle above). The list below is illustrative — discover the actual set and their descriptions at runtime by scanning `templates/` and reading each template's `AGENTS.md`.

- `_base/` — applied to every project; defines shared conventions, the "Optional Tools" table, and the post-scaffold setup steps. Read its `AGENTS.md` for the authoritative list of files and behaviors it contributes.
- `<family>/` — a runtime/ecosystem base (e.g., `typescript`, `bun`). Each has `AGENTS.md` and usually `REQUIREMENTS.md`.
- `<family>/<derivative>/` — a specialization (e.g., `typescript/node`, `typescript/vite`). Inherits and **overrides per concern** the family and base, per the Cascade Principle.

When listing templates in step 2, for each family and derivative read the first paragraph (or a dedicated purpose line) of its `AGENTS.md` and show it as the description. Do not hardcode descriptions here.

Template authors should organize each `AGENTS.md`/`REQUIREMENTS.md` by **concern** (clearly labeled sections like `## Framework init`, `## Runtime deps`, `## Test runner`, `## Lint`). The cascade resolver keys off these sections; a deeper layer overrides a shallower layer only for concerns it explicitly addresses.

## Examples

User inputs that should trigger this skill (even without the explicit `/project-init` command):

- "start a new TypeScript project"
- "scaffold a Vite app"
- "initialize a Node project here"
- "create a new Bun project"
- "set up a new repo with project conventions"
- "I want to start a new web app, help me scaffold it"

## Anti-Patterns

- Do NOT generate `package.json`, `tsconfig.json`, or any starter source files.
- Do NOT run package managers or framework CLIs — only recommend the commands.
- Do NOT recommend two CLIs for the same concern (e.g., a TypeScript init CLI and a Vite init CLI). The cascade resolver picks the deepest layer's instruction per concern; shallower duplicate instructions are dropped, not accumulated.
- Do NOT skip shallower layers when a derivative is selected — the cascade applies the full stack (`_base` → family → derivative). Shallower layers still contribute any concern the deeper layers don't override.
- After step 7 (scaffold files in cascade) completes, do NOT edit any scaffolded file. Subsequent setup is the user's responsibility via the recommended CLI commands resolved in step 10.
- Do NOT duplicate template content (file lists, setup commands, tool tables, template descriptions) in this file. The scaffolded `AGENTS.md` and `REQUIREMENTS.md` are the single source of truth; this file only describes the **workflow** that consumes them. If a template's contents change, this file must not need editing.
