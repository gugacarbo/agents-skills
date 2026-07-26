# Template system

The deterministic executor in `../scripts/project-init.mjs` is the only implementation of template discovery, inheritance, document composition, semantic package merges, collision detection, and file writes.

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

- `id`, `extends`, and `description`: identity, parent layers, and discovery text;
- `packageManager`: package manager used for generated recommendations;
- `documents`: output document name to Markdown section source;
- `files` and `omitTargets`: explicit assets and inherited targets removed by a derivative;
- `packageJson` and `omitPackageJson`: semantically managed fields and inherited JSON pointers removed by a derivative;
- `dependencies` and `devDependencies`: packages used to build missing-only install recommendations;
- `commands`: recommended framework, setup, and typecheck commands;
- `requiresFrameworkReady` and `readiness`: application gate plus required files and installed package names;
- `variants`: named framework variants and their typecheck/readiness contract;
- `optionalTools`: complete optional package, script, asset, and note overlays.

No file is copied merely because it exists under `files/`. Every emitted asset must be declared by a manifest. Sources remain under `templates/`; output targets are normalized relative paths and may not contain `.` or `..`.

## Document and package composition

Project-facing `AGENTS.md` and `REQUIREMENTS.md` fragments contain only second-level sections. New headings accumulate in layer order; a deeper layer replaces a shallower section with the same heading.

Managed `package.json` objects merge by key:

- missing fields are added without approval;
- equal fields are unchanged;
- differing managed fields become collisions such as `package.json#/scripts/lint`;
- unrelated existing fields are preserved.

## Lifecycle and safety

- `plan` never creates the target.
- `apply` writes nothing while any file or package-field collision lacks exact approval.
- Generator-first templates require their declared files and framework packages.
- Framework commands run from the absolute target parent and safely quote the target basename.
- Manifest sources and targets remain inside their allowed roots.
- Symlinks are rejected anywhere along planned write paths.
- Package-manager and framework commands are recommendations only.

## Optional tools

Optional tools merge by id across the resolved stack. Assets and package fields apply only when the tool is selected. A published optional tool must provide enough package, script, configuration, and hook wiring to be operational; dependency-only entries are not allowed.

## Adding a template

1. Add a manifest with explicit inheritance, readiness, package fields, and dependencies.
2. Add project-facing document fragments and explicitly declared assets.
3. Add deterministic tests for plan, apply, merge conflicts, path safety, and lifecycle.
4. Add a behavioral eval only when it exercises agent decisions beyond the executor.
5. Keep [FILES.md](FILES.md) aligned with every manifest-reachable source.
