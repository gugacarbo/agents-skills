# Template system

The deterministic executor in `../scripts/project-init.mjs` is the only implementation of template discovery, inheritance, composition, collision detection, and file writes.

## Layer model

Every selectable layer has a `template.json`. Inheritance is explicit through `extends`:

```text
_base
├── bun
└── typescript
    ├── typescript/node
    ├── typescript/vite
    └── typescript/tanstack-start
```

`base-only` is the user-facing alias for `_base`.

## Manifest contract

Supported fields:

- `id`: stable template id;
- `extends`: parent ids, resolved before the current layer;
- `description`: user-facing discovery text;
- `packageManager`: resolved package manager;
- `documents`: output document name to Markdown section source;
- `files`: explicit `{ source, target }` assets;
- `commands`: recommended framework, install, setup, and typecheck commands;
- `requiresFrameworkReady`: block overlay application until `package.json` exists;
- `variants`: named framework variants and their typecheck contract;
- `optionalTools`: tool descriptions, per-package-manager commands, assets, and notes.

No file is copied merely because it exists under a `files/` directory. Every emitted asset must be declared by a manifest.

## Document composition

Layer `AGENTS.md` and `REQUIREMENTS.md` files are project-facing fragments. They must not contain scaffolder control flow, question-tool instructions, copy rules, or optional-tool selection logic.

The executor merges second-level Markdown sections by heading:

- new headings accumulate in layer order;
- a deeper layer replaces a shallower section with the same heading;
- the generated document reports no scaffolder-only instructions.

Use stable concern headings such as `General`, `Runtime`, `Package manager`, `Module system`, `Env contract`, `Entry point`, `Scripts contract`, `Test runner`, `Lint & Format`, `Type checking`, `Dead code`, `Git hooks`, `Commands`, `Dependencies`, `Project Structure`, `CI/CD`, and `Skills`.

## Lifecycle contract

- `plan` never creates the target.
- Existing files are collisions only when the overlay would write the same path with different bytes.
- `apply` is atomic with respect to approval: it writes nothing while any collision lacks exact path approval.
- Unrelated files are preserved.
- Generator-first templates such as Vite and TanStack Start require `package.json` before the overlay can be applied.
- Package-manager and framework commands are recommendations only.

## Optional tools

Optional tools merge by id across the resolved stack. Assets are copied only when the tool is selected. Package-manager-specific commands belong in the manifest, not in project-facing Markdown.

## Adding a template

1. Add `template.json` with explicit inheritance.
2. Add project-facing document fragments.
3. Declare every emitted asset.
4. Add deterministic tests for plan, apply, collisions, and lifecycle.
5. Add a behavioral eval only when it exercises agent decisions beyond the script's deterministic tests.

Keep the static publication inventory in [FILES.md](FILES.md) aligned with manifest sources.
