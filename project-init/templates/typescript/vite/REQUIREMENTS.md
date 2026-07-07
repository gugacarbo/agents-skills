# TypeScript + Vite — Requirements

> All packages are installed via CLI at their latest stable version. No pinned versions.

## Runtime

- Node.js (LTS)
- Package manager: pnpm (mandatory)

## Core Dependencies

| Package    | Purpose                 | Install                  |
| ---------- | ----------------------- | ------------------------ |
| typescript | TypeScript compiler     | `pnpm add -D typescript` |
| vite       | Build tool + dev server | `pnpm add -D vite`       |

## Dev Dependencies

| Package | Purpose                                   | Install              |
| ------- | ----------------------------------------- | -------------------- |
| vitest  | Test runner (shares Vite config)          | `pnpm add -D vitest` |
| biome   | Linter + formatter (unified)              | `pnpm add -D biome`  |
| knip    | Dead code and unused dependency detection | `pnpm add -D knip`   |
| husky   | Git hooks (pre-commit, pre-push)          | `pnpm add -D husky`  |

## Install all at once

```sh
pnpm create vite . --template vanilla-ts   # or react-ts, vue-ts, svelte-ts
pnpm add -D biome knip husky
pnpm exec husky init
```

## Framework Plugins (optional)

| Package                      | Purpose        | Install                                    |
| ---------------------------- | -------------- | ------------------------------------------ |
| @vitejs/plugin-react         | React support  | `pnpm add -D @vitejs/plugin-react`         |
| @vitejs/plugin-vue           | Vue support    | `pnpm add -D @vitejs/plugin-vue`           |
| @sveltejs/vite-plugin-svelte | Svelte support | `pnpm add -D @sveltejs/vite-plugin-svelte` |

## Git Hooks (Husky)

- **pre-commit**: `pnpm lint && pnpm typecheck`
- **pre-push**: `pnpm test`

## CI Requirements

- Type checking: `tsc --noEmit`
- Tests: `vitest run`
- Lint: `biome check`
- Dead code: `knip`
- Build: `vite build`
- All must pass on PR/merge
